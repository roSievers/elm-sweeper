module ExampleLevel exposing (level1)

import Dict
import Grid exposing (Grid, Direction(..))
import Types exposing (..)
import Cell exposing (Cell, empty, count, typedCount, mine, flower, rowCount, typedRowCount)


level1 =
  { title = "Feature testing level"
  , author = "Rolf Sievers"
  , comments = []
  , content = grid1
  }


grid1 : Grid Cell
grid1 =
    Dict.fromList
        [ ( ( 1, 4 ), empty )
        , ( ( 2, 3 ), mine )
        , ( ( 3, 4 ), empty )
        , ( ( 3, 2 ), mine )
        , ( ( 4, 3 ), empty )
        , ( ( 5, 4 ), typedCount )
        , ( ( 1, 6 ), count )
        , ( ( 2, 5 ), typedCount )
        , ( ( 3, 6 ), flower )
        , ( ( 4, 5 ), mine )
        , ( ( 5, 6 ), mine )
        , ( ( 6, 5 ), flower )
        , ( ( 1, 8 ), count )
        , ( ( 2, 7 ), count )
        , ( ( 3, 8 ), empty )
        , ( ( 4, 7 ), count )
        , ( ( 5, 8 ), empty )
        , ( ( 4, 9 ), mine )
        , ( ( 4, 1 ), typedRowCount Down )
        , ( ( 2, 1 ), typedRowCount DownRight )
        , ( ( 1, 2 ), rowCount Down )
        ]
