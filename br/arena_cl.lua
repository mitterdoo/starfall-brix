--@name BRIX: Arena (clientside)
--@author mitterdoo
--@client
--@include brix/br/arena.lua

require("brix/br/arena.lua")


local ENEMY = {}
ENEMY.__index = ENEMY

function ENEMY:garbage(gap)
	return self.matrix:garbage(gap)
end

function ENEMY:place(piece, rot, x, y, mono)

	self.matrix:lock(piece, rot, x, y, mono)
	local lines = self.matrix:check()
	if #lines > 0 then
		self.matrix:clear(lines)
	end
	
	print("CLIENT ENEMY PLACE", self.uniqueID, piece.type, rot, 'x', x, 'y', y, mono)
	if self.matrix.cellCount >= brix.dangerCapacity then
		self.danger = self.matrix.cellCount - brix.dangerCapacity
	else
		self.danger = false
	end

end

function ENEMY:giveBadgeBits(badgeBits)
	self.badgeBits = self.badgeBits + badgeBits
end

function br.createEnemy(uniqueID)

	local self = {}

	self.uniqueID = uniqueID
	self.badgeBits = 0
	self.matrix = brix.makeMatrix(brix.w, brix.trueHeight)
	self.danger = false

	return setmetatable(self, ENEMY)

end

function ARENA:enqueue(...)

	table.insert(self.queue, {...})

end

function ARENA:userInput(input, down)

	local frame = brix.getFrame(timer.realtime() - self.startTime)
	return BR.userInput(self, frame, input, down)

end

function br.createArena(seed, uniqueID)

	local self = br.createGame(ARENA, seed, uniqueID)

	self.queue = {}
	self.arena = {}

	self.hook("preInput", function(when, input, pressed)

		self:enqueue(self.clientEvents.INPUT, when, input, pressed)

	end)

	self.hook("changeTarget", function(target)

		self:enqueue(self.clientEvents.TARGET, self.frame, target)

	end)

	self.hook("die", function()
	
		self:enqueue(self.clientEvents.DIE, self.diedAt)

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
				for i = 1, playerCount do
					local id = net.readUInt(6)
					if id ~= arena.uniqueID then
						players[id] = true
					end
				end
				arena.tempArena = players
				arena.remainingPlayers = playerCount
				arena.playerCount = playerCount

				-- TODO: hook when new players joined

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

end

function ARENA:sendSnapshot()

	local e = ARENA.clientEvents
	net.start(ARENA.netTag)
	net.writeUInt(#self.queue, 10)
	for _, data in pairs(self.queue) do

		local event = data[1]
		local frame = data[2]
		net.writeUInt(event, 2)
		net.writeUInt(frame, 32)

		if event == e.INPUT then
			local input, down = data[3], data[4]
			net.writeUInt(input, 3)
			net.writeBit(down and 1 or 0)

		elseif event == e.TARGET then
			local target = data[3]
			net.writeUInt(target, 6)

		elseif event == e.ACKNOWLEDGE then
			local snapshotID = data[3]
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
