module ExampleLevel exposing (grid1)

import Dict
import Grid exposing (Grid, Direction(..))
import Types exposing (..)


grid1 : Grid Cell
grid1 =
    Dict.fromList
        [ ( ( 1, 2 ), GameCell { content = Empty, revealed = False } )
        , ( ( 2, 2 ), GameCell { content = Mine, revealed = False } )
        , ( ( 3, 2 ), GameCell { content = Empty, revealed = False } )
        , ( ( 3, 1 ), GameCell { content = Mine, revealed = False } )
        , ( ( 4, 2 ), GameCell { content = Empty, revealed = False } )
        , ( ( 5, 2 ), GameCell { content = TypedCount, revealed = False } )
        , ( ( 1, 3 ), GameCell { content = Count, revealed = False } )
        , ( ( 2, 3 ), GameCell { content = TypedCount, revealed = False } )
        , ( ( 3, 3 ), GameCell { content = Flower False, revealed = False } )
        , ( ( 4, 3 ), GameCell { content = Mine, revealed = False } )
        , ( ( 5, 3 ), GameCell { content = Mine, revealed = False } )
        , ( ( 6, 3 ), GameCell { content = Flower False, revealed = False } )
        , ( ( 1, 4 ), GameCell { content = Count, revealed = False } )
        , ( ( 2, 4 ), GameCell { content = Count, revealed = False } )
        , ( ( 3, 4 ), GameCell { content = Empty, revealed = False } )
        , ( ( 4, 4 ), GameCell { content = Count, revealed = False } )
        , ( ( 5, 4 ), GameCell { content = Empty, revealed = False } )
        , ( ( 4, 5 ), GameCell { content = Mine, revealed = False } )
        , ( ( 4, 1 ), TypedRowCount Down )
        , ( ( 2, 1 ), TypedRowCount DownRight )
        , ( ( 1, 1 ), RowCount Down )
        ]
