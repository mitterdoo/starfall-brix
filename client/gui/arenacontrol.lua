local PANEL = {}

--[[
	Note: this Control has no way to distinguish enemies from the local player
	You must handle local player stuff yourself.
	If any attack ID involves the local player, set the ID to 0.
	Do not add or remove a player with ID 0

	Arena:AddPlayer(uniqueID)
	Arena:RemovePlayer(uniqueID)

	Arena:SetPlayerEnemy(uniqueID, enemyObj)
		Connects the enemy object to the player's Control
	Arena:CreatePlayerEnemy(uniqueID, [matrixString, badgeBits])
		Creates an enemy object for this player.
		[Allows for restoring an existing state of this enemy]

	Arena:SendDamage(attackerID, lines, {victimIDs})
	Arena:OutgoingDamage(badges, lines, victimID, startPosAbsolute)
	Arena:KillPlayer(victimID, killerID, placement, badgeBits, entIndex, nick)

Avoid using these functions if the matrix is controlled by a third party
	Arena:KillPlayerFull(victimID, killerID, placement, badgeBits, entIndex, nick)
		Updates enemy objects accordingly
	Arena:MatrixPlace(playerID, pieceID, rot, x, y, isMono)
	Arena:MatrixGarbage(playerID, gaps)
	Arena:MatrixGarbageSolid(playerID, lines)
If the matrix is controlled by something else, changes will be detected automatically

overridable
	Arena:GetFieldCenter() -> Vector(x, y, 0)
		Absolute pos of the field center
	
	Arena:GetEnemyPos(id) -> x, y, w, h
	Arena.backgroundAttackGroup = {function enter(), function exit()}
		If set, any attacks that don't involve attacker/victim number 0 will be put in this group


]]
local attackGlowIntensity = 1.5
local function fx_AttackTravel(x, y, w, h, frac, glow)

	render.setRGBA(255, 255, 255, 255)
	if glow then

		render.drawRectFast(
			x + w/2 - (w*attackGlowIntensity)/2,
			y + h/2 - (h*attackGlowIntensity)/2,
			w*attackGlowIntensity,
			h*attackGlowIntensity
		)
	else
		render.drawRectFast(x, y, w, h)
	end

end

local spr_targetHit = sprite.sheets[1].targetHit

local function fx_TargetHit(x, y, w, h, frac)

	local frac_b = math.max(0, 1-frac*2)^2*255
	local frac_g = math.max(0, 1-frac)^2
	render.setRGBA(255, 120 + 135 * frac_g, frac_b, frac_g*255)
	sprite.setSheet(1)
	sprite.draw(spr_targetHit, x, y, w, h)

end

local koGlowIntensity = 1.5
local function fx_KnockoutTravel(x, y, w, h, frac, glow)

	if glow then
		render.setRGBA(255, 0, 0, 255)
	else
		render.setRGBA(255, 200, 200, 255)
	end
	if glow then

		render.drawRectFast(
			x + w/2 - (w*koGlowIntensity)/2,
			y + h/2 - (h*koGlowIntensity)/2,
			w*koGlowIntensity,
			h*koGlowIntensity
		)
	else
		render.drawRectFast(x, y, w, h)
	end

end

local fx_Attacks = {}

for i = 1, 5 do
	local spr = sprite.sheets[1].attack + i-1

	local setSheet = sprite.setSheet
	local sprDraw = sprite.draw
	local outgoingAttackGlowIntensity = 1.2
	local function thisAttack(x, y, w, h, frac, glow)
		setSheet(1)
		if not glow then
			render.setRGBA(255, 255, 255, 255)
			sprDraw(spr, x, y, w, h)
		else
			render.setRGBA(255, 255, 255, 255)
			sprDraw(spr,
				x + w/2 - (w*outgoingAttackGlowIntensity)/2,
				y + h/2 - (h*outgoingAttackGlowIntensity)/2,
				w*outgoingAttackGlowIntensity,
				h*outgoingAttackGlowIntensity)
		end
	end
	fx_Attacks[i] = thisAttack
end

local function fx_Connect(x, y, w, h, frac)

	local down = (1-frac)^2
	frac = frac^2
	render.setRGBA(down*200, 255, 255, down*255)
	render.drawRectFast(x, y, w, h)

end

local function fx_AttackLand(x, y, w, h, frac, glow)

	frac = (1-frac)^2
	render.setRGBA(255, 128 + frac*127, frac*255, frac*255)
	render.drawRectFast(x, y, w, h)

end


local spectatorPosArray = {
	{320, 160, 64, 128},
	{400, 160, 64, 128},
	{480, 160, 64, 128},
	{560, 160, 64, 128},
	{640, 160, 64, 128},
	
	{240, 304, 64, 128},
	{320, 304, 64, 128},
	{400, 304, 64, 128},
	{480, 304, 64, 128},
	{560, 304, 64, 128},
	{640, 304, 64, 128},
	{720, 304, 64, 128},
	
	{160, 448, 64, 128},
	{240, 448, 64, 128},
	{320, 448, 64, 128},
	{400, 448, 64, 128},
	{480, 448, 64, 128},
	{560, 448, 64, 128},
	{640, 448, 64, 128},
	{720, 448, 64, 128},
	{800, 448, 64, 128},
	
	{240, 592, 64, 128},
	{320, 592, 64, 128},
	{400, 592, 64, 128},
	{480, 592, 64, 128},
	{560, 592, 64, 128},
	{640, 592, 64, 128},
	{720, 592, 64, 128},
	
	{320, 736, 64, 128},
	{400, 736, 64, 128},
	{480, 736, 64, 128},
	{560, 736, 64, 128},
	{640, 736, 64, 128},
}

function PANEL:Init()
	PANEL.super.Init(self)
	self:SetSize(1024, 1024)

	-- {[enemyID] = EnemyControl}
	self.Enemies = {}

end

function PANEL:GetEnemyPos(uniqueID)
	return unpack(spectatorPosArray[uniqueID])
end

function PANEL:GetFieldCenter()
	return Vector(0, 0, 0)
end

function PANEL:AddPlayer(uniqueID, hideFX)

	local Ctrl = gui.Create("Enemy", self)
	local x, y, w, h = self:GetEnemyPos(uniqueID)
	Ctrl:SetPos(x, y)
	local scale_w, scale_h = w / 64, h / 128
	Ctrl:SetScale(scale_w, scale_h)
	self.Enemies[uniqueID] = Ctrl
	self.invalid = true

	if not hideFX then
		-- Connect effect
		local pos, scale = Ctrl:AbsolutePos(Vector(Ctrl.w/2, Ctrl.h/2, 0))
		local size = Vector(Ctrl.w, Ctrl.h, 0)
		gfx.EmitParticle(
			{pos, pos},
			{size*scale, size*scale*Vector(4, 0.05, 0)},
			0, 0.15,
			fx_Connect,
			true, true
		)
	end

end

function PANEL:RemovePlayer(uniqueID)
	if self.Enemies[uniqueID] then
		self.Enemies[uniqueID]:Remove()
		self.Enemies[uniqueID] = nil
		self.invalid = true
	end
end

function PANEL:SetPlayerEnemy(uniqueID, enemy)
	if self.Enemies[uniqueID] then
		self.Enemies[uniqueID]:SetEnemy(enemy)
	else
		error("No control created for enemy " .. tostring(uniqueID))
	end
	self.invalid = true
end

function PANEL:CreatePlayerEnemy(uniqueID, matrixString, badgeBits, solidHeight, placement)

	local enemyObj = br.createEnemy(uniqueID)
	if matrixString then
		enemyObj.matrix.data = matrixString
		enemyObj.matrix:updateCount()
		enemyObj.danger = math.max(0, enemyObj.matrix.cellCount - brix.dangerCapacity)
		enemyObj.matrix.invalid = true
	end

	if badgeBits then
		enemyObj.badgeBits = badgeBits
		enemyObj.matrix.invalid = true
	end

	if solidHeight then
		enemyObj.matrix.solidHeight = solidHeight
		enemyObj.matrix.invalid = true
	end

	self.Enemies[uniqueID]:SetEnemy(enemyObj)

	if placement then
		enemyObj.dead = true
		enemyObj.placement = placement
		self.Enemies[uniqueID]:Kill()
	end

end

function PANEL:SendDamage(attackerID, damage, targetID)

	local attackerCtrl = self.Enemies[attackerID]
	local targetCtrl = self.Enemies[targetID]

	if attackerCtrl == nil then return end
	local enemySize = Vector(attackerCtrl.w, attackerCtrl.h, 0)
	local attackerPos, scale = attackerCtrl:AbsolutePos(enemySize/2)
	local targetPos
	local under = true
	if not targetCtrl then
		if targetID ~= 0 then
			error("Tried to make garbage anim for unknown target ID " .. tostring(targetID))
		end
		targetPos = self:GetFieldCenter()
		under = false
	else
		targetPos = targetCtrl:AbsolutePos(Vector(targetCtrl.w/2, targetCtrl.h/2, 0))
	end

	local percent = damage / 20
	local size = Vector(1, 1, 0) * (24 + 32*percent) * scale

	gfx.EmitParticle(
		{attackerPos, targetPos},
		{size, size},
		0, 0.5,
		fx_AttackTravel,
		true, true,
		nil, under and self.backgroundAttackGroup
	)

	gfx.EmitParticle(
		{targetPos, targetPos},
		{enemySize*scale, enemySize*scale*1.2},
		0.5, 0.1,
		fx_AttackLand,
		true, true
	)
end

function PANEL:SendDamageToPlayers(attackerID, lines, victims)
	for _, targetID in pairs(victims) do
		self:SendDamage(attackerID, lines, targetID)
	end
end

local shrinkStart = 0.95
function PANEL:OutgoingDamage(badges, lines, victim, startPos)

	local percent = lines / 20
	local _, gameScale = self:AbsolutePos(Vector(0, 0, 0))
	local size = Vector(1, 1, 0) * (250 + percent*100) * gameScale

	badges = math.min(4, badges)
	local attackFX = fx_Attacks[badges+1]

	local Ctrl = self.Enemies[victim]
	if not Ctrl then return end
	local endPos, scale = Ctrl:AbsolutePos(Vector(Ctrl.w/2, Ctrl.h/2, 0))
	local enemySize = Vector(Ctrl.w, Ctrl.h, 0)

	gfx.EmitParticle(
		{{0, startPos}, {shrinkStart, endPos}, {1, endPos}},
		{{0, size}, {shrinkStart, size}, {1, Vector(0, 0, 0)}},
		0, 0.5 / shrinkStart,
		attackFX,
		true, true
	)
	gfx.EmitParticle(
		{endPos, endPos},
		{enemySize*scale, enemySize*scale*1.2},
		0.5, 0.1,
		fx_AttackLand,
		true, true
	)
	local hitSize = enemySize*scale
	gfx.EmitParticle(
		{endPos, endPos},
		{hitSize, hitSize*8},
		0.5, 1/6,
		fx_TargetHit,
		true, true
	)

end

local trailCount = 3
function PANEL:KillPlayer(victimID, attackerID, placement, badgeBits, entIndex, nick)

	local victimCtrl = self.Enemies[victimID]
	victimCtrl:Kill()

	local attackerCtrl = self.Enemies[attackerID]
	if not attackerCtrl then return end
	assert(victimCtrl ~= nil, "attempt to create KO particle from unknown victim " .. tostring(victimID))

	local startPos, scale = victimCtrl:AbsolutePos(Vector(victimCtrl.w/2, victimCtrl.h/2, 0))
	local endPos = attackerCtrl:AbsolutePos(Vector(attackerCtrl.w/2, attackerCtrl.h/2, 0))

	local percent = badgeBits / 20
	local size = Vector(24, 24, 0) * scale * (1 + percent)

	for i = 1, trailCount do
		local sizeScale = 1 - (i-1)/trailCount
		gfx.EmitParticle(
			{startPos, endPos},
			{size*sizeScale, size*sizeScale},
			(i - 1)*(2/60), 0.5,
			fx_KnockoutTravel,
			true, true,
			nil, self.backgroundAttackGroup
		)
	end

end

function PANEL:KillPlayerFull(victimID, killerID, placement, badgeBits, entIndex, nick)

	local Ctrl = self.Enemies[victimID]
	local Killer = self.Enemies[killerID]
	Killer.enemy:giveBadgeBits(badgeBits)
	Ctrl.enemy.dead = true
	Ctrl.enemy.placement = placement

	self:KillPlayer(victimID, killerID, placement, badgeBits, entIndex, nick)

end



function PANEL:MatrixPlace(playerID, pieceID, rot, x, y, mono)

	local enemy = self.Enemies[playerID]
	if not enemy then error("MatrixPlace: Enemy doesn't exist " .. tostring(playerID)) end
	local piece = brix.pieces[pieceID]
	enemy.enemy:place(piece, rot, x, y, mono)

end

function PANEL:MatrixGarbage(playerID, gaps, mono)

	local enemy = self.Enemies[playerID]
	if not enemy then error("MatrixGarbage: Enemy doesn't exist " .. tostring(playerID)) end
	enemy.enemy:garbage(gaps, mono)

end

function PANEL:MatrixGarbageSolid(playerID, lines)

	local enemy = self.Enemies[playerID]
	if not enemy then error("MatrixGarbageSolid: Enemy doesn't exist " .. tostring(playerID)) end
	for i = 1, lines do
		enemy.enemy:garbage()
	end

end

function PANEL:Load(data)

	local stream = bit.stringstream(data)
	local size = #data
	while stream:tell() <= size do

		local id = stream:readInt8()
		self:AddPlayer(id, true)
		local dead = stream:readInt8() == 1
		if dead then
			self:CreatePlayerEnemy(id, nil, nil, nil, stream:readInt8())
		else
			local bits = stream:readInt8()
			local solidHeight = stream:readInt8()
			local dataSize = stream:readInt16()
			local mat = stream:read(dataSize)
			self:CreatePlayerEnemy(id, mat, bits, solidHeight)
		end


	end

	self.Loaded = true
end

function PANEL:Think()
	if not self.invalid then
		for id, Ctrl in pairs(self.Enemies) do
			Ctrl:Think()
		end
	end
end

gui.Register("ArenaControl", PANEL, "RTControl")
