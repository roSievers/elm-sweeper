module Cell exposing (..)

import Grid


type Cell
    = Empty { revealed : Bool, enabled : Bool }
    | Count { typed : Bool, revealed : Bool, enabled : Bool }
    | Mine { revealed : Bool }
    | Flower { revealed : Bool, overlay : Bool, enabled : Bool }
    | RowCount { typed : Bool, direction : Grid.Direction, overlay : Bool, enabled : Bool }


empty : Cell
empty =
    Empty { revealed = False, enabled = True }


count : Cell
count =
    Count { typed = False, revealed = False, enabled = True }


typedCount : Cell
typedCount =
    Count { typed = True, revealed = False, enabled = True }


mine : Cell
mine =
    Mine { revealed = False }


flower : Cell
flower =
    Flower { revealed = False, overlay = False, enabled = True }


rowCount : Grid.Direction -> Cell
rowCount direction =
    RowCount { typed = False, direction = direction, overlay = False, enabled = True }


typedRowCount : Grid.Direction -> Cell
typedRowCount direction =
    RowCount { typed = True, direction = direction, overlay = False, enabled = True }



-- Properties


isMine : Cell -> Bool
isMine cell =
    case cell of
        Mine _ ->
            True

        Flower _ ->
            True

        otherCell ->
            False


isHidden : Cell -> Bool
isHidden cell =
    case cell of
        Empty data ->
            not data.revealed

        Count data ->
            not data.revealed

        Mine data ->
            not data.revealed

        Flower data ->
            not data.revealed

        RowCount _ ->
            False


isHiddenMine : Cell -> Bool
isHiddenMine cell =
    isMine cell && isHidden cell



-- Modification functions


setRevealed : Bool -> Cell -> Cell
setRevealed revealed cell =
    case cell of
        Empty data ->
            Empty { data | revealed = revealed }

        Count data ->
            Count { data | revealed = revealed }

        Mine data ->
            Mine { data | revealed = revealed }

        Flower data ->
            Flower { data | revealed = revealed }

        otherCell ->
            otherCell


reveal : Cell -> Cell
reveal =
    setRevealed True


setOverlay : Bool -> Cell -> Cell
setOverlay overlay cell =
    case cell of
        Flower data ->
            Flower { data | overlay = overlay }

        RowCount data ->
            RowCount { data | overlay = overlay }

        otherCell ->
            otherCell


setEnabled : Bool -> Cell -> Cell
setEnabled enabled cell =
    case cell of
        Empty data ->
            Empty { data | enabled = enabled }

        Count data ->
            Count { data | enabled = enabled }

        Flower data ->
            Flower { data | enabled = enabled }

        RowCount data ->
            RowCount { data | enabled = enabled }

        otherCell ->
            otherCell
