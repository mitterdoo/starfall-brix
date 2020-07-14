local function fx_AttackTravel(x, y, w, h, frac, glow)

	render.setRGBA(255, 255, 255, 255)
	if glow then
		render.drawRectFast(x - w/2, y - h/2, w*2, h*2)
	else
		render.drawRectFast(x, y, w, h)
	end

end

local fx_Attacks = {}

for i = 1, 5 do
	local spr = sprite.sheets[1].attack + i-1

	local setSheet = sprite.setSheet
	local sprDraw = sprite.draw
	local function thisAttack(x, y, w, h, frac, glow)
		setSheet(1)
		if not glow then
			render.setRGBA(255, 255, 255, 255)
			sprDraw(spr, x, y, w, h)
		else
			render.setRGBA(255, 255, 255, 128)
			sprDraw(spr, x, y, w, h)
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
	render.setRGBA(255, 255, frac*255, frac*255)
	if glow then
		render.drawRectFast(x-w/2, y-h/2, w*2, h*2)
	else
		render.drawRectFast(x, y, w, h)
	end

end

local spr_attacker = sprite.sheets[1].enemy_outline
local spr_target = 58
local spr_targetBlip = 59

local blip_w, blip_h = sprite.sheets[1][spr_targetBlip][3], sprite.sheets[1][spr_targetBlip][4]

local function fx_TargetBlip(x, y, w, h, frac)

	local f = (1-frac)^2
	render.setRGBA(255, 255, 255, f*255)
	sprite.setSheet(1)
	sprite.draw(spr_targetBlip, x, y, w, h)

end

local lookup = sprite.sheets[3]
local function getEnemyPos(id, ourID)

	if id > ourID then
		id = id - 1
	end

	if id < 1 or id > 32 then
		error("Cannot get enemy pos for ID " .. tostring(id))
	end

	return unpack(lookup[id])

end

hook.add("brConnect", "enemy", function(game, arena)

	local enemies = {}
	game.controls.Enemies = enemies

	local AttackerOutlines = {}
	local TargetOutlines = {}
	local TargetBlipFrequency = 0.4
	local LastTargetBlip = 0


	local LayerAbove = game.controls.Attacks_Above
	local LayerBelow = game.controls.Attacks_Below
	local EnemyRT = gui.Create("RTControl", LayerBelow)
	EnemyRT:SetSize(1024, 1024)

	function EnemyRT:Think()

		if not self.invalid then
			for id, Ctrl in pairs(enemies) do
				Ctrl:Think()
			end
		end

		local t = timer.realtime()
		if t > LastTargetBlip + TargetBlipFrequency then

			LastTargetBlip = t
			for _, Ctrl in pairs(TargetOutlines) do

				local pos, scale = Ctrl:AbsolutePos(Vector(0, 0, 0))
				gfx.EmitParticle(
					{pos, pos},
					{Vector(blip_w, blip_h, 0) * scale, Vector(blip_w, blip_h, 0)*scale*2},
					0, 0.5,
					fx_TargetBlip,
					false, true
				)

			end

		end

	end

	local function setAttackers(attackers)

		for _, Ctrl in pairs(AttackerOutlines) do
			Ctrl:Remove()
		end
		AttackerOutlines = {}

		for _, id in pairs(attackers) do

			local Enemy = enemies[id]
			if Enemy then
				local Ctrl = gui.Create("Sprite", LayerAbove)
				local x, y = Enemy:GetPos()
				local sw, sh = Enemy.scale_w, Enemy.scale_h
				Ctrl:SetPos(x + Enemy.w*sw/2, y + Enemy.h*sh/2)
				Ctrl:SetScale(sw, sh)
				Ctrl:SetSheet(1)
				Ctrl:SetSprite(spr_attacker)
				Ctrl:SetAlign(0, 0)
				table.insert(AttackerOutlines, Ctrl)
			end

		end

	end

	local function setTargets(targets)

		for _, Ctrl in pairs(TargetOutlines) do
			Ctrl:Remove()
		end
		TargetOutlines = {}

		for _, id in pairs(targets) do

			local Enemy = enemies[id]
			if Enemy then
				local Ctrl = gui.Create("Sprite", LayerBelow)
				local x, y = Enemy:GetPos()
				local sw, sh = Enemy.scale_w, Enemy.scale_h
				Ctrl:SetPos(x + Enemy.w*sw/2, y + Enemy.h*sh/2)
				Ctrl:SetScale(sw, sh)
				Ctrl:SetSheet(1)
				Ctrl:SetSprite(spr_target)
				Ctrl:SetAlign(0, 0)
				table.insert(TargetOutlines, Ctrl)
			end

		end

	end

	arena.hook("playerConnect", function(who)
	
		if who == arena.uniqueID then return end
		local Ctrl = gui.Create("Enemy", EnemyRT)
		local x, y, w, h = getEnemyPos(who, arena.uniqueID)
		Ctrl:SetPos(x, y)

		local scale_w, scale_h = w / 64, h / 128
		Ctrl:SetScale(scale_w, scale_h)
		enemies[who] = Ctrl
		EnemyRT.invalid = true

		local pos, scale = Ctrl:AbsolutePos(Vector(Ctrl.w/2, Ctrl.h/2, 0))
		local size = Vector(Ctrl.w, Ctrl.h, 0)
		gfx.EmitParticle(
			{pos, pos},
			{size*scale, size*scale*Vector(4, 0.05, 0)},
			0, 0.15,
			fx_Connect,
			true, true
		)


	end)

	arena.hook("arenaFinalized", function()
	
		for id, enemy in pairs(arena.arena) do
			if enemies[id] then
				enemies[id]:SetEnemy(enemy)
			else
				error("No control created for enemy " .. tostring(id))
			end
		end
		EnemyRT.invalid = true

	end)

	arena.hook("playerDie", function(victim, killer, placement, deathFrame, badgeBits)
	
		if enemies[victim] then
			local Ctrl = enemies[victim]

			Ctrl:Kill()

		end

	end)

	arena.hook("badgeBits", function(count, sourceID)
	
		if enemies[sourceID] then
			local enemy = enemies[sourceID]
			local w, h = enemy:GetSize()
			local pos = enemy:AbsolutePos(Vector(w/2, h/2, 0))
			game.controls.Scoreboard:AwardBitsFromAbsolutePos(count, pos)
		end

	end)

	arena.hook("attackersChanged", function(attackers)
	
		setAttackers(attackers)

	end)

	arena.hook("changeTarget", function(target)
	
		local targets = target == 0 and arena.attackers or {target}
		setTargets(targets)

	end)

	local shrinkStart = 0.95
	local brickSize = sprite.sheets[3].field_main[3]

	arena.hook("garbageSend", function(lines)
	
		local targets
		if arena.target == 0 then
			targets = arena.attackers
		else
			targets = {arena.target}
		end

		lines = math.ceil(lines / #targets)
		local percent = lines / arena.params.maxGarbageOut
		local center = game.controls.LineClearCenter
		local centerX = center:AbsolutePos(0, 0)
		local startLeft = center:AbsolutePos(Vector(-brickSize, 0, 0) * 5)
		local startRight = center:AbsolutePos(Vector(brickSize, 0, 0) * 5)
		local size = Vector(1, 1, 0) * (150 + percent*100)

		local badges = br.getBadgeCount(arena.badgeBits)
		badges = math.min(4, badges)

		local attackFX = fx_Attacks[badges+1]

		for _, id in pairs(targets) do

			local enemy = enemies[id]
			if enemy then
				local endPos, scale = enemy:AbsolutePos(Vector(enemy.w/2, enemy.h/2, 0))

				local startPos = endPos.x < centerX and startLeft or startRight

				local enemySize = Vector(enemy.w, enemy.h, 0)
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
			end

		end

	end)

end)

