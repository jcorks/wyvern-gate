Wyvern Gate
===========

A procedural, console-based RPG (Role-Playing Game).

A game by Johnathan Corkery

The source here is for playing the console version of the game. [The web version of the game is available to play.](https://jcorks.github.io/wyvern-gate/) Web version styling and help by [Adrian Hernik](https://skie.me), thanks a ton!


(Feel free to add suggestions to the Issues page!)

About the game
--------------

Wyvern gate is a game where you seek to have your wish granted by the powerful Wyverns. Others too will seek their own wish, so you will have competition. Survival is essential in this game, and there are some battles best avoided.

Default controls:
- confirm: z (or Enter on web)
- deny: x (or Backspace on web)
- left: left arrow
- right: right arrow
- up: up arrow
- down: down arrow


At first, the game provides one scenario where this can happen, but after progressing to your wish, more scenarios will be available.

Playing the game 
----------------

The game can be built for console on Linux and Windows. Windows is encouraged to use MSYS2 and git to build and play, but it should not be necessary. the export-cli directory contains whats needed to build the main binary to run the game. First, run `get_matte.sh` to pull the Matte language runtime, then `make` to build `wyvern-gate-bin`, the binary to run the game. By default, the binary will use the current directory as the expected source location.

Alternatively, the [web version of the game is available to play](https://jcorks.github.io/wyvern-gate/) and is maintained regularly.

About the game's construction
-----------------------------

The game is played using direction keys / axes, confirm, and deny. Letters are not specifically used as controls, extending support to versions with gamepad and touch support. This game is entirely text-based; no graphical characters are used outside of Unicode box characters for window graphics. Similarly, the game is intended to fit onto a standard virtual terminal (80x24).

Wyvern Gate is created mostly in the [Matte language](http://github.com/jcorks/matte) , which was the impetus for the project at its start. As such, the code for the game is shipped with it, and this source is used for the runtime of the game. The executable is mostly a wrapper of the Matte interpreter with a few native features added for performance and compatibility.

Because of the scripting nature and open source aspects of the game, Wyvern Gate is intended to be easily modable. While this repo currently will not be accepting merge requests, mods will be encouraged as a way to publicly extend the game.


About this repo
---------------

The game will be maintained here and updated regularly unless stated otherwise. While others are welcome to fork this project, merges will not be accepted at this time.

Modding
-------

Samples will be provided soon on modding. Stay tuned!
