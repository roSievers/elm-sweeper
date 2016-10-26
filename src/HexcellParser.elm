module HexcellParser exposing (..)

--import Result

import Dict
import Grid exposing (Grid, Direction(..))
import Types exposing (..)
import Combine exposing (..)
import Combine.Char exposing (newline)
import Combine.Infix exposing (..)
import List.Extra as List


type alias Level =
    { title : String
    , author : String
    , grid : Grid Cell
    }


type alias Intermediate =
    { title : String
    , author : String
    , comments : List String
    , content : Grid Cell
    }


{-| How does parsing a Hexcells level file work?

  - Expect the Hexcells level v1 header
  - Parse the Title and Author
  - Expect two linebreaks
  - Parse tiles into Array2 (Maybe Cell)
  - Get rid of Cells at half heights and dump results into Grid
    - Maybe do this by seperating the array into two interlocking Grids
      and verifying that one is empty and the other nonempty.

-}



-- TODO: Handle last line not terminating in linebreak.
--parseLevel : String -> Intermediate


parseLevel inputString =
    parse
        (versionStatement
            *> (Intermediate <$> readline <*> readline <*> comments <*> cellGrid <* end)
        )
        inputString


versionStatement =
    string "Hexcells level v1" <* newline


readline =
    while (\c -> c /= '\n') <* newline


comments =
    count 2 readline
        |> Combine.map (List.filter (\comment -> comment /= ""))


emptyCell : Parser Cell
emptyCell =
    or
        (GameCell { content = Empty, revealed = False } <$ string "o.")
        (GameCell { content = Empty, revealed = True } <$ string "O.")


countCell : Parser Cell
countCell =
    or
        (GameCell { content = Count, revealed = False } <$ string "o+")
        (GameCell { content = Count, revealed = True } <$ string "O+")


typedCountCell : Parser Cell
typedCountCell =
    or
        (GameCell { content = TypedCount, revealed = False } <$ (string "oc" <|> string "on"))
        (GameCell { content = TypedCount, revealed = True } <$ (string "Oc" <|> string "On"))


mineCell : Parser Cell
mineCell =
    or
        (GameCell { content = Mine, revealed = False } <$ string "x.")
        (GameCell { content = Mine, revealed = True } <$ string "X.")


flowerCell : Parser Cell
flowerCell =
    or
        (GameCell { content = Flower False, revealed = False } <$ string "x+")
        (GameCell { content = Flower False, revealed = True } <$ string "X+")


rowCount : Parser Cell
rowCount =
    (RowCount DownLeft <$ string "/+")
        <|> (RowCount Down <$ string "|+")
        <|> (RowCount DownRight <$ string "\\+")


typedRowCount : Parser Cell
typedRowCount =
    (TypedRowCount DownLeft <$ (string "/c" <|> string "/n"))
        <|> (TypedRowCount Down <$ (string "|c" <|> string "|n"))
        <|> (TypedRowCount DownRight <$ (string "\\c" <|> string "\\n"))


nothing : Parser (Maybe a)
nothing =
    Nothing <$ string ".."


cell : Parser (Maybe Cell)
cell =
    choice
        [ emptyCell
        , countCell
        , typedCountCell
        , mineCell
        , flowerCell
        , rowCount
        , typedRowCount
        ]
        |> Combine.map Just
        |> or nothing


cellRow : Parser (List (Maybe Cell))
cellRow =
    many1 cell


cellGrid : Parser (Grid Cell)
cellGrid =
    createIndices <$> sepEndBy newline cellRow



-- Processing the parsed data


createIndices : List (List (Maybe Cell)) -> Grid Cell
createIndices rawGrid =
    List.indexedFoldl
        (\rowIndex row grid ->
            List.indexedFoldl
                (\colIndex maybeCell grid ->
                    case maybeCell of
                        Nothing ->
                            grid

                        Just cell ->
                            Dict.insert ( colIndex, (rowIndex+1) // 2 ) cell grid
                )
                grid
                row
        )
        Dict.empty
        rawGrid


encodeLevel : Level -> String
encodeLevel level =
    "understand how the half heights are placed"
