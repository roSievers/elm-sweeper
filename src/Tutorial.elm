module Tutorial exposing (..)

{-| This tutorial is designed to introduce new players to the concepts found
in the game. It contains playable examples to teach mechanics.

@docs tutorial

-}

import Html exposing (Html, div, text, p, a, button)
import Html.Events exposing (onClick)
import Types exposing (..)
import Literate exposing (Segment(..))
import Components
import MixedPuzzle exposing (MixedPuzzle, puzzleInline, puzzleGroup)


{-| The tutorial, written using the Literate library.
See MixedPuzzle.elm to see how the library is connected to the game specific code.
-}
tutorial : MixedPuzzle
tutorial =
    [ StaticHtml
        (Components.flatButton (SetRoute MainMenu) "Main Menu")
    , StaticMarkdown """
# How to play Elm Sweeper

This tutorial intends to quickly introduce you to all game mechanics. After
this you should be able to play all user made levels. If you prefer learning about
mechanics one by one as they are gradually introduced, go play the original
Hexcells first.

In Elm Sweeper you are confronted with a hexagonal grid. Below some of the orange hexes hide mines.
Hexes without mines hold clues to help you figure out where the mines are hidden:
The number tells you how many of the adjacent hexes contain mines.
"""
    , DynamicMarkdown
        (\config ->
            "If you have figured out that a hex is empty you can **reveal it using your "
                ++ revealButton config.flippedControlls
                ++ " mouse button**. If you know the position of a mine, **mark it with your "
                ++ mineButton config.flippedControlls
                ++ "** mouse button."
        )
    , StaticHtml
        (p []
            [ text "You can also "
            , a [ onClick FlipControlls ] [ text "exchange the buttons" ]
            , text " if you prefer it the other way round."
            ]
        )
    , StaticMarkdown """
**Todo:** Implement a tablet mode, explain it here and put a *swich on tablet mode* button.
"""
    , puzzleInline 3 """
..o+..x.........O+
O+..o+..O+....x...x.
......x...o+....x.
"""
    , StaticMarkdown """
Not all patterns are quite as easy to uncover. Can you figure out how to solve these two puzzles?
Try not to guess! I promise that it is possible."""
    , puzzleInline 4 """
..o+............O+....
O+..O+........x...x...
..x...o+........o+..O+
x...o+........O+..o+..
"""
    , StaticMarkdown """
If this is your first time playing a puzzle like this here are a few easy levels
to get you started. Skip ahead if you feel comfortable already.

**TODO:** Embed several levels in here. With some GUI (Mistakes, Mines left)
This might also be a good place to introduce the total count as a mechanic."""
    , puzzleInline 5 """
....X.
..o+..o+
O+..O+..O+
..x...x.
x...o+..x.
"""
    , StaticMarkdown """
# Connected and Disconnected Neighborhoods

Some hints reveal additional information. When they are surrounded by curly
braces, like `{3}`, it means the adjacent cells are all connected.
Dashes as in `-3-` indicate that the adjacent cells form two or more groups.
Here are some examples:

"""
    , puzzleInline 3 """
..Oc......On....X.....
X...X...X...X.....On..
..X.......O+....X...X.
"""
    , StaticMarkdown """
To get some practice with these “typed hints” here are some more levels:

**TODO:** These levels belong in one tabbed container with only one visible at a time.
Puzzle nr. 4 (The mask puzzle) requires a visible remaining mines counter.
"""
    , puzzleGroup 6 [ """
....o+....
..o+..oc..
x...o+..x.
..oc..x...
x.......x.
..o+..oc..
On..on..x.
..x...x...
....o+....""", """
....x.....
..o+..o+..
o+..on..o+
..o+..x...
x.......x.
..o+..on..
On..oc..o+
..x...x...
....x.....""", """
....x.....
..o+..x...
o+..Oc..O+
..o+..o+..
....o+....""", """
....o+..........x.....
......o+......o+......
....o+..o+..o+..x.....
..x...x...o+..on..o...
x.......X...X.......o.
..o+..x...o+..o+..o+..
....O+..Oc..O+..Oc....
......x.......x.......
....o...........x.....""", """
............o+....
..........O+..On..
....o+..x...x...x.
..o+..on..o+..o+..
x...Oc..O+..o...O+
..o+..x...........
....x.......o+..o+
..............o+..""" ]
    , StaticMarkdown """
# Mines on lines

The next hint to learn about are vertical and diagonal sums. These are located
at the borders of the levels and indicate how many mines are on a certain line.

These are sometimes typed as well, but connectedness works subtly different.
While the center `-2-` cell in the example below is disconnected by an empty space,
the `{3}` line on the right is connected.
Empty space does not break connectedness **on lines**.

When you click on a line hint it will display an overlay to help you figure out
which cells are on the line. This is particularly useful for large levels.
"""
    , puzzleInline 6 """
\\+......\\n......\\c..........
..O...|+..O+../+..O+........
....X.......Oc......X.......
......O+..X...X.............
........X.......O.......X...
......O...X.......X.......X."""
    , StaticMarkdown """
Pratice makes perfect, take these levels for a spin.
"""
    , puzzleGroup 10 [ """
..|n......|c
............
..x...o...o+
....x...o+..
..o...x...x.
\\+..o...o+..
..x...on..x.
\\+..o+..x...
..x...o...x.
....o+..x...""", """
......|+......
....|+........
..|n..x...|c..
\\+..o...o.....
..x...x...o+..
\\+..on..o.../n
..o+..o...x...
....o+..x.....
..x...o...x...
....x...x.....
......x.......""", """
........|+..|c..|+..
..|+..\\+............
........o...o...x...
..x...x...x...x.....
\\+..o+..On..o+..x...
..o...O+..x...o.....
....o...o...x...|+..
..|+..o.........../+
\\+..............o...
..o...\\+............
........x...x...x...
..x.................
........x...o+......""" ]
    , StaticMarkdown """
# Flowers (Hints on Mines)

The last game element is the “flower”. These are mines which contain a hint.
However, the number doesn't just count directly adjacent mines, but also an
extra layer. Sounds complicated? Click on a flower to see where it counts mines.
(Note that the flower itself does not count towards the total.)

"""
    , puzzleGroup 10 [ """
..........o+..........
....X...x...o+..x.....
..o+......on......o+..
X+..X...O+..X+..x...O+
..o+......x.......oc..
....X...o...o+..x+....
..........o+..........""", """
....|n......
..|c........
\\+..x...o+..
..o+..o+..x.
....o+..o+..
..x+......x.
....x...x+..
..x...o+..o+
....o+..o+..""", """
..........x...o+..........
........x+..o+..o.........
..........on..x+..........
....x.......x.......x+....
..x...x...oc..o+..x+..o...
O+..Oc..O+..x+..o+......o+
..o+..x+..o+..o...o+..o...
....o+......o+......o+....
..........oc..o...........
........o+..x+..x+........
..........x...x...........""" ]
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
