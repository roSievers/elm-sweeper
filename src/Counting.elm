module Counting exposing (..)

import Dict exposing (Dict)
import Grid exposing (Grid, Direction(..), Coordinate)
import Types exposing (..)
import Cell exposing (Cell)


-- Counting Mines


countNbhd : Grid Cell -> Coordinate -> Int
countNbhd grid coordinate =
    Grid.getNbhd coordinate grid
        |> List.filterMap identity
        |> List.filter (\cell -> Cell.isMine cell)
        |> List.length


type NbhdType
    = ConnectedNbhd
    | DisjointNbhd


typeNbhd : Grid Cell -> Coordinate -> NbhdType
typeNbhd grid coordinate =
    Grid.getNbhd coordinate grid
        |> List.map (Maybe.map Cell.isMine >> Maybe.withDefault False)
        |> changes
        |> (\count ->
                if count <= 2 then
                    ConnectedNbhd
                else
                    DisjointNbhd
           )


changes : List Bool -> Int
changes list =
    List.map2 (/=) list (List.drop 1 list)
        |> List.filter identity
        |> List.length


countFlower : Grid Cell -> Coordinate -> Int
countFlower grid coordinate =
    Grid.getNbhd2 coordinate grid
        |> List.filter (\cell -> Cell.isMine cell)
        |> List.length


countInDirection : Grid.BoundingBox -> Grid Cell -> Coordinate -> Direction -> Int
countInDirection bounds grid basePoint direction =
    Grid.foldDirected
        (\coordinate maybeCell accumulator ->
            if Grid.isInside bounds coordinate then
                case maybeCell of
                    Nothing ->
                        Just accumulator

                    Just cell ->
                        if Cell.isMine cell then
                            Just (accumulator + 1)
                        else
                            Just accumulator
            else
                Nothing
        )
        0
        direction
        grid
        basePoint


typeInDirection : Grid.BoundingBox -> Grid Cell -> Coordinate -> Direction -> NbhdType
typeInDirection bounds grid basePoint direction =
    Grid.foldDirected
        (\coordinate maybeCell accumulator ->
            if Grid.isInside bounds coordinate then
                case maybeCell of
                    Nothing ->
                        Just accumulator

                    Just cell ->
                        if Cell.isGameElement cell then
                            if Cell.isMine cell then
                                Just (True :: accumulator)
                            else
                                Just (False :: accumulator)
                        else
                            Just accumulator
            else
                Nothing
        )
        []
        direction
        grid
        basePoint
        |> (::) False
        |> changes
        |> (\count ->
                if count <= 2 then
                    ConnectedNbhd
                else
                    DisjointNbhd
           )
