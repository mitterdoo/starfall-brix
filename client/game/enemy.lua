local function fx_AttackTravel(x, y, w, h, frac, glow)

	render.setRGBA(255, 255, 255, 255)
	if glow then
		render.drawRectFast(x - w/2, y - h/2, w*2, h*2)
	else
		render.drawRectFast(x, y, w, h)
	end

end

hook.add("brConnect", "enemy", function(game, arena)

	local enemies = {}
	game.controls.Enemies = enemies

	local LayerAbove = game.controls.Attacks_Above
	local LayerBelow = game.controls.Attacks_Below

	arena.hook("arenaFinalized", function()
	
		local i = 0
		for id, enemy in pairs(arena.arena) do

			i = i + 1
			local Ctrl = gui.Create("Enemy", LayerBelow)
			Ctrl:SetPos(0, i * 130)
			Ctrl:SetEnemy(enemy)
			Ctrl:SetField(enemy.matrix)
			enemies[id] = Ctrl

		end

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


end)

