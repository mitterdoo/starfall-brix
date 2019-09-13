# starfall-brix
A multiplayer block puzzle game written for the Starfall chip in Garry's Mod.

The actual code for the stacking puzzle game is in the `BRIX` object, which is all defined in `brix_core_*.txt` files. The files are `.txt` instead of `.lua`, because Starfall can only write/read `.txt` files due to security limitations set by Garry's Mod.
Other planned gamemodes, such as Battle Royale Multiplayer, Singleplayer, or Local Multiplayer, will simply use this core game object, making slight changes for each mode.

To use this code in Starfall, you must place it all inside the folder `garrysmod/garrysmod/data/starfall/brix`. This will *only* expose the base code. __You have to write the implementation yourself.__

## DISCLAIMER
This source code may, and will *only* be used **non**-commercially. It may ***not*** be used to make any profit whatsoever. The code was written for learning purposes for its developer. If there are any other concerns, please contact the developer at mitterdoo@live.com
