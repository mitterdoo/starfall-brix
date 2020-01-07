--@name BRIX Battle Royale
--@author mitterdoo
--@shared
--@include brix/engine/engine.lua
--[[
	Game object for client/server

	On the SERVER, this should represent a single player in the game.
	On the CLIENT, this should only represent the player's local game, and not any other players.

	This is also hook-based. This object should not handle any networking traffic.
	Networking traffic should be handled by the parent Arena object, which should utilize these hooks.

]]

require("brix/engine/engine.lua")

br = {} -- library

BR = setmetatable({}, {__index = BRIX}) -- Inherit from engine
BR.__index = BR


-- Clone hook table
BR.hookNames = {
	"changeTarget",		-- When the target has been changed
		-- number uniqueID (or 0, if targeting attackers)

	"attackersChanged",	-- When the list of players attacking us has been changed
		-- table {attackerUniqueID, ...}

	"badgeBits"			-- When we receive badge bits
		-- number count
		-- number uniqueID of giver
}
for _, name in pairs(BRIX.hookNames) do
	table.insert(BR.hookNames, name)
end

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



local gravLookup = {
	{60, 50, 40, 30, 20, 10, 8, 6, 4, 2, 1,		1 / 2,	1 / 3,	1 / 4, 1 / 6,	1 / 10,	1 / 15, 1 / 20},
	{3,  3,  2,  2,  1,  1,  1, 1, 1, 1, 1 / 2,	1 / 4 , 1 / 6,	1 / 8, 1 / 12,	1 / 20, 1 / 20, 1 / 20}
}
local maxLevel = #gravLookup[1] -- 18

local levelFrames = 1200

function BR:calcLevel(nolimit)

	if self.levelTimer < 0 then return 1 end
	local frame = self.frame
	local timeSpent = frame - self.levelTimer
	local max = maxLevel
	if nolimit then
		max = math.huge
	end


	return math.min(max, math.floor((timeSpent + levelFrames/2) / levelFrames) + 1)

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

function BR:giveBadgeBits(count, who)
	self.badgeBits = self.badgeBits + count
	self.hook:run("badgeBits", count, who)
end

function BR:setAttackers(attackers)
	self.attackers = attackers
	self.hook:run("attackersChanged", attackers)
end

function BR:addAttacker(attacker)
	local attackers = self.attackers
	for _, id in pairs(attackers) do
		if id == attacker then return end
	end

	table.insert(attackers, attacker)
	self:setAttackers(attackers)
end

function BR:removeAttacker(attacker)
	local attackers = self.attackers
	for key, id in pairs(attackers) do
		if id == attacker then
			table.remove(attackers, key)
			self:setAttackers(attackers)
			return
		end
	end
end

function BR:startLevelTimer(frame)
	self.levelTimer = frame
end


-- override
function BR:calculateLinesSent(tricks)

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
		elseif combo <= 4 then
			base = base + 2
		elseif combo <= 6 then
			base = base + 3
		elseif combo <= 9 then
			base = base + 4
		else
			base = base + 5
		end
	end

	local attackers = #self.attackers
	if attackers >= 2 then
		local add = 1 + (attackers - 2) * 2
		add = math.min(9, add)
		base = base + add
	end

	local mult = br.getBadgeMultiplier(self.badgeBits)
	local sent = math.floor(base * mult)

	return math.min(20, sent)

end

-- override
--[[
	Add special level-up features, such as
	Monochrome mode, which forces all new pieces to appear as "[ ]"
	"Hurryup" solid garbage is added every 20 seconds when the game takes too long
]]
function BR:levelUpCheck()

	-- Level can change mid-phase
	local level = self:calcLevel(true) -- Limitless levelling
	if level > self.lastLevel then
		self.lastLevel = self.lastLevel + 1

		level = self.lastLevel
		if level >= maxLevel + 4 then
			self.params.monochrome = true
		end

		if level >= maxLevel + 6 then
			self:queueSolidGarbage(1)
		end

		return true
	end

	return false

end

-- Override
function BR:onGameStart()

	self.gameStartFrame = 60 * 6 -- Start 6 seconds after
	self:sleep("readyUp", self.gameStartFrame) -- Frame will be same duration as wait.

end

--[[

	Initializes the BR game object. Takes:
		seed:		Global PRNG seed for the match
		uniqueID:	The uniqueID associated with this player's game.

]]
function br.createGame(GameClass, seed, uniqueID)

	local self -- forward reference
	local BRParams = {
		gravityFunc = function(obj, soft)
			return self:gravityFunc(soft)
		end,
		rotateBuffering = false,
		holdBuffering = false
	}
	self = brix.createGame(GameClass, seed, BRParams)
	self.uniqueID = uniqueID


	self.levelTimer = -1 -- Gets set to the frame when level begins increasing


	self.attackers = {}		-- List of attackers' uniqueIDs
	self.badgeBits = 0		-- Number of badge bits
	self.target = 0			-- 0 = attackers, otherwise individual uniqueID

	self.lastLevel = 1		-- Used for endless level calculation

	

	return self


end

br.inputEvents = {
	CHANGE_TARGET = 7
}

function BR:userInput(frame, input, down)

	if input < 7 then
		return BRIX.userInput(self, frame, input, down)
	end

	if input == br.inputEvents.CHANGE_TARGET then

		-- down is no longer down; it now denotes the uniqueID we are attacking
		local target = down
		if target == self.uniqueID then
			--error("Attempt to attack self!")
		end

		if type(target) ~= "number" then
			error("Attempt to set target to invalid type '" .. type(target) .. "'")
		end
		self.target = target
		self.hook:run("changeTarget", self.target)


	else
		error("Unknown input type: " .. tostring(input))
	end

end


