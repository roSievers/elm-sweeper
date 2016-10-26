module Main exposing (..)

import Html exposing (Html, div, text, button, br, textarea)
import Html.App
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (placeholder, value)
import Return exposing (Return)
import Dict exposing (Dict)
import Grid exposing (Grid, Direction(..), Coordinate)
import Types exposing (..)
import Cell exposing (Cell)
import ExampleLevel
import GameView
import Monocle.Lens as Lens exposing (Lens, modify)
import Monocle.Optional as Optional
import Monocle.Common exposing ((=>))
import HexcellParser


main =
    Html.App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { route : Route
    , currentGame : GameModel
    , pasteBox : String
    , flippedControlls : Bool
    }


gameModel : Lens Model GameModel
gameModel =
    Lens (.currentGame) (\gModel model -> { model | currentGame = gModel })


gameGrid : Lens GameModel (Grid Cell)
gameGrid =
    Lens (.level) (\newGrid model -> { model | level = newGrid })


init : Return msg Model
init =
    Return.singleton
        { route = InGame
        , currentGame = initExampleGame
        , pasteBox = ""
        , flippedControlls = True
        }


initExampleGame : GameModel
initExampleGame =
    { level = ExampleLevel.grid1
    , mistakes = 0
    }



-- UPDATE


update : Msg -> Model -> Return msg Model
update action model =
    case action of
        Reveal button coordinate ->
            model
                |> modify gameModel
                    (handleReveal model.flippedControlls button coordinate)
                |> Return.singleton

        ToggleOverlay coordinate overlay ->
            model
                |> Optional.modify
                    (Optional.fromLens (Lens.compose gameModel gameGrid)
                        => (Grid.at coordinate)
                    )
                    (Cell.setOverlay overlay)
                |> Return.singleton

        ToggleEnabled coordinate enabled ->
            model
                |> Optional.modify
                    (Optional.fromLens (Lens.compose gameModel gameGrid)
                        => (Grid.at coordinate)
                    )
                    (if enabled then
                        Cell.setEnabled enabled
                     else
                        Cell.setEnabled enabled >> Cell.setOverlay False
                    )
                |> Return.singleton

        FlipControlls ->
            Return.singleton { model | flippedControlls = not model.flippedControlls }

        SetRoute route ->
            Return.singleton { model | route = route }

        PasteBoxEdit newPaste ->
            Return.singleton { model | pasteBox = newPaste }

        NewLevel grid ->
            model
                |> modify gameModel (setGrid grid)
                |> Return.singleton



-- Update helper functions used while ingame


handleReveal : Bool -> MouseButton -> Coordinate -> GameModel -> GameModel
handleReveal flippedControlls button coordinate model =
    Maybe.map
        (\cell ->
            let
                mineClicked =
                    Cell.isMine cell

                mineDesired =
                    xor (button == LeftButton) flippedControlls
            in
                case mineClicked == mineDesired of
                    True ->
                        Optional.modify
                            ((Optional.fromLens gameGrid) => (Grid.at coordinate))
                            Cell.reveal
                            model

                    False ->
                        { model
                            | mistakes = model.mistakes + 1
                        }
        )
        (Grid.get coordinate model.level)
        |> Maybe.withDefault model


setGrid : Grid Cell -> GameModel -> GameModel
setGrid grid model =
    { model | level = grid }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    case model.route of
        InGame ->
            GameView.gameView model.flippedControlls model.currentGame

        MainMenu ->
            mainMenuView model


mainMenuView : Model -> Html Msg
mainMenuView model =
    div []
        [ text "Fancy Main Menu!"
        , button [ onClick (SetRoute InGame) ] [ text "CurrentGame" ]
        , br [] []
        , textarea
            [ placeholder "Paste a Hexcells level file!"
            , onInput PasteBoxEdit
            , value model.pasteBox
            ]
            []
        , br [] []
        , parsedResultView (first (HexcellParser.parseLevel model.pasteBox))
        ]


first ( a, _ ) =
    a


parsedResultView : Result (List String) HexcellParser.Intermediate -> Html Msg
parsedResultView parseResult =
    case parseResult of
        Err errorMessage ->
            text ("Parsing Error: " ++ toString errorMessage)

        Ok intermediate ->
            div []
                [ text "Parsing successful!"
                , text <| "Author: " ++ intermediate.author
                , text <| "Title: " ++ intermediate.title
                , button [ onClick (NewLevel intermediate.content) ] [ text "Load Level" ]
                ]
