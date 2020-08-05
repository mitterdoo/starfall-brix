local SCENE = {}



function SCENE.Open(from)

	
	local root = gui.Create("Control")
	local gw, gh = render.getGameResolution()
	function root:Paint(w, h)
		render.setRGBA(32, 32, 32, 255)
		render.drawRectFast(0, 0, gw, gh)
	end

	local Arena = gui.Create("ArenaControl", root)
	Arena:SetPos(gw/2 - Arena.w/2, gh/2 - Arena.h/2)


		
	hook.add("net", "spectate", function(name, len)
		if name == ARENA.netTag then
			local snapshot = br.decodeServerSnapshot()
			local e = ARENA.serverEvents
			for _, data in pairs(snapshot) do

				local event = data[1]
				if not Arena.Loaded and event == e.UPDATE then
					Arena:Load(data[2])
				elseif Arena.Loaded then
					if event == e.DAMAGE then
						local attacker, lines, victims = data[2], data[3], data[4]
						Arena:SendDamageToPlayers(attacker, lines, victims)
					elseif event == e.DIE then
						local victim, killer, placement, badgeBits, entIndex, nick = data[2], data[3], data[4], data[6], data[7], data[8]					
						Arena:KillPlayerFull(victim, killer, placement, badgeBits, entIndex, nick)
					elseif event == e.MATRIX_PLACE then
						local player, piece, rot, x, y, mono = data[2], data[3], data[4], data[5], data[6], data[7]
						Arena:MatrixPlace(player, piece, rot, x, y, mono)
					elseif event == e.MATRIX_GARBAGE then
						local player, gaps, mono = data[2], data[3], data[4]
						Arena:MatrixGarbage(player, gaps, mono)
					elseif event == e.MATRIX_SOLID then
						local player, lines = data[2], data[3]
						Arena:MatrixGarbageSolid(player, lines)
					end
				end

			end

		end
	end)

	return function()
		hook.remove("net", "spectate")
		root:Remove()
	end

end

scene.Register("Spectate", SCENE)
