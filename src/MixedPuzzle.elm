module MixedPuzzle
    exposing
        ( MixedPuzzle
        , Example
        , ExampleHeight(..)
        , update
        , puzzleInline
        , puzzleGroup
        , toHtml
        )

import Html exposing (Html, div, text, p, a)
import Html.Attributes
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


type Example
    = Plain
        { config : ExampleDisplayConfig
        , game : GameModel
        }
    | LoadError String


type alias ExampleDisplayConfig =
    { height : ExampleHeight
    , displayInformation : Bool
    }


type ExampleHeight
    = Small
    | Medium
    | Large


sizeClass height =
    case height of
        Small ->
            "inline-small"

        Medium ->
            "inline-medium"

        Large ->
            "inline-large"


renderExample : Config -> Example -> Html GameAction
renderExample _ example =
    case example of
        Plain data ->
            div []
                [ renderInformation data
                , GameView.viewLevel "" ("inline-grid " ++ sizeClass data.config.height) data.game.level.content
                ]

        LoadError errorMessage ->
            p []
                [ text "An error occured: "
                , text errorMessage
                ]


renderInformation data =
    case data.config.displayInformation of
        True ->
            let
                ( mineText, mistakeText ) =
                    GameView.statsText data.game
            in
                Components.blockContainer
                    [ Components.flatLabel mineText
                    , Components.flatLabel mistakeText
                    ]

        False ->
            div [] []


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
                    (Game.updateGame config action)
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


toExample : ExampleDisplayConfig -> String -> Example
toExample config data =
    case HexcellParser.parseCellGrid data of
        Ok grid ->
            Plain
                { config = config
                , game = initGameModel grid
                }

        Err errorMessages ->
            LoadError (toString errorMessages)


puzzleInline : ExampleHeight -> String -> Segment config Example msg
puzzleInline height data =
    InlineExample (toExample { height = height, displayInformation = False } data)


puzzleGroup : ExampleHeight -> List String -> Segment config Example msg
puzzleGroup height levels =
    List.map (toExample { height = height, displayInformation = True }) levels
        |> TabbedExample
