--[[
	Clientside Arena implementation. Adds functionality to communicate with the server.
]]

--@name BRIX: Arena (clientside)
--@author mitterdoo
--@client
--@include brix/br/arena.lua

require("brix/br/arena.lua")


local ENEMY = {}
ENEMY.__index = ENEMY

function ENEMY:garbage(gap)
	local retValue = self.matrix:garbage(gap)
	if self.matrix.cellCount >= brix.dangerCapacity then
		self.danger = self.matrix.cellCount - brix.dangerCapacity
	end
	return retValue
end

function ENEMY:place(piece, rot, x, y, mono)

	self.matrix:lock(piece, rot, x, y, mono)
	local lines = self.matrix:check()
	if #lines > 0 then
		self.matrix:clear(lines)
	end
	
	self.danger = math.max(0, self.matrix.cellCount - brix.dangerCapacity)

end

function ENEMY:giveBadgeBits(badgeBits)
	self.badgeBits = self.badgeBits + badgeBits
	self.matrix.invalid = true
end

ARENA.targetModes = {
	MANUAL = 0,
	ATTACKER = 8,
	BADGES = 9,
	KO = 10,
	RANDOM = 11
}

function br.createEnemy(uniqueID)

	local self = {}

	self.uniqueID = uniqueID
	self.badgeBits = 0
	self.matrix = brix.makeMatrix(brix.w, brix.trueHeight)
	self.danger = 0				-- If in danger, will be set to how many bricks they are over the danger threshold
	self.dead = false
	self.placement = 0			-- Final placement when dead
	self.killedByUs = false

	return setmetatable(self, ENEMY)

end

function ARENA:enqueue(...)

	table.insert(self.queue, {...})
	local i = #self.queue -- TODO: when SF fixes table.insert's return value, use that instead


	local time = timer.realtime()
	if time ~= self.currentInstant_Time then
		self.currentInstant = {i}
		self.currentInstant_Time = time
	else
		table.insert(self.currentInstant, i)
	end

end

-- returns const table
function ARENA:getTargets()

	if self.target == 0 then
		return self.attackers
	else
		return {self.target}
	end

end

function ARENA:userInput(input, down)

	if input >= ARENA.targetModes.ATTACKER then
		self:changeTargetMode(input)
		return
	end
	local frame = brix.getFrame(timer.realtime() - self.startTime)
	return BR.userInput(self, frame, input, down)

end

function ARENA:changeTargetMode(mode)

	self.manuallyAdjusting = true

	self.targetMode = mode
	self.hook:run("changeTargetMode", mode)
	self:pickTarget()

	self.manuallyAdjusting = false

end

local sort_badges = function(a, b)
	return a.badgeBits > b.badgeBits
end

local sort_danger = function(a, b)
	return a.danger > b.danger
end

function ARENA:_setTarget(target)

	self:userInput(br.inputEvents.CHANGE_TARGET, target)

end

function ARENA:manualTarget(who)

	self.manuallyAdjusting = true

	self.targetMode = ARENA.targetModes.MANUAL
	self.hook:run("changeTargetMode", ARENA.targetModes.MANUAL)
	self.desiredTarget = who
	self:pickTarget()

	self.manuallyAdjusting = false

end

-- Picks a target based on the current target mode
function ARENA:pickTarget()

	local mode = self.targetMode

	local players = {}
	local playerCount = 0
	for _, enemy in pairs(self.arena) do
		if not enemy.dead then
			table.insert(players, enemy)
			playerCount = playerCount + 1
		end
	end

	-- Shuffle the players, so "identical" enemies, when being sorted, will be picked randomly
	if mode == ARENA.targetModes.BADGES or mode == ARENA.targetModes.KO then
		local shuffledPlayers = {}
		for i = playerCount, 1, -1 do
			local index = math.random(i)
			local enemy = table.remove(players, index)
			table.insert(shuffledPlayers, enemy)
		end

		players = shuffledPlayers
		shuffledPlayers = nil
	end

	if playerCount == 0 then
		self:_setTarget(0)
		return
	elseif playerCount == 1 then
		self:_setTarget(players[1].uniqueID)
		return
	end


	if mode == ARENA.targetModes.ATTACKER then
		if #self.attackers == 0 then
			enemy = players[math.random(#players)]
			self:_setTarget(enemy.uniqueID)
		else
			self:_setTarget(0)
		end
	elseif mode == ARENA.targetModes.BADGES then
		table.sort(players, sort_badges)
		self:_setTarget(players[1].uniqueID)
	elseif mode == ARENA.targetModes.KO then
		table.sort(players, sort_danger)
		self:_setTarget(players[1].uniqueID)
	elseif mode == ARENA.targetModes.RANDOM then
		self:_setTarget( players[math.random(#players)].uniqueID )
	elseif mode == ARENA.targetModes.MANUAL then
		local found = self.arena[self.desiredTarget]
		if found and not found.dead then
			self:_setTarget(found.uniqueID)
		else
			found = players[math.random(#players)]
			self.desiredTarget = found.uniqueID
			self:_setTarget(self.desiredTarget)
		end
	else
		error("Invalid target mode " .. tostring(mode))
	end

end

function br.createArena(seed, uniqueID)

	local self = br.createGame(ARENA, seed, uniqueID)

	self.selfEnemy = br.createEnemy(uniqueID)

	self.queue = {}
	self.arena = {}
	self.targetMode = ARENA.targetModes.RANDOM
	self.desiredTarget = 0

	self.currentInstant = {} -- List of indices in queue that were set this frame
	self.currentInstant_Time = -1

	self.hook("preInput", function(when, input, pressed)

		self:enqueue(self.clientEvents.INPUT, when, input, pressed)

	end)

	self.hook("changeTarget", function(target)

		self:enqueue(self.clientEvents.TARGET, self.frame, target)

	end)

	self.hook("die", function()
	
		self:enqueue(self.clientEvents.DIE, self.diedAt)

	end)

	self.hook("preGarbageSend", function()
	
		local oldCount = #self.currentInstant
		self:pickTarget()
		local newCount = #self.currentInstant

		-- Reorders the event queue, placing any retargets before any other event that occurred in this instant
		for i = newCount, oldCount + 1, -1 do
			local key = self.currentInstant[i]
			if self.queue[key][1] == self.clientEvents.TARGET then
				local event = table.remove(self.queue, key)
				table.insert(self.queue, self.currentInstant[1], event)
				self.currentInstant = {}
				return
			end
		end
	end)

	return self

end

function br.connectToServer(callback)

	net.start(ARENA.netConnectTag)
	net.send()

	local hookName = tostring(math.random(2^31-1))
	local arena

	hook.add("net", hookName, function(name)
		if name == ARENA.netConnectTag then

			local e = ARENA.connectEvents
			local event = net.readUInt(2)
			if event == e.ACCEPT then
				local seed, uniqueID = net.readUInt(32), net.readUInt(6)
				arena = br.createArena(seed, uniqueID)
				arena.tempArena = {} -- Dict of uniqueIDs on the server
				callback(arena)

			elseif event == e.UPDATE then
				if not arena then return end
				local playerCount = net.readUInt(6)
				local players = {}
				local newPlayers = {}
				for i = 1, playerCount do
					local id = net.readUInt(6)
					if id ~= arena.uniqueID then
						players[id] = true

						if arena.tempArena[id] == nil then
							table.insert(newPlayers, id)
						end

					end
				end
				arena.tempArena = players
				arena.remainingPlayers = playerCount
				arena.playerCount = playerCount

				for _, id in pairs(newPlayers) do
					arena.hook:run("playerConnect", id)
				end

			elseif event == e.READY then
				if not arena then return end
				local time = net.readFloat()

				local delta = timer.realtime() - timer.curtime() -- Find how much time it takes to move from curtime to realtime
				time = time + delta

				arena.startTime = time

				arena:onReady()

				hook.remove("net", hookName)
			end
		end
	end)

end

function ARENA:start()

	self:changeTargetMode(ARENA.targetModes.RANDOM)

	BR.start(self)
end

-- Called when the server has notified us that the game is about to start.
function ARENA:onReady()

	-- Finalize enemy list
	for id, _ in pairs(self.tempArena) do
		self.arena[id] = br.createEnemy(id)
	end
	self.tempArena = nil

	self.hookName = "brixNet" .. math.random(2^31-1)
	self.hook("die", function()

		hook.remove("net", self.hookName)

	end)

	hook.add("net", self.hookName, function(name)
		if name == ARENA.netTag and timer.realtime() >= self.startTime then
			self:handleServerSnapshot()
		end
	end)

	hook.add("think", self.hookName, function()
	
		local time = timer.realtime()
		if not self.started then
			if time >= self.startTime then
				self:start()
				self.nextSnapshot = self.startTime + self.refreshRate
			end
		else
			if time >= self.nextSnapshot and #self.queue > 0 then
				while self.nextSnapshot <= time do
					self.nextSnapshot = self.nextSnapshot + self.refreshRate
				end
				self:sendSnapshot()
			end
		end
	end)

	self.hook:run("arenaFinalized")

end

-- Disconnects from the server
function ARENA:disconnect()

	self.dead = true -- don't allow any more inputs
	self.currentPiece.piece = nil
	self.currentPiece.type = -1
	self.hook:run("disconnect")
	if not self.hookName then return end
	hook.remove("think", self.hookName)
	hook.remove("net", self.hookName)

end

function ARENA:sendSnapshot()

	local e = ARENA.clientEvents
	net.start(ARENA.netTag)
	net.writeUInt(#self.queue, 10)

		--print("====CLIENT SNAPSHOT START")
	for _, data in pairs(self.queue) do

		local event = data[1]
		local frame = data[2]
		net.writeUInt(event, 2)
		net.writeUInt(frame, 32)

		--print("↓    frame", frame)
		if event == e.INPUT then
			local input, down = data[3], data[4]
			--print("> INPUT", input, down)
			net.writeUInt(input, 3)
			net.writeBit(down and 1 or 0)

		elseif event == e.TARGET then
			local target = data[3]
			--print("> TARGET", target)
			net.writeUInt(target, 6)

		elseif event == e.ACKNOWLEDGE then
			local snapshotID = data[3]
			--print("> ACKNOWLEDGE", snapshotID)
			net.writeUInt(snapshotID, 32)

		elseif event == e.DIE then
			hook.remove("think", self.hookName)
		else
			error("Unknown event type " .. tostring(event) .. " when encoding")
		end

	end
	net.send()
	self.queue = {}

end

function ARENA:handleServerSnapshot()
	local frame = brix.getFrame(timer.realtime() - self.startTime)

	local snapshot = {}

	local snapshotID = net.readUInt(32)
	local eventCount = net.readUInt(32)
	local e = ARENA.serverEvents

	for _ = 1, eventCount do

		local data
		local event = net.readUInt(3)
		if event == e.DAMAGE then
			local attacker, victimCount, lines = net.readUInt(6), net.readUInt(6), net.readUInt(5)
			local victims = {}
			for i = 1, victimCount do
				victims[i] = net.readUInt(6)
			end
			data = {event, attacker, lines, victims}
		
		elseif event == e.TARGET then
			local attacker, victimCount = net.readUInt(6), net.readUInt(6)
			local victims = {}
			for i = 1, victimCount do
				victims[i] = net.readUInt(6)
			end

			data = {event, attacker, victims}

		elseif event == e.DIE then
			local victim, killer, placement, deathFrame, badgeBits = net.readUInt(6), net.readUInt(6), net.readUInt(6), net.readUInt(32), net.readUInt(6)

			data = {event, victim, killer, placement, deathFrame, badgeBits}
		
		elseif event == e.MATRIX_PLACE then
			local player, piece, rot, x, y, mono = net.readUInt(6), net.readUInt(3), net.readUInt(2), net.readInt(5), net.readInt(6), net.readBit() == 1

			data = {event, player, piece, rot, x, y, mono}
		
		elseif event == e.MATRIX_GARBAGE then
			local player, gapCount = net.readUInt(6), net.readUInt(5)
			local gaps = {}

			for i = 1, gapCount do
				gaps[i] = net.readUInt(4)
			end
			data = {event, player, gaps}

		elseif event == e.MATRIX_SOLID then
			local player, lines = net.readUInt(6), net.readUInt(5)

			data = {event, player, lines}
		
		elseif event == e.CHANGEPHASE then
			data = {event, net.readUInt(2), net.readUInt(32)}
		else
			error("Unknown event type " .. tostring(event) .. " when decoding")
		end

		table.insert(snapshot, data)

	end

	self:enqueue(ARENA.clientEvents.ACKNOWLEDGE, frame, snapshotID)
	br.handleServerSnapshot(self, frame, snapshot)

end
