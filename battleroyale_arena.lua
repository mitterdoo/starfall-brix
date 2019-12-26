--@name BRIX Battle Royale Arena Object
--@author mitterdoo
--@shared

--[[

	Contains the main Arena object that, on the SERVER:
		Keeps track of all players, each containing a reference to their respective battle royale game object.
		Handles all network traffic, routing events to their respective players' games.
	and on the CLIENT:
		Handles the player's input
		Handles targeting
		Sends snapshot queue to the SERVER, periodically
		Keeps track of other players, containing only:
			Player's unique ID
			Playfield/matrix
			Badge count
			Placement (if dead)

]]

