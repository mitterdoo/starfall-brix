--[[
	Serverside Arena implementation. Adds functionality to communicate with all clients.
]]

--@name BRIX: Arena (server)
--@author mitterdoo
--@server
--@include brix/br/arena.lua

require("brix/br/arena.lua")

local openServers = {}

-- Opens the server for connections
function ARENA:open()

	openServers[self] = true

end

function ARENA:preConnect(ply)
	return true
end

function ARENA:onConnect(ply)

end

function ARENA:connectPlayer(ply)

	if not self:preConnect(ply) then return end

	if self.playerCount == self.maxPlayers then
		print("Max players reached!")
		return
	end

	for k, v in pairs(self.arena) do
		if v.player == ply then
			print("Player", ply, "attempted to connect again!")
			return
		end
	end

	local index = math.random(1, #self.uniqueIDs)
	local id = table.remove(self.uniqueIDs, index)


	local game = br.createGame(BR, self.seed, id)
	game.player = ply
	game.pendingSnapshots = {}
	game.pendingCount = 0
	game.targetChanges = {}
	game.arena = self

	self.arena[id] = game
	table.insert(self.connectedPlayers, ply)
	self.players[ply] = id

	net.start(ARENA.netConnectTag)
	net.writeUInt(ARENA.connectEvents.ACCEPT, 2)
	net.writeUInt(self.seed, 32)
	net.writeUInt(id, 6)
	net.send(ply)

	self.playerCount = self.playerCount + 1
	self.remainingPlayers = self.remainingPlayers + 1

	net.start(ARENA.netConnectTag)
	net.writeUInt(ARENA.connectEvents.UPDATE, 2)
	net.writeUInt(self.playerCount, 6)

	for plyID, _ in pairs(self.arena) do
		net.writeUInt(plyID, 6)
	end

	net.send()

	self:onConnect(ply)

end

function ARENA:connectBot()

	if self.playerCount == self.maxPlayers then
		print("Max players reached!")
		return
	end

	local index = math.random(1, #self.uniqueIDs)
	local id = table.remove(self.uniqueIDs, index)

	local game = br.createGame(BR, self.seed, id)
	game.bot = true
	game.arena = self
	
	self.arena[id] = game
	
	self.playerCount = self.playerCount + 1
	self.remainingPlayers = self.remainingPlayers + 1

	net.start(ARENA.netConnectTag)
	net.writeUInt(ARENA.connectEvents.UPDATE, 2)
	net.writeUInt(self.playerCount, 6)

	for plyID, _ in pairs(self.arena) do
		net.writeUInt(plyID, 6)
	end

	net.send()

end

-- Call this when the server has been populated and should start
function ARENA:readyUp()

	openServers[self] = nil -- Close the server
	self.startTime = timer.curtime() + ARENA.readyUpTime

	--[[
		Tell the clients that the game is about to start.
		This should be the "Get ready!" phase.
		self.startTime denotes when the game object should actually begin its coroutine.
	]]
	net.start(ARENA.netConnectTag)
	net.writeUInt(ARENA.connectEvents.READY, 2)
	net.writeFloat(self.startTime)
	net.send(self.connectedPlayers)

	self.phaseStartHalfway = math.max(2, math.ceil(self.playerCount / 2))		-- Playercount at which the game speeds up
	self.phaseStartShowdown = math.max(2, math.ceil(self.playerCount * 0.24))	-- Playercount at which garbage delay is quick

	self.hookName = "brixNet" .. self.seed
	hook.add("net", self.hookName, function(name, len, ply)

		local id = self.players[ply]
		if name == ARENA.netTag and id and timer.curtime() >= self.startTime then
			self:handleClientSnapshot(self.arena[id], ply)
		end

	end)

	timer.simple(ARENA.readyUpTime, function()
		self:start()
	end)

end

function ARENA:pickRandomTarget(attacker)

	local ids = {}
	for id, game in pairs(self.arena) do
		if not game.dead and id ~= attacker then
			table.insert(ids, id)
		end
	end

	return ids[math.random(1, #ids)]

end

function ARENA:targetSanityCheck(target, game)
	if target == 0 and #game.attackers == 0 or
		target ~= 0 and not self.arena[target] or
		target == game.uniqueID
	then
		target = self:pickRandomTarget(game.uniqueID)
	end
	return target
end

function ARENA:start()

	local e = ARENA.serverEvents
	-- Setup each game object
	for id, game in pairs(self.arena) do

		game.hook("garbageSend", function(lines)
		
			if game.dead then return end
			local target = game.target
			target = self:targetSanityCheck(target, game)

			local targets = {}
			if target == 0 then
				targets = game.attackers
			else
				targets = {target}
			end
			lines = math.ceil(lines / #targets)

			self:enqueue(e.DAMAGE, game.uniqueID, lines, targets)

		end)

		game.hook("changeTarget", function(target)
		
			if game.dead then return end
			local targets
			if target == 0 then
				targets = game.attackers
			else
				targets = {target}
			end

			self:enqueue(e.TARGET, game.uniqueID, targets)

		end)

		game.hook("die", function(killer)

			local placement, deathFrame, badgeBits = self.remainingPlayers, game.diedAt, game.badgeBits + 1

			self:enqueue(e.DIE, game.uniqueID, killer, placement, deathFrame, badgeBits)

			self.remainingPlayers = self.remainingPlayers - 1

			if self.remainingPlayers <= self.phaseStartHalfway and self.phase == 0 then
				self.phase = 1
				self:enqueue(e.CHANGEPHASE, self.phase, deathFrame)
			end

			if self.remainingPlayers <= self.phaseStartShowdown and self.phase == 1 then
				self.phase = 2
				self:enqueue(e.CHANGEPHASE, self.phase, deathFrame)
			end

			if self.remainingPlayers <= 1 then
				self.dead = true
			end

		end)

		game.hook("prelock", function(piece, rot, x, y, mono)
		
			self:enqueue(e.MATRIX_PLACE, game.uniqueID, piece.type, rot, x, y, mono)

		end)

		game.hook("garbageDumpFull", function(solid, lines)
		
			local eventType = solid and e.MATRIX_SOLID or e.MATRIX_GARBAGE
			self:enqueue(eventType, game.uniqueID, lines)


		end)

		game:start()
	end

	self.nextSnapshot = self.startTime + self.refreshRate
	hook.add("think", self.hookName, function()
	
		local time = timer.curtime()
		if time >= self.nextSnapshot then
			while self.nextSnapshot <= time do
				self.nextSnapshot = self.nextSnapshot + self.refreshRate
			end
			self:sendSnapshot()
			if self.dead then
				hook.remove("think", self.hookName)
			end
		end

	end)

end


-- Handles incoming network traffic from a player. This will decode the snapshot via net
function ARENA:handleClientSnapshot(game, ply)

	if game.dead then
		if not game.printedDisregard then
			game.printedDisregard = true
			print("Player", ply, "is dead. disregarding their net messages")
			print("   reason: " .. tostring(game.kickReason))
		end
		return
	end

	local eventCount = net.readUInt(10) -- max 1024


	for i = 1, eventCount do

		local event = net.readUInt(2)
		local frame = net.readUInt(32)

		if event == ARENA.clientEvents.INPUT then
			local input = net.readUInt(3)
			local down = net.readBit() == 1
			
			game:userInput(frame, input, down)


		elseif event == ARENA.clientEvents.TARGET then
			local target = net.readUInt(6)
			
			if game.waitingForTarget then
				game:callEvent(game.waitingForTarget, "sv_changeTarget", target)
			else
				game:userInput(frame, br.inputEvents.CHANGE_TARGET, target)
			end

		elseif event == ARENA.clientEvents.ACKNOWLEDGE then
			local snapshotID = net.readUInt(32)

			local snapshot = self.snapshots[snapshotID]
			if not snapshot then
				print(ply, "tried to acknowledge unknown snapshotID " .. tostring(snapshotID) .. "!")
			else
				br.handleServerSnapshot(game, frame, snapshot)
				game.pendingSnapshots[snapshotID] = nil
				game.pendingCount = game.pendingCount - 1
			end

		elseif event == ARENA.clientEvents.DIE then

			game:update(frame)
			if game.dead and game.diedAt == frame then
			else
				print("bad death! player says " .. tostring(frame) .. ", game " .. (game.dead and ("died at " .. game.diedAt) or "did not die!"))
			end

		end
	
	end

end

function ARENA:enqueue(...)
	table.insert(self.queue, {...})
end

function ARENA:sendSnapshot()

	self.snapshotCount = self.snapshotCount + 1
	
	local snapshotID = self.snapshotCount

	for id, game in pairs(self.arena) do
		if not game.dead and game.bot then
			local frame = brix.getFrame(timer.curtime() - self.startTime)
			game:update(frame)
		end
	end

	for id, game in pairs(self.arena) do
		if not game.dead and not game.bot then
			game.pendingSnapshots[snapshotID] = self.queue
			game.pendingCount = game.pendingCount + 1

			local nextID = next(game.pendingSnapshots)
			if self.snapshotCount - nextID > ARENA.maxUnacknowledgedSnapshots then
				print("Kicking player " .. tostring(game.uniqueID) .. " for failing to acknowledge old snapshot: " .. tostring(nextID))
				game:killGame()
				game.kickReason = "Failed to acknowledge old snapshot " .. nextID
			elseif game.pendingCount >= ARENA.maxUnacknowledgedSnapshots then
				print("Kicking player " .. tostring(game.uniqueID) .. " for too many pending snapshots")
				game:killGame()
				game.kickReason = "Timed out"
			end
		end

	end

	local e = ARENA.serverEvents

	net.start(ARENA.netTag)
	net.writeUInt(snapshotID, 32) -- snapshotID
	net.writeUInt(#self.queue, 32) -- size of queue
	for _, data in pairs(self.queue) do
	
		local event = data[1]
		net.writeUInt(event, 3)
		if event == e.DAMAGE then
			local attacker, lines, victims = data[2], data[3], data[4]

			local victimCount = #victims
			net.writeUInt(attacker, 6)
			net.writeUInt(victimCount, 6)
			net.writeUInt(lines, 5)
			for _, victim in pairs(victims) do
				net.writeUInt(victim, 6)
			end

		elseif event == e.TARGET then
			local attacker, victims = data[2], data[3]
			local victimCount = #victims
			
			net.writeUInt(attacker, 6)
			net.writeUInt(victimCount, 6)
			for _, victim in pairs(victims) do
				net.writeUInt(victim, 6)
			end

		elseif event == e.DIE then
			local victim, killer, placement, deathFrame, badgeBits = data[2], data[3], data[4], data[5], data[6]

			net.writeUInt(victim, 6)
			net.writeUInt(killer, 6)
			net.writeUInt(placement, 6)
			net.writeUInt(deathFrame, 32)
			net.writeUInt(badgeBits, 6)

		elseif event == e.MATRIX_PLACE then
			local player, piece, rot, x, y, mono = data[2], data[3], data[4], data[5], data[6], data[7]

			net.writeUInt(player, 6)
			net.writeUInt(piece, 3)
			net.writeUInt(rot, 2)
			net.writeInt(x, 5)
			net.writeInt(y, 6)
			net.writeBit(mono and 1 or 0)

		elseif event == e.MATRIX_GARBAGE then
			local player, gaps = data[2], data[3]
			local gapCount = #gaps

			net.writeUInt(player, 6)
			net.writeUInt(gapCount, 5)
			for _, gap in pairs(gaps) do
				net.writeUInt(gap, 4)
			end

		elseif event == e.MATRIX_SOLID then
			local player, lines = data[2], data[3]

			net.writeUInt(player, 6)
			net.writeUInt(lines, 5)

		elseif event == e.CHANGEPHASE then
			local phase, statedFrame = data[2], data[3]
			net.writeUInt(phase, 2)
			net.writeUInt(statedFrame, 32)
		
		else
			error("Unknown event type " .. tostring(event) )
		end

	end

	net.send()

	table.insert(self.snapshots, self.queue)

	for id, game in pairs(self.arena) do
		if not game.dead and game.bot then
			local frame = brix.getFrame(timer.curtime() - self.startTime)
			br.handleServerSnapshot(game, frame, self.queue)
		end
	end



	self.queue = {}


end

function br.createArena()

	local self = {}
	self.seed = math.random(2^31-1)
	self.arena = {} -- dict of players' BR objects
	self.players = {} -- lookup table of a player's ID
	self.connectedPlayers = {} -- list of players

	self.snapshots = {}		-- Lookup table of past snapshots sent to clients.
	self.snapshotCount = 0
	self.queue = {}			-- Ordered list of events in current snapshot

	self.phase = 0

	self.playerCount = 0
	self.remainingPlayers = 0
	self.uniqueIDs = {}
	for i = 1, ARENA.maxPlayers do
		self.uniqueIDs[i] = i
	end

	return setmetatable(self, ARENA)

end

hook.add("net", "brixConnect", function(name, len, ply)

	if name == ARENA.netConnectTag then

		for arena, _ in pairs(openServers) do
			arena:connectPlayer(ply)
		end

	elseif name == "BRIX_BOT" and ply == owner() then

		for arena, _ in pairs(openServers) do
			arena:connectBot()
		end

	end

end)

