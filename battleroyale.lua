--@name BRIX Battle Royale
--@author mitterdoo
--@shared
--[[
	Game object for client/server

	On the SERVER, this should represent a single player in the game.
	On the CLIENT, this should only represent the player's local game, and not any other players.

	This is also hook-based. This object should not handle any networking traffic.
	Networking traffic should be handled by the parent Arena object, which should utilize these hooks.

]]

br = {} -- library

br.hooks = {
	"garbageSend",		-- When garbage is sent to a player
		-- senderID
		-- victimID
		-- lineCount
	"changeTarget",		-- When a player switches their target
		-- attackerID
		-- {victimID, ...}
	"die",				-- When a player dies
		-- victimID
		-- killerID
		-- placement
		-- deathFrame
		-- badgeBits
	"matrixPlace",		-- When a player places a piece in their matrix
		-- playerID
		-- pieceID
		-- rotation
		-- x
		-- y
		-- isMonochromeb
	"matrixGarbage",	-- When a player's fbield receives garbage
		-- playerID
		-- {gaps}
	"matrixSolid",		-- When a player's field receives solid garbage
		-- playerID
		-- count
}

function br.getBadgeCount(badgeBits)
	local badges = 0
	local running = 0
	local denomination = math.huge
	for i = 1, badgeBits do
		denomination = 2^(badges+1)
		running = running + 1
		if running >= denomination then
			running = 0
			badges = badges + 1
		end
		if badges == 4 then break end
	end
	return badges, running / denomination

end

function br.getBadges(badgeBits)
	local badges = br.getBadgeCount(badgeBits)
	return badges
end

function br.getBadgeMultiplier(badgeBits)
	return br.getBadges(badgeBits) / 4 + 1
end


br.serverEvents = {
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
	--MATRIX_CLEAR = 6,	-- {UInt6 player, UInt5 lineCount, UInt5 line1, UInt5 line2, ..., UInt5 line4}
	-- Redundant, since the client can just check for line clears automatically

}
br.clientEvents = {
	INPUT = 0,		-- {UInt32 frame, UInt3 inputButton, Bit inputDown}
					-- Signals a standard game input.

	TARGET = 1,		-- {UInt32 frame, UInt6 uniqueId}
					-- Signals a change of target. 0 for attackers

	DIE = 2,		-- {UInt32 frame, UInt6 killerUniqueId}
					-- Signals death. uniqueId = 0 for self

	ACKNOWLEDGE = 3	-- {UInt32 frame, UInt32 snapshotID}
}


local BR = {}
BR.__index = BR

local gravLookup = {
	{60, 50, 40, 30, 20, 10, 8, 6, 4, 2, 1,		1 / 2,	1 / 3,	1 / 4, 1 / 6,	1 / 10,	1 / 15, 1 / 20},
	{3,  3,  2,  2,  1,  1,  1, 1, 1, 1, 1 / 2,	1 / 4 , 1 / 6,	1 / 8, 1 / 12,	1 / 20, 1 / 20, 1 / 20}
}
local maxLevel = #gravLookup[1] -- 18

function BR:calcLevel(nolimit)

	if self.levelTimer == 0 then return 1 end
	local frame = self.game.frame
	local timeSpent = frame - self.levelTimer
	local max = maxLevel
	if nolimit then
		max = math.huge
	end


	return math.min(max, math.floor((timeSpent + 600) / 1200) + 1)

end

function BR:gravityFunc(soft)

	-- The proper thing to do, would be to rewrite the drop system so "frame counting" works, but that's too much work for such a small detail.
	local level = self:calcLevel()
	if soft then
		return gravLookup[2][level]
	else
		return gravLookup[1][level]
	end

end

--[[

	Initializes the BR game object. Takes:
		seed:		Global PRNG seed for the match
		uniqueId:	The uniqueId associated with this player's game.
		arena:		If serverside, a reference to the Arena object for the match.

]]
function BR:init(seed, uniqueId, arena)

	local br_obj = self
	local client = not arena
	self.uniqueId = uniqueId

	if client then
		self.client = true

		self.clientQueue = {}

	else
		self.server = true

		self.arena = arena
	end

	local BRParams = {
		gravityFunc = function(obj, soft)
			return self:gravityFunc(soft)
		end
	}

	self.levelTimer = 0 -- Gets set to the frame when level begins increasing
	self.game = brix.createGame(seed, BRParams)


	self.attackers = {}		-- List of attackers' uniqueIds
	self.badgeBits = 0		-- Number of badge bits
	self.target = 0			-- 0 = attackers, otherwise individual uniqueId

	if client then
		self.arena = {} -- [uniqueId] = enemyObject
	end


	function self.game:calculateLinesSent(tricks)

		local base = 0 -- Base damage

		local lines
		if flagGet(tricks, brix.tricks.SINGLE) then
			lines = 1
		elseif flagGet(tricks, brix.tricks.DOUBLE) then
			lines = 2
		elseif flagGet(tricks, brix.tricks.TRIPLE) then
			lines = 3
		elseif flagGet(tricks, brix.tricks.QUAD) then
			lines = 4
		end

		if flagGet(tricks, brix.tricks.TSPIN) then
			base = lines * 2
		else
			if lines == 2 then base = 1
			elseif lines == 3 then base = 2
			elseif lines == 4 then base = 4 end
		end

		if flagGet(tricks, brix.tricks.BACK_TO_BACK) then
			base = base + 1
		end
		if flagGet(tricks, brix.tricks.ALL_CLEAR) then
			base = base + 3
		end

		if flagGet(tricks, brix.tricks.COMBO) then
			local combo = self.currentCombo
			if combo <= 2 then
				base = base + 1
			elseif com <= 4 then
				base = base + 2
			elseif com <= 6 then
				base = base + 3
			elseif com <= 9 then
				base = base + 4
			else
				base = base + 5
			end
		end

		local attackers = #br_obj.attackers
		if attackers >= 2 then
			local add = 1 + (attackers - 2) * 2
			add = math.min(9, add)
			base = base + add
		end

		local mult = br.getBadgeMultiplier(br_obj.badgeBits)
		local sent = math.floor(base * mult)

		return math.min(20, sent)

	end

	local lastLevel = 1

	function self.game:levelUpCheck()

		-- Level can change mid-phase
		local level = br_obj:calcLevel(true) -- Limitless levelling
		if level > lastLevel then
			lastLevel = lastLevel + 1
			return true
		end

		return false

	end

	

	--[[ Add special level-up features, such as
		Monochrome mode, which forces all new pieces to appear as "[ ]"
		"Hurryup" solid garbage is added every 20 seconds when the game takes too long

	]]
	self.game.hook("levelUp", function(level)
	
		if level >= maxLevel + 4 then
			self.game.params.monochrome = true
		end

		if level >= maxLevel + 6 then
			self.game:queueSolidGarbage(1)
		end

	end)

	self.game.hook("die", function(killer)
	
		if client then

			self:enqueue(br.clientEvents.DIE, self.game.diedAt, self.game.lastGarbageSender)

		else

			-- Call a function to verify death and do other things
			self:sv_handleDie(self.game.diedAt, self.game.lastGarbageSender)

		end

	end)


	if not client then
		--[[
			Handles garbage sending.
		]]
		self.game.hook("lock", function(tricks, combo, lines, linesCleared)

			local p = self.game.lastPieceLocked

			self:sv_handleMatrixPlace(p.piece.type, p.rot, p.x, p.y, self.game.params.monochrome)

			if lines > 0 then
				self:sv_handleDamage(lines)
			end

		end)

		self.game.hook("garbageDumpFull", function(isSolid, lines)
		
			self:sv_handleMatrixGarbage(isSolid, lines)

		end)
	end

end

function BR:start()
	self.game:start()
end

function BR:sv_handleDie(serverFrame, killer)

	-- Arena will set our received death frame automatically.
	local clientFrame = self.deathFrame
	if not clientFrame then
		error("Possible Desync! Server game died, but client didn't!")
	end

	if serverFrame ~= clientFrame then
		print("Note: client's death frame did not match server frame")
	end

	local killerObject = self.arena.players[killer]
	if killerObject then
		killerObject.badgeBits = killerObject.badgeBits + self.badgeBits
	end


	local placement = self.arena:eliminate(self.uniqueId)
	self.arena:enqueue(br.serverEvents.DIE,
		self.uniqueId,
		killer,
		placement,
		serverFrame,
		self.badgeBits)
	


end

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



function BR:userInput(frame, input, down)

	if input < 7 then
		self.game:userInput(frame, input, down)
		return
	end

	local e = br.inputEvent
	-- TODO: handle tactics and manual attacks

end

function BR:update(frame)
	return self.game:update(frame)
end


function NewBRGame(seed, uniqueId, arena)

	local obj = setmetatable({}, BR)
	obj:init(seed, uniqueId, arena)
	brix.hookObject(obj, br.hooks)
	return obj

end

