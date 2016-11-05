module Main exposing (..)

import Html exposing (Html, div, text, button, br, textarea, h1, p, a)
import Html.App
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (placeholder, value, href)
import Return exposing (Return)
import Dict exposing (Dict)
import Grid exposing (Grid, Direction(..), Coordinate)
import Types exposing (..)
import Cell exposing (Cell)
import Game
import ExampleLevel
import GameView
import Tutorial exposing (tutorial, TutorialModel)
import Monocle.Lens as Lens exposing (Lens)
import Monocle.Optional as Optional
import Monocle.Common exposing ((=>))
import HexcellParser
import Components


(>>>) : Lens a b -> Lens b c -> Lens a c
(>>>) =
    Lens.compose


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
    , tutorial : TutorialModel
    , pasteBox : String
    , config : Config
    }


gameModel : Lens Model GameModel
gameModel =
    Lens (.currentGame) (\gModel model -> { model | currentGame = gModel })


gameLevel : Lens GameModel Level
gameLevel =
    Lens (.level) (\newLevel model -> { model | level = newLevel })


config : Lens Model Config
config =
    Lens (.config) (\newConfig model -> { model | config = newConfig })


flippedControlls : Lens Config Bool
flippedControlls =
    Lens (.flippedControlls) (\newState config -> { config | flippedControlls = newState })


tabletMode : Lens Config Bool
tabletMode =
    Lens (.tabletMode) (\newState config -> { config | tabletMode = newState })


init : Return msg Model
init =
    Return.singleton
        { route = MainMenu
        , currentGame = initExampleGame
        , tutorial = Tutorial.tutorial
        , pasteBox = ""
        , config =
            { flippedControlls = True
            , tabletMode = False
            }
        }


initExampleGame : GameModel
initExampleGame =
    { level = ExampleLevel.level1
    , mistakes = 0
    }



-- UPDATE


update : Msg -> Model -> Return msg Model
update action model =
    case action of
        GameMsg gameAction ->
            model
                |> Lens.modify gameModel
                    (Game.updateGame model.config gameAction)
                |> Return.singleton

        TutorialMsg exampleId action ->
            Return.singleton
                { model | tutorial = Tutorial.updateTutorial model.config exampleId action model.tutorial }

        FlipControlls ->
            model
                |> Lens.modify (config >>> flippedControlls) not
                |> Return.singleton

        FlipTabletMode ->
            model
                |> Lens.modify (config >>> tabletMode) not
                |> Return.singleton

        SetRoute route ->
            Return.singleton { model | route = route }

        PasteBoxEdit newPaste ->
            Return.singleton { model | pasteBox = newPaste }

        NewLevel level ->
            model
                |> .set (gameModel >>> gameLevel) level
                |> Return.singleton



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    case model.route of
        InGame ->
            GameView.gameView model.config model.currentGame

        MainMenu ->
            mainMenuView model

        Tutorial ->
            Tutorial.toHtml model.config model.tutorial


mainMenuView : Model -> Html Msg
mainMenuView model =
    Components.paperWrapper
        [ h1 [] [ text "Elm Sweeper" ]
        , p []
            [ text "Elm Sweeper aims to reimplement the puzzle mechanicsof "
            , a [ href "http://store.steampowered.com/app/265890/" ] [ text "Hexcells" ]
            , text " as a web application. Hexcells is a supercharged Minesweeper with hand crafted levels."
            ]
        , div [ Html.Attributes.class "flex-container" ]
            [ div [ Html.Attributes.class "flex-block" ]
                [ Components.flatButton (SetRoute Tutorial) "Tutorial"
                ]
            , div [ Html.Attributes.class "flex-block" ]
                [ Components.flatButton (SetRoute InGame) "Current Game"
                ]
            , div [ Html.Attributes.class "flex-block" ]
                [ Components.flatButton FlipTabletMode "Swich Tablet Mode"
                ]
            ]
        , p []
            [ text "Community made levels are collected on "
            , a [ href "https://www.reddit.com/r/hexcellslevels/" ] [ text "/r/hexcellslevels" ]
            , text "."
            ]
        , textarea
            [ placeholder "Paste a Hexcells level file!"
            , onInput PasteBoxEdit
            , value model.pasteBox
            , Html.Attributes.id "paste-box"
            ]
            []
        , parsedResultView (HexcellParser.parseLevel model.pasteBox)
        ]


parsedResultView : Result (List String) Level -> Html Msg
parsedResultView parseResult =
    case parseResult of
        Err errorMessage ->
            p []
                [ text "This doesn't look like a valid Hexcells level. Maybe the error message helps?"
                , br [] []
                , text (toString errorMessage)
                ]

        Ok level ->
            div []
                [ text "Parsing successful!"
                , text <| "Author: " ++ level.author
                , text <| "Title: " ++ level.title
                , GameView.previewLevel "levelPreview" level.content
                , br [] []
                , Components.flatButton (NewLevel level) "Load Level"
                ]
