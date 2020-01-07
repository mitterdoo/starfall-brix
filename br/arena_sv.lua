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


	local game = br.createGame(BR, self.seed, id)
	game.player = ply

	self.arena[id] = game
	table.insert(self.connectedPlayers, ply)
	self.players[ply] = id

	net.start(ARENA.netConnectTag)
	net.writeUInt(ARENA.connectEvents.ACCEPT, 2)
	net.writeUInt(self.seed, 32)
	net.writeUInt(id, 6)
	net.send(ply)

	self.playerCount = self.playerCount + 1

	net.start(ARENA.netConnectTag)
	net.writeUInt(ARENA.connectEvents.UPDATE)
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

	self.netHook = "brixNet" .. self.seed
	hook.add("net", self.netHook, function(name, len, ply)

		local id = self.players[ply]
		if name == ARENA.netTag and id and timer.curtime() >= self.startTime then
			self:playerNet(self.arena[id], ply)
		end

	end)

	timer.simple(ARENA.readyUpTime, function()
		self:start()
	end)

end

function ARENA:start()

	-- Setup each game object
	for id, game in pairs(self.arena) do

		game:start()
	end

end


-- Handles incoming network traffic from a player. Decodes and turns the info into a table.
function ARENA:playerNet(game, ply)

	if game.diedAt then
		print("Player", ply, "is dead. disregarding their net message")
		return
	end

	local clientSnapshot = {}

	local eventCount = net.readUInt(10) -- max 1024

	for i = 1, eventCount do

		local event = net.readUInt(2)
		local frame = net.readUInt(32)

		local clientEvent = {event, frame}

		if event == ARENA.clientEvents.INPUT then
			local input = net.readUInt(3)
			local down = net.readBit() == 1
			table.insert(clientEvent, input)
			table.insert(clientEvent, down)

		elseif event == ARENA.clientEvents.TARGET then
			local target = net.readUInt(6)
			table.insert(clientEvent, target)

		elseif event == ARENA.clientEvents.ACKNOWLEDGE then
			local snapshotID = net.readUInt(32)
			table.insert(clientEvent, snapshotID)

		end

		table.insert(clientSnapshot, clientEvent)
	
	end

	self:handleClientSnapshot(game, ply, clientSnapshot)

end

function ARENA:enqueue(...)
	table.insert(self.queue, {...})
end

function br.createArena()

	local self = {}
	math.randomseed(os.time())
	self.seed = math.random(2^31-1)
	self.arena = {} -- dict of players' BR objects
	self.players = {} -- lookup table of a player's ID
	self.connectedPlayers = {} -- list of players

	self.snapshots = {}		-- Lookup table of past snapshots sent to clients.
	self.queue = {}			-- Ordered list of events in current snapshot

	self.playerCount = 0
	self.uniqueIDs = {}
	for i = 1, self.maxPlayers do
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

