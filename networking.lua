--[[
	The idea:
	CLIENT and SERVER both have Deltas, and Delta Queues. Information is queued up, and then sent as Deltas, be it CLIENT to SERVER, or vice versa.
	A Delta generally contains the "delta" from the last game state, and the current game state.
	The Delta send rate for both realms, must be the same. For example, 5 Deltas a second.

	Additionally, there are Games. Alice's CLIENT has one Game: their own. They communicate to the SERVER, which is running an identical Game specifically for Alice.
	Because a Game for a CLIENT must be identical to the SERVER's dedicated Game for that player, Games must also keep track of information, including:
		Player's playfield (BRIX game)
		Alive players
		Other players' badges
		Other players' fields
		Other players targeting this player
		
	
	CLIENT Deltas may consist of:
		Every input event
		Targeting tactics (manual or attackers/k.o.'s/badges/random; IDs are not sent)
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
	If their game ends for any reason, the CLIENT must send the frame at which its game ended.
	After a specified amount of time, the CLIENT Delta Queue is sent to the SERVER.

	When the SERVER receives a Delta from a CLIENT, each event is iterated through, in order:
		If the event is an input, or targeting tactics, it is "plugged in" to the CLIENT's linked Game (hosted on the SERVER)
			If the player sends garbage, or changes targets, those events are queued in the SERVER Delta Queue.
			Furthermore, if the receiving player of garbage/target is currently dead, disregard it.
		If the event is a Game Over, K.O. is added to SERVER Delta Queue, and SERVER no longer listens to this CLIENT.
		If the event is a Delta Acknowledge, the player's SERVERside simulated game is adjusted accordingly, plugging in the specified Delta's events, just like the CLIENT


]]