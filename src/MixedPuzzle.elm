module MixedPuzzle
    exposing
        ( MixedPuzzle
        , update
        , puzzleInline
        , puzzleGroup
        , toHtml
        )

import Html exposing (Html, div, text, p, a)
import Html.Attributes exposing (style, class)
import Html.Events exposing (onClick)
import Types exposing (..)
import HexcellParser
import GameView
import Grid exposing (Grid)
import Cell exposing (Cell)
import Game
import Dict exposing (Dict)
import Monocle.Lens as Lens exposing (Lens)
import Literate exposing (LiteratePuzzle, Segment(..))
import Components
import List.Extra as List
import Pivot exposing (Pivot)


type alias MixedPuzzle =
    LiteratePuzzle Config Example Msg



{- type alias ExampleData =
   { game : GameModel
   , height : Int
   , displayInformation : Bool
-}


emSize : Int -> Html.Attribute msg
emSize height =
    let
        h =
            (toFloat height + 1) * 3
    in
        style [ ( "height", toString h ++ "em" ) ]


renderExample : Config -> Literate.Index -> Example -> Html Msg
renderExample config index example =
    case example of
        Plain height gameModel ->
            withoutUI config index height gameModel
                |> Html.map MixedPuzzleMsg

        Tabbed height content ->
            div []
              [ tabHeader config index content
              , withUI config index height (Pivot.getPivot content)
              ]

        LoadError errorMessage ->
            p []
                [ text "An error occured: "
                , text errorMessage
                ]


withUI : Config -> Int -> Int -> GameModel -> Html Msg
withUI config index height gameModel =
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
            , withoutUI config index height gameModel
                |> Html.map MixedPuzzleMsg
            ]


withoutUI : Config -> Int -> Int -> GameModel -> Html (Literate.Msg e MixedPuzzleAction)
withoutUI config index height gameModel =
    div [ emSize height ]
        [ GameView.viewLevel "" "inline-grid" gameModel.level.content ]
        |> Html.map (PuzzleMsg >> Literate.tagMsg index)


goFullscreen : GameModel -> Msg
goFullscreen gameModel =
    let
        onClose newGameModel =
            MultiMessage
                (SetRoute Tutorial)
                (PasteBoxMsg (PasteBoxFullscreenReturn newGameModel))

        fullscreen =
            { gameModel = gameModel
            , onClose = (\newGameModel -> onClose newGameModel)
            }
    in
        SetRoute (FullscreenView fullscreen)


renderPreview : Config -> GameModel -> Html msg
renderPreview _ gameModel =
    GameView.previewLevel "" gameModel.level.content


updateExample : Config -> MixedPuzzleAction -> Example -> Example
updateExample config action example =
    case action of
        PuzzleMsg gameAction ->
            updateGameContent config gameAction example

        TabChange subIndex ->
            updateActiveTab subIndex example


updateGameContent : Config -> GameAction -> Example -> Example
updateGameContent config action example =
    case example of
        Plain height gameModel ->
            Plain height
                (Game.update config action gameModel)

        Tabbed height content ->
            Lens.modify Pivot.pivot
              (Game.update config action)
              content
              |> Tabbed height

        anythingElse ->
            anythingElse


updateActiveTab : Int -> Example -> Example
updateActiveTab subIndex example =
    case Debug.log "example" example of
        Tabbed height content ->
            Pivot.setIndex subIndex content
              |> Maybe.withDefault content
              |> Tabbed height

        anythingElse ->
            anythingElse


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


update : Config -> Literate.Msg Example MixedPuzzleAction -> MixedPuzzle -> MixedPuzzle
update config message model =
    Literate.update
        message
        (updateExample config)
        model


toHtml : Config -> MixedPuzzle -> Html Msg
toHtml config model =
    Literate.toHtml (renderExample config) config model


stripResult : Result a a -> a
stripResult result =
    case result of
        Ok a ->
            a

        Err a ->
            a


puzzleInline : Int -> String -> Segment config Example msg
puzzleInline height data =
    HexcellParser.parseCellGrid data
        |> Result.map (\grid -> Plain height (initGameModel grid))
        |> Result.mapError (\errorMessages -> LoadError (toString errorMessages))
        |> stripResult
        |> InlineExample


maybeCombine : List (Maybe a) -> Maybe (List a)
maybeCombine =
    let
        step e acc =
            case e of
                Nothing ->
                    Nothing

                Just x ->
                    Maybe.map ((::) x) acc
    in
        List.foldr step (Just [])


puzzleGroup : Int -> List String -> Segment config Example msg
puzzleGroup height data =
    let
        parsing =
            HexcellParser.parseCellGrid
                >> Result.toMaybe
                >> Maybe.map initGameModel
    in
        List.map parsing data
            |> maybeCombine
            |> Maybe.andThen Pivot.fromList
            |> Maybe.map (Tabbed height)
            |> Maybe.withDefault (LoadError "At least one level isn't valid.")
            |> InlineExample



{- Things pushed in here by the literate refactor -}




--    TabChange index subindex ->
--        List.updateAt index (updateActiveTab subindex) puzzle
--            |> Maybe.withDefault puzzle


tabHeaderSpacing : List (Html msg) -> Html msg
tabHeaderSpacing tabs =
    let
        length =
            List.length tabs

        tabsPerLine =
            if length <= 6 then
                length
            else
                6

        tabWidth =
            if length > 0 then
                100 / toFloat tabsPerLine
            else
                100

        wrapTab tab =
            div
                [ style
                    [ ( "width", toString tabWidth ++ "%" )
                    , ( "display", "inline-flex" )
                    ]
                ]
                [ tab ]
    in
        div
            [ style [ ( "width", "100%" ), ( "flex-direction", "row" ) ]
            ]
            (List.map wrapTab tabs)


tab : Config -> Int -> GameModel -> Html MixedPuzzleAction
tab config subIndex gameModel =
    div
        [ style
            [ ( "width", "100%" )
            , ( "border", "1px solid lightgray" )
            , ( "text-align", "center" )
            ]
        , onClick (TabChange subIndex)
        ]
        [ renderPreview config gameModel
            |> Html.map never
        ]


tabHeader : Config -> Int -> Pivot GameModel -> Html Msg
tabHeader config index examples =
    examples
        |> Pivot.toList
        |> List.indexedMap (tab config)
        |> List.map (Html.map (Literate.tagMsg index))
        |> tabHeaderSpacing
        |> Html.map (MixedPuzzleMsg)


activeExample config index example =
    withUI config index example
