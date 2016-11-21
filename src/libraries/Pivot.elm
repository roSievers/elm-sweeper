module Pivot
    exposing
        ( Pivot
        , pivot
        , getPivot
        , asPivot
        , toList
        , fromList
        , setIndex
        )

import Monocle.Lens exposing (Lens)
import Monocle.Prism exposing (Prism)
import List.Extra as List


type Pivot a
    = Pivot a (List a) (List a)


pivot : Lens (Pivot a) a
pivot =
    { get = \(Pivot c _ _) -> c
    , set = \c (Pivot _ l r) -> Pivot c l r
    }


getPivot =
    pivot.get


asPivot : Prism (List a) (Pivot a)
asPivot =
    { getOption = List.uncons >> Maybe.map (\( c, r ) -> Pivot c [] r)
    , reverseGet = \(Pivot c l r) -> List.reverse l ++ (c :: r)
    }


toList =
    asPivot.reverseGet


fromList =
    asPivot.getOption


setIndex : Int -> Pivot a -> Maybe (Pivot a)
setIndex index (Pivot c l r) =
    let
        currentIndex =
            List.length l
    in
        if currentIndex < index then
            increaseIndexBy (index - currentIndex) (Pivot c l r)
        else if currentIndex == index then
            Just (Pivot c l r)
        else if index >= 0 then
            Just (decreaseIndexBy (currentIndex - index) (Pivot c l r))
        else
            Nothing


increaseIndexBy : Int -> Pivot a -> Maybe (Pivot a)
increaseIndexBy shift (Pivot c l r) =
    if shift == 0 then
        Just (Pivot c l r)
    else
        case r of
            r1 :: rTail ->
                increaseIndexBy (shift - 1) (Pivot r1 (c :: l) rTail)

            _ ->
                Nothing


decreaseIndexBy : Int -> Pivot a -> Pivot a
decreaseIndexBy shift (Pivot c l r) =
    if shift == 0 then
        Pivot c l r
    else
        case l of
            l1 :: lTail ->
                decreaseIndexBy (shift - 1) (Pivot l1 lTail (c :: r))

            _ ->
                Pivot c l r



--setPivot index (Pivot c l r) =
