module Main exposing (..)

import Html exposing (Html, div, text, button, br, textarea)
import Html.App
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (placeholder, value)
import Return exposing (Return)
import Dict exposing (Dict)
import Grid exposing (Grid, Direction(..), Coordinate)
import Types exposing (..)
import ExampleLevel
import GameView
import Counting exposing (isMineContent)
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
        }


initExampleGame : GameModel
initExampleGame =
    { level = ExampleLevel.grid1
    , intent = RevealEmpty
    , mistakes = 0
    }



-- UPDATE


update : Msg -> Model -> Return msg Model
update action model =
    case action of
        Reveal intent coordinate cell ->
            model
                |> modify gameModel (handleReveal intent coordinate cell)
                |> Return.singleton

        ToggleOverlay coordinate overlay ->
            model
                |> Optional.modify
                    (Optional.fromLens (Lens.compose gameModel gameGrid)
                        => (Grid.at coordinate)
                    )
                    (toggleOverlay overlay)
                |> Return.singleton

        SetIntent intent ->
            model
                |> modify gameModel (\gModel -> { gModel | intent = intent })
                |> Return.singleton

        SetRoute route ->
            Return.singleton { model | route = route }

        PasteBoxEdit newPaste ->
            Return.singleton { model | pasteBox = newPaste }

        NewLevel grid ->
            model
                |> modify gameModel (setGrid grid)
                |> Return.singleton



-- Update helper functions used while ingame


handleReveal : Intent -> Coordinate -> CellData -> GameModel -> GameModel
handleReveal intent coordinate cell model =
    let
        mineClicked =
            isMineContent cell.content

        mineDesired =
            intent == RevealMine
    in
        case mineClicked == mineDesired of
            True ->
                { model
                    | level = Grid.insert coordinate (GameCell { cell | revealed = True }) model.level
                }

            False ->
                { model
                    | mistakes = model.mistakes + 1
                }


toggleOverlay : Bool -> Cell -> Cell
toggleOverlay overlay cell =
    case cell of
        GameCell cellData ->
            case cellData.content of
                Flower _ ->
                    GameCell { cellData | content = Flower overlay }

                _ ->
                    GameCell cellData

        RowCount direction _ ->
            RowCount direction overlay

        TypedRowCount direction _ ->
            TypedRowCount direction overlay


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
            GameView.gameView model.currentGame

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
