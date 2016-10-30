# Elm Sweeper

Elm Sweeper aims to reimplement the puzzle mechanics of
[Hexcells](http://store.steampowered.com/app/265890/)
as a web application. Hexcells is a supercharged
Minesweeper with hand crafted levels.

Community made levels are collected on
[/r/hexcellslevels](https://www.reddit.com/r/hexcellslevels/).

One core thing I am aiming for is directly linking levels from other websites (e.g. reddit) skipping the copy-open hexcells-start game sequence.

## Screenshots

Early development version, loading and playing levels works, but there is no propper menu flow yet. (28.10.16)

![Screenshot on Imgur](http://i.imgur.com/ARPdQRX.png)

## Compiling

Install [Elm](http://elm-lang.org/), run [elm-reactor](https://github.com/elm-lang/elm-reactor/)
from the project root, then open [index.html](http://localhost:8000/index.html) in elm-reactor.

## Comparison to Hexcells

### Hexcells has

  - Nicer Graphics
  - The original level collection by Matthew Brown
  - Steam integration
  - Achivements

### Elm Sweeper has

  - Arbitrary level size
  - Ability to fade out all numbers, not only flowers and rows. (Which is really the reason this whole project got started.)

### Elm Sweeper might someday have

Just a dump of ideas for this floating around my head.

- A collection of user levels
- Create a link which opens a certain level automatically.
  - .../#decode=FancyUrlEncoding
  - .../#source=https://github.com/rosievers/hexcelllevels/raw/master/l1
  - Maybe even .../#reddit=4y2l34/level_broken_spaceship_mediumhard
  this would link back to the reddit discussion thread from inside Elm Sweeper.
- An integrated level editor. There is already [SixCells](https://github.com/blaxpirit/sixcells) but you have to download it.
- More random map generators.
