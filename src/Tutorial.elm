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
import Dict exposing (Dict)


type alias TutorialModel =
    { examples : Dict String Example
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


tutorial : Bool -> Html Msg
tutorial flippedControlls =
    div [ Html.Attributes.id "outer-text-container" ]
        [ div [ Html.Attributes.id "inner-text-container" ]
            [ greeting
            , buttons flippedControlls
            , changeButtons
            , inlineExample exampleLevel1
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
                GameView.viewLevel "" className (Debug.log "" grid)
                    |> Html.App.map (TutorialMsg "")

            Err error ->
                p []
                    [ text "An error occured: "
                    , text (toString error)
                    ]
