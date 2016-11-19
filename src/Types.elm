module Types exposing (..)

{- This modul collects shared types. -}

import Grid exposing (Grid, Direction, Coordinate)
import Cell exposing (Cell)
import Literate


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


{-| The Fullscreen view can't close itself for two reasons:

  * It has no access to the parent `Model`
  * It doesn't know where it came from

Instead, it uses fires the `ClosingAction` provided to it which wraps the
`GameModel` in a message.
-}
type alias ClosingAction =
    GameModel -> Msg


type alias Fullscreen =
    { gameModel : GameModel
    , onClose : ClosingAction
    }


type Route
    = MainMenu
    | FullscreenView Fullscreen
    | Tutorial

type alias Config =
    { flippedControlls : Bool
    , tabletMode : Bool
    }

-- Messages


type Msg
    = FullscreenMsg GameAction
    | TutorialMsg (Literate.Msg GameAction)
    | FlipControlls
    | FlipTabletMode
    | SetRoute Route
    | PasteBoxMsg PasteBoxAction
    | MultiMessage Msg Msg


type GameAction
    = Reveal MouseButton Coordinate
    | ToggleOverlay Coordinate Bool
    | ToggleEnabled Coordinate Bool


type PasteBoxAction
    = PasteBoxEdit String
    | UserLevelMsg GameAction
    | PasteBoxFullscreenReturn GameModel
