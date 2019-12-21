--[[
	The idea:
	CLIENT and SERVER both have Deltas, and Delta Queues. Information is queued up, and then sent as Deltas, be it CLIENT to SERVER, or vice versa.
	A Delta generally contains the "delta" from the last game state, and the current game state.
	The Delta send rate for both realms, must be the same. For example, 5 Deltas a second.

	Additionally, there are Games. Alice's CLIENT has one Game: their own. They communicate to the SERVER, which is running an identical Game specifically for Alice.
	Because a Game for a CLIENT must be identical to the SERVER's dedicated Game for that player, Games must also keep track of information, including:
		Player's playfield (BRIX game)
		
	
	CLIENT Deltas may consist of:
		Every input event
		Targeting tactics, can be either:
			Single ID of player to target, or
			No ID, implying targeting Attackers
		Game Over (to a player or self)
		Delta acknowledge

		These must be sent in chronological order, and are all sent containing the time at which they occurred.
	
	SERVER Deltas may consist of:
			<combat>
		Alice sends Bob X garbage lines
		Alice targets {list} players
		Alice is K.O.'d by Bob
		Alice receives X badge bits from Bob

			<playfield>
		Alice places piece X
		Alice receives X garbage lines
		Alice clears X lines
	

		SERVER Deltas are not ordered. They must contain a unique Delta identifier.
	
	As the CLIENT plays, their inputs are recorded to their current Delta Queue.
	If they receive a SERVER Delta, it must be immediately acknowledged, by getting added to the Delta Queue.
		Events received in the Delta are displayed immediately to the CLIENT (k.o.'s, sent garbage, targeting, etc.)
	If their game ends for any reason, the CLIENT must send the frame, at which its game ended, in the next Delta.
	At a set interval, the current CLIENT Delta Queue is sent to the SERVER.

	When the SERVER receives a Delta from a CLIENT, each event is iterated through, in order:
		If the event is an input, it is "plugged in" to the CLIENT's linked Game (hosted on the SERVER)
			If the player sends garbage, those events are queued in the SERVER Delta Queue.
			Furthermore, if the receiving player of garbage is currently dead, disregard it.
		If the event is a change of targets, queue the target switch to the SERVER Delta Queue
			If the individual target is currently dead, pick a random player until the CLIENT gets the next SERVER Delta.
			If there are no attackers for this player, pick a random player as well.
		If the event is a Game Over, K.O. is added to SERVER Delta Queue, and SERVER no longer listens to this CLIENT.
		If the event is a Delta Acknowledge, the player's SERVERside simulated game is adjusted accordingly, plugging in the specified Delta's events, just like the CLIENT
			Only Garbage/Badges/K.O.'s regarding this player are considered on SERVER.


	Which players to target shall only be done on the CLIENT. The CLIENT should handle picking a near-death player, high-badge player, and random player.
		When switching to Attackers, if the player does not have any, pick a random player and stay on them, until attacked or mode change
	

]]