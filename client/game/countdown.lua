-- Countdown timer
hook.add("brConnect", "countdown", function(game, arena)

	local textSprite, numberSprite

	arena.hook("init", function()
	
		local root = game.controls.root
		local center_x, center_y = root.w/2, root.h/4

		textSprite = gui.Create("Sprite", root)
		textSprite:SetPos(center_x, center_y)
		textSprite:SetAlign(0, 0)
		textSprite:SetSheet(1)
		textSprite:SetSprite(67)
		textSprite:SetColor(Color(255, 255, 0))

		numberSprite = gui.Create("Number", root)
		numberSprite:SetColor(Color(255, 255, 0))
		numberSprite:SetSize(96, 80)
		numberSprite:SetAlign(0)
		numberSprite:SetPos(center_x, center_y - 40)
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

end)
