hook.add("brConnect", "strategy", function(game, arena)

	local HUD = game.controls.HUD

	local Strategy = gui.Create("Strategy", HUD)
	Strategy:SetPos(HUD.w/2, 152)
	Strategy:SetVisible(false)

	arena.hook("changeTargetMode", function(newMode)
	
		Strategy:SetStrategy(newMode)

	end)

	arena.hook("init", function()
	
		Strategy:SetVisible(true)

	end)

end)
