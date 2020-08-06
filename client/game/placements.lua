local backFont = render.createFont("Roboto", 36, 100)
hook.add("brConnect", "placements", function(game, arena)

	local Placements = gui.Create("Placements", game.controls.HUD)
	Placements:SetVisible(false)
	local w, h = game.controls.HUD:GetSize()
	local pw, ph = 600, 968
	Placements:SetPos(w / 2 - pw/2, h / 2 - ph/2)

	arena.hook("arenaFinalized", function()
		Placements:SetMaxPlacement(arena.playerCount)
		Placements:SetSize(pw, ph)
	end)
	arena.hook("gameover", function(reason)
	
		timer.simple(2, function()
			game.controls.Board:Remove()
			game.controls.RT:Remove()
			game.controls.NextPieceRT:Remove()
			game.controls.Garbage:Remove()
			game.controls.Scoreboard:Remove()
			game.controls.Strategy:Remove()
			Placements:SetVisible(true)
			game.controls.BackLabel:SetVisible(true)


		end)

	end)

	arena.hook("disconnect", function(auto)
		if auto then

			local PlayLabel = gui.Create("ActionLabel", game.controls.HUD)
			PlayLabel:SetPos(w - 8, h - 8)
			PlayLabel:SetAlign(1, 1)
			PlayLabel:SetFont(backFont)
			PlayLabel:SetText("{ui_accept} Join Next Match")

			local PlayButton = gui.Create("Button", root)
			PlayButton:SetVisible(false)
			PlayButton:SetHotAction("ui_accept")
			function PlayButton:DoPress()
				scene.Open("Game", 1)
			end
		
		end
	end)

	arena.hook("finalPlace", function(place)
	
		Placements:SetPlacement(place)
		Placements:AddPlacement(place, player():getName(), "us")
		Placements:ScrollTo(place)

	end)

	arena.hook("playerDie", function(victim, killer, placement, deathFrame, bits, plyInd, nick)
	
		Placements:AddPlacement(placement, nick, killer == arena.uniqueID and "ko")

	end)

	arena.hook("winnerDeclared", function(player, entIndex, nick)

		Placements:AddPlacement(1, nick)

	end)

end)
