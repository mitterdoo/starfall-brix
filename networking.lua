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




function BR:sv_handleMatrixGarbage(isSolid, lines)

	if isSolid then
		self.arena:enqueue(br.serverEvents.MATRIX_SOLID, self.uniqueId, lines)
	else
		self.arena:enqueue(br.serverEvents.MATRIX_GARBAGE, self.uniqueId, #lines, unpack(lines))
	end

end


function BR:sv_handleMatrixPlace(pieceID, rot, x, y, mono)

	self.hook:run("matrixPlace", self.uniqueId, p, rot, x, y, mono)
	self.arena:enqueue(br.serverEvents.MATRIX_PLACE, self.uniqueId, p, rot, x, y, mono and 1 or 0)

end

--[[
	Called when this player is sending garbage lines.
	This will handle recipients of garbage.
]]
function BR:sv_handleDamage(lines)

	if self.target ~= 0 then

		if self.target == self.uniqueId then
			error("Attempt to attack self!")
		end

		self.arena:enqueue(br.serverEvents.DAMAGE, self.uniqueId, 1, lines, self.target)


	else

		local targets = self.attackers
		lines = math.ceil(lines / #targets)
		self.arena:enqueue(br.serverEvents.DAMAGE, self.uniqueId, #targets, lines, unpack(targets))

	end

end

-- {id, ...}
function BR:enqueue(...)

	table.insert(self.clientQueue, {...})

end




--[[
	If using this outside of Starfall, rewrite this function to send data accordingly.
]]
local Tag = "brixnet"

function br.sendQueue(isClient, queue, snapshotID)

	local events = isClient and br.clientEvents or br.serverEvents
	net.start(Tag)
	
	if not isClient then
		net.writeUInt(snapshotID, 32)
	end

	net.writeUInt(#queue, 32)
	for _, event in pairs(queue) do

		local kind = event[1]
		net.writeUInt(kind, 3)

		if isClient then
			net.writeUInt(event[2], 32) -- Frame

			if kind == events.INPUT then
				net.writeUInt(event[3], 3) -- inputButton
				net.writeBit(event[4]) -- inputDown

				-- 3 + 32 + 3 + 1
				-- 39 bits
			elseif kind == events.TARGET then
				net.writeUInt(event[3], 6) -- uniqueId

				-- 3 + 32 + 6
				-- 41 bits
			elseif kind == events.DIE then
				net.writeUInt(event[4], 6) -- killer ID

				-- 3 + 32 + 6
				-- 41 bits
			elseif kind == events.ACKNOWLEDGE then
				net.writeUInt(event[3], 32) -- snapshot ID

				-- 3 + 32 + 32
				-- 67 bits
			else
				error("Unknown net event type: " .. tostring(kind))
			end
		
		else

			if kind == events.DAMAGE then
				net.writeUInt(event[2], 6) -- Attacker
				local count = event[3]
				net.writeUInt(count, 6) -- Victim Count
				net.writeUInt(event[4], 5) -- Garbage count
				for i = 1, count do
					net.writeUInt(event[4 + i], 6) -- Victim X
				end

				-- 3 + 6 + 6 + 5 + 6x
				-- 20 + 6x bits
			elseif kind == events.TARGET then
				net.writeUInt(event[2], 6) -- Attacker
				local targetCount = event[3]
				net.writeUInt(targetCount, 6) -- targetCount
				for i = 1, targetCount do
					net.writeUInt(event[3 + i], 6) -- targetX
				end

				-- 3 + 6 + 6 + 6x
				-- 15 + 6x bits		(x = targets)
			elseif kind == events.DIE then
				net.writeUInt(event[2], 6) -- victim
				net.writeUInt(event[3], 6) -- killer
				net.writeUInt(event[4], 6) -- placement
				net.writeUInt(event[5], 32) -- deathFrame
				net.writeUInt(event[6], 6) -- badgeBits

				-- 3 + 6 + 6 + 6 + 32 + 6
				-- 59 bits
			elseif kind == events.MATRIX_PLACE then
				net.writeUInt(event[2], 6) -- player
				net.writeUInt(event[3], 3) -- pieceID
				net.writeUInt(event[4], 2) -- rotation
				net.writeUInt(event[5], 4) -- x
				net.writeUInt(event[6], 5) -- y
				net.writeBit(event[7]) -- monochrome

				-- 3 + 6 + 3 + 2 + 4 + 5 + 1
				-- 24 bits
			elseif kind == events.MATRIX_GARBAGE then
				net.writeUInt(event[2], 6) -- player
				local lineCount = event[3]
				net.writeUInt(lineCount, 5) -- lineCount
				for i = 1, lineCount do
					net.writeUInt(event[3 + i], 4) -- gapX
				end

				-- 3 + 6 + 5 + 4x
				-- 14 + 4x
			elseif kind == events.MATRIX_SOLID then
				net.writeUInt(event[2], 6) -- player
				net.writeUInt(event[3], 5)

				-- 3 + 6 + 5
				-- 14
			else
				error("Unknown net event type: " .. tostring(kind))
			end
		end

	end

	net.send()


end


