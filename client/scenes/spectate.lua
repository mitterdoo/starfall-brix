local SCENE = {}


local backFont = render.createFont("Roboto", 36, 100)
function SCENE.Open(from)

	
	local root = gui.Create("Control")
	local gw, gh = render.getGameResolution()
	root:SetSize(gw, gh)

	local Background = gui.Create("Background", root)
	Background:SetSize(render.getGameResolution())

	local SpectateLabel = gui.Create("Sprite", root)
	SpectateLabel:SetSheet(2)
	SpectateLabel:SetSprite(sprite.sheets[2].spectating)
	SpectateLabel:SetAlign(0, -1)
	SpectateLabel:SetPos(gw/2, 8)

	local Arena = gui.Create("ArenaControl", root)
	Arena:SetPos(gw/2 - Arena.w/2, gh/2 - Arena.h/2)

	local BackLabel = gui.Create("ActionLabel", root)
	BackLabel:SetPos(8, root.h - 8)
	BackLabel:SetAlign(-1, 1)
	BackLabel:SetFont(backFont)
	BackLabel:SetText("{ui_cancel} Main Menu")

	local BackButton = gui.Create("Button", root)
	BackButton:SetVisible(false)
	BackButton:SetHotAction("ui_cancel")
	function BackButton:DoPress()
		if BackLabel.visible then
			scene.Open("Title", 1)
		end
	end

	local function gameOver()

		local PlayLabel = gui.Create("ActionLabel", root)
		PlayLabel:SetPos(root.w - 8, root.h - 8)
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

	local levelTimerStart
	local levelDuration = 20
	local lastLevel

	local curPlayers = {}

	hook.add("net", "spectate", function(name, len)
		if name == ARENA.netTag then
			local snapshot = br.decodeServerSnapshot()
			local e = ARENA.serverEvents
			for _, data in pairs(snapshot) do

				local event = data[1]
				if not Arena.Loaded and event == e.UPDATE then
					Arena:Load(data[2])
					Arena.finalized = true
				elseif Arena.Loaded then
					if event == e.DAMAGE then
						local attacker, lines, victims = data[2], data[3], data[4]
						Arena:SendDamageToPlayers(attacker, lines, victims)
					elseif event == e.DIE then
						local victim, killer, placement, badgeBits, entIndex, nick = data[2], data[3], data[4], data[6], data[7], data[8]
						sound.play("se_game_ko2")
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
					elseif event == e.CHANGEPHASE then
						if data[2] == 1 then
							levelTimerStart = timer.realtime()
						end
					elseif event == e.WINNER then
						hook.remove("think", "spectate")
						hook.remove("net", "spectate")
						gameOver()
					end
				end

			end

		elseif name == ARENA.netConnectTag then

			local e = ARENA.connectEvents
			local event = net.readUInt(3)
			if event == e.UPDATE then
				Arena.Loaded = true
				local lobbyTimer = net.readFloat()
				local playerCount = net.readUInt(6)
				local players = {}
				for i = 1, playerCount do
					table.insert(players, net.readUInt(6))
				end

				local newPlayers, dcPlayers = table.delta(curPlayers, players)
				curPlayers = players

				for k, v in pairs(newPlayers) do
					Arena:AddPlayer(v)
				end

				for k, v in pairs(dcPlayers) do
					Arena:RemovePlayer(v)
				end

				local finalized = net.readBit() == 1
				if finalized and not Arena.finalized then
					Arena.finalized = true
					for id, Ctrl in pairs(Arena.Enemies) do
						Arena:CreatePlayerEnemy(id)
					end
				end

			elseif event == e.READY then
				if Arena.Loaded and not Arena.finalized then
					Arena.finalized = true
					for id, Ctrl in pairs(Arena.Enemies) do
						Arena:CreatePlayerEnemy(id)
					end
				end

			elseif event == e.NO_SERVER then
				scene.Open("Title", 0.5)

			elseif event == e.UPDATE_ONGOING then
				-- do nothing; just catch the next fullupdate
			end

		end
	end)

	net.start(ARENA.netConnectTag)
	net.writeUInt(ARENA.netConnectEvents.REQUEST, 2)
	net.send()

	hook.add("think", "spectate", function()

		if levelTimerStart then
			local t = timer.realtime() - levelTimerStart
			local level = math.floor((t+levelDuration/2) / levelDuration) + 1
			if level ~= lastLevel then
				lastLevel = level
				Background:SetLevel(level)
			end
		end

	end)

	return function()
		hook.remove("net", "spectate")
		hook.remove("think", "spectate")
		root:Remove()

		gfx.KillAllParticles()
	end

end

scene.Register("Spectate", SCENE)
