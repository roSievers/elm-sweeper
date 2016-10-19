module Main exposing (..)

import Html exposing (Html, div, text)
import Html.App
import Return exposing (Return)
import Svg exposing (Svg, svg, rect)
import Svg.Attributes exposing (..)
import Dict exposing (Dict)
import Grid exposing (..)


main =
    Html.App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Coordinate =
    { x : Int
    , y : Int
    }


type CellContent
    = Empty
    | Count
    | Mine
    | Flower


type alias Cell =
    { content : CellContent
    , revealed : Bool
    }


type alias Model =
    { level : Grid Cell }


init : Return Msg Model
init =
    Return.singleton
        { level =
            Dict.fromList
                [ ( ( 1, 2 ), { content = Count, revealed = False } )
                , ( ( 2, 2 ), { content = Count, revealed = False } )
                , ( ( 3, 2 ), { content = Count, revealed = False } )
                , ( ( 4, 2 ), { content = Count, revealed = False } )
                , ( ( 5, 2 ), { content = Count, revealed = False } )
                , ( ( 1, 3 ), { content = Count, revealed = False } )
                , ( ( 2, 3 ), { content = Count, revealed = False } )
                , ( ( 3, 3 ), { content = Count, revealed = False } )
                , ( ( 4, 3 ), { content = Count, revealed = False } )
                , ( ( 5, 3 ), { content = Count, revealed = False } )
                , ( ( 1, 4 ), { content = Count, revealed = False } )
                , ( ( 2, 4 ), { content = Count, revealed = False } )
                , ( ( 3, 4 ), { content = Count, revealed = False } )
                , ( ( 4, 4 ), { content = Count, revealed = False } )
                , ( ( 5, 4 ), { content = Count, revealed = False } )
                ]
        }



-- UPDATE


type Msg
    = Reset


update : Msg -> Model -> Return Msg Model
update action model =
    case action of
        Reset ->
            Return.singleton model



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ viewLevel model
        ]


viewLevel : Model -> Html.Html msg
viewLevel model =
    svg
        [ width "1000", height "800", viewBox "0 0 20 16" ]
        (Grid.view cellSvg model.level)



cellSvg : Coordinate -> Cell -> Svg msg
cellSvg coordinate cell =
    hexagon coordinate


hexagon : Coordinate -> Svg msg
hexagon coordinate =
    Svg.g [ atCoordinate coordinate ]
        [ Svg.polygon
            [ fill "blue"
            , points "1,0 0.5,-0.866 -0.5,-0.866 -1,0 -0.5,0.866 0.5,0.866"
            , transform "scale(0.9)"
            ]
            []
        ]


atCoordinate : Coordinate -> Svg.Attribute msg
atCoordinate coordinate =
    transform
        ("translate("
            ++ toString (1.5 * toFloat coordinate.x)
            ++ ","
            ++ toString
                (1.732
                    * toFloat coordinate.y
                    + (if coordinate.x % 2 == 1 then
                        0.866
                       else
                        0
                      )
                )
            ++ ")"
        )



--<polygon fill="lime" stroke="blue" stroke-width="10"
