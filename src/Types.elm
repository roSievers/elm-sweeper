module Types exposing (..)

{- This modul collects shared types. -}

import Grid exposing (Grid, Direction, Coordinate)


type CellContent
    = Empty
    | Count
    | TypedCount
    | Mine
    | Flower Bool


type alias CellData =
    { content : CellContent
    , revealed : Bool
    }


type Cell
    = GameCell CellData
    | RowCount Direction Bool
    | TypedRowCount Direction Bool


type Intent
    = RevealEmpty
    | RevealMine


type alias GameModel =
    { level : Grid Cell
    , intent : Intent
    , mistakes : Int
    }


type Route
    = MainMenu
    | InGame


-- Messages


type Msg
    = Reveal Intent Coordinate CellData
    | ToggleOverlay Coordinate Bool
    | SetIntent Intent
    | SetRoute Route
    | PasteBoxEdit String
    | NewLevel (Grid Cell)
