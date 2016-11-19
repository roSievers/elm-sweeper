module PasteBox exposing (PasteBox, view, update, init)

import Types exposing (..)
import Html exposing (Html, div, p, text, a, textarea, button, br)
import Html.Attributes exposing (href, placeholder, value, style)
import Html.Events exposing (onInput, onClick)
import Components
import GameView
import Game
import HexcellParser


type PasteBox
    = Empty
    | TextEntry String (List String)
    | LevelLoaded GameModel


init : PasteBox
init =
    Empty


fromContent : String -> PasteBox
fromContent content =
    if content == "" then
        Empty
    else
        let
            parseResult =
                HexcellParser.parseLevel content
        in
            case parseResult of
                Err errorMessage ->
                    TextEntry content errorMessage

                Ok level ->
                    LevelLoaded { level = level, mistakes = 0 }


update : Config -> PasteBoxAction -> PasteBox -> PasteBox
update config action pasteBox =
    case action of
        PasteBoxEdit newContent ->
            fromContent newContent

        UserLevelMsg gameAction ->
            case pasteBox of
                LevelLoaded gameModel ->
                    LevelLoaded (Game.update config gameAction gameModel)

                anythingElse ->
                    anythingElse

        PasteBoxFullscreenReturn gameModel ->
            LevelLoaded gameModel


view : Config -> PasteBox -> Html Msg
view config pasteBox =
    case pasteBox of
        Empty ->
            div []
                [ explaination
                , text ""
                , pasteArea ""
                ]

        TextEntry pastedText parseError ->
            div []
                [ explaination
                , errorMessage parseError
                , pasteArea pastedText
                ]

        LevelLoaded gameModel ->
            div []
                [ levelPreview config gameModel
                , clearButton
                ]


explaination : Html msg
explaination =
    p []
        [ text "Community made levels are collected on "
        , a [ href "https://www.reddit.com/r/hexcellslevels/" ] [ text "/r/hexcellslevels" ]
        , text "."
        ]


errorMessage : List String -> Html msg
errorMessage parseError =
    p []
        [ text "This doesn't look like a valid Hexcells level. Maybe the error message helps?"
        , br [] []
        , text (toString parseError)
        ]


pasteArea : String -> Html Msg
pasteArea pastedText =
    textarea
        [ placeholder "Paste a Hexcells level file!"
        , onInput (PasteBoxEdit >> PasteBoxMsg)
        , value pastedText
        , Html.Attributes.id "paste-box"
        ]
        []


clearButton : Html Msg
clearButton =
    button [ onClick (PasteBoxEdit "" |> PasteBoxMsg) ] [ text "Clear Level" ]


levelPreview : Config -> GameModel -> Html Msg
levelPreview config gameModel =
    let
        ( mineText, mistakeText ) =
            GameView.statsText gameModel
    in
        div []
            [ Components.blockContainer
                [ Components.flatLabel mineText
                , Components.flatLabel mistakeText
                , Components.flatButton (goFullscreen gameModel) "Fullscreen"
                ]
            , div [ style [ ( "height", "27em" ) ] ]
                [ GameView.viewLevel "" "inline-grid" gameModel.level.content ]
                |> Html.map (UserLevelMsg >> PasteBoxMsg)
            ]


goFullscreen : GameModel -> Msg
goFullscreen gameModel =
    let
        onClose newGameModel =
            MultiMessage
                (SetRoute MainMenu)
                (PasteBoxMsg (PasteBoxFullscreenReturn newGameModel))

        fullscreen =
            { gameModel = gameModel
            , onClose = (\newGameModel -> onClose newGameModel)
            }
    in
        SetRoute (FullscreenView fullscreen)
