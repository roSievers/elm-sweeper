module Grid exposing (..)

import Dict exposing (Dict)


type alias Grid a =
    Dict ( Int, Int ) a


type alias Coordinate =
    { x : Int
    , y : Int
    }

{-| Working with ( Int, Int ) inside the Grid module works around the missing
comparable typeclass of records in elm. -}
toCoordinate : ( Int, Int ) -> Coordinate
toCoordinate ( x, y ) =
    { x = x, y = y }


view : (Coordinate -> a -> output) -> Grid a -> List output
view cellSvg grid =
    Dict.foldl
        (\coord a list -> (cellSvg (toCoordinate coord) a) :: list)
        []
        grid
