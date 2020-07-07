-- Countdown timer
hook.add("brConnect", "countdown", function(game, arena)

	local textSprite, numberSprite
	local root = game.controls.root
	local center_x, center_y = root.w/2, root.h/2
	local getReady = gui.Create("Sprite", root)
	getReady:SetSheet(1)
	getReady:SetSprite(65)
	getReady:SetAlign(0, 0)
	getReady:SetPos(center_x, center_y / 2 * 3)

	arena.hook("init", function()
	
		if getReady then
			getReady:Remove()
		end

		textSprite = gui.Create("Sprite", root)
		textSprite:SetPos(center_x, center_y/2)
		textSprite:SetAlign(0, 0)
		textSprite:SetSheet(1)
		textSprite:SetSprite(67)
		textSprite:SetColor(Color(255, 255, 0))

		numberSprite = gui.Create("Number", root)
		numberSprite:SetColor(Color(255, 255, 0))
		numberSprite:SetSize(96, 80)
		numberSprite:SetAlign(0)
		numberSprite:SetPos(center_x, center_y/2 - 40)
		numberSprite:SetVisible(false)

		local counter = 0
		timer.create("brCountdown" .. math.random(), 1, 6, function()
			counter = counter + 1
			if counter == 2 then
				textSprite:SetVisible(false)
				numberSprite:SetVisible(true)
				numberSprite:SetValue(3)
			elseif counter == 3 then
				numberSprite:SetValue(2)
			elseif counter == 4 then
				numberSprite:SetValue(1)
			elseif counter == 5 then
				numberSprite:SetVisible(false)
				textSprite:SetVisible(true)
				textSprite:SetSprite(68)
			elseif counter == 6 then
				numberSprite:Remove()
				textSprite:Remove()
			end
		end)

	end)

	arena.hook("arenaFinalized", function()

		getReady:SetSprite(66)

	end)

end)
