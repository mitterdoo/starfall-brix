--[[

	The main Arena object. Behavior differs between SERVER and CLIENT.
	This object is responsible for maintaining an online connection.

]]

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
ARENA.__index = ARENA

ARENA.netTag = "brix"
ARENA.netConnectTag = "brixConnect"
ARENA.garbageSendDelay = 30	-- Number of frames to wait between garbage sending and receiving.
ARENA.maxPlayers = 33
ARENA.refreshRate = 0.2 -- Snapshots will get sent at this rate (in seconds)
ARENA.readyUpTime = 2 -- Seconds to wait between server being ready, and game starting.
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

	MATRIX_PLACE = 3,	-- {UInt6 player, UInt3 piece, UInt2 rotation, Int5 x, Int6 y, Bit monochrome}
						-- Signals placing a piece on the field.


	MATRIX_GARBAGE = 4, -- {UInt6 player, UInt5 lineCount, UInt4 gap1, UInt4 gap2, ...}
	MATRIX_SOLID = 5,	-- {UInt6 player, UInt5 lineCount}

	CHANGEPHASE = 6		-- {UInt2 Phase, UInt32 frame}
						-- When the server changes phase. 0 for normal, 1 for speedup begin, 2 for final showdown

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

	"changeTargetMode", 	-- Our game has changed targeting mode
		-- number mode (see ARENA.targetModes)

	"arenaFinalized",

	"finish"				-- Called when the match is over
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
			if CLIENT then
				game.hook:run("playerGarbage", attacker, lines, victims)
			end

		elseif event == e.TARGET then
			local attacker, victims = data[2], data[3]

			local changed = false

			for _, id in pairs(victims) do
				if id == game.uniqueID then
					changed = game:addAttacker(attacker)
					goto found
				end
			end

			-- we're not being attacked
			changed = game:removeAttacker(attacker)

		::found::
			if CLIENT then
				if changed and game.targetMode == ARENA.targetModes.ATTACKER then
					game:pickTarget()
				end
				game.hook:run("playerTarget", attacker, victims)
			end
		
		elseif event == e.CHANGEPHASE then
			local phase, statedFrame = data[2], data[3]
			game:changePhase(phase, statedFrame)

		elseif SERVER then

			if event == e.DIE then
				local victim = data[2]
				local enemy = game.arena.arena[victim]
				if enemy then
					game:removeAttacker(victim)
				end
			end

		else

			if event == e.DIE then -- useless on server
				local victim, killer, placement, deathFrame, badgeBits = data[2], data[3], data[4], data[5], data[6]

				if victim == game.uniqueID then
					error("Kicked by server.")
				end

				local enemy = game.arena[victim]
				for _, id in pairs(game:getTargets()) do
					if id == victim then
						game:pickTarget()
					end
				end
				if enemy then
					enemy.dead = true
					enemy.placement = placement
					game:removeAttacker(victim)
					game.remainingPlayers = game.remainingPlayers - 1
					if killer == game.uniqueID then
						enemy.killedByUs = true
					end
				end

				if killer == game.uniqueID then
					game:giveBadgeBits(badgeBits, victim)
				else
					if game.arena[killer] then 
						game.arena[killer]:giveBadgeBits(badgeBits)
					end
				end

				game.hook:run("playerDie", victim, killer, placement, deathFrame, badgeBits)

				if game.remainingPlayers <= 1 then
					game:finish()
					if not game.dead then
						game.hook:run("win")
					end
				end

			elseif event == e.MATRIX_PLACE then
				local player, pieceID, rot, x, y, mono = data[2], data[3], data[4], data[5], data[6]

				local enemy = game.arena[player]
				if player == game.uniqueID then
					enemy = game.selfEnemy
				end
				local piece = brix.pieces[pieceID]
					enemy:place(piece, rot, x, y, mono)

				game.hook:run("playerMatrixPlace", player, pieceID, rot, x, y, mono)

			elseif event == e.MATRIX_GARBAGE then
				local player, gaps = data[2], data[3]

				local enemy = game.arena[player]
				if player == game.uniqueID then
					enemy = game.selfEnemy
				end
				enemy:garbage(gaps)

				game.hook:run("playerMatrixGarbage", player, gaps)
			
			elseif event == e.MATRIX_SOLID then
				local player, lines = data[2], data[3]

				local obj = game.arena[player]
				if player == game.uniqueID then
					obj = game.selfEnemy
				end
				for i = 1, lines do
					obj:garbage()
				end

				game.hook:run("playerMatrixSolid", player, lines)

			end

		end

	end

end
