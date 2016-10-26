module ExampleLevel exposing (grid1)

import Dict
import Grid exposing (Grid, Direction(..))
import Types exposing (..)


grid1 : Grid Cell
grid1 =
    Dict.fromList
        [ ( ( 1, 4 ), GameCell { content = Empty, revealed = False } )
        , ( ( 2, 3 ), GameCell { content = Mine, revealed = False } )
        , ( ( 3, 4 ), GameCell { content = Empty, revealed = False } )
        , ( ( 3, 2 ), GameCell { content = Mine, revealed = False } )
        , ( ( 4, 3 ), GameCell { content = Empty, revealed = False } )
        , ( ( 5, 4 ), GameCell { content = TypedCount, revealed = False } )
        , ( ( 1, 6 ), GameCell { content = Count, revealed = False } )
        , ( ( 2, 5 ), GameCell { content = TypedCount, revealed = False } )
        , ( ( 3, 6 ), GameCell { content = Flower False, revealed = False } )
        , ( ( 4, 5 ), GameCell { content = Mine, revealed = False } )
        , ( ( 5, 6 ), GameCell { content = Mine, revealed = False } )
        , ( ( 6, 5 ), GameCell { content = Flower False, revealed = False } )
        , ( ( 1, 8 ), GameCell { content = Count, revealed = False } )
        , ( ( 2, 7 ), GameCell { content = Count, revealed = False } )
        , ( ( 3, 8 ), GameCell { content = Empty, revealed = False } )
        , ( ( 4, 7 ), GameCell { content = Count, revealed = False } )
        , ( ( 5, 8 ), GameCell { content = Empty, revealed = False } )
        , ( ( 4, 9 ), GameCell { content = Mine, revealed = False } )
        , ( ( 4, 1 ), TypedRowCount Down False )
        , ( ( 2, 1 ), TypedRowCount DownRight False )
        , ( ( 1, 2 ), RowCount Down False )
        ]
