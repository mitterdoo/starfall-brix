--@name BRIX: ARENA
--@shared


--[[


	TODO TODO TODO TODO
	Make BRIX object completely independent of BR mechanics.
	Input should be fed into ARENA object, and it must determine whether that input goes to the BRIX object, or whether the ARENA should handle it instead.
	Levelling up should be methods of a BRIX object.
	Add hooks for input buffers


	When the CLIENT has died,
		CLIENT sends server the frame at which they died
		SERVER "simulates" the game up to that point and verifies that they died there
		Whoever the server hears from first, is the person who died first. I really can't be bothered to solve this dilemma,
			and let's be honest, T99 developers probably couldn't have been, either.
	

	SERVER snapshot
		This is a "snapshot" of the game that is sent every 11 frames of the game.
		There is a unique ID associated with this snapshot.
		When the CLIENT receives it:
			Playfields are updated
			Badges are rewarded
			Deaths are shown
			Garbage is sent to players

			CLIENT sends "acknowledge" with their own input snapshot
				(they send the snapshot number, and the frame at which it occurred)
				SERVER will then plug in the CLIENT's inputs, and the contents of the snapshot.
	
		This means that, when garbage is received by a player on the SERVER,
			the player's SERVER game instance will NOT be given garbage. The garbage
			will only be plugged in according to the snapshot.
	
	CLIENT snapshot
		This will contain a list of inputs (and the frame numbers for when they occurred) made since the
		last snapshot sent by the client. It will also contain the ID of the SERVER snapshot that has
		been acknowledged, as well as the frame for when the CLIENT received it.

			
]]


ARENA = {}
ARENA.__index = ARENA

brix.SERVER_EVENTS = {
    INIT = 0,        --{youUniqueID, rseed, numPlayers}      Beginning of game
    TARGET = 1,      --{players}                             Who is targeting you
    ATTACK = 2,      --{fromwho, towho, number of lines}     An attack has been sent
    KO = 3,          --{who, placement}                      Somebody was knocked out
    REFRESH = 4      --{who, pinch, field}                   A player's field changed

}
brix.CLIENT_EVENTS = { -- events that are caused by the controller
    MOVELEFT = 0,
    MOVERIGHT = 1,
    SOFTDROP = 2,
    HARDDROP = 3,
    HOLD = 4,
    ROT_CW = 5,
    ROT_CCW = 6,
    TARGET_KO = 7,
    TARGET_BADGES = 8,
    TARGET_ATTACKERS = 9,
    TARGET_RANDOM = 10,
    TARGET_UP = 11,
    TARGET_DOWN = 12,
    TARGET_LEFT = 13,
    TARGET_RIGHT = 14,
	ACKNOWLEDGE_OR_DEATH = 15,
}


function ARENA:sh_Init()


end

function ARENA:sv_Init()

	self:sh_Init()
	self.snapshot = {}
	self.players = {}
	self.playerLookup = {} -- uniqueId = {player = Entity, game = BRIX, uniqueId = number}
	self.arenaCount = 0

end

function ARENA:sv_getUniqueIDForPlayer(ply)

	for uniqueId, obj in pairs(self.playerLookup) do
		if obj.player == ply then
			return uniqueId
		end
	end

end

function ARENA:sv_Panic(who, ...)

	local str = table.concat({...}, "\t")
	error("ARENA PANIC Player " .. who.uniqueId .. ":\t" .. str )

end

local cl_e = brix.CLIENT_EVENTS
local sv_e = brix.SERVER_EVENTS

--[[
	Multiple ack packets must be able to be stored on server.
	Packets[id] = pkt
	NextPa
]]
function ARENA:sv_ReceivePacket(who, ack, packet)

	-- local ack = net.readUInt(30)
	if ack ~= who.lastAck + 1 then
		self:sv_Panic(who, "Unexpected acknowledgement " .. tostring(ack) .. " (expected " .. (who.lastAck + 1) .. ")")
		return false
	end
	who.lastAck = ack
	local packetSize = #packet -- net.readUInt(16)
	if packetSize == 0 then
		self:sv_Panic(who, "Empty acknowledgement packet")
		return false
	end

	local acknowledged = false

	local expectedDeath = false
	local died = false
	for k, this in ipairs(packet) do

		local frame = this.frame -- net.readUInt(32)
		local event = this.event -- net.readUInt(4)
		local flag = this.flag -- net.readBit() == 1 -- For held buttons, this is `held`. For ACKNOWLEDGE, this is 1 if acknowledging, or 0 if death

		if event == cl_e.ACKNOWLEDGE_OR_DEATH then
			if flag then -- Acknowledged
				acknowledged = true
				self:sv_Acknowledge(who, ack) -- Add needed garbage
			else -- Died
				if who.game.diedAt ~= frame then
					self:sv_Panic(who, "Death frame does not match with SERVER")
					return false
				end
				died = true
				self:sv_EventDie(who, frame) -- killer is stored in the game
			end
		else
			local err = who.game:userInput(frame, event, flag)
			if err == 1 then -- We died
				expectedDeath = true
			elseif err then -- Return value = error
				self:sv_Panic(who, tostring(err))
				return false
			end
		end

	end

	if not acknowledged then
		self:sv_Panic(who, "Could not fine acknowledge frame!")
		return false
	elseif expectedDeath and not died then
		self:sv_Panic(who, "SERVER game died, but CLIENT did not send death message!")
		return false
	end

	return true

end








-------------------------------SERVER ↑
-------------------------------CLIENT ↓








function ARENA:cl_Init()

	self:sh_Init()
	
	local game = brix.createGame(self, self.seed, false)
	self.game = game
	self.players = {} -- item is enemy
	self.playerLookup = {} -- uniqueId
	self.arenaCount = 0

	self.renderTarget = "arenaRenderTarget"
	render.createRenderTarget(self.renderTarget)

	self._invalid = true

	game.hook("lock", function(piece, rot, x, y)
	
		self.players[1]:AddPiece(piece, rot, x, y)

	end)

	game.hook("postlock", function(tricks, combo, sent, cleared)
	
		if sent > 0 then
			print("attack with lines=", sent)
		end

		self.players[1]:ClearLines(cleared)

	end)

	game.hook("garbageDumpFull", function(gaps)
	
		self.players[1]:AddGarbage(gaps)

	end)

	self:cl_AddPlayer(self.uniqueId)

end

function ARENA:cl_ReceiveSnapshot(snapshot) -- decode and pass into cl_UpdateEnemy

end

function ARENA:cl_AddPlayer(uniqueId)

	local ply = brix.createEnemy(uniqueId)
	table.insert(self.players, ply)
	self.arenaCount = self.arenaCount + 1
	return ply

end

brix.snapshotEvents = {
	PIECE = 0,		-- who, piece (type, not id), rot, x, y
	GARBAGE = 1,	-- who, {gaps}
	CLEAR = 2,		-- who, {lines}
	BADGE = 3,		-- who, count
	ATTACK = 4,		-- who, {uniqueId = linesReceived} 
	DIE = 5,		-- who, killer
	TARGET = 6		-- who, {attackers}
}

function ARENA:cl_UpdateEnemy(updateType, uniqueId, ...) -- Do the same in SERVER when acknowledging snapshot, but only use ATTACK and DIE (for garbage and badge rewarding)

	if uniqueId == self.myUniqueId then return end
	if not self.playerLookup[uniqueId] then error("ARENA:cl_UpdateEnemy(): attempt to update nil/dead player " .. tostring(uniqueId) ) end

	local ply = self.playerLookup[uniqueId]
	local e = brix.snapshotEvents
	if updateType == e.PIECE then
		local piece, rot, x, y = ...
		ply:AddPiece(piece, rot, x, y)

	elseif updateType == e.GARBAGE then
		local gaps = ...
		ply:AddGarbage(gaps)

	elseif updateType == e.CLEAR then
		local lines = ...
		ply:ClearLines(lines)

	elseif updateType == e.BADGE then
		local badges = ...
		ply:AddBadges(badges)

	elseif updateType == e.ATTACK then
		local targets = ...
		self:cl_EnemyAttack(ply, targets)

	elseif updateType == e.DIE then
		local killer = ...
		self:cl_EnemyDie(ply, killer)

	else
		error("ARENA:cl_UpdateEnemy(): unknown updateType: " .. tostring(updateType))

	end

end

if CLIENT then

	function ARENA:cl_RenderUpdate()



	end

	function ARENA:cl_Render()

	-- Render the other players



		if self._invalid then
			self:cl_RenderUpdate()
		end
		render.setRGBA(255, 255, 255, 255)
		render.setRenderTargetTexture(self.renderTarget)
		render.drawTexturedRect(0, 0, 512, 512)



	end

end


function brix.createArena(seed, uniqueId)

	local arena = {}
	if not uniqueId then
		arena.SERVER = true
	else
		arena.CLIENT = true
		arena.myUniqueId = uniqueId
	end
	arena.seed = seed

	setmetatable(arena, ARENA)
	if server then
		arena:sv_Init()
	else
		arena:cl_Init()
	end

	return arena

end

