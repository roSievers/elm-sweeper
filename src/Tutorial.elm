module Tutorial exposing (..)

{-| This tutorial is designed to introduce new players to the concepts found
in the game. It contains playable examples to teach mechanics.

@docs tutorial

-}

import Html exposing (Html, div, text, p, a)
import Html.App
import Html.Events exposing (onClick)
import Html.Attributes
import Types exposing (..)
import HexcellParser
import GameView
import Grid exposing (Grid)
import Cell exposing (Cell)
import Game
import Dict exposing (Dict)
import Monocle.Optional as Optional exposing (Optional)
import Monocle.Common exposing ((=>))
import Literate exposing (LiteratePuzzle, Segment(..), RenderConfig)


type alias TutorialModel =
    LiteratePuzzle Bool Example Msg

{-| The tutorial, written using the Literate library. -}
tutorial : TutorialModel
tutorial =
    [ StaticMarkdown """
# How to play Elm Sweeper

Below the orange hexes hides a pattern of mines.
Hexes without mines hold clues to help you figure out where the mines are hidden:
The number tells you how many of the adjacent hexes contain mines.
"""
    , DynamicMarkdown
        (\config ->
            "If you have figured out that a hex is empty you can **reveal it using your "
                ++ revealButton config
                ++ " mouse button**. If you know the position of a mine, **mark it with your "
                ++ mineButton config
                ++ "** mouse button."
        )
    , StaticHtml
        (p []
            [ text "You can also "
            , a [ onClick FlipControlls ] [ text "exchange the buttons" ]
            , text " if you prefer it the other way round."
            ]
        )
    , puzzleInline Small """
..o+..x.........O+
O+..o+..O+....x...x.
......x...o+....x.
"""
    , StaticMarkdown """
Not all patterns are quite as easy to uncover. Can you figure out how to solve these two puzzles?
Try not to guess!"""
    , puzzleInline Small """
..............X.
..o+........o+..o+
O+..O+....O+..O+..O+
..x...o+....x...x.
x...o+....x...o+..x.
"""
    , StaticMarkdown """
If this is your first time playing a puzzle like this here are a few easy levels
to get you started. Skip ahead if you feel comfortable already.

Do work to embed several levels in here."""
    , StaticHtml
        (Html.button [ Html.Events.onClick (SetRoute MainMenu) ]
            [ Html.text "Main Menu" ]
        )
    ]
        |> Literate.literate


revealButton flippedControlls =
    if not flippedControlls then
        "right"
    else
        "left"


mineButton flippedControlls =
    if not flippedControlls then
        "left"
    else
        "right"



-- This wires the LiteratePuzzle up for use with Elm Sweeper.


type Example
    = Plain
        { height : ExampleHeight
        , grid : Grid Cell
        }
    | LoadError String


type ExampleHeight
    = Small
    | Medium
    | Large


sizeClass height =
    case height of
        Small ->
            "inline-small"

        Medium ->
            "inline-medium"

        Large ->
            "inline-large"


renderExample : config -> Example -> Html GameAction
renderExample _ example =
    case example of
        Plain data ->
            GameView.viewLevel "" ("inline-grid " ++ sizeClass data.height) data.grid

        LoadError errorMessage ->
            p []
                [ text "An error occured: "
                , text errorMessage
                ]


tagExampleMsg : Int -> GameAction -> Msg
tagExampleMsg id exampleMsg =
    TutorialMsg id exampleMsg


renderConfig : RenderConfig Bool Example GameAction Msg
renderConfig =
    { renderExample = renderExample
    , tagExampleMsg = tagExampleMsg
    }


updateExample : Bool -> GameAction -> Example -> Example
updateExample flippedControlls action example =
    case example of
        Plain data ->
            Plain
                (Optional.modify (grid => asGameModel)
                    (Game.updateGame flippedControlls action)
                    data
                )

        (LoadError _) as error ->
            error


grid : Optional { a | grid : Grid Cell } (Grid Cell)
grid =
    { getOption = \example -> Just example.grid
    , set = \grid example -> { example | grid = grid }
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


updateTutorial : Bool -> Int -> GameAction -> TutorialModel -> TutorialModel
updateTutorial flippedControlls exampleId action model =
    Literate.updateExample
        exampleId
        (updateExample flippedControlls action)
        model


toHtml : Bool -> TutorialModel -> Html Msg
toHtml flippedControlls model =
    Literate.toHtml renderConfig flippedControlls model


puzzleInline : ExampleHeight -> String -> Segment config Example msg
puzzleInline height data =
    case HexcellParser.parseCellGrid data of
        Ok grid ->
            Plain
                { height = height
                , grid = grid
                }
                |> InlineExample

        Err errorMessages ->
            LoadError (toString errorMessages)
                |> InlineExample
