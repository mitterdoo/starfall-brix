hook.add("brConnect", "enemy", function(game, arena)

	local AttackerOutlines = {}
	local TargetReticles = {}

	local WatchOutFlashDuration = 1
	local LastWatchOutFlash = 0

	local LastAttackerCount = 0

	local LayerAbove = game.controls.Attacks_Above
	local LayerBelow = game.controls.Attacks_Below

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

	local ArenaCtrl = gui.Create("ArenaControl", LayerBelow)
	ArenaCtrl.backgroundAttackGroup = group_backgroundAttacks
	
	local spr_attacker = sprite.sheets[1].enemy_outline

	local lookup = sprite.sheets[3]
	function ArenaCtrl:GetEnemyPos(id)
		if id > arena.uniqueID then
			id = id - 1
		end
		if id < 1 or id > 32 then
			error("Cannot get enemy pos for ID " .. tostring(id))
		end
		return unpack(lookup[id])
	end

	function ArenaCtrl:GetFieldCenter()

		local pos = LayerBelow:AbsolutePos(Vector(LayerBelow.w/2, LayerBelow.h/2, 0))
		return pos

	end


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
	ArenaCtrl._Think = ArenaCtrl.Think
	function ArenaCtrl:Think()

		self:_Think()
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
			local Enemy = ArenaCtrl.Enemies[id]
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

		local Enemy = ArenaCtrl.Enemies[enemyID]
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

		local Enemy = ArenaCtrl.Enemies[enemyID]
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
						Ctrl:Remove()
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
		ArenaCtrl:AddPlayer(who)

	end)

	arena.hook("playerDisconnect", function(who)
		if who == arena.uniqueID then return end
		ArenaCtrl:RemovePlayer(who)
	end)

	arena.hook("arenaFinalized", function()
	
		for id, enemy in pairs(arena.arena) do
			ArenaCtrl:SetPlayerEnemy(id, enemy)
		end

	end)

	arena.hook("badgeBits", function(count, sourceID)
	
		if arena.dead then return end
		if ArenaCtrl.Enemies[sourceID] then
			local enemy = ArenaCtrl.Enemies[sourceID]
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

	local brickSize = sprite.sheets[3].field_main[3]

	arena.hook("garbageSend", function(lines)
	
		local targets
		if arena.target == 0 then
			targets = arena.attackers
		else
			targets = {arena.target}
		end

		local center = game.controls.LineClearCenter
		local centerX = center:AbsolutePos(0, 0)
		local startLeft = center:AbsolutePos(Vector(-brickSize, 0, 0) * 2)
		local startRight = center:AbsolutePos(Vector(brickSize, 0, 0) * 2)

		local badges = br.getBadgeCount(arena.badgeBits)

		for _, id in pairs(targets) do

			local enemy = ArenaCtrl.Enemies[id]
			local endPos, _ = enemy:AbsolutePos(Vector(enemy.w/2, enemy.h/2, 0))
			local startPos = endPos.x < centerX and startLeft or startRight
			ArenaCtrl:OutgoingDamage(badges, lines, id, startPos)

		end

	end)

	arena.hook("playerGarbage", function(attackerID, damage, targets)
		local targs = {}
		for k,v in pairs(targets) do
			if v == arena.uniqueID then
				targs[k] = 0
			else
				targs[k] = v
			end
		end
		ArenaCtrl:SendDamageToPlayers(attackerID, damage, targs)
	end)

	arena.hook("playerDie", function(victim, killer, placement, deathFrame, badgeBits, entIndex, nick)
		ArenaCtrl:KillPlayer(victim, killer, placement, badgeBits, entIndex, nick)
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

		curTarget = ArenaCtrl.Enemies[curTarget]
		if not curTarget then return end
		local list = {}
		local x, y = curTarget.x, curTarget.y
		for id, Ctrl in pairs(ArenaCtrl.Enemies) do

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

