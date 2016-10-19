module Main exposing (..)

import Html exposing (..)
import Html.App
import Return exposing (Return)

main =
    Html.App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    {}


init : Return Msg Model
init =
    Return.singleton {}



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
        [ text "Hello Elm!"]
