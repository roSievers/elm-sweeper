module Main exposing (..)

import Html exposing (Html, div, text)
import Html.App
import Html.Events
import Html.Attributes
import Return exposing (Return)
import Svg exposing (Svg, svg, rect)
import Svg.Attributes exposing (..)
import Svg.Events
import Json.Decode
import Dict exposing (Dict)
import Grid exposing (Grid)
import Debug


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
    | Flower Bool


type alias Cell =
    { content : CellContent
    , revealed : Bool
    }


type Intent
    = RevealEmpty
    | RevealMine


type alias Model =
    { level : Grid Cell
    , intent : Intent
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
                , ( ( 3, 1 ), { content = Mine, revealed = False } )
                , ( ( 4, 2 ), { content = Empty, revealed = False } )
                , ( ( 5, 2 ), { content = Count, revealed = False } )
                , ( ( 1, 3 ), { content = Count, revealed = False } )
                , ( ( 2, 3 ), { content = Count, revealed = False } )
                , ( ( 3, 3 ), { content = Flower False, revealed = False } )
                , ( ( 4, 3 ), { content = Mine, revealed = False } )
                , ( ( 5, 3 ), { content = Mine, revealed = False } )
                , ( ( 6, 3 ), { content = Flower False, revealed = False } )
                , ( ( 1, 4 ), { content = Count, revealed = False } )
                , ( ( 2, 4 ), { content = Count, revealed = False } )
                , ( ( 3, 4 ), { content = Count, revealed = False } )
                , ( ( 4, 4 ), { content = Count, revealed = False } )
                , ( ( 5, 4 ), { content = Empty, revealed = False } )
                ]
        , intent = RevealEmpty
        , mistakes = 0
        }



-- UPDATE


type Msg
    = Reveal Intent Coordinate Cell
    | ToggleFlower Coordinate Cell Bool
    | SetIntent Intent


update : Msg -> Model -> Return Msg Model
update action model =
    case Debug.log "msg" action of
        Reveal intent coordinate cell ->
            handleReveal intent coordinate cell model
                |> Return.singleton

        ToggleFlower coordinate cell overlay ->
            { model
                | level =
                    Grid.insert
                        coordinate
                        { cell | content = Flower overlay }
                        model.level
            }
                |> Return.singleton

        SetIntent intent ->
            Return.singleton
                { model | intent = intent }


handleReveal : Intent -> Coordinate -> Cell -> Model -> Model
handleReveal intent coordinate cell model =
    let
        mineClicked =
            isMine cell.content

        mineDesired =
            intent == RevealMine
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
        , Html.text <| "Remaining: " ++ (toString <| Grid.count isHiddenMine model.level)
        , Html.br [] []
        , Html.text ("Mistakes: " ++ toString model.mistakes)
        , Html.br [] []
        , intentDisplay model.intent
        ]


viewLevel : Model -> Html.Html Msg
viewLevel model =
    let
        visibleArea =
            Grid.boundingBox model.level
                |> Maybe.map (levelBox >> viewBox)
                |> Maybe.withDefault (viewBox "0 0 20 16")
    in
        svg
            [ Html.Attributes.id "levelView", width "1000", height "800", visibleArea, preserveAspectRatio "xMidYMid meet" ]
            [ Grid.view (cellSvg model) model.level
            ]


levelBox : Grid.BoundingBox -> String
levelBox box =
    toString (1.5 * toFloat box.left - 2)
        ++ " "
        ++ toString (2 * toFloat box.top - 2)
        ++ " "
        ++ toString (1.5 * toFloat (box.right - box.left) + 4)
        ++ " "
        ++ toString (2 * toFloat (box.bottom - box.top) + 4)


cellSvg : Model -> Grid Cell -> Coordinate -> Cell -> Grid.SvgStack Msg
cellSvg model grid coordinate cell =
    if cell.revealed then
        case cell.content of
            Empty ->
                emptyCell coordinate |> Grid.singleton

            Count ->
                counterCell grid coordinate cell |> Grid.singleton

            Mine ->
                mineCell coordinate |> Grid.singleton

            Flower overlay ->
                flowerCell grid coordinate cell overlay
    else
        hiddenCell model.intent coordinate cell |> Grid.singleton


mineCell : Coordinate -> Svg Msg
mineCell coordinate =
    Svg.g
        [ atCoordinate coordinate
        , Svg.Attributes.class "cell"
        ]
        [ hexagon "hex mine"
        ]


hiddenCell : Intent -> Coordinate -> Cell -> Svg Msg
hiddenCell intent coordinate cell =
    Svg.g
        [ atCoordinate coordinate
        , Svg.Events.onClick (Reveal intent coordinate cell)
        , onRightClick (Reveal (flipIntent intent) coordinate cell)
        , Svg.Attributes.class "cell"
        ]
        [ hexagon "hex hidden-cell"
        , hexagon "highlight"
        ]


onRightClick message =
    Html.Events.onWithOptions
        "contextmenu"
        { stopPropagation = False
        , preventDefault = True
        }
        (Json.Decode.succeed message)


flipIntent : Intent -> Intent
flipIntent intent =
    case intent of
        RevealEmpty ->
            RevealMine

        RevealMine ->
            RevealEmpty


emptyCell : Coordinate -> Svg msg
emptyCell coordinate =
    withCaption coordinate "cell" "hex lightgray" "?"


counterCell : Grid Cell -> Coordinate -> Cell -> Svg msg
counterCell grid coordinate cell =
    withCaption coordinate "cell" "hex lightgray" (toString (countNbhd grid coordinate))


flowerCell : Grid Cell -> Coordinate -> Cell -> Bool -> Grid.SvgStack Msg
flowerCell grid coordinate cell hasOverlay =
    let
        position =
            atCoordinate coordinate

        base =
            Svg.g
                [ position
                , Svg.Attributes.class "cell flower"
                , Svg.Events.onClick (ToggleFlower coordinate cell (not hasOverlay))
                ]
                [ hexagon "hex mine"
                , centeredCaption (toString (countFlower grid coordinate))
                , hexagon "highlight"
                ]

        overlayPolygon =
            Svg.g [ position ] [ flowerNbhdPolygon hasOverlay ]
    in
        Grid.singleton base
            |> Grid.setOverlay overlayPolygon


{-| This function creates a hexagon with a sidelength of 0.9 as a svg polygon.
Supply a classname to style the polygon via css.
-}
hexagon : String -> Svg msg
hexagon hexClass =
    Svg.polygon
        [ Svg.Attributes.class hexClass
        , points "1,0 0.5,-0.866 -0.5,-0.866 -1,0 -0.5,0.866 0.5,0.866"
        , transform "scale(0.9)"
        ]
        []


flowerNbhdPolygon : Bool -> Svg msg
flowerNbhdPolygon active =
    Svg.polygon
        [ Svg.Attributes.class
            (if active then
                "flower-overlay flower-active"
             else
                "flower-overlay"
            )
        , points "0.5,4.33 1,3.464 2,3.464 2.5,2.598 3.5,2.598 4,1.732 3.5,0.866 4,0 3.5,-0.866 4,-1.732 3.5,-2.598 2.5,-2.598 2,-3.464 1,-3.464 0.5,-4.33 -0.5,-4.33 -1,-3.464 -2,-3.464 -2.5,-2.598 -3.5,-2.598 -4,-1.732 -3.5,-0.866 -4,0 -3.5,0.866 -4,1.732 -3.5,2.598 -2.5,2.598 -2,3.464 -1,3.464 -0.5,4.33"
        , transform "scale(0.9)"
        ]
        []


withCaption : Coordinate -> String -> String -> String -> Svg msg
withCaption coordinate cellClass hexClass caption =
    Svg.g
        [ atCoordinate coordinate
        , Svg.Attributes.class cellClass
        ]
        [ hexagon hexClass
        , centeredCaption caption
        ]


centeredCaption : String -> Svg msg
centeredCaption caption =
    Svg.text'
        [ Svg.Attributes.style "text-anchor:middle;font-size:0.8;pointer-events:none;"
        , dominantBaseline "central"
        ]
        [ Svg.text caption ]


isMine : CellContent -> Bool
isMine content =
    case content of
        Empty ->
            False

        Count ->
            False

        Mine ->
            True

        Flower _ ->
            True


isHiddenMine : Cell -> Bool
isHiddenMine cell =
    isMine cell.content && (not cell.revealed)


countNbhd : Grid Cell -> Coordinate -> Int
countNbhd grid coordinate =
    Grid.getNbhd coordinate grid
        |> List.filter (\cell -> isMine cell.content)
        |> List.length


countFlower : Grid Cell -> Coordinate -> Int
countFlower grid coordinate =
    Grid.getNbhd2 coordinate grid
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


{-| This svg informs the player about the current intent (reveal, mark mine)
and allows them to change it.
-}
intentDisplay : Intent -> Svg Msg
intentDisplay intent =
    let
        ( className, newIntent ) =
            case intent of
                RevealEmpty ->
                    ( "", RevealMine )

                RevealMine ->
                    ( "flipped", RevealEmpty )
    in
        svg
            [ Html.Attributes.id "intent"
            , Svg.Attributes.class className
            , Svg.Events.onClick (SetIntent newIntent)
            , viewBox "-1.4 -1.2 2.8 2.4"
            , preserveAspectRatio "xMidYMid meet"
            ]
            [ Svg.g
                [ Svg.Attributes.class "right-click-intent"
                , Svg.Attributes.transform "translate(0.2, -0.1)"
                ]
                [ hexagon "hex" ]
            , Svg.g
                [ Svg.Attributes.class "left-click-intent"
                , Svg.Attributes.transform "translate(-0.2, 0.1)"
                ]
                [ hexagon "hex" ]
            ]
