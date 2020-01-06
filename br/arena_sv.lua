--@name BRIX: Arena (server)
--@author mitterdoo
--@server
--@include brix/br/arena.lua

require("brix/br/arena.lua")

local openServers = {}

-- Opens the server for connections
function ARENA:open()

	table.insert(openServers, self)

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

	local id = self:pickUniqueID()
	local game = br.createGame(BR, self.seed, id)
	game.player = ply

	self.arena[id] = game

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

-- Picks an available uniqueID and uses it up.
function ARENA:pickUniqueID()

	local index = math.random(1, #self.uniqueIDs)
	return table.remove(self.uniqueIDs, index)

end

function br.createArena()

	local self = {}
	math.randomseed(os.time())
	self.seed = math.random(2^31-1)
	self.arena = {} -- dict of players' BR objects

	self.playerCount = 0
	self.uniqueIDs = {}
	for i = 1, self.maxPlayers do
		self.uniqueIDs[i] = i
	end

	return setmetatable(self, ARENA)

end

hook.add("net", "brixConnect", function(name, len, ply)

	if name == ARENA.netConnectTag then

		for _, arena in pairs(openServers) do
			arena:connectPlayer(ply)
		end

	end

end)

