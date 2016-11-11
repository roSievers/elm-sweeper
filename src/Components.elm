module Components exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)


flatButton : msg -> String -> Html msg
flatButton message caption =
    div
        [ class "flat-button"
        , onClick message
        ]
        [ text caption ]


flatLabel : String -> Html msg
flatLabel caption =
    div [ class "flat-label" ]
        [ text caption ]


paperWrapper : List (Html msg) -> Html msg
paperWrapper content =
    div [ Html.Attributes.id "outer-text-container" ]
        [ div [ Html.Attributes.id "inner-text-container" ]
            content
        ]


blockContainer : List (Html msg) -> Html msg
blockContainer elements =
    let
        blockWrapper content =
            div [ class "flex-block" ] [ content ]
    in
        div [ class "flex-container" ]
            (List.map blockWrapper elements)
