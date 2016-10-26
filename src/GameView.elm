module GameView exposing (gameView)

import Html exposing (Html, div, text)
import Html.App
import Html.Events
import Html.Attributes
import Svg exposing (Svg, svg, rect)
import Svg.Attributes exposing (..)
import Svg.Events
import Json.Decode
import Grid exposing (Grid, Direction(..), Coordinate)
import Types exposing (..)
import Counting exposing (..)

gameView : GameModel -> Html Msg
gameView model =
    div []
        [ viewLevel model
        , Html.br [] []
        , Html.text <| "Remaining: " ++ (toString <| Grid.count isHiddenMine model.level)
        , Html.br [] []
        , Html.text ("Mistakes: " ++ toString model.mistakes)
        , Html.br [] []
        , intentDisplay model.intent
        , Html.br [] []
        , Html.button [ Html.Events.onClick (SetRoute MainMenu) ] [ Html.text "Main Menu" ]
        ]


viewLevel : GameModel -> Html.Html Msg
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


cellSvg : GameModel -> Grid Cell -> Coordinate -> Cell -> Grid.SvgStack Msg
cellSvg model grid coordinate cell =
    case cell of
        GameCell cellData ->
            if cellData.revealed then
                case cellData.content of
                    Empty ->
                        emptyCell coordinate |> Grid.singleton

                    Count ->
                        counterCell grid coordinate cellData |> Grid.singleton

                    TypedCount ->
                        typedCounterCell grid coordinate cellData |> Grid.singleton

                    Mine ->
                        mineCell coordinate |> Grid.singleton

                    Flower overlay ->
                        flowerCell grid coordinate cellData overlay
            else
                hiddenCell model.intent coordinate cellData |> Grid.singleton

        RowCount direction ->
            rowCountCell grid coordinate direction

        TypedRowCount direction ->
            typedRowCountCell grid coordinate direction


mineCell : Coordinate -> Svg Msg
mineCell coordinate =
    Svg.g
        [ atCoordinate coordinate
        , Svg.Attributes.class "cell"
        ]
        [ hexagon "hex mine"
        ]


hiddenCell : Intent -> Coordinate -> CellData -> Svg Msg
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


counterCell : Grid Cell -> Coordinate -> CellData -> Svg msg
counterCell grid coordinate cell =
    withCaption coordinate "cell" "hex lightgray" (toString (countNbhd grid coordinate))


typedCounterCell : Grid Cell -> Coordinate -> CellData -> Svg msg
typedCounterCell grid coordinate cell =
    let
        count =
            countNbhd grid coordinate

        nbhdType =
            typeNbhd grid coordinate

        caption =
            case nbhdType of
                ConnectedNbhd ->
                    "{" ++ toString count ++ "}"

                DisjointNbhd ->
                    "-" ++ toString count ++ "-"
    in
        withCaption coordinate "cell" "hex lightgray" caption


flowerCell : Grid Cell -> Coordinate -> CellData -> Bool -> Grid.SvgStack Msg
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


rowCountCell : Grid Cell -> Coordinate -> Direction -> Grid.SvgStack Msg
rowCountCell grid coordinate direction =
    Svg.g
        [ atCoordinate coordinate
        , Svg.Attributes.class "row-count"
        ]
        [ Svg.g [ rotation direction ]
            [ (Grid.boundingBox grid)
                |> Maybe.map (\bounds -> countInDirection bounds grid coordinate direction)
                |> Maybe.withDefault 0
                |> toString
                |> bottomCaption
            ]
        ]
        |> Grid.singleton



-- TODO


typedRowCountCell : Grid Cell -> Coordinate -> Direction -> Grid.SvgStack Msg
typedRowCountCell grid coordinate direction =
    let
        count =
            (Grid.boundingBox grid)
                |> Maybe.map (\bounds -> countInDirection bounds grid coordinate direction)
                |> Maybe.withDefault 0

        nbhdType =
            (Grid.boundingBox grid)
                |> Maybe.map (\bounds -> typeInDirection bounds grid coordinate direction)
                |> Maybe.withDefault ConnectedNbhd

        caption =
            case nbhdType of
                ConnectedNbhd ->
                    "{" ++ toString count ++ "}"

                DisjointNbhd ->
                    "-" ++ toString count ++ "-"
    in
        Svg.g
            [ atCoordinate coordinate
            , Svg.Attributes.class "row-count"
            ]
            [ Svg.g [ rotation direction ]
                [ bottomCaption caption ]
            ]
            |> Grid.singleton



-- Helper functions used by the various cell view functions


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


bottomCaption : String -> Svg msg
bottomCaption caption =
    Svg.text'
        [ Svg.Attributes.style "text-anchor:middle;font-size:0.4;"
        , Svg.Attributes.y "0.75"
        ]
        [ Svg.text caption ]


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


rotation : Direction -> Svg.Attribute msg
rotation direction =
    case direction of
        DownLeft ->
            Svg.Attributes.transform "rotate(60)"

        Down ->
            Svg.Attributes.transform "rotate(0)"

        DownRight ->
            Svg.Attributes.transform "rotate(-60)"



-- Intent Display


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
