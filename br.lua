--@name BRIX: Battle-Royale Mechanics
--@shared


brix.garbageNagSlow = 150
brix.garbageNagFast = 90
brix.garbageNagFastest = 30
brix.dangerHeight = brix.h - 3
brix.stages = {
	STAGE_BEGIN = 0,    -- Beginning
	STAGE_MIDDLE = 1,   -- Top 50
	STAGE_END = 2       -- Top 10
}
brix.levelLookup = {
	60,
	50,
	40,
	30,
	20,
	10,
	8,
	6,
	4,
	2,
	1
}
brix.softLevelLookup = {
	3,
	3,
	2,
	2,
	1,
	1,
	1,
	1,
	1,
	1,
	1
}

stages = brix.stages

brix.onInit(function(self)

	self.level = 1 -- d
	self.badgeBits = 0 -- Total number of badge bits. This is not the number of badge "groups". Use BRIX:getBadges() to get the number of badges used in attacks
	self.speedupBegin = -1 -- d

end)


function BRIX:getLevelFromFrame(frame)

	if self.speedupBegin == -1 then return 1 end
	return math.max( 1, math.min( 11, math.floor( (frame/brix.frequency + brix.levelUpTime * 1.5) / brix.levelUpTime) ) )

end

function BRIX:getLevelUpFrame(level)

	if self.speedupBegin == -1 or level <= 1 or level > 11 then return math.huge end

	local seconds = level * brix.levelUpTime - brix.levelUpTime/2
	return self.speedupBegin + seconds*brix.frequency

end


function BRIX:updateGameStage()

	if not self.players then
		self.stage = stages.STAGE_BEGIN
		return
	end
	local middle = self.arenaSize / 2
	local finish = self.arenaSize / 10
	local stage
	
	if #self.players > middle then
		stage = stages.STAGE_BEGIN
	elseif #self.players > finish then
		stage = stages.STAGE_MIDDLE
	else
		stage = stages.STAGE_END
	end
	
	if stage ~= self.stage then
		self.stage = stage
		self.hook:run("stage", self.stage)
	end

end

function BRIX:getFramesPerDrop()

	local lookup = brix.levelLookup
	if self.inputs[brix.CLIENT_EVENTS.SOFTDROP] then
		lookup = brix.softLevelLookup
	end
	--return (0.8 - ((level-1)*0.007))^(level-1)*brix.frequency * mul
	
	local curFrame = self.frame
	local curLevel = self:getLevelFromFrame(curFrame)
	local duration = lookup[curLevel]
	local nextLevelUp = self:getLevelUpFrame(curLevel + 1)
	
	if curFrame + duration <= nextLevelUp then return duration end -- If this regular time doesn't go past the level-up point, we're fine
	local nextDuration = lookup[curLevel + 1] -- Otherwise, figure out how long it takes with the next level's time
	if curFrame + nextDuration >= nextLevelUp then return nextDuration end -- If THAT time goes past, then we're good, and use that one instead.
	
	-- this is gonna get cut inbetween.
	return nextLevelUp - curFrame

end

function BRIX:updateDanger()

	local g = self:getGarbageCount()
	local inDanger = self:_highestPoint() + g >= brix.dangerHeight
	if inDanger ~= self.danger then
		self.hook:run("pinch", inDanger)
	end
	self.danger = inDanger
	return self.danger

end

function brix.getBadgeCount(badgeBits)
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

function BRIX:getBadges()

	local badges = brix.getBadgeCount(badgeBits)
	return badges

end

function BRIX:getBadgeMultiplier()

	return self:getBadges() / 4 + 1

end

function BRIX:calcLinesSent(lines, tspin)

	local tricks = 0
	local base = 0
	if tspin == 2 then
		base = lines*2
		if base > 6 then error("t spun, but cleared " .. tostring(lines) .. " lines?") end
	else
		if lines == 2 then base = 1
		elseif lines == 3 then base = 2
		elseif lines == 4 then base = 4 end
	end
	
	if lines == 1 then
		tricks = enumSet(tricks, brix.tricks.SINGLE)
	elseif lines == 2 then
		tricks = enumSet(tricks, brix.tricks.DOUBLE)
	elseif lines == 3 then
		tricks = enumSet(tricks, brix.tricks.TRIPLE)
	elseif lines == 4 then
		tricks = enumSet(tricks, brix.tricks.QUAD)
	end
	if tspin == 2 then
		tricks = enumSet(tricks, brix.tricks.TSPIN)
	elseif tspin == 1 then
		tricks = enumSet(tricks, brix.tricks.MINI_TSPIN)
	end
	
	-- TODO:
	-- ATTACKER BONUS
	-- BADGE BONUS
	
	if self.backToBack and self:checkBackToBack(lines, tspin, true) then
		base = base + 1
		tricks = enumSet(tricks, brix.tricks.BACK_TO_BACK)
	end
	if self:_isClear() then
		base = base + 3
		tricks = enumSet(tricks, brix.tricks.ALL_CLEAR)
	end
	if self.currentCombo and self.currentCombo > 0 then
	
		tricks = enumSet(tricks, brix.tricks.COMBO)
		local com = self.currentCombo
		if com <= 2 then
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
	
	if self.attackers then
		local c = #self.attackers
		if c == 2 then
			base = base + 1
		elseif c == 3 then
			base = base + 3
		elseif c == 4 then
			base = base + 5
		elseif c == 5 then
			base = base + 7
		elseif c >= 6 then
			base = base + 9
		end
	end
	
	local mult = self:getBadgeMultiplier()
	base = math.floor(base * mult)
	
	if base > 0 then
		tricks = enumSet(tricks, brix.tricks.SENT)
	end
	return math.min(20, base), tricks
	

end
