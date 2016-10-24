module Grid exposing (..)

import Dict exposing (Dict)
import List
import Svg exposing (Svg)
import Svg.Keyed


{-| Implements a hexagonal grid type.
-}
type alias Grid a =
    Dict ( Int, Int ) a


type alias Coordinate =
    { x : Int
    , y : Int
    }


{-| Working with ( Int, Int ) inside the Grid module works around the missing
comparable typeclass of records in elm. All exposed functions should only talk
using Coordinate.
-}
toCoordinate : ( Int, Int ) -> Coordinate
toCoordinate ( x, y ) =
    { x = x, y = y }


updateAt : Coordinate -> (a -> a) -> Grid a -> Grid a
updateAt coordinate function grid =
    let
        coord =
            ( coordinate.x, coordinate.y )
    in
        Dict.get coord grid
            |> Maybe.map
                (\value -> Dict.insert coord (function value) grid)
            |> Maybe.withDefault grid


get : Coordinate -> Grid a -> Maybe a
get coordinate grid =
    Dict.get ( coordinate.x, coordinate.y ) grid


insert : Coordinate -> a -> Grid a -> Grid a
insert coordinate value grid =
    Dict.insert ( coordinate.x, coordinate.y ) value grid


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


type alias SvgStack msg =
    ( Svg msg, Maybe (Svg msg) )


type alias RenderStack msg =
    ( List (String, Svg msg), List (String, Svg msg) )


singleton : Svg msg -> SvgStack msg
singleton svg =
    ( svg, Nothing )


setOverlay : Svg msg -> SvgStack msg -> SvgStack msg
setOverlay overlay ( base, _ ) =
    ( base, Just overlay )


addToStack : Coordinate -> SvgStack msg -> RenderStack msg -> RenderStack msg
addToStack coordinate ( base, maybeOverlay ) ( bases, overlays ) =
    ( (toString coordinate, base) :: bases
    , case maybeOverlay of
        Nothing ->
            overlays

        Just overlay ->
            ("overlay-" ++ toString coordinate, overlay) :: overlays
    )


collapseStack : RenderStack msg -> List (String, Svg msg)
collapseStack (bases, overlays) =
    bases ++ overlays


view : (Grid a -> Coordinate -> a -> SvgStack msg) -> Grid a -> Svg msg
view cellSvg grid =
    Dict.foldl
        (\coord a -> addToStack (toCoordinate coord) (cellSvg grid (toCoordinate coord) a))
        ([], [])
        grid
        |> collapseStack
        |> Svg.Keyed.node "g" []


getRelative : Coordinate -> Coordinate -> Grid a -> Maybe a
getRelative origin delta grid =
    let
        coord =
            ( origin.x + delta.x, origin.y + delta.y )
    in
        Dict.get coord grid


getNbhd : Coordinate -> Grid a -> List a
getNbhd center grid =
    let
        nbhd =
            if center.x % 2 == 0 then
                [ { x = -1, y = -1 }
                , { x = 0, y = -1 }
                , { x = 1, y = -1 }
                , { x = -1, y = 0 }
                , { x = 1, y = 0 }
                , { x = 0, y = 1 }
                ]
            else
                [ { x = -1, y = 1 }
                , { x = 0, y = 1 }
                , { x = 1, y = 1 }
                , { x = -1, y = 0 }
                , { x = 1, y = 0 }
                , { x = 0, y = -1 }
                ]
    in
        nbhd
            |> List.map (\delta -> getRelative center delta grid)
            |> List.filterMap identity


getNbhd2 : Coordinate -> Grid a -> List a
getNbhd2 center grid =
    let
        base =
            [ { x = 0, y = -2 }
            , { x = -2, y = -1 }
            , { x = -1, y = -1 }
            , { x = 0, y = -1 }
            , { x = 1, y = -1 }
            , { x = 2, y = -1 }
            , { x = -2, y = 0 }
            , { x = -1, y = 0 }
            , { x = 1, y = 0 }
            , { x = 2, y = 0 }
            , { x = -2, y = 1 }
            , { x = -1, y = 1 }
            , { x = 0, y = 1 }
            , { x = 1, y = 1 }
            , { x = 2, y = 1 }
            , { x = 0, y = 2 }
            ]

        nbhd =
            if center.x % 2 == 0 then
                { x = -1, y = -2 }
                    :: { x = 1, y = -2 }
                    :: base
            else
                { x = -1, y = 2 }
                    :: { x = 1, y = 2 }
                    :: base
    in
        nbhd
            |> List.map (\delta -> getRelative center delta grid)
            |> List.filterMap identity
