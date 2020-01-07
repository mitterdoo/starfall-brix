--@name BRIX: Arena
--@author mitterdoo
--@shared
--@include brix/br/br.lua

require("brix/br/br.lua")

if CLIENT then
	ARENA = setmetatable({}, {__index = BR}) -- inherit from BR object
else
	ARENA = {}
end

ARENA.netTag = "brix"
ARENA.netConnectTag = "brixConnect"
ARENA.garbageSendDelay = 30	-- Number of frames to wait between garbage sending and receiving.
ARENA.maxPlayers = 33
ARENA.refreshRate = 0.2 -- Snapshots will get sent at this rate (in seconds)
ARENA.maxUnacknowledgedSnapshots = 40

ARENA.connectEvents = {
	ACCEPT = 0,		-- {UInt32 seed, UInt6 uniqueID}
					-- Sent to a single player attempting to connect, letting them know they were accepted.

	UPDATE = 1,		-- {UInt6 playerCount, UInt6 player1ID, UInt6 player2ID, ...}
					-- Broadcasted to refresh the number of players

	READY = 2,		-- {float startTime}
					-- Broadcasted to signify the exact start time.

	
}

ARENA.serverEvents = {
	DAMAGE = 0,		-- {UInt6 attacker, UInt6 victimCount, UInt5 garbageLines, UInt6 victim1, UInt6 victim2, ...}
					-- Signals damage being sent to another player.

	TARGET = 1,		-- {UInt6 attacker, UInt6 targetCount, UInt6 target1, UInt6 target2, ...}
					-- Signals a player changing their targets.

	DIE = 2,		-- {UInt6 victim, UInt6 killer, UInt6 placement, UInt32 deathFrame, UInt6 badgeBits}
					-- Signals a player's death, containing their placement in the match, the frame at which they died, and the badge bits transferred to the killer.

	MATRIX_PLACE = 3,	-- {UInt6 player, UInt3 piece, UInt2 rotation, UInt4 x, Uint5 y, Bit monochrome}
						-- Signals placing a piece on the field.


	MATRIX_GARBAGE = 4, -- {UInt6 player, UInt5 lineCount, UInt4 gap1, UInt4 gap2, ...}
	MATRIX_SOLID = 5,	-- {UInt6 player, UInt5 lineCount}

	LEVELUP = 6,		-- {UInt32 frame}
						-- Frame at which the level up timer should be started at
	START = 7

}

ARENA.clientEvents = {
	INPUT = 0,		-- {UInt32 frame, UInt3 inputButton, Bit inputDown}
					-- Signals a standard game input.

	TARGET = 1,		-- {UInt32 frame, UInt6 uniqueID}
					-- Signals a change of target. 0 for attackers

	DIE = 2,		-- {UInt32 frame}
					-- Signals death

	ACKNOWLEDGE = 3	-- {UInt32 frame, UInt32 snapshotID}
}


ARENA.hookNames = {
	"playerGarbage",		-- Player sends garbage to other players
		-- number attacker uniqueID
		-- number garbageLines (sent to each, already has been divided)
		-- table {number victimID, ...}

	"playerTarget",			-- Player targets players
		-- number attacker uniqueID
		-- table {number victimID, ...}

	"playerDie",			-- Player dies
		-- number victimID
		-- number killerID
		-- number placement
		-- number deathFrame
		-- number badgeBits

	"playerMatrixPlace",	-- Player places piece down
		-- number player
		-- number pieceID
		-- number rotation
		-- number x
		-- number y
		-- bool mono
	
	"playerMatrixGarbage",	-- Player gets garbage
		-- number player
		-- table {number gap, ...}
	
	"playerMatrixSolid",	-- Player gets solid garbage
		-- number player
		-- number lineCount
}

for _, name in pairs(BR.hookNames) do
	table.insert(ARENA.hookNames, name)
end


-- Handle a server snapshot using the provided game object. `game` must be of BR type
function br.handleServerSnapshot(game, frame, snapshot)

	game:update(frame)
	local e = ARENA.serverEvents
	for _, data in pairs(snapshot) do

		local event = data[1]
		if event == e.DAMAGE then
			local attacker, lines, victims = data[2], data[3], data[4]

			for _, id in pairs(victims) do
				if id == game.uniqueID then
					game:queueGarbageDelayed(lines, attacker, ARENA.garbageSendDelay)
					break
				end
			end
			game.hook:run("playerGarbage", attacker, lines, victims)

		elseif event == e.TARGET then

			local attacker, victims = data[2], data[3]

			for _, id in pairs(victims) do
				if id == game.uniqueID then
					game:addAttacker(attacker)
					goto found
				end
			end

			-- we're not being attacked
			game:removeAttacker(attacker)

		::found::
			
			game.hook:run("playerTarget", attacker, victims)
		
		elseif event == e.LEVELUP then

			game:startLevelTimer(data[2])

		elseif CLIENT then

			if event == e.DIE then -- useless on server

				local victim, killer, placement, deathFrame, badgeBits = data[2], data[3], data[4], data[5], data[6]

				if victim == game.uniqueID then
					error("Kicked by server.")
				end
				if killer == game.uniqueID then
					game:giveBadgeBits(badgeBits, victim)
				else
					game.arena[killer]:giveBadgeBits(badgeBits)
				end

				game.hook:run("playerDie", victim, killer, placement, deathFrame, badgeBits)

			elseif event == e.MATRIX_PLACE and data[2] ~= game.uniqueID then

				local player, pieceID, rot, x, y, mono = data[2], data[3], data[4], data[5], data[6]

				local piece = brix.pieces[pieceID]
				game.arena[player]:place(piece, rot, x, y, mono)

				game.hook:run("playerMatrixPlace", player, pieceID, rot, x, y, mono)

			elseif event == e.MATRIX_GARBAGE then

				local player, gaps = data[2], data[3]

				game.arena[player]:garbage(gaps)

				game.hook:run("playerMatrixGarbage", player, gaps)
			
			elseif event == e.MATRIX_SOLID then

				local player, lines = data[2], data[3]

				local obj = game.arena[player]
				for i = 1, lines do
					obj:garbage()
				end

				game.hook:run("playerMatrixSolid", player, lines)

			end

		end

	end

end
