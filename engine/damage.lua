--@name BRIX: Damage
--@shared

brix.onInit(function(self)

	self.garbage = {} -- d { {lines = n, begin = frame, dump = frame, who = player} }
	self.solidGarbage = 0 -- number of lines of solid garbage waiting to be dumped
	self.lastGarbageSender = 0

end)

brix.tricks = {
	SINGLE = 0x1,			-- 1 line cleared
	DOUBLE = 0x2,			-- 2 lines cleared
	TRIPLE = 0x4,			-- 3 lines cleared
	QUAD = 0x8,				-- 4 lines cleared
	TSPIN =  0x10,			-- Was t-spin
	MINI_TSPIN = 0x20,		-- Was mini t-spin
	ALL_CLEAR = 0x40,		-- Was an all clear
	BACK_TO_BACK = 0x80,	-- Is b2b
	COMBO = 0x100,			-- Has combo (see BRIX.currentCombo)
	SENT = 0x200,			-- Sent any damage
	CLEARED = 0x400			-- Cleared any lines
}

function BRIX:addGarbageLine(gap) -- nil gap implies solid line

	if not self.matrix:garbage(gap) then
		return false
	end

	self.hook:run("garbageDump", gap ~= nil, gap)
	return true

end

function BRIX:garbageDumpPending()

	local g = self.garbage[1]
	if not g then return false end
	if g.dump == -1 then return false end
	if self.frame < g.dump then return false end
	return g

end

function BRIX:generateGarbageGap()

	if not self.garbageGapID then
		self.garbageGapID = 0
	end
	self.garbageGapID = self.garbageGapID + 1
	
	local rndString = tostring(self.garbageGapID)
	for _, v in pairs(self.pieceQueue) do
		rndString = rndString .. tostring(v)
	end
	
	local rnd = tonumber(crc(rndString))
	return math.ceil( rnd / (2^32-1) * brix.w )

end

-- returns whether we're alive afterward
function BRIX:dumpCurrentGarbage()

	local g = self.garbage[1]
	if not g then return true end
	if g.dump == -1 then error("dumping garbage but its timer was not set!") end
	if self.frame < g.dump then return true end
	
	local lines = g.lines
	local gaps = {}
	local curGap = 1
	for i = 0, lines - 1 do
		if i % 8 == 0 then
			curGap = self:generateGarbageGap()
		end
		gaps[i + 1] = curGap
	end

	self.hook:run("garbageDumpFull", false, gaps)
	
	for i = 0, lines - 1 do
		local gap = gaps[i + 1]
		if not self:addGarbageLine(gap) then
			return false
		end

		g.lines = g.lines - 1
		if i < lines - 1 then
			self:sleep("garbageLine", self.params.garbageLineDelay)
		end
		
	end
	
	table.remove(self.garbage, 1)
	self:checkGarbage()
	return true

end

function BRIX:dumpSolidGarbage()

	if self.solidGarbage == 0 then return true end

	self.hook:run("garbageDumpFull", true, self.solidGarbage)

	while self.solidGarbage > 0 do
		self.solidGarbage = self.solidGarbage - 1
		if not self:addGarbageLine() then
			return false
		end
		if self.solidGarbage > 0 then
			self:sleep("garbageLine", self.params.garbageLineDelay)
		end
	end

	return true

end

function BRIX:onGarbageNag(second, garb)
	garb.stage = second and 2 or 1
	self.hook:run("garbageNag", second)

end

-- activates timer for current garbage
function BRIX:checkGarbage()

	local g = self.garbage[1]
	if not g then return false end
	if g.begin ~= -1 then return false end
	local frame = self.frame
	local speed = g.speed
	
	g.begin = frame
	g.dump = frame + speed * 2
	
	self.hook:run("garbageActivate", g.lines, g.who, g.begin)

	self:startTimer("garbageNag1", speed, self.onGarbageNag, false, g)
	self:startTimer("garbageNag2", speed * 2, self.onGarbageNag, true, g)
	
	return true

end

function BRIX:clearGarbage(lines)

	if #self.garbage == 0 then return lines end
	if lines == 0 then return 0 end

	local leftover = lines
	for i = 1, lines do
	
		local this = self.garbage[1]
		this.lines = this.lines - 1
		leftover = leftover - 1
		if this.lines == 0 then
			table.remove(self.garbage, 1)
			self:cancelTimer("garbageNag1")
			self:cancelTimer("garbageNag2")
		end
		
		if #self.garbage == 0 then
			self.hook:run("garbageCancelled", lines - leftover)
			return leftover
		end
	
	end
	
	self.hook:run("garbageCancelled", lines)
	self:checkGarbage()
	
	return 0

end

function BRIX:getGarbageCount()

	local c = 0
	for k,v in pairs(self.garbage) do
		c = c + v.lines
	end
	return c    

end

--- Queues garbage instantaneously
--- PUBLIC
function BRIX:queueGarbage(lines, who)

	if lines == 0 then return false end

	local count = self:getGarbageCount()
	if count >= self.params.maxGarbageIn then return false end
	
	local speed = self.params.garbageNagDelay
	lines = math.min(self.params.maxGarbageIn - count, lines)
	table.insert(self.garbage, #self.garbage + 1, {
		lines = lines,                  -- How many lines
		begin = -1,                     -- When the timer begins
		dump = -1,                      -- When the timer expires
		speed = speed,                  -- Number of frames before the garbage decays (2nd decay is activate)
		who = who,                      -- UniqueID of the sender
		stage = 0,						-- Nag stage. 0 = yellow, 1 = red, 2 = flashing red
	})
	self.hook:run("garbageQueue", lines, who, brix.frame)
	self.lastGarbageSender = who
	self:checkGarbage()
	self:updateDanger()
	
	return true

end

--- Queues garbage after the specified frame delay
--- PUBLIC
function BRIX:queueGarbageDelayed(lines, who, duration)

	self:startTimer("queueGarbage", duration, self.queueGarbage, lines, who)

end

--- Queues solid garbage lines. Will forcefully be dumped at end of phase. Occurs after regular garbage
function BRIX:queueSolidGarbage(lines)
	self.solidGarbage = self.solidGarbage + math.max(0, lines)
end

function BRIX:checkGarbageNag()

	local g = self.garbage[1]
	if not g then return end
	local frame = self.frame
	local gStart = g.begin
	local gEnd = g.dump
	
	local halfNag = gStart + (gStart - gEnd) / 2
	local endNag = gEnd
	
	g.nag = g.nag or 0
	if frame > halfNag and g.nag == 0 or frame > endNag and g.nag == 1 then
		g.nag = g.nag + 1
		self.hook:run("garbageNag")
	end
		

end

function BRIX:calculateTricks(lines, tspin)

	local tricks = 0
	--[[
	local base = 0
	if tspin == 2 then
		base = lines*2
		if base > 6 then error("t spun, but cleared " .. tostring(lines) .. " lines?") end
	else
		if lines == 2 then base = 1
		elseif lines == 3 then base = 2
		elseif lines == 4 then base = 4 end
	end
	]]
	
	if lines == 1 then
		tricks = flagSet(tricks, brix.tricks.SINGLE)
	elseif lines == 2 then
		tricks = flagSet(tricks, brix.tricks.DOUBLE)
	elseif lines == 3 then
		tricks = flagSet(tricks, brix.tricks.TRIPLE)
	elseif lines == 4 then
		tricks = flagSet(tricks, brix.tricks.QUAD)
	end
	if lines > 0 then
		tricks = flagSet(tricks, brix.tricks.CLEARED)
	end

	if tspin == 2 then
		tricks = flagSet(tricks, brix.tricks.TSPIN)
	elseif tspin == 1 then
		tricks = flagSet(tricks, brix.tricks.MINI_TSPIN)
	end
	
	if self.backToBack and self:checkBackToBack(lines, tspin, true) then
		-- base = base + 1
		tricks = flagSet(tricks, brix.tricks.BACK_TO_BACK)
	end
	if self:_isClear() then
		-- base = base + 3
		tricks = flagSet(tricks, brix.tricks.ALL_CLEAR)
	end
	if self.currentCombo and self.currentCombo > 0 then
	
		tricks = flagSet(tricks, brix.tricks.COMBO)
		--[[
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
		]]
	
	end
	
	--[[
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
	]]
	
	if lines > 0 then
		tricks = flagSet(tricks, brix.tricks.SENT)
	end
	return tricks
	

end

--- OVERRIDABLE
function BRIX:calculateLinesSent(tricks)

	local tspin = flagGet(tricks, brix.tricks.TSPIN)
	local b2b = flagGet(tricks, brix.tricks.BACK_TO_BACK)

	local single, double, triple, quad =
		flagGet(tricks, brix.tricks.SINGLE),
		flagGet(tricks, brix.tricks.DOUBLE),
		flagGet(tricks, brix.tricks.TRIPLE),
		flagGet(tricks, brix.tricks.QUAD)

	local base = 0
	if tspin then
		if single then
			base = 2
		elseif double then
			base = 4
		elseif triple then
			base = 6
		else
			error("TSpin but no single, double, or triple?")
		end
	else
		if double then base = 1
		elseif triple then base = 2
		elseif quad then base = 4 end
	end

	if b2b then
		base = base + 1
	end
	return math.min(self.params.maxGarbageOut, base)


end
