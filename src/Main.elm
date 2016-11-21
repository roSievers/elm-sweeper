module Main exposing (..)

import Html exposing (Html, div, text, button, br, textarea, h1, p, a)
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
import Fullscreen
import Tutorial exposing (tutorial)
import MixedPuzzle exposing (MixedPuzzle)
import Monocle.Lens as Lens exposing (Lens)
import Monocle.Optional as Optional exposing (Optional)
import Monocle.Common exposing ((=>))
import Components
import PasteBox exposing (PasteBox)


(>>>) : Lens a b -> Lens b c -> Lens a c
(>>>) =
    Lens.compose


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { route : Route
    , tutorial : MixedPuzzle
    , pasteBox : PasteBox
    , config : Config
    }


config : Lens Model Config
config =
    Lens (.config) (\newConfig model -> { model | config = newConfig })


flippedControlls : Lens Config Bool
flippedControlls =
    Lens (.flippedControlls) (\newState config -> { config | flippedControlls = newState })


tabletMode : Lens Config Bool
tabletMode =
    Lens (.tabletMode) (\newState config -> { config | tabletMode = newState })


fullscreenRoute : Optional Model Fullscreen
fullscreenRoute =
    { getOption =
        (\model ->
            case model.route of
                FullscreenView fullscreen ->
                    Just fullscreen

                _ ->
                    Nothing
        )
    , set = (\newFullscreen model -> { model | route = FullscreenView newFullscreen })
    }


init : Return msg Model
init =
    Return.singleton
        { route = MainMenu
        , tutorial = Tutorial.tutorial
        , pasteBox = PasteBox.init
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
        FullscreenMsg gameAction ->
            model
                |> Optional.modify fullscreenRoute
                    (Fullscreen.update model.config gameAction)
                |> Return.singleton

        MixedPuzzleMsg literateMsg ->
            Return.singleton
                { model | tutorial = MixedPuzzle.update model.config (Debug.log "msg" literateMsg) model.tutorial }

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

        PasteBoxMsg msg ->
            Return.singleton
                { model | pasteBox = PasteBox.update model.config msg model.pasteBox }

        MultiMessage msg1 msg2 ->
            update msg1 model
              |> Return.andThen (update msg2)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    case model.route of
        FullscreenView fullscreen ->
            Fullscreen.view model.config fullscreen

        MainMenu ->
            mainMenuView model

        Tutorial ->
            MixedPuzzle.toHtml model.config model.tutorial


mainMenuView : Model -> Html Msg
mainMenuView model =
    Components.paperWrapper
        [ h1 [] [ text "Elm Sweeper" ]
        , p []
            [ text "Elm Sweeper aims to reimplement the puzzle mechanicsof "
            , a [ href "http://store.steampowered.com/app/265890/" ] [ text "Hexcells" ]
            , text " as a web application. Hexcells is a supercharged Minesweeper with hand crafted levels."
            ]
        , Components.blockContainer
            [ Components.flatButton (SetRoute Tutorial) "Tutorial"
            , Components.flatButton FlipTabletMode "Swich Tablet Mode"
            ]
        , PasteBox.view model.config model.pasteBox
        ]
