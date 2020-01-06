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

function br.createArena(seed, uniqueID)

	local self = br.createGame(ARENA, seed, uniqueID)

	self.queue = {}

	self.hook("preInput", function(when, pressed, input)

		self:enqueue(self.clientEvents.INPUT, when, input, pressed)

	end)

	self.hook("changeTarget", function(target)

		self:enqueue(self.clientEvents.TARGET, self.frame, target)

	end)

	self.hook("die", function()
	
		self:enqueue(self.clientEvents.DIE, self.frame)

	end)

	return self

end

function ARENA:connect()

	net.start(ARENA.netConnectTag)
	net.send()

	net.receive(ARENA.netConnectTag, function()
	
	end)

end

function ARENA:handleServerSnapshot(snapshot)
	local frame = brix.getFrame(timer.realtime() - self.startTime)

	br.handleServerSnapshot(self, frame, snapshot)

end
