hook.add("brConnect", "sound", function(game, arena)

	arena.hook("danger", function(danger)
	
		if danger then
			sound.playLooped("se_game_danger")
		else
			sound.fadeLooped("se_game_danger", 0.2)
		end

	end)

	local lastMatch = 0
	local matchDelay = 0.15
	arena.hook("playerConnect", function(who)
		local t = timer.realtime()
		if t >= lastMatch + matchDelay then
			lastMatch = t
			sound.play("se_game_match")
		end
	end)

	function game.badgeBitsUpdate(newCount, oldCount)

		local newBadges, newBits = br.getBadgeCount(newCount)
		local oldBadges, oldBits = br.getBadgeCount(oldCount)

		if newBadges > oldBadges then
			sound.play("se_game_badge")
		end
		if newBits > oldBits then
			sound.play("se_game_badgebit")
		end

	end

	arena.hook("lock", function(tricks, combo, sent, cleared)
	
		sound.play("se_piece_lock")
		if #cleared > 0 then
			local se = "se_game_clear" .. #cleared
			sound.play(se)
		end
		if flagGet(tricks, brix.tricks.TSPIN) or flagGet(tricks, brix.tricks.MINI_TSPIN) or flagGet(tricks, brix.tricks.BACK_TO_BACK) then
			sound.play("se_piece_special")
		end
	
	end)
	
	arena.hook("matrixFall", function()
		sound.play("se_game_fall")
	end)
	
	arena.hook("garbageDump", function()
		-- vibrate
	end)
	
	arena.hook("garbageCancelled", function()
		local n = math.random(1, 2)
		sound.play("se_game_offset" .. n)
	end)
	
	arena.hook("garbageNag", function(second)
		sound.play(second and "se_game_nag2" or "se_game_nag1")
	end)
	
	arena.hook("garbageActivate", function()
		sound.play("se_game_nag1")
	end)
	
	arena.hook("garbageQueue", function(lines)
		local severe = lines > 5
		sound.play(severe and "se_game_damage2" or "se_game_damage1")
	end)
	
	arena.hook("pieceRotate", function()
		sound.play("se_piece_rotate")
	end)
	
	arena.hook("pieceHold", function()
		sound.play("se_piece_hold")
	end)
	
	arena.hook("pieceTranslate", function()
		sound.play("se_piece_translate")
	end)
	
	arena.hook("pieceSoftDrop", function()
		sound.play("se_piece_softdrop")
	end)
	
	arena.hook("pieceHardDrop", function()
		sound.play("se_piece_harddrop")
	end)
	
	arena.hook("pieceLand", function()
		sound.play("se_piece_contact")
	end)

	arena.hook("playerDie", function(victimID, killerID)
	
		if killerID == arena.uniqueID then
			sound.play("se_game_ko1")
		else
			sound.play("se_game_ko2")
		end

	end)

	local lastAttackers = 0
	arena.hook("attackersChanged", function(attackers)

		if arena.dead then return end
		local c = #attackers
		if c ~= lastAttackers then
			if c > 0 then
				sound.play("se_target_warn")
			end
			lastAttackers = c
		end

	end)

	arena.hook("changeTarget", function()
		if arena.dead then return end
		sound.play("se_target_found")
	end)
	
	arena.hook("changeTargetMode", function(mode)
		if arena.dead then return end
		sound.play("se_target_adjust")
	end)

	arena.hook("die", function()
		sound.play("se_game_lose")
	end)

end)
