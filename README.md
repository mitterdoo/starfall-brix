# DISCONTINUED (in gmod)
Due to the limits of the game engine, Brix development and support has been ***discontinued*** in Garry's Mod. While many changes were made to Starfall to make some features work such as post-processing effects, XInput support, and error handling, a fast-paced game such as this is hindered by the unavoidable garbage collector in Garry's Mod, which causes unpredictable and frustrating game freezes.

As of 22 March, 2022, Brix is planned to be completed as a standalone game to be released on Itch.io. I give many thanks to those who playtested in Garry's Mod!

The core brick stacking engine in the `engine/` folder can be used by others for their own similar games in Lua, under the [LICENSE.md](https://github.com/mitterdoo/starfall-brix/blob/master/LICENSE.md) in this repository. Its code was designed to run in pure Lua, and has no ugly GLua syntax or Garry's Mod/Starfall-specific features. I made sure to leave lots of documentation in `engine/engine.lua` to explain the structure of the game.

# starfall-brix
A multiplayer block puzzle game written for the Starfall chip in Garry's Mod.

## Setup
If you would like to play this on your Garry's Mod server, you must have [Starfall](https://github.com/thegrb93/StarfallEx) installed, then download this repository into your `garrysmod/garrysmod/data/starfall/brix` folder (make the folder if it doesn't exist), and open `brix/main.txt` as the source file in Starfall.

The Starfall chip requires 33 linked vehicles (preferably seats), and a Starfall HUD linked to each vehicle. Lastly, to keep players' inputs from making them exit their seats, a Wire Keyboard should be linked to each vehicle. It doesn't need to be *wired* to anything, as the inputs are handled by the Starfall chip, but it does need to be *linked* to the vehicles. Lastly, a Starfall screen may be linked so that outside players may spectate ongoing matches.

## Demos
[Demo Playlist](https://www.youtube.com/playlist?list=PLiY0S5J6PIvjcVaIJ5wwwPZSGlQYfCEoU) on YouTube.


## DISCLAIMER
The code was written for learning purposes for its developer, and was not made with the purpose of commercial profit. If there are any other concerns, please review the [LICENSE.md](https://github.com/mitterdoo/starfall-brix/blob/master/LICENSE.md), or contact the developer at mitterdoo@live.com
