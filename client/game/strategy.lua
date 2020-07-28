hook.add("brConnect", "strategy", function(game, arena)

	local HUD = game.controls.HUD
	local Background = game.controls.Field_UnderMatrix

	local field_x, field_bottom, brickSize = unpack(sprite.sheets[3].field_main)


	local Strategy = gui.Create("Strategy", Background)
	Strategy:SetPos(0, -brickSize*20)
	Strategy.foreground = false
	game.controls.Strategy = Strategy

	-- Define functions to call when this HUD element switches between foreground and background
	local function requestLayerChange(foreground)

		if foreground then
			Strategy:SetPos(field_x, field_bottom - brickSize*20)
			Strategy:SetParent(HUD)
		else
			Strategy:SetPos(0, -brickSize*20)
			Strategy:SetParent(Background)
		end
	end


	Strategy:SetSize(brickSize*10, brickSize*4)
	Strategy.RequestLayerChange = requestLayerChange
	Strategy:SetVisible(false)

	arena.hook("changeTargetMode", function(newMode)
	
		if arena.dead then return end
		Strategy:SetStrategy(newMode)

	end)

	arena.hook("init", function()
	
		Strategy:SetVisible(true)

	end)

end)
