module Main exposing (..)

import Html exposing (Html, div, text)
import Html.App
import Html.Events
import Return exposing (Return)
import Svg exposing (Svg, svg, rect)
import Svg.Attributes exposing (..)
import Svg.Events
import Json.Decode as Json
import Dict exposing (Dict)
import Grid exposing (Grid)
import Debug exposing (log)


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


type ClickType
    = RevealEmpty
    | RevealMine


type alias Model =
    { level : Grid Cell
    , clickType : ClickType
    , mistakes : Int
    }


init : Return Msg Model
init =
    Return.singleton
        { level =
            Dict.fromList
                [ ( ( 1, 2 ), { content = Count, revealed = True } )
                , ( ( 2, 2 ), { content = Mine, revealed = True } )
                , ( ( 3, 2 ), { content = Empty, revealed = True } )
                , ( ( 4, 2 ), { content = Empty, revealed = True } )
                , ( ( 5, 2 ), { content = Count, revealed = False } )
                , ( ( 1, 3 ), { content = Count, revealed = False } )
                , ( ( 2, 3 ), { content = Count, revealed = False } )
                , ( ( 3, 3 ), { content = Mine, revealed = False } )
                , ( ( 4, 3 ), { content = Mine, revealed = False } )
                , ( ( 5, 3 ), { content = Mine, revealed = True } )
                , ( ( 1, 4 ), { content = Count, revealed = False } )
                , ( ( 2, 4 ), { content = Count, revealed = False } )
                , ( ( 3, 4 ), { content = Count, revealed = False } )
                , ( ( 4, 4 ), { content = Count, revealed = False } )
                , ( ( 5, 4 ), { content = Count, revealed = False } )
                ]
        , clickType = RevealEmpty
        , mistakes = 0
        }



-- UPDATE


type Msg
    = ClickOn Coordinate
    | SetClickType ClickType


update : Msg -> Model -> Return Msg Model
update action model =
    case action of
        ClickOn coordinate ->
            Grid.get coordinate model.level
                |> Maybe.map (handleClickOn model coordinate)
                |> Maybe.withDefault model
                |> Return.singleton

        SetClickType clickType ->
            Return.singleton
                { model | clickType = clickType }


handleClickOn : Model -> Coordinate -> Cell -> Model
handleClickOn model coordinate cell =
    let
        mineClicked =
            isMine cell.content

        mineDesired =
            (model.clickType == RevealMine)
    in
        case mineClicked == mineDesired of
            True ->
                { model
                    | level = Grid.insert coordinate { cell | revealed = True } model.level
                }

            False ->
                { model
                    | mistakes = model.mistakes + 1
                }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ viewLevel model
        , Html.br [] []
        , Html.text ("Mistakes: " ++ toString model.mistakes)
        , clickTypeToggle model.clickType
        ]


clickTypeToggle : ClickType -> Html Msg
clickTypeToggle clickType =
    case clickType of
        RevealEmpty ->
            Html.button
                [ Html.Events.onClick (SetClickType RevealMine) ]
                [ Html.text "currently Revealing" ]

        RevealMine ->
            Html.button
                [ Html.Events.onClick (SetClickType RevealEmpty) ]
                [ Html.text "currently marking Mines" ]


viewLevel : Model -> Html.Html Msg
viewLevel model =
    svg
        [ width "1000", height "800", viewBox "0 0 20 16" ]
        (Grid.view cellSvg model.level)


cellSvg : Grid.Context Cell -> Cell -> Svg Msg
cellSvg context cell =
    if cell.revealed then
        case cell.content of
            Empty ->
                withCaption context.coordinate "lightgray" "?"

            Count ->
                withCaption context.coordinate "lightgray" (toString (countNbhd context))

            Mine ->
                hexagon context.coordinate "blue"

            Flower ->
                hexagon context.coordinate "blue"
    else
        hexagon context.coordinate "orange"


hexagon : Coordinate -> String -> Svg Msg
hexagon coordinate color =
    Svg.g
        [ atCoordinate coordinate
        , Svg.Events.onClick (ClickOn coordinate)
        ]
        [ Svg.polygon
            [ fill color
            , points "1,0 0.5,-0.866 -0.5,-0.866 -1,0 -0.5,0.866 0.5,0.866"
            , transform "scale(0.9)"
            ]
            []
        ]


withCaption : Coordinate -> String -> String -> Svg msg
withCaption coordinate color caption =
    Svg.g [ atCoordinate coordinate ]
        [ Svg.polygon
            [ fill color
            , points "1,0 0.5,-0.866 -0.5,-0.866 -1,0 -0.5,0.866 0.5,0.866"
            , transform "scale(0.9)"
            ]
            []
        , Svg.text'
            [ Svg.Attributes.style "text-anchor:middle;font-size:0.8"
            , dominantBaseline "central"
            ]
            [ Svg.text caption ]
        ]


isMine : CellContent -> Bool
isMine content =
    case content of
        Empty ->
            False

        Count ->
            False

        Mine ->
            True

        Flower ->
            True


countNbhd : Grid.Context Cell -> Int
countNbhd context =
    context.nbhd ()
        |> List.filter (\cell -> isMine cell.content)
        |> List.length


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
