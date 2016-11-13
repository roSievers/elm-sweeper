module Fullscreen
    exposing
        ( gameView
        )

import GameView exposing (viewLevel, previewLevel, statsText, translate, hexagon)
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
import Components


gameView : Config -> GameModel -> Html Msg
gameView config model =
    div []
        [ flexibleMainContent
            (viewLevel "levelView" "" model.level.content
                |> Html.App.map GameMsg
            )
            (comment model.level.comments)
            (sidebar config model)
        , attribution model.level
        ]


flexibleMainContent : Html msg -> Html msg -> Html msg -> Html msg
flexibleMainContent mainContent footer sidebar =
    div [ Html.Attributes.id "flexbox-wrapper" ]
        [ div [ Html.Attributes.id "flexbox-sidebar" ] [ sidebar ]
        , div [ Html.Attributes.id "flexbox-main" ]
            [ div [ Html.Attributes.id "flexbox-grid" ] [ mainContent ]
            , footer
            ]
        ]


sidebar : Config -> GameModel -> Html Msg
sidebar config model =
    [ Just (stats model)
    , if config.tabletMode then
        Just (intentDisplay config.flippedControlls)
      else
        Nothing
    ]
        |> List.filterMap identity
        |> Html.div []


stats : GameModel -> Html Msg
stats model =
    let
        ( mineText, mistakeText ) =
            statsText model
    in
        Html.div []
            [ Components.flatLabel mineText
            , Components.flatLabel mistakeText
            , Components.flatButton (SetRoute MainMenu) "Menu"
            ]


attribution : Level -> Html msg
attribution level =
    Html.div [ Html.Attributes.id "levelMeta" ]
        [ Html.text level.title
        , Html.br [] []
        , Html.text <| "by " ++ level.author
        ]


comment : List String -> Html msg
comment comments =
    comments
        |> List.map Html.text
        |> List.intersperse (Html.br [] [])
        |> div
            [ Html.Attributes.id "flexbox-footer"
            , Html.Attributes.class "level-comments"
            ]



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
