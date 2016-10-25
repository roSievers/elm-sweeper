module Main exposing (..)

import Html exposing (Html, div, text)
import Html.App
import Html.Events
import Html.Attributes
import Return exposing (Return)
import Dict exposing (Dict)
import Grid exposing (Grid, Direction(..), Coordinate)
import Types exposing (..)
import ExampleLevel
import GameView
import Counting exposing (isMineContent)


main =
    Html.App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type Route
    = MainMenu
    | InGame GameModel


type alias Model =
    { route : Route
    }


init : Return Msg GameModel
init =
    Return.singleton
        { level = ExampleLevel.grid1
        , intent = RevealEmpty
        , mistakes = 0
        }



-- UPDATE


update : Msg -> GameModel -> Return Msg GameModel
update action model =
    case Debug.log "msg" action of
        Reveal intent coordinate cell ->
            handleReveal intent coordinate cell model
                |> Return.singleton

        ToggleFlower coordinate cell overlay ->
            { model
                | level =
                    Grid.insert
                        coordinate
                        (GameCell { content = Flower overlay, revealed = True })
                        model.level
            }
                |> Return.singleton

        SetIntent intent ->
            Return.singleton
                { model | intent = intent }


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



-- SUBSCRIPTIONS


subscriptions : GameModel -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view =
    GameView.gameView
