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
import Cell exposing (Cell(..))
import Counting exposing (..)


gameView : Bool -> GameModel -> Html Msg
gameView flippedControlls model =
    div []
        [ viewLevel model
        , Html.br [] []
        , Html.text <| "Remaining: " ++ (toString <| Grid.count Cell.isHiddenMine model.level)
        , Html.br [] []
        , Html.text ("Mistakes: " ++ toString model.mistakes)
        , Html.br [] []
        , intentDisplay flippedControlls
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
    toString (1.5 * toFloat box.left - 1)
        ++ " "
        ++ toString (0.866 * toFloat box.top - 2)
        ++ " "
        ++ toString (1.5 * toFloat (box.right - box.left) + 2)
        ++ " "
        ++ toString (0.866 * toFloat (box.bottom - box.top) + 4)


cellSvg : GameModel -> Grid Cell -> Coordinate -> Cell -> Grid.SvgStack Msg
cellSvg model grid coordinate cell =
    case cell of
        Empty data ->
            emptySvg coordinate data

        Count data ->
            countSvg grid coordinate data

        Mine data ->
            mineSvg coordinate data

        Flower data ->
            flowerSvg grid coordinate data

        RowCount data ->
            rowCountSvg grid coordinate data


emptySvg coordinate data =
    if data.revealed then
        withCaption coordinate "hex lightgray" data.enabled "?"
            |> Grid.singleton
    else
        hiddenSvg coordinate


countSvg grid coordinate data =
    if data.revealed then
        let
            count =
                countNbhd grid coordinate

            caption =
                if data.typed then
                    case typeNbhd grid coordinate of
                        ConnectedNbhd ->
                            "{" ++ toString count ++ "}"

                        DisjointNbhd ->
                            "-" ++ toString count ++ "-"
                else
                    toString count
        in
            withCaption coordinate "hex lightgray" data.enabled caption
                |> Grid.singleton
    else
        hiddenSvg coordinate


mineSvg coordinate data =
    if data.revealed then
        Svg.g
            [ atCoordinate coordinate
            , Svg.Attributes.class "cell"
            ]
            [ hexagon "hex mine"
            ]
            |> Grid.singleton
    else
        hiddenSvg coordinate


flowerSvg grid coordinate data =
    if data.revealed then
        let
            position =
                atCoordinate coordinate

            class =
                (if data.enabled then
                    "cell flower"
                 else
                    "cell flower disabled"
                )

            base =
                Svg.g
                    [ position
                    , Svg.Attributes.class class
                    , Svg.Events.onClick (ToggleOverlay coordinate (not data.overlay))
                    , onRightClick (ToggleEnabled coordinate (not data.enabled))
                    ]
                    [ hexagon "hex mine"
                    , centeredCaption (toString (countFlower grid coordinate))
                    , hexagon "highlight"
                    ]

            overlayPolygon =
                Svg.g [ position ] [ flowerNbhdPolygon data.overlay ]
        in
            Grid.singleton base
                |> Grid.setOverlay overlayPolygon
    else
        hiddenSvg coordinate


rowCountSvg grid coordinate data =
    let
        position =
            atCoordinate coordinate

        count =
            (Grid.boundingBox grid)
                |> Maybe.map (\bounds -> countInDirection bounds grid coordinate data.direction)
                |> Maybe.withDefault 0

        nbhdType =
            (\() ->
                (Grid.boundingBox grid)
                    |> Maybe.map (\bounds -> typeInDirection bounds grid coordinate data.direction)
                    |> Maybe.withDefault ConnectedNbhd
            )

        caption =
            if data.typed then
                case nbhdType () of
                    ConnectedNbhd ->
                        "{" ++ toString count ++ "}"

                    DisjointNbhd ->
                        "-" ++ toString count ++ "-"
            else
                toString count

        class =
            (if data.enabled then
                "row-count"
             else
                "row-count disabled"
            )
    in
        Svg.g
            [ position
            , Svg.Attributes.class class
            , Svg.Events.onClick (ToggleOverlay coordinate (not data.overlay))
            , onRightClick (ToggleEnabled coordinate (not data.enabled))
            ]
            [ Svg.g [ rotation data.direction ]
                [ bottomCaption caption ]
            ]
            |> Grid.singleton
            |> Grid.setOverlay (overlayLine position (rotation data.direction) data.overlay)


hiddenSvg : Coordinate -> Grid.SvgStack Msg
hiddenSvg coordinate =
    Svg.g
        [ atCoordinate coordinate
        , Svg.Events.onClick (Reveal LeftButton coordinate)
        , onRightClick (Reveal RightButton coordinate)
        , Svg.Attributes.class "cell"
        ]
        [ hexagon "hex hidden-cell"
        , hexagon "highlight"
        ]
        |> Grid.singleton



-- Helper functions used by the various cell view functions


onRightClick message =
    Html.Events.onWithOptions
        "contextmenu"
        { stopPropagation = False
        , preventDefault = True
        }
        (Json.Decode.succeed message)


overlayLine position rotation overlay =
    let
        overlayClassName =
            if overlay then
                "row-counter-overlay row-counter-active"
            else
                "row-counter-overlay"
    in
        Svg.g [ position ]
            [ Svg.g [ rotation ]
                [ Svg.line
                    [ Svg.Attributes.x1 "0"
                    , Svg.Attributes.y1 "0.866"
                    , Svg.Attributes.x2 "0"
                    , Svg.Attributes.y2 "20"
                    , Svg.Attributes.class overlayClassName
                    ]
                    []
                ]
            ]


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


withCaption : Coordinate -> String -> Bool -> String -> Svg Msg
withCaption coordinate hexClass enabled caption =
    Svg.g
        [ atCoordinate coordinate
        , Svg.Attributes.class
            (if enabled then
                "cell"
             else
                "cell disabled"
            )
        , onRightClick (ToggleEnabled coordinate (not enabled))
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



-- Transformations


atCoordinate : Coordinate -> Svg.Attribute msg
atCoordinate coordinate =
    transform
        ("translate("
            ++ toString (1.5 * toFloat coordinate.x)
            ++ ","
            ++ toString
                (0.866 * toFloat coordinate.y)
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
intentDisplay : Bool -> Svg Msg
intentDisplay flippedControlls =
    svg
        [ Html.Attributes.id "intent"
        , Svg.Attributes.class
            (if flippedControlls then
                "flipped"
             else
                ""
            )
        , Svg.Events.onClick FlipControlls
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
