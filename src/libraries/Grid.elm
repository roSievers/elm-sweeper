module Grid
    exposing
        ( Grid
        , Coordinate
        , at
        , Direction(..)
        , BoundingBox
        , boundingBox
        , isInside
        , SvgStack
        , singleton
        , setOverlay
        , view
        , count
        , foldDirected
        , getNbhd
        , getNbhd2
        )

import Dict exposing (Dict)
import List
import Svg exposing (Svg)
import Svg.Keyed
import Monocle.Optional exposing (Optional)
import Monocle.Common
import Monocle.Iso exposing (Iso)


{-| Implements a hexagonal grid type. The representation is sparse, i.e. using
a Dictionary. As a result, the coordinates used in `Grid a` can be as large as `Int`.
-}
type alias Grid a =
    Dict Coord a


{-| Type alias for nice two-dimensional coordinates.
-}
type alias Coordinate =
    { x : Int
    , y : Int
    }


{-| Internal type to work with a Dict of Coordinates.
-}
type alias Coord =
    ( Int, Int )


{-| Working with ( Int, Int ) inside the Grid module works around the missing
comparable typeclass of records in elm. All exposed functions should only talk
using `Coordinate`.
-}
coordIso : Iso Coordinate Coord
coordIso =
    { get = \r -> ( r.x, r.y )
    , reverseGet = \( x, y ) -> { x = x, y = y }
    }


{-| There are six possible directions in a hexagonal grid.
I don't need half of them at the moment, that is why they are missing.
-}
type Direction
    = Down
    | DownLeft
    | DownRight


{-| Moving in a direction isn't straitforward on a hexagonal grid, use this
function to move by one.
-}
moveDirection : Direction -> Coordinate -> Coordinate
moveDirection direction coordinate =
    case direction of
        Down ->
            { coordinate | y = coordinate.y + 1 }

        DownRight ->
            { x = coordinate.x + 1, y = coordinate.y + 1 }

        DownLeft ->
            { x = coordinate.x - 1, y = coordinate.y + 1 }



{-| A Monocle.Optional for accessing grid cells.
This is the prefered way to interact with the grid contents.

This means I have to copy pretty much no dict functions.
-}
at : Coordinate -> Optional (Grid a) a
at coordinate =
    Monocle.Common.dict (coordIso.get coordinate)



-- Calculating the BoundigBox


type alias BoundingBox =
    { top : Int
    , right : Int
    , bottom : Int
    , left : Int
    }


{-| Calculates a bounding box for all Elements in the Grid.
If the Grid is empty, then this returns Nothing.
-}
boundingBox : Grid a -> Maybe BoundingBox
boundingBox grid =
    let
        coords =
            Dict.keys grid

        xCoords =
            List.map (\( x, _ ) -> x) coords

        yCoords =
            List.map (\( _, y ) -> y) coords
    in
        Maybe.map4
            (\top right bottom left ->
                { top = top
                , right = right
                , bottom = bottom
                , left = left
                }
            )
            (List.minimum yCoords)
            (List.maximum xCoords)
            (List.maximum yCoords)
            (List.minimum xCoords)


isInside : BoundingBox -> Coordinate -> Bool
isInside box coordinate =
    (box.top <= coordinate.y)
        && (box.right >= coordinate.x)
        && (box.bottom >= coordinate.y)
        && (box.left <= coordinate.x)



-- View functions and helpers


{-| In my application, there might be an overlay at each position.
To capture this and correctly order the Svg elements use the SvgStack type.
-}
type alias SvgStack msg =
    ( Svg msg, Maybe (Svg msg) )


type alias RenderStack msg =
    ( List ( String, Svg msg ), List ( String, Svg msg ) )


{-| Returns a SvgStack with no overlay.
-}
singleton : Svg msg -> SvgStack msg
singleton svg =
    ( svg, Nothing )


{-| Sets the overlay of a SvgStack and leaves the base in place.
-}
setOverlay : Svg msg -> SvgStack msg -> SvgStack msg
setOverlay overlay ( base, _ ) =
    ( base, Just overlay )


addToStack : Coordinate -> SvgStack msg -> RenderStack msg -> RenderStack msg
addToStack coordinate ( base, maybeOverlay ) ( bases, overlays ) =
    ( ( toString coordinate, base ) :: bases
    , case maybeOverlay of
        Nothing ->
            overlays

        Just overlay ->
            ( "overlay-" ++ toString coordinate, overlay ) :: overlays
    )


collapseStack : RenderStack msg -> List ( String, Svg msg )
collapseStack ( bases, overlays ) =
    bases ++ overlays


{-| Core function used to turn a `Grid a` value into a Svg.
-}
view : (Grid a -> Coordinate -> a -> SvgStack msg) -> Grid a -> Svg msg
view cellSvg grid =
    let
        appendToRenderStack coord a =
            addToStack
                (coordIso.reverseGet coord)
                (cellSvg grid (coordIso.reverseGet coord) a)
    in
        Dict.foldl appendToRenderStack ( [], [] ) grid
            |> collapseStack
            |> Svg.Keyed.node "g" []



-- Get global&local information about the Grid.


count : (a -> Bool) -> Grid a -> Int
count doesCount grid =
    Dict.foldl
        (\_ a accumulator ->
            if doesCount a then
                accumulator + 1
            else
                accumulator
        )
        0
        grid


{-| This fold function starts at a given coordinate and keeps moving
in a direction until the accumulating function returns Nothing.
Then the last Just value is returned.

Defined using tail recursion.
-}
foldDirected :
    (Coordinate -> Maybe a -> b -> Maybe b)
    -> b
    -> Direction
    -> Grid a
    -> Coordinate
    -> b
foldDirected fold init direction grid basePoint =
    Dict.get (coordIso.get basePoint) grid
        |> (\a -> fold basePoint a init)
        |> (\maybeB ->
                case maybeB of
                    Nothing ->
                        init

                    Just b ->
                        foldDirected fold b direction grid (moveDirection direction basePoint)
           )


getRelative : Coordinate -> Coordinate -> Grid a -> Maybe a
getRelative origin delta grid =
    let
        coord =
            ( origin.x + delta.x, origin.y + delta.y )
    in
        Dict.get coord grid


getNbhd : Coordinate -> Grid a -> List (Maybe a)
getNbhd center grid =
    let
        nbhd =
            [ { x = -1, y = -1 }
            , { x = 0, y = -2 }
            , { x = 1, y = -1 }
            , { x = 1, y = 1 }
            , { x = 0, y = 2 }
            , { x = -1, y = 1 }
            ]
    in
        nbhd
            |> List.map (\delta -> getRelative center delta grid)


getNbhd2 : Coordinate -> Grid a -> List a
getNbhd2 center grid =
    let
        nbhd =
            [ { x = -1, y = -1 }
            , { x = 0, y = -2 }
            , { x = 1, y = -1 }
            , { x = 1, y = 1 }
            , { x = 0, y = 2 }
            , { x = -1, y = 1 }
            , { x = 0, y = 4 }
            , { x = 1, y = 3 }
            , { x = 2, y = 2 }
            , { x = 2, y = 0 }
            , { x = 2, y = -2 }
            , { x = 1, y = -3 }
            , { x = 0, y = -4 }
            , { x = -1, y = -3 }
            , { x = -2, y = -2 }
            , { x = -2, y = 0 }
            , { x = -2, y = 2 }
            , { x = -1, y = 3 }
            ]
    in
        nbhd
            |> List.map (\delta -> getRelative center delta grid)
            |> List.filterMap identity
