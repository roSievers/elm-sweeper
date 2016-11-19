module Fullscreen
    exposing
        ( view
        , update
        )

import GameView exposing (viewLevel, previewLevel, statsText, intentDisplay)
import Html exposing (Html, div, text, br)
import Html.Events
import Html.Attributes exposing (class)
import Types exposing (..)
import Components
import Game


update : Config -> GameAction -> Fullscreen -> Fullscreen
update config action fullscreen =
    { fullscreen
        | gameModel = Game.update config action fullscreen.gameModel
    }


view : Config -> Fullscreen -> Html Msg
view config model =
    div []
        [ flexibleMainContent
            (viewLevel "levelView" "" model.gameModel.level.content
                |> Html.map FullscreenMsg
            )
            (comment model.gameModel.level.comments)
            (sidebar config model.gameModel)
        , attribution model.gameModel.level
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
    let
        ( mineText, mistakeText ) =
            statsText model
    in
        [ Just (Components.flatLabel mineText)
        , Just (Components.flatLabel mistakeText)
        , Just (Components.flatButton (SetRoute MainMenu) "Menu")
        , if config.tabletMode then
            Just (intentDisplay config.flippedControlls)
          else
            Nothing
        ]
            |> List.filterMap identity
            |> div []


attribution : Level -> Html msg
attribution level =
    div [ Html.Attributes.id "levelMeta" ]
        [ text level.title
        , br [] []
        , text <| "by " ++ level.author
        ]


comment : List String -> Html msg
comment comments =
    comments
        |> List.map text
        |> List.intersperse (br [] [])
        |> div
            [ Html.Attributes.id "flexbox-footer"
            , class "level-comments"
            ]
