module Literate
    exposing
        ( LiteratePuzzle
        , Segment(..)
        , Index
        , literate
        , update
        , RenderConfig
        , noPreview
        , toHtml
        , Msg
        )

{-| A library to write tutorials with interactive examples mixed in.

@docs LiteratePuzzle

The `LiteratePuzzle` takes quite a few type parameters, here is why:

Your tutorial text can depend on the `config` type, this is useful when you
explain keybindings or other global data that might change while the documentation is read.
Inside the tutorials are interactive examples, to help you manage them the LiteratePuzzle
needs to know their type, this is why it asks for a `example` type.
And finally, there is no interactivity without passing messages of a known `msg` type.

# Writing literate puzzles

Literate puzzles can contain a mix of both markdown and html.
As noted above, both may depend on some configuration data.

@docs Segment, literate

**Warning:** Configuration dependent markdown is fully parsed on each `toHtml`,
so keep it short.

# Rendering literate puzzles to Html

To output Html, the LiteratePuzzle needs to know how it should treat examples.
There are two things to consider here:

  - How to render an example to Html.
  - How to wire messages from the examples back to your program while remembering
    which example fired it.

@docs RenderConfig, toHtml

# Updating examples inside the literate puzzle

@docs updateExample

The name is inspired by “literate programming”, where a program is written
as an explanation of the program logic in a natural language,
mixed with snippets of source code. Here puzzles take the place of the code.
-}

import Html exposing (Html, div, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Markdown
import List.Extra as List


{-| Encodes a LiteratePuzzle.
-}
type alias LiteratePuzzle config example msg =
    List (ProcessedSegment config example msg)


{-| The Index type is used to adress segments instead of a simple Int to allow
nested segments.
-}
type Index
    = Flat Int
    | Nested Int Int


flat : Index -> Int
flat id =
    case id of
        Flat index ->
            index

        Nested index _ ->
            index


nested : Index -> Maybe Int
nested id =
    case id of
        Flat _ ->
            Nothing

        Nested _ index ->
            Just index


type Msg exampleMsg
    = TabChange Int Int
    | ExampleMsg Index exampleMsg


{-| Specify how examples are rendered and messages are treated.
-}
type alias RenderConfig config example exampleMsg msg =
    { example : config -> example -> Html exampleMsg
    , preview : config -> example -> Html Never
    , tagMsg : Msg exampleMsg -> msg
    }


noPreview : config -> example -> Html Never
noPreview _ _ =
    div [] [ text "Previews are disabled." ]


{-| A literate puzzle is a sequence of segments. Some of the segments might
be generated from `config` data.
-}
type Segment config example msg
    = StaticMarkdown String
    | StaticHtml (Html msg)
    | DynamicMarkdown (config -> String)
    | DynamicHtml (config -> Html msg)
    | InlineExample example
    | TabbedExample (List example)


type ProcessedSegment config example msg
    = Static (Html msg)
    | Dynamic (config -> Html msg)
    | Interactive example
    | Tabbed (List example) Int


processSegment : Segment config example msg -> ProcessedSegment config example msg
processSegment segment =
    case segment of
        StaticMarkdown string ->
            Static (Markdown.toHtml [] string)

        StaticHtml html ->
            Static html

        DynamicMarkdown generateMarkdown ->
            Dynamic (generateMarkdown >> Markdown.toHtml [])

        DynamicHtml generateHtml ->
            Dynamic generateHtml

        InlineExample example ->
            Interactive example

        TabbedExample examples ->
            Tabbed examples 0


{-| Turn a list of segments into a LiteratePuzzle. This converts all static markdown to Html.
-}
literate : List (Segment config example msg) -> LiteratePuzzle config example msg
literate =
    List.map processSegment


update :
    Msg exampleMsg
    -> (exampleMsg -> example -> example)
    -> LiteratePuzzle config example msg
    -> LiteratePuzzle config example msg
update message updateFunction puzzle =
    case message of
        TabChange index subindex ->
            List.updateAt index (updateActiveTab subindex) puzzle
                |> Maybe.withDefault puzzle

        ExampleMsg index exampleMsg ->
            updateExample index (updateFunction exampleMsg) puzzle


updateActiveTab subindex segment =
    case segment of
        Tabbed examples _ ->
            Tabbed examples subindex

        anythingElse ->
            anythingElse


{-| Try to update an example at a specific position.
Do nothing if there is no example at the specified position.
-}
updateExample :
    Index
    -> (example -> example)
    -> LiteratePuzzle config example msg
    -> LiteratePuzzle config example msg
updateExample index updateFunction puzzle =
    let
        internalUpdateFunction segment =
            case segment of
                Interactive example ->
                    Interactive (updateFunction example)

                Tabbed examples current ->
                    (nested index)
                        |> Maybe.map
                            (\i -> List.updateAt i updateFunction examples)
                        |> Maybe.withDefault (Just examples)
                        |> Maybe.withDefault examples
                        |> flip Tabbed current

                anythingElse ->
                    anythingElse
    in
        List.updateAt (flat index) internalUpdateFunction puzzle
            |> Maybe.withDefault puzzle


{-| Turn a LiteratePuzzle into an HTML element.
-}
toHtml :
    RenderConfig config example exampleMsg msg
    -> config
    -> LiteratePuzzle config example msg
    -> Html msg
toHtml render config puzzle =
    div [ Html.Attributes.id "outer-text-container" ]
        [ div [ Html.Attributes.id "inner-text-container" ]
            (List.indexedMap
                (segmentToHtml render config)
                puzzle
            )
        ]


segmentToHtml :
    RenderConfig config example exampleMsg msg
    -> config
    -> Int
    -> ProcessedSegment config example msg
    -> Html msg
segmentToHtml render config index segment =
    case segment of
        Static html ->
            html

        Dynamic generateHtml ->
            generateHtml config

        Interactive example ->
            render.example config example
                |> Html.map (ExampleMsg (Flat index) >> render.tagMsg)

        Tabbed examples activeSubindex ->
            div []
                [ tabHeader
                    (List.indexedMap (nestedExampleToHtml render config index) examples)
                , div [ style [ ( "border", "1px solid lightgray" ) ] ]
                    [ activeExample render config index activeSubindex examples ]
                ]


tabHeader : List (Html msg) -> Html msg
tabHeader tabs =
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


nestedExampleToHtml render config index1 index2 example =
    div
        [ style
            [ ( "width", "100%" )
            , ( "border", "1px solid lightgray" )
            , ( "text-align", "center" )
            ]
        , onClick (render.tagMsg (TabChange index1 index2))
        ]
        [ render.preview config example
            |> Html.map never
        ]


activeExample render config index activeSubindex examples =
    let
        maybeExample =
            List.getAt activeSubindex examples
    in
        case maybeExample of
            Just example ->
                render.example config example
                    |> Html.map (ExampleMsg (Nested index activeSubindex) >> render.tagMsg)

            Nothing ->
                div [] [ text "A nonexistent tab is active. This should be impossible." ]
