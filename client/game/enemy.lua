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
		--sprite.setSheet(1, render.setMaterialEffectAdd)
		--sprite.draw(spr_knockout, x, y, w, h)
		render.drawRectFast(x, y, w, h)
	end

end

local fx_Attacks = {}

for i = 1, 5 do
	local spr = sprite.sheets[1].attack + i-1

	local setSheet = sprite.setSheet
	local sprDraw = sprite.draw
	local attackGlowIntensity = 1.2
	local function thisAttack(x, y, w, h, frac, glow)
		setSheet(1)
		if not glow then
			render.setRGBA(255, 255, 255, 255)
			sprDraw(spr, x, y, w, h)
		else
			render.setRGBA(255, 255, 255, 255)
			sprDraw(spr,
				x + w/2 - (w*attackGlowIntensity)/2,
				y + h/2 - (h*attackGlowIntensity)/2,
				w*attackGlowIntensity,
				h*attackGlowIntensity)
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
	--if glow then
	--	render.drawRectFast(x-w/2, y-h/2, w*2, h*2)
	--else
		render.drawRectFast(x, y, w, h)
	--end

end

local spr_attacker = sprite.sheets[1].enemy_outline

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
	local TargetReticles = {}

	local WatchOutFlashDuration = 1
	local LastWatchOutFlash = 0

	local LastAttackerCount = 0

	local LayerAbove = game.controls.Attacks_Above
	local LayerBelow = game.controls.Attacks_Below

	local EnemyRT = gui.Create("RTControl", LayerBelow)
	EnemyRT:SetSize(1024, 1024)

	local WatchOut = gui.Create("Sprite", LayerBelow)
	WatchOut:SetSheet(1)
	WatchOut:SetSprite(sprite.sheets[1].watchOut)
	WatchOut:SetVisible(false)
	local WatchOutFlash = gui.Create("Sprite", WatchOut)
	WatchOutFlash:SetSheet(1)
	WatchOutFlash:SetSprite(sprite.sheets[1].watchOut + 1)
	WatchOutFlash:SetColor(Color(255, 255, 255, 0))

	do
		local x, y, w, h = unpack(sprite.sheets[3].watchOut)
		WatchOut:SetPos(x, y)
		WatchOut:SetSize(w, h)

		WatchOutFlash:SetSize(w, h)
	end

	local _x, _y = unpack(sprite.sheets[3].watchOutAttachLeft)
	local WatchOutAttachLeft = Vector(_x, _y, 0)
	_x, _y = unpack(sprite.sheets[3].watchOutAttachRight)
	local WatchOutAttachRight = Vector(_x, _y, 0)

	local WatchOutStart
	local WatchOutLineDuration = 4/15


	function EnemyRT:Think()

		if not self.invalid then
			for id, Ctrl in pairs(enemies) do
				Ctrl:Think()
			end
		end

		local t = timer.realtime()

		if t > LastWatchOutFlash + WatchOutFlashDuration then
			LastWatchOutFlash = t
		end

		if WatchOutStart and t >= WatchOutStart + WatchOutLineDuration and not WatchOut.visible then
			WatchOut:SetVisible(true)
			LastWatchOutFlash = t
		end
		
		if WatchOut.visible then
			local f = timeFrac(t, LastWatchOutFlash, LastWatchOutFlash + WatchOutFlashDuration)
			f = (1 - math.min(1, timeFrac(f, 0, 0.2)))^2
			WatchOutFlash.color.a = f*255
		end

	end

	local AttackerStartTimes = {}


	function LayerAbove:PostPaint(w, h)

		render.setRGBA(255, 255, 0, 255)
		local t = timer.realtime()
		for _, Ctrl in pairs(AttackerOutlines) do

			local attachPoint
			if Ctrl.x < w/2 then
				attachPoint = WatchOutAttachLeft
			else
				attachPoint = WatchOutAttachRight
			end

			local startPos = Vector(Ctrl.x, Ctrl.y, 0)

			local startTime = AttackerStartTimes[Ctrl.uniqueID]
			local frac = timeFrac(t, startTime, startTime + WatchOutLineDuration)
			if frac >= 1 then
				render.drawLine(Ctrl.x, Ctrl.y, attachPoint[1], attachPoint[2])
			else
				local delta = (attachPoint - startPos)*frac
				render.drawLine(startPos[1], startPos[2], startPos[1] + delta[1], startPos[2] + delta[2])
			end


		end

	end

	local function setAttackers(attackers)

		if arena.dead then return end
		local keys = {} for k, v in pairs(attackers) do keys[v] = true end

		for id, _ in pairs(AttackerStartTimes) do
			if not keys[id] then
				AttackerStartTimes[id] = nil
			end
		end

		for _, Ctrl in pairs(AttackerOutlines) do
			Ctrl:Remove()
		end

		AttackerOutlines = {}

		if #attackers == 0 then
			WatchOutStart = nil
			timer.simple(WatchOutLineDuration, function()
				if WatchOutStart == nil then
					WatchOut:SetVisible(false)
				end
			end)
		elseif not WatchOutStart then
			WatchOutStart = timer.realtime()
		end

		for _, id in pairs(attackers) do

			if not AttackerStartTimes[id] then
				AttackerStartTimes[id] = timer.realtime()
			end
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
				Ctrl.uniqueID = id
				table.insert(AttackerOutlines, Ctrl)
			end

		end

	end

	local function createReticle(enemyID, flash)

		local Enemy = enemies[enemyID]
		if Enemy then
			local Ctrl = gui.Create("Reticle", LayerAbove)
			Ctrl:SetPos(LayerBelow.w/2, LayerAbove.h/2)
			local x, y = Enemy:GetPos()
			local sw, sh = Enemy.scale_w, Enemy.scale_h
			Ctrl:MoveTo(x + Enemy.w*sw/2, y + Enemy.h*sh/2)
			Ctrl.uniqueID = enemyID
			if flash then
				Ctrl:Flash()
			end
			table.insert(TargetReticles, Ctrl)
		end

	end

	local function moveReticle(Ctrl, enemyID, flash)

		local Enemy = enemies[enemyID]
		if Enemy then
			local x, y = Enemy:GetPos()
			local sw, sh = Enemy.scale_w, Enemy.scale_h
			Ctrl:MoveTo(x + Enemy.w*sw/2, y + Enemy.h*sh/2)
			if flash and enemyID ~= Ctrl.uniqueID then -- don't flash if nothing happened
				Ctrl:Flash()
			end
			Ctrl.uniqueID = enemyID
		end

	end

	local function setTargets(targets, causedByInput)

		if arena.dead then return end
		local lastCount, curCount = #TargetReticles, #targets

		if curCount == 1 then
			if lastCount ~= 1 then
				for _, Ctrl in pairs(TargetReticles) do
					Ctrl:Remove()
				end
				TargetReticles = {}
				
				createReticle(targets[1], causedByInput)
			else

				moveReticle(TargetReticles[1], targets[1], causedByInput)
			end
		else

			if lastCount == 1 then
				for _, Ctrl in pairs(TargetReticles) do
					Ctrl:Remove()
				end
				TargetReticles = {}

				for _, id in pairs(targets) do
					createReticle(id, causedByInput)
				end
			else
				-- Find already targeted enemies and keep them

				local reticleKeys = {}
				for _, Ctrl in pairs(TargetReticles) do
					reticleKeys[Ctrl.uniqueID] = true
				end

				local targetKeys = {}
				for _, id in pairs(targets) do

					targetKeys[id] = true
					if not reticleKeys[id] then -- new target
						createReticle(id, causedByInput)
					end

				end

				-- Removed targets
				local i = 1
				while true do

					local Ctrl = TargetReticles[i]
					if not Ctrl then break end
					if not targetKeys[Ctrl.uniqueID] then
						table.remove(TargetReticles, i)
					else
						i = i + 1
					end

				end
			end

		end

	end

	arena.hook("gameover", function(reason)
	
		WatchOutStart = nil
		WatchOut:SetVisible(false)

		for _, Ctrl in pairs(TargetReticles) do
			Ctrl:Remove()
		end
		TargetReticles = {}

		for _, Ctrl in pairs(AttackerOutlines) do
			Ctrl:Remove()
		end

		AttackerOutlines = {}

	end)

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

	arena.hook("playerDisconnect", function(who)
		if who == arena.uniqueID then return end
		if enemies[who] then
			enemies[who]:Remove()
			enemies[who] = nil
			EnemyRT.invalid = true
		end
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

	arena.hook("badgeBits", function(count, sourceID)
	
		if arena.dead then return end
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
		setTargets(targets, arena.manuallyAdjusting)

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

		local percent = lines / arena.params.maxGarbageOut
		local center = game.controls.LineClearCenter
		local centerX = center:AbsolutePos(0, 0)
		local startLeft = center:AbsolutePos(Vector(-brickSize, 0, 0) * 2)
		local startRight = center:AbsolutePos(Vector(brickSize, 0, 0) * 2)
		local _, gameScale = EnemyRT:AbsolutePos(Vector(0, 0, 0))
		local size = Vector(1, 1, 0) * (250 + percent*100) * gameScale

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
				local hitSize = Vector(enemy.w, enemy.w, 0)*scale
				gfx.EmitParticle(
					{endPos, endPos},
					{hitSize, hitSize*8},
					0.5, 1/6,
					fx_TargetHit,
					true, true
				)
			end

		end

	end)

	local framePos, frameSize = Vector(0, 0, 0), Vector(0, 0, 0)
	do

		local scale
		framePos, scale = LayerAbove:AbsolutePos(Vector(148, 52, 0))
		frameSize = Vector(728, 920, 0) * scale

	end

	local group_backgroundAttacks = {
		enter = function()

			render.setStencilWriteMask(0xFF)
			render.setStencilTestMask(0xFF)
			render.setStencilReferenceValue(0)
			render.setStencilCompareFunction(STENCIL_ALWAYS)
			render.setStencilPassOperation(STENCIL_KEEP)
			render.setStencilFailOperation(STENCIL_KEEP)
			render.setStencilZFailOperation(STENCIL_KEEP)
			render.clearStencil()
			render.setStencilEnable(true)

			render.setStencilReferenceValue(1)
			render.setStencilPassOperation(STENCIL_REPLACE)
			render.setRGBA(255, 255, 255, 0)
			render.drawRect(framePos[1], framePos[2], frameSize[1], frameSize[2])

			render.setStencilCompareFunction(STENCIL_NOTEQUAL)

		end,
		exit = function()

			render.setStencilEnable(false)

		end
	}

	local trailCount = 3
	local function knockoutTravel(victimID, badgeBits, attackerID)

		local victimCtrl = enemies[victimID]
		local attackerCtrl = enemies[attackerID]
		assert(victimCtrl ~= nil, "attempt to create KO particle from unknown victim " .. tostring(victimID))
		assert(attackerCtrl ~= nil, "attempt to create KO particle to unknown attacker " .. tostring(attackerID))

		local startPos, scale = victimCtrl:AbsolutePos(Vector(victimCtrl.w/2, victimCtrl.h/2, 0))
		local endPos = attackerCtrl:AbsolutePos(Vector(attackerCtrl.w/2, attackerCtrl.h/2, 0))

		local percent = badgeBits / 20
		local size = Vector(48, 48, 0) * scale * (1 + percent)


		for i = 1, trailCount do
			local sizeScale = 1 - (i-1)/trailCount
			gfx.EmitParticle(
				{startPos, endPos},
				{size*sizeScale, size*sizeScale},
				(i - 1)*(2/60), 0.5,
				fx_KnockoutTravel,
				true, true,
				nil, group_backgroundAttacks
			)
		end

	end

	local function garbageTravel(attackerID, damage, targetID)

		if targetID == arena.uniqueID and arena.dead then return end
		local attackerCtrl = enemies[attackerID]
		local targetCtrl = enemies[targetID]

		if attackerCtrl == nil then return end
		local enemySize = Vector(attackerCtrl.w, attackerCtrl.h, 0)
		local attackerPos, scale = attackerCtrl:AbsolutePos(enemySize/2)
		local overlay = false
		if not targetCtrl then
			if targetID ~= arena.uniqueID then
				error("Tried to make garbage anim for unknown target ID " .. tostring(targetID))
			end
			targetCtrl = LayerBelow
			overlay = true
		end
		local targetPos = targetCtrl:AbsolutePos(Vector(targetCtrl.w/2, targetCtrl.h/2, 0))

		local percent = damage / arena.params.maxGarbageOut
		local size = Vector(1, 1, 0) * (32 + 32*percent) * scale

		gfx.EmitParticle(
			{attackerPos, targetPos},
			{size, size},
			0, 0.5,
			fx_AttackTravel,
			true, true,
			nil, not overlay and group_backgroundAttacks
		)

		gfx.EmitParticle(
			{targetPos, targetPos},
			{enemySize*scale, enemySize*scale*1.2},
			0.5, 0.1,
			fx_AttackLand,
			true, true
		)

	end

	arena.hook("playerGarbage", function(attackerID, damage, targets)
	
		for _, targetID in pairs(targets) do

			garbageTravel(attackerID, damage, targetID)

		end

	end)

	arena.hook("playerDie", function(victim, killer, placement, deathFrame, badgeBits)
	
		if enemies[victim] then
			local Ctrl = enemies[victim]

			Ctrl:Kill()

		end
		
		if victim ~= arena.uniqueID and killer ~= arena.uniqueID and killer ~= 0 then

			knockoutTravel(victim, badgeBits, killer)

		end

	end)

	local triggerActions = {
		target_manualPrev = true,
		target_manualNext = true,
		manual_up = true,
		manual_down = true,
		manual_left = true,
		manual_right = true
	}

	local function manualTarget(direction)

		local curTarget = arena.target
		if curTarget == 0 then
			local attackers = arena.attackers
			if #attackers == 0 then return end
			curTarget = attackers[math.random(1, #attackers)]
		end

		if direction == "target_manualPrev" or direction == "target_manualNext" then

			local i = curTarget
			while true do

				i = i + (direction == "target_manualPrev" and -1 or 1)
				if i < 1 or i > 33 then
					i = (i-1)%33+1
				end
				if i == curTarget then return end

				local enemy = arena.arena[i]
				if enemy and not enemy.dead then
					arena:manualTarget(i)
					break
				end

			end

			return

		end

		curTarget = enemies[curTarget]
		if not curTarget then return end
		local list = {}
		local x, y = curTarget.x, curTarget.y
		for id, Ctrl in pairs(enemies) do

			if not Ctrl.enemy.dead then
				local cx, cy = Ctrl.x, Ctrl.y
				local dx, dy = math.abs(cx - x), math.abs(cy - y)
				if	direction == "manual_right" and x < cx then
					table.insert(list, {id, dx + dy*2000})
				elseif direction == "manual_down" and y < cy then
					table.insert(list, {id, dx*2000 + dy})
				elseif direction == "manual_left" and x > cx then
					table.insert(list, {id, dx + dy*2000})
				elseif direction == "manual_up" and y > cy then
					table.insert(list, {id, dx*2000 + dy})
				end
			end

		end

		if #list == 0 then return end

		table.sort(list, function(a, b) return a[2] < b[2] end)
		arena:manualTarget(list[1][1])

	end

	hook.add("action", "enemy", function(button, pressed)
		if triggerActions[button] and pressed then
			manualTarget(button)
		end
	end)

end)

