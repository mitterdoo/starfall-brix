--@name BRIX: Arena (server)
--@author mitterdoo
--@server
--@include brix/br/arena.lua

require("brix/br/arena.lua")

local openServers = {}

-- Opens the server for connections
function ARENA:open()

	openServers[self] = true
	local hookName = tostring(math.random(2^31-1))
	hook.add("PlayerSay", hookName, function(ply, text)
		if ply == owner() and text == "$start" then
			hook.remove("PlayerSay", hookName)
			self:readyUp()
		end
	end)

end

function ARENA:connectPlayer(ply)

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
	print("giving", ply, id)


	local game = br.createGame(BR, self.seed, id)
	game.player = ply
	game.pendingSnapshots = {}
	game.pendingCount = 0

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
		not self.arena[target] or
		self.arena[target].dead
		-- or target == game.uniqueID
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
		
			local target = game.target
			target = self:targetSanityCheck(target, game)

			local targets = {}
			if target == 0 then
				targets = game.attackers
			else
				targets = {target}
			end
			lines = math.ceil(lines / #targets)
			print("__server garbage send", game.uniqueID, lines)

			self:enqueue(e.DAMAGE, game.uniqueID, lines, targets)

		end)

		game.hook("changeTarget", function(target)
		
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

			print("__server die", game.uniqueID, killer, placement, deathFrame, badgeBits)
			self:enqueue(e.DIE, game.uniqueID, killer, placement, deathFrame, badgeBits)

			self.remainingPlayers = self.remainingPlayers - 1


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
		end

	end)

end


-- Handles incoming network traffic from a player. This will decode the snapshot via net
function ARENA:handleClientSnapshot(game, ply)

	if game.dead then
		print("Player", ply, "is dead. disregarding their net message")
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
			
			game:userInput(frame, br.inputEvents.CHANGE_TARGET, target)

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
			if game.died and game.diedAt == frame then
				print("SUCCESSFUL death!", ply)
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
		if not game.dead then
			game.pendingSnapshots[snapshotID] = self.queue
			game.pendingCount = game.pendingCount + 1
			wire.ports.A = game.pendingCount

			if game.pendingCount >= ARENA.maxUnacknowledgedSnapshots then
				print("Kicking player " .. tostring(game.uniqueID) .. " for too many pending snapshots")
				game:killGame()
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
			net.writeUInt(x, 4)
			net.writeUInt(y, 5)
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

		elseif event == e.LEVELUP then
			net.writeUInt(data[2], 32)
		
		else
			error("Unknown event type " .. tostring(event) )
		end

	end

	net.send()

	table.insert(self.snapshots, self.queue)
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

	end

end)

