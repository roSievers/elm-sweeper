module MixedPuzzle
    exposing
        ( MixedPuzzle
        , Example
        , update
        , puzzleInline
        , puzzleGroup
        , toHtml
        )

import Html exposing (Html, div, text, p, a)
import Html.Attributes exposing (style, class)
import Types exposing (..)
import HexcellParser
import GameView
import Grid exposing (Grid)
import Cell exposing (Cell)
import Game
import Dict exposing (Dict)
import Monocle.Lens as Lens exposing (Lens)
import Literate exposing (LiteratePuzzle, Segment(..), RenderConfig)
import Components


type alias MixedPuzzle =
    LiteratePuzzle Config Example Msg


type alias ExampleData =
    { game : GameModel
    , height : Int
    , displayInformation : Bool
    }


type Example
    = Plain ExampleData
    | LoadError String


emSize : Int -> Html.Attribute msg
emSize height =
    let
        h =
            (toFloat height + 1) * 3
    in
        style [ ( "height", toString h ++ "em" ) ]


renderExample : Config -> Example -> Html (Literate.EitherMsg GameAction Msg)
renderExample config example =
    case example of
        Plain data ->
            if data.displayInformation then
                withUI config data
            else
                withoutUI config data

        LoadError errorMessage ->
            p []
                [ text "An error occured: "
                , text errorMessage
                ]


withUI : Config -> ExampleData -> Html (Literate.EitherMsg GameAction Msg)
withUI config data =
    let
        ( mineText, mistakeText ) =
            GameView.statsText data.game
    in
        div []
            [ Components.blockContainer
                [ Components.flatLabel mineText
                , Components.flatLabel mistakeText
                ]
            , withoutUI config data
            ]


withoutUI : Config -> ExampleData -> Html (Literate.EitherMsg GameAction Msg)
withoutUI config data =
    div [ emSize data.height ]
        [ GameView.viewLevel "" "inline-grid" data.game.level.content ]
          |> Html.map Literate.Internal


renderPreview : Config -> Example -> Html msg
renderPreview _ example =
    case example of
        Plain data ->
            GameView.previewLevel "" data.game.level.content

        LoadError errorMessage ->
            p []
                [ text "An error occured: "
                , text errorMessage
                ]


renderConfig : RenderConfig Config Example GameAction Msg
renderConfig =
    { example = renderExample
    , preview = renderPreview
    , tagMsg = TutorialMsg
    }


updateExample : Config -> GameAction -> Example -> Example
updateExample config action example =
    case example of
        Plain data ->
            Plain
                (Lens.modify game
                    (Game.update config action)
                    data
                )

        (LoadError _) as error ->
            error


game : Lens { a | game : GameModel } GameModel
game =
    { get = .game
    , set = \game example -> { example | game = game }
    }


{-| This is not actually a lens, clean this up later!
Or is it? What are the lens axiomn?
TODO
-}
asGameModel : Lens (Grid Cell) GameModel
asGameModel =
    { get =
        \grid ->
            { level =
                { title = ""
                , author = ""
                , comments = []
                , content = grid
                }
            , mistakes = 0
            }
    , set = \model _ -> model.level.content
    }


initGameModel : Grid Cell -> GameModel
initGameModel grid =
    { level =
        { title = ""
        , author = ""
        , comments = []
        , content = grid
        }
    , mistakes = 0
    }


update : Config -> Literate.Msg GameAction -> MixedPuzzle -> MixedPuzzle
update config message model =
    Literate.update
        message
        (updateExample config)
        model


toHtml : Config -> MixedPuzzle -> Html Msg
toHtml config model =
    Literate.toHtml renderConfig config model


toExample : (GameModel -> ExampleData) -> String -> Example
toExample wrapSuccess data =
    case HexcellParser.parseCellGrid data of
        Ok grid ->
            grid
              |> initGameModel
              |> wrapSuccess
              |> Plain

        Err errorMessages ->
            LoadError (toString errorMessages)


puzzleInline : Int -> String -> Segment config Example msg
puzzleInline height data =
    InlineExample (toExample (\model -> ExampleData model height False ) data)


puzzleGroup : Int -> List String -> Segment config Example msg
puzzleGroup height levels =
    List.map (toExample (\model -> ExampleData model height True )) levels
        |> TabbedExample
