module Tutorial exposing (..)

import Html exposing (Html, div, text, p, a)
import Html.App
import Html.Events exposing (onClick)
import Html.Attributes
import Types exposing (..)
import Markdown
import HexcellParser
import GameView
import Grid exposing (Grid)
import Cell exposing (Cell)
import Game
import Dict exposing (Dict)
import Monocle.Optional as Optional exposing (Optional)
import Monocle.Common exposing ((=>))


type alias TutorialModel =
    { ex1 : Example
    , ex2 : Example
    }


type alias Example =
    { height : ExampleHeight
    , grid : WithError (Grid Cell)
    , id : String
    }


type alias WithError a =
    Result (List String) a


type ExampleHeight
    = Small
    | Medium
    | Large


init : TutorialModel
init =
    { ex1 = exampleLevel1
    , ex2 = exampleLevel2
    }


tutorial : Bool -> TutorialModel -> Html Msg
tutorial flippedControlls model =
    div [ Html.Attributes.id "outer-text-container" ]
        [ div [ Html.Attributes.id "inner-text-container" ]
            [ greeting
            , buttons flippedControlls
            , changeButtons
            , inlineExample model.ex1
            , firstDeduction
            , inlineExample model.ex2
            , firstSetOfLevels
            , Html.button [ Html.Events.onClick (SetRoute MainMenu) ] [ Html.text "Main Menu" ]
            ]
        ]


greeting : Html msg
greeting =
    Markdown.toHtml [] """

# How to play Elm Sweeper

Below the orange hexes hides a pattern of mines.
Hexes without mines hold clues to help you figure out where the mines are hidden:
The number tells you how many of the adjacent hexes contain mines.
"""


buttons : Bool -> Html Msg
buttons flippedControlls =
    let
        revealButton =
            if flippedControlls then
                "left mouse button"
            else
                "right mouse button"

        mineButton =
            if not flippedControlls then
                "left mouse button"
            else
                "right mouse button"
    in
        Markdown.toHtml []
            ("If you have figured out that a hex is empty you can **reveal it using your "
                ++ revealButton
                ++ "**. If you know the position of a mine, **mark it with your "
                ++ mineButton
                ++ "**."
            )


changeButtons : Html Msg
changeButtons =
    p []
        [ text "You can also "
        , a [ onClick FlipControlls ] [ text "exchange the buttons" ]
        , text " if you prefer it the other way round."
        ]


exampleLevel1 : Example
exampleLevel1 =
    { height = Small
    , grid = HexcellParser.parseCellGrid """
..o+..x.........O+
O+..o+..O+....x...x.
......x...o+....x.
"""
    , id = "example-1"
    }


firstDeduction : Html Msg
firstDeduction =
    Markdown.toHtml [] """
Not all patterns are quite as easy to uncover. Can you figure out how to solve these two puzzles?
Try not to guess!"""


exampleLevel2 : Example
exampleLevel2 =
    { height = Small
    , grid = HexcellParser.parseCellGrid """
..............X.
..o+........o+..o+
O+..O+....O+..O+..O+
..x...o+....x...x.
x...o+....x...o+..x.
"""
    , id = "example-2"
    }


firstSetOfLevels : Html Msg
firstSetOfLevels =
    Markdown.toHtml [] """
If this is your first time playing a puzzle like this here are a few easy levels
to get you started. Skip ahead if you feel comfortable already.

Do work to embed several levels in here."""



-- Helper functions


inlineExample : Example -> Html Msg
inlineExample example =
    let
        sizeClass =
            case example.height of
                Small ->
                    "inline-small"

                Medium ->
                    "inline-medium"

                Large ->
                    "inline-large"

        className =
            "inline-grid " ++ sizeClass
    in
        case example.grid of
            Ok grid ->
                GameView.viewLevel "" className grid
                    |> Html.App.map (TutorialMsg example.id)

            Err error ->
                p []
                    [ text "An error occured: "
                    , text (toString error)
                    ]


grid : Optional Example (Grid Cell)
grid =
    { getOption = \example -> Result.toMaybe example.grid
    , set = \grid example -> { example | grid = Ok grid }
    }


{-| This is not actually an optional, clean this up later!
-}
asGameModel : Optional (Grid Cell) GameModel
asGameModel =
    { getOption =
        \grid ->
            Just
                { level =
                    { title = ""
                    , author = ""
                    , comments = []
                    , content = grid
                    }
                , mistakes = 0
                }
    , set = \model _ -> model.level.content
    }


updateTutorial : Bool -> String -> GameAction -> TutorialModel -> TutorialModel
updateTutorial flippedControlls exampleId action model =
    case Debug.log "" exampleId of
        "example-1" ->
            { model
                | ex1 =
                    model.ex1
                        |> Optional.modify (grid => asGameModel)
                            (Game.updateGame flippedControlls action)
            }

        "example-2" ->
            { model
                | ex2 =
                    model.ex2
                        |> Optional.modify (grid => asGameModel)
                            (Game.updateGame flippedControlls action)
            }

        _ ->
            model
