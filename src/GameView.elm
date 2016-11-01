module GameView exposing (gameView, viewLevel, previewLevel)

import Html exposing (Html, div, text)
import Html.App
import Html.Events
import Html.Attributes
import Svg exposing (Svg, svg, rect)
import Svg.Attributes exposing (..)
import Svg.Events
import String
import Basics.Extra exposing (never)
import Json.Decode
import Grid exposing (Grid, Direction(..), Coordinate)
import Types exposing (..)
import Cell exposing (Cell(..))
import Counting exposing (..)


gameView : Bool -> GameModel -> Html Msg
gameView flippedControlls model =
    div []
        [ flexibleMainContent
            (viewLevel "levelView" model.level.content)
            (comment model.level.comments)
            (sidebar flippedControlls model)
        , attribution model.level
        ]


flexibleMainContent : Html msg -> Html msg -> Html msg -> Html msg
flexibleMainContent mainContent footer sidebar =
    div [ Html.Attributes.id "flexbox-wrapper" ]
        [ div [ Html.Attributes.id "flexbox-sidebar" ] [ sidebar ]
        , div [ Html.Attributes.id "flexbox-main" ]
          [ div [Html.Attributes.id "flexbox-grid"] [ mainContent ]
          , div [Html.Attributes.id "flexbox-footer"] [ footer ]
          ]
        ]


sidebar : Bool -> GameModel -> Html Msg
sidebar flippedControlls model =
    Html.div []
        [ stats model
        , Html.br [] []
        , intentDisplay flippedControlls
        , Html.br [] []
        , Html.button [ Html.Events.onClick (SetRoute MainMenu) ] [ Html.text "Main Menu" ]
        ]


stats : GameModel -> Html msg
stats model =
    let
        minesLeft =
            Grid.count Cell.isHiddenMine model.level.content

        mineText =
            if minesLeft == 0 then
                "No mines left"
            else if minesLeft == 1 then
                "1 mine left"
            else
                toString minesLeft ++ " mines left"

        mistakeText =
            if model.mistakes == 0 then
                "Flawless"
            else if model.mistakes == 1 then
                "1 mistake"
            else
                toString model.mistakes ++ " mistakes"
    in
        Svg.svg
            [ Html.Attributes.id "errorCounter"
            , width "100%"
            , viewBox "-100 0 200 120"
            ]
            [ Svg.rect [ x "-95", y "10", width "190", height "45", style "fill:blue" ] []
            , Svg.rect [ x "-95", y "60", width "190", height "45", style "fill:blue" ] []
            , Svg.text'
                [ Svg.Attributes.style "text-anchor:middle;fill:lightgray;font-weight:bold;"
                , atCoordinate { x = 0, y = 45 }
                ]
                [ Svg.text mineText ]
            , Svg.text'
                [ Svg.Attributes.style "text-anchor:middle;fill:lightgray;font-weight:bold;"
                , atCoordinate { x = 0, y = 100 }
                ]
                [ Svg.text mistakeText ]
            ]


attribution : Level -> Html msg
attribution level =
    Html.div [ Html.Attributes.id "levelMeta" ]
        [ Html.text level.title
        , Html.br [] []
        , Html.text <| "by " ++ level.author
        ]

{-| TODO: This should somehow shrink if only one line of text is present.
Then `viewBox "-100 0 200 40"` and a #flexbox-footer.height of 100px is good. -}
comment : List String -> Html msg
comment comments =
    let
        textNode index caption =
          Svg.text'
              [ Svg.Attributes.style "text-anchor:middle;fill:lightgray;font-weight:bold;"
              , atCoordinate { x = 0, y = 30 + index * 30 }
              ]
              [ Svg.text caption ]
    in
        Svg.svg
            [ Html.Attributes.id "comments"
            , width "100%"
            , height "100%"
            , viewBox "-100 0 200 70"
            ]
            (List.indexedMap textNode comments)


viewLevel : String -> Grid Cell -> Html.Html Msg
viewLevel idAttribute grid =
    let
        visibleArea =
            Grid.boundingBox grid
                |> Maybe.map (levelBox >> viewBox)
                |> Maybe.withDefault (viewBox "0 0 20 16")
    in
        svg
            [ Html.Attributes.id idAttribute, width "100", height "80", visibleArea, preserveAspectRatio "xMidYMid meet" ]
            [ Grid.view cellSvgInteractive grid
            ]


previewLevel : String -> Grid Cell -> Html.Html msg
previewLevel idAttribute grid =
    let
        visibleArea =
            Grid.boundingBox grid
                |> Maybe.map (levelBox >> viewBox)
                |> Maybe.withDefault (viewBox "0 0 20 16")
    in
        svg
            [ Html.Attributes.id idAttribute, width "100", height "80", visibleArea, preserveAspectRatio "xMidYMid meet" ]
            [ Grid.view cellSvgPreview grid
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



-- Rendering a single cell to Svg


cellSvg : Grid Cell -> Coordinate -> Cell -> CellDisplay
cellSvg grid coordinate cell =
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


cellSvgInteractive : Grid Cell -> Coordinate -> Cell -> Grid.SvgStack Msg
cellSvgInteractive grid coordinate cell =
    cellSvg grid coordinate cell
        |> genericCellInteractive


cellSvgPreview : Grid Cell -> Coordinate -> Cell -> Grid.SvgStack msg
cellSvgPreview grid coordinate cell =
    cellSvg grid coordinate cell
        |> genericCellPreview


{-| The CellDisplay type captures all revevant information for rendering a
cell without actually creating any Svg nodes yet. This allows some late
modifications (like removing event handlers and overlays).

There are a few `Html.App.map never` sprinkled in the code they can be
replaced by Svg.map once Elm 0.18 is out.
-}
type alias CellDisplay =
    { class : String
    , coordinate : Coordinate
    , leftClick : Maybe Msg
    , rightClick : Maybe Msg
    , content : List (Svg Never)
    , overlay : Maybe (List (Svg Never))
    }


genericCellInteractive : CellDisplay -> Grid.SvgStack Msg
genericCellInteractive displayData =
    let
        position =
            atCoordinate displayData.coordinate

        attributes =
            [ Just (Svg.Attributes.class displayData.class)
            , Just position
            , Maybe.map Svg.Events.onClick displayData.leftClick
            , Maybe.map onRightClick displayData.rightClick
            ]
                |> List.filterMap identity

        content =
            displayData.content
                |> List.map (Html.App.map never)
    in
        case displayData.overlay of
            Nothing ->
                Svg.g attributes content
                    |> Grid.singleton

            Just overlayContent ->
                Svg.g attributes content
                    |> Grid.singleton
                    |> Grid.setOverlay (Svg.g [ position ] (List.map (Html.App.map never) overlayContent))


genericCellPreview : CellDisplay -> Grid.SvgStack msg
genericCellPreview displayData =
    let
        position =
            atCoordinate displayData.coordinate

        attributes =
            [ Svg.Attributes.class (displayData.class ++ " preview")
            , position
            ]
    in
        Svg.g attributes displayData.content
            |> Html.App.map never
            |> Grid.singleton


emptySvg coordinate data =
    if data.revealed then
        withCaption coordinate "hex lightgray" data.enabled "?"
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
    else
        hiddenSvg coordinate


mineSvg coordinate data =
    if data.revealed then
        { class = "cell"
        , coordinate = coordinate
        , leftClick = Nothing
        , rightClick = Nothing
        , content =
            [ hexagon "hex mine"
            ]
        , overlay = Nothing
        }
    else
        hiddenSvg coordinate


flowerSvg grid coordinate data =
    if data.revealed then
        { class = classList [ ( "cell flower", True ), ( "disabled", not data.enabled ) ]
        , coordinate = coordinate
        , leftClick = Just (ToggleOverlay coordinate (not data.overlay))
        , rightClick = Just (ToggleEnabled coordinate (not data.enabled))
        , content =
            [ hexagon "hex mine"
            , centeredCaption (toString (countFlower grid coordinate))
            , hexagon "highlight"
            ]
        , overlay = Just [ flowerNbhdPolygon data.overlay ]
        }
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
    in
        { class = classList [ ( "row-count", True ), ( "disabled", not data.enabled ) ]
        , coordinate = coordinate
        , leftClick = Just (ToggleOverlay coordinate (not data.overlay))
        , rightClick = Just (ToggleEnabled coordinate (not data.enabled))
        , content =
            [ Svg.g [ rotation data.direction ]
                [ bottomCaption caption ]
            ]
        , overlay = Just [ (overlayLine (rotation data.direction) data.overlay) ]
        }


hiddenSvg : Coordinate -> CellDisplay
hiddenSvg coordinate =
    { class = "cell"
    , coordinate = coordinate
    , leftClick = Just (Reveal LeftButton coordinate)
    , rightClick = Just (Reveal RightButton coordinate)
    , content = [ hexagon "hex hidden-cell", hexagon "highlight" ]
    , overlay = Nothing
    }



-- Helper functions used by the various cell view functions


{-| Svg version of Html.Attributes.classList.
-}
classList : List ( String, Bool ) -> String
classList classes =
    classes
        |> List.filter (\( _, active ) -> active)
        |> List.map (\( className, _ ) -> className)
        |> String.join " "


classListOld =
    classList >> Svg.Attributes.class


onRightClick message =
    Html.Events.onWithOptions
        "contextmenu"
        { stopPropagation = False
        , preventDefault = True
        }
        (Json.Decode.succeed message)


overlayLine rotation overlay =
    Svg.g [ rotation ]
        [ Svg.line
            [ Svg.Attributes.x1 "0"
            , Svg.Attributes.y1 "0.866"
            , Svg.Attributes.x2 "0"
            , Svg.Attributes.y2 "40"
            , classListOld [ ( "row-counter-overlay", True ), ( "row-counter-active", overlay ) ]
            ]
            []
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
        [ classListOld [ ( "flower-overlay", True ), ( "flower-active", active ) ]
        , points "0.5,4.33 1,3.464 2,3.464 2.5,2.598 3.5,2.598 4,1.732 3.5,0.866 4,0 3.5,-0.866 4,-1.732 3.5,-2.598 2.5,-2.598 2,-3.464 1,-3.464 0.5,-4.33 -0.5,-4.33 -1,-3.464 -2,-3.464 -2.5,-2.598 -3.5,-2.598 -4,-1.732 -3.5,-0.866 -4,0 -3.5,0.866 -4,1.732 -3.5,2.598 -2.5,2.598 -2,3.464 -1,3.464 -0.5,4.33"
        , transform "scale(0.9)"
        ]
        []


withCaption : Coordinate -> String -> Bool -> String -> CellDisplay
withCaption coordinate hexClass enabled caption =
    { class = classList [ ( "cell", True ), ( "disabled", not enabled ) ]
    , coordinate = coordinate
    , leftClick = Nothing
    , rightClick = Just (ToggleEnabled coordinate (not enabled))
    , content =
        [ hexagon hexClass
        , centeredCaption caption
        ]
    , overlay = Nothing
    }


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
    [ "translate("
    , toString (1.5 * toFloat coordinate.x)
    , ","
    , toString (0.866 * toFloat coordinate.y)
    , ")"
    ]
        |> String.join ""
        |> transform


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
        , viewBox "-1.2 -1.2 2.4 2.4"
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
