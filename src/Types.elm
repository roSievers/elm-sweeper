module Types exposing (..)

{- This modul collects shared types. -}

import Grid exposing (Grid, Direction, Coordinate)
import Cell exposing (Cell)


type alias Level =
    { title : String
    , author : String
    , comments : List String
    , content : Grid Cell
    }


type MouseButton
    = LeftButton
    | RightButton


type alias GameModel =
    { level : Level
    , mistakes : Int
    }


type Route
    = MainMenu
    | InGame
    | Tutorial

type alias Config =
    { flippedControlls : Bool
    , tabletMode : Bool
    }

-- Messages


type Msg
    = GameMsg GameAction
    | TutorialMsg Int GameAction
    | FlipControlls
    | SetRoute Route
    | PasteBoxEdit String
    | NewLevel Level


type GameAction
    = Reveal MouseButton Coordinate
    | ToggleOverlay Coordinate Bool
    | ToggleEnabled Coordinate Bool
