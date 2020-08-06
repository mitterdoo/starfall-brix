-- Countdown timer

hook.add("brCreateGame", "countdown", function(game)

	local root = game.controls.HUD
	local center_x, center_y = root.w/2, root.h/2
	local getReady = gui.Create("Sprite", root)
	getReady:SetSheet(1)
	getReady:SetSprite(65)
	getReady:SetAlign(0, 0)
	getReady:SetPos(center_x, center_y / 2 * 3)
	game.controls.getReady = getReady

	local Timer = gui.Create("LobbyTimer", getReady)
	Timer:SetAlign(0)
	Timer:SetPos(0, 64)
	Timer:SetSize(64, 80)
	game.controls.Timer = Timer

end)
hook.add("brConnect", "countdown", function(game, arena)

	local textSprite, numberSprite
	local root = game.controls.HUD
	local center_x, center_y = root.w/2, root.h/2
	local getReady = game.controls.getReady
	local Timer = game.controls.Timer

	arena.hook("arenaFinalized", function()
		game.controls.BackLabel:SetVisible(false)
	end)

	arena.hook("lobbyTimer", function(t)
		Timer:SetFinish(t)
	end)

	arena.hook("init", function()
	
		if getReady then
			getReady:Remove()
		end

		textSprite = gui.Create("Sprite", root)
		textSprite:SetPos(center_x, center_y)
		textSprite:SetAlign(0, 0)
		textSprite:SetSheet(1)
		textSprite:SetSprite(67)
		textSprite:SetColor(Color(255, 255, 0))

		numberSprite = gui.Create("Number", root)
		numberSprite:SetColor(Color(255, 255, 0))
		numberSprite:SetSize(64, 80)
		numberSprite:SetAlign(0)
		numberSprite:SetPos(center_x, center_y - 40)
		numberSprite:SetVisible(false)

		sound.play("se_start_1")
		local counter = 0
		timer.create("brCountdown" .. math.random(), 1, 6, function()
			counter = counter + 1
			if counter >= 2 and counter <= 4 then
				sound.play("se_start_2")
			end
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
				sound.play("se_start_3")
			elseif counter == 6 then
				numberSprite:Remove()
				textSprite:Remove()
			end
		end)

	end)

	arena.hook("arenaFinalized", function()

		Timer:Remove()
		getReady:SetSprite(66)

	end)

	local function playersRemain(num)

		local start = timer.realtime()

		local ctrl = gui.Create("Control", root)
		ctrl:SetPos(center_x, center_y)
		ctrl:SetScale(0, 0)

		local Ctrl_Count = gui.Create("Number", ctrl)
		Ctrl_Count:SetSize(64, 80)
		Ctrl_Count:SetColor(Color(200, 200, 200))
		Ctrl_Count:SetAlign(0)
		Ctrl_Count:SetValue(num)
		Ctrl_Count:SetPos(0, -80)

		local Ctrl_Label = gui.Create("Sprite", ctrl)
		Ctrl_Label:SetColor(Color(200, 200, 200))
		Ctrl_Label:SetAlign(0, -1)
		Ctrl_Label:SetSheet(1)
		Ctrl_Label:SetSprite(69)

		local duration = 2
		local transition = 0.1

		function ctrl:Think()

			local t = timer.realtime() - start

			if t < transition then
				ctrl:SetScale(1, t/transition)
			elseif t >= duration - transition and t <= duration then
				t = timeFrac(t, duration - transition, duration)
				ctrl:SetScale(1, 1-t)
			elseif t > duration then
				ctrl:Remove()
			elseif ctrl.scale_w ~= 1 then
				ctrl:SetScale(1, 1)
			end

		end

	end

	arena.hook("phaseChange", function()
	
		local playersLeft = arena.remainingPlayers
		playersRemain(playersLeft)

	end)


end)
