module Game exposing (updateGame)


import Types exposing (..)
import Cell exposing (Cell)
import Grid exposing (Grid, Coordinate)
import Monocle.Lens as Lens exposing (Lens, modify)
import Monocle.Optional as Optional
import Monocle.Common exposing ((=>))

(>>>) : Lens a b -> Lens b c -> Lens a c
(>>>) = Lens.compose


gameLevel : Lens GameModel Level
gameLevel =
    Lens (.level) (\newLevel model -> { model | level = newLevel })


gameGrid : Lens Level (Grid Cell)
gameGrid =
    Lens (.content) (\newGrid model -> {model | content = newGrid})


updateGame : Config -> GameAction -> GameModel -> GameModel
updateGame config action model =
    case action of
      Reveal button coordinate ->
          handleReveal config.flippedControlls button coordinate model

      ToggleOverlay coordinate overlay ->
          model
              |> Optional.modify
                  (Optional.fromLens (gameLevel >>> gameGrid)
                      => (Grid.at coordinate)
                  )
                  (Cell.setOverlay overlay)

      ToggleEnabled coordinate enabled ->
          model
              |> Optional.modify
                  (Optional.fromLens (gameLevel >>> gameGrid)
                      => (Grid.at coordinate)
                  )
                  (if enabled then
                      Cell.setEnabled enabled
                   else
                      Cell.setEnabled enabled >> Cell.setOverlay False
                  )


-- Update helper functions used while ingame


handleReveal : Bool -> MouseButton -> Coordinate -> GameModel -> GameModel
handleReveal flippedControlls button coordinate model =
    Maybe.map
        (\cell ->
            let
                mineClicked =
                    Cell.isMine cell

                mineDesired =
                    xor (button == LeftButton) flippedControlls
            in
                case mineClicked == mineDesired of
                    True ->
                        Optional.modify
                            (Optional.fromLens (gameLevel >>> gameGrid) => (Grid.at coordinate))
                            Cell.reveal
                            model

                    False ->
                        { model
                            | mistakes = model.mistakes + 1
                        }
        )
        ((Grid.at coordinate).getOption model.level.content)
        |> Maybe.withDefault model
