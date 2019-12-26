--[[
	The idea:
	CLIENT and SERVER both have Snapshots, and Snapshot Queues. Information is queued up, and then sent as Snapshots, be it CLIENT to SERVER, or vice versa.
	A Snapshot generally contains the "Snapshot" from the last game state, and the current game state.
	The Snapshot send rate for both realms, must be the same. For example, 5 Snapshots a second.

	Additionally, there are Games. Alice's CLIENT has one Game: their own. They communicate to the SERVER, which is running an identical Game specifically for Alice.
	Because a Game for a CLIENT must be identical to the SERVER's dedicated Game for that player, Games must also keep track of information, including:
		Player's playfield (BRIX game)
		
	
	CLIENT Snapshots may consist of:
		Every input event
		Targeting tactics, can be either:
			Single ID of player to target, or
			No ID, implying targeting Attackers
		Game Over (to a player or self)
		Snapshot acknowledge

		These must be sent in chronological order, and are all sent containing the time at which they occurred.
	
	SERVER Snapshots may consist of:
			<combat>
		Alice sends Bob X garbage lines
		Alice targets {list} players
		Alice is K.O.'d by Bob (Alice's place, and frame of death, as well as badge bits)

			<playfield>
		Alice places piece X
		Alice receives X garbage lines
		Alice receives X solid garbage lines
		Alice clears X lines
	

		SERVER Snapshots are not ordered. They must contain a unique Snapshot identifier.
	
	As the CLIENT plays, their inputs are recorded to their current Snapshot Queue.
	If they receive a SERVER Snapshot, it must be immediately acknowledged, by getting added to the Snapshot Queue.
		Events received in the Snapshot are displayed immediately to the CLIENT (k.o.'s, sent garbage, targeting, etc.)
	If their game ends for any reason, the CLIENT must send the frame, at which its game ended, in the next Snapshot.
	At a set interval, the current CLIENT Snapshot Queue is sent to the SERVER.

	When the SERVER receives a Snapshot from a CLIENT, each event is iterated through, in order:
		If the event is an input, it is "plugged in" to the CLIENT's linked Game (hosted on the SERVER)
			If the player sends garbage, those events are queued in the SERVER Snapshot Queue.
			Furthermore, if the receiving player of garbage is currently dead, disregard it.
		If the event is a change of targets, queue the target switch to the SERVER Snapshot Queue
			If the individual target is currently dead, pick a random player until the CLIENT gets the next SERVER Snapshot.
			If there are no attackers for this player, pick a random player as well.
		If the event is a Game Over, K.O. is added to SERVER Snapshot Queue, and SERVER no longer listens to this CLIENT.
		If the event is a Snapshot Acknowledge, the player's SERVERside simulated game is adjusted accordingly, plugging in the specified Snapshot's events, just like the CLIENT
			
			Only Garbage/Badges/K.O.'s/Targets regarding this player are considered on SERVER.
				This means, that the SERVER copy of this game, will see what the CLIENT saw at the time.


	Which players to target shall only be done on the CLIENT. The CLIENT should handle picking a near-death player, high-badge player, and random player.
		When switching to Attackers, if the player does not have any, pick a random player and stay on them, until attacked or mode change
	

]]


