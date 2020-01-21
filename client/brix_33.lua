--@name BRIX 33
--@author mitterdoo
--@shared

--@include brix/br/arena_cl.lua
--@include brix/br/arena_sv.lua
--@include xinput_nooverlap.txt


local _print = print
function print(...)
	_print(CLIENT and "<client> " or "<server> ", ...)
end

require"brix/br/arena_cl.lua"

HIGH_SENSITIVITY = player() == owner()
require("xinput_nooverlap.txt")

local rtIdx = 0


local function lerp(perc, from, to)

	if perc > 1 then return to end
	if perc < 0 then return from end
	return from + (to - from) * perc

end

local function lerp2d(perc, x1, y1, x2, y2)
	return lerp(perc, x1, x2), lerp(perc, y1, y2)
end

function createGame(game)
	
	
	
	local function drawBlock(idx, x, y, size, ghost)
	
		--render.setRGBA(255, 255, 255, 255)
		--sprite.setSheet(1)
		if idx == 9 then -- solid garbage
			idx = sprite.sheets[1].garbageSolid
		elseif idx == 8 then
			idx = sprite.sheets[1].garbage
		elseif idx == 10 then
			idx = ghost and sprite.sheets[1].classicPieceGhost or sprite.sheets[1].classicPiece
		elseif ghost then
			idx = sprite.sheets[1].pieceGhosts + idx
		else
			idx = sprite.sheets[1].pieces + idx
		end
		
		sprite.draw(idx, x, y - size, size, size)
	
	end
	
	local function drawPiece(idx, x, y, rot, size, ghost, override)
	
		local mono = bit.band(idx, 0x8) > 0
		idx = brix.normalPiece(idx)
		if mono then override = 10 end
		
		render.setRGBA(255, 255, 255, 255)
		sprite.setSheet(1)
		local data = brix.pieces[idx]
		idx = override or idx
		for oy = 0, data.size - 1 do
			for ox = 0, data.size - 1 do
				local i = brix.getShapeIndex(ox, oy, rot, data.size)
				if data.shape[i] == "x" then
					drawBlock(idx, x + ox * size, y - oy * size, size, ghost)
				end
			end
		end
	
	end
	
	--[[
	local levelTime = 10
	local nextLevel = levelTime
	function game:levelUpCheck()
		if self.frame >= nextLevel * 60 then
			nextLevel = self.frame/60 + levelTime

			return true
		end
	end]]
	
	
	local rt = "gamert" .. rtIdx
	rtIdx = rtIdx + 1
	render.createRenderTarget(rt)


	
	local function renderGame()
	
		render.selectRenderTarget(rt)
		render.clear(Color(0, 0, 0, 0), false)
	
		render.setRGBA(255, 255, 255, 255)
		sprite.setSheet(3)
		sprite.draw(sprite.sheets[3].field, 0, 0, 1024, 1024)
		
		local matrix_x, matrix_y, matrix_size = unpack(sprite.sheets[3].field_main)
		local held_x, held_y, held_size = unpack(sprite.sheets[3].field_hold)
		local next_x, next_y, next_size = unpack(sprite.sheets[3].field_next)
		
		sprite.setSheet(1)
		
		-- next
		for i = 1, 5 do
			
			local p = game.pieceQueue[i]
			if p then
				local wide = next_size * brix.pieces[brix.normalPiece(p)].size
				drawPiece(p, next_x + next_size*2 - wide/2, next_y - (5 - i) * next_size * 4 - next_size*2 + wide/2, 0, next_size, false)
			end
		
		end

		if game.danger then
			render.setRGBA(255, 0, 0, 32)
			render.drawRect(matrix_x, matrix_y - 20 * matrix_size, matrix_size*10, matrix_size*20)
		end
		sprite.setSheet(1)
		
		-- field
		render.setRGBA(190, 190, 190, 255)

		local clipX1, clipY1, clipX2, clipY2 = unpack(sprite.sheets[3].field_main_clip)
		clipX2 = clipX1 + clipX2 -- x2 is width
		clipY2 = clipY1 + clipY2 -- y2 is height
		render.enableScissorRect(clipX1, clipY1, clipX2, clipY2)
		for oy = 0, brix.h do
		
			local row = game.matrix:getrow(oy)
			for i = 1, #row do
				local block = row[i]
				local ox = i-1
				
				local block_x, block_y = matrix_x + ox * matrix_size, matrix_y - oy * matrix_size
				if block == "!" then
					drawBlock(8, block_x, block_y, matrix_size)
				elseif block == "=" then
					drawBlock(9, block_x, block_y, matrix_size)
				elseif block == "[" then
					drawBlock(10, block_x, block_y, matrix_size)
				elseif tonumber(block) then
					drawBlock(tonumber(block), block_x, block_y, matrix_size)
				end
			end
		
		end
		render.disableScissorRect()
		
		-- piece
		local piece = game.currentPiece
		if piece.piece then
			
			local x, y = game:getFallLocation()
			if x then
				drawPiece(piece.type, matrix_x + x * matrix_size, matrix_y - y * matrix_size, piece.rot, matrix_size, true)
			end
		
			drawPiece(piece.type, matrix_x + piece.x * matrix_size, matrix_y - piece.y * matrix_size, piece.rot, matrix_size)
			
		end
		
		-- held
		if game.held > -1 then
			local wide = brix.pieces[brix.normalPiece(game.held)].size * held_size
			drawPiece(game.held, held_x + held_size*2 - wide/2, held_y - held_size*2 + wide/2, 0, held_size, false, mono or game.heldThisPhase and 8)
		end
		

		local fullBadges, partialBadges = br.getBadgeCount(game.badgeBits)
		local totalBadges = fullBadges + partialBadges

		local statX, statY, statW, statH = unpack(sprite.sheets[3].arena_stats)
		local bx, by, bsize = statX, statY + statH/2, statW/2

		for i = 1, math.ceil(totalBadges) do

			local xpos = (i-1) % 2
			local ypos = math.floor((i-1) / 2)

			local index = math.min(1, totalBadges - i + 1) * 16 - 1
			local badgeSprite = sprite.sheets[1].badgeBits + index
			sprite.draw(badgeSprite, bx + xpos*bsize, by + ypos*bsize, bsize, bsize)

		end
		
		
		render.selectRenderTarget()
		
	end
	
	local enemyRT = {}

	for i = 1, 14 do
		enemyRT[i] = "brixEnemy" .. i
		render.createRenderTarget(enemyRT[i])
	end
	local GAME = {}

	local function renderEnemy(enemy)

		local thisRT = enemy.RT
		render.selectRenderTarget(thisRT)
		render.clear(Color(0, 0, 0, 0), false)

		
		local w, h = 64, 128

		local matrix_x, matrix_y = 2, h - 2
		local matrix_size = (w-4)/10

		sprite.setSheet(1)
		render.setRGBA(255, 255, 255, 255)
		sprite.draw(sprite.sheets[1].enemy, 0, 0, 64, 128)

		if enemy.danger > 0 then
			render.setRGBA(255, 0, 0, 32)
			render.drawRectFast(0, 0, 64, 128)
		end
		sprite.setSheet(1)
		render.setRGBA(190, 190, 190, 255)
		for oy = 0, brix.h - 1 do
		
			local row = enemy.matrix:getrow(oy)
			for i = 1, #row do
				local block = row[i]
				local ox = i-1

				local block_x, block_y = matrix_x + ox * matrix_size, matrix_y - oy * matrix_size

				if block == "!" then
					drawBlock(8, block_x, block_y, matrix_size)
				elseif block == "=" then
					drawBlock(9, block_x, block_y, matrix_size)
				elseif block == "[" then
					drawBlock(10, block_x, block_y, matrix_size)
				elseif tonumber(block) then
					drawBlock(tonumber(block), block_x, block_y, matrix_size)
				end
			end
		
		end


		local fullBadges, partialBadges = br.getBadgeCount(enemy.badgeBits)
		local totalBadges = fullBadges + partialBadges
		local bx, by, bsize = matrix_x + matrix_size, matrix_y - matrix_size*20, matrix_size*2 

		for i = 1, math.ceil(totalBadges) do

			local xpos = (i-1)

			local index = math.min(1, totalBadges - i + 1) * 16 - 1
			local badgeSprite = sprite.sheets[1].badgeBits + index
			sprite.draw(badgeSprite, bx + xpos*bsize, by, bsize, bsize)

		end

		render.selectRenderTarget()

	end
	-- Returns pixel coords for uniqueID
	local function getEnemyPos(uniqueID, gx, gy, gw, gh)
		local scale = gw / 1024
		if uniqueID > GAME.game.uniqueID then
			uniqueID = uniqueID - 1
		end
		local start = sprite.sheets[3].enemy
		local index = start + uniqueID - 1

		local x, y, w, h = unpack(sprite.sheets[3][index])
		
		return gx + x * scale,
			gy + y * scale,
			w * scale,
			h * scale
	end

	local function drawEnemy(enemy, gx, gy, gw, gh)

		local x, y, w, h = getEnemyPos(enemy.uniqueID, gx, gy, gw, gh)


		sprite.setSheet(1)
		render.setRGBA(255, 255, 255, 255)
		if enemy.dead then
			local thisSprite = enemy.killedByUs and sprite.sheets[1].ko_us or sprite.sheets[1].ko
			sprite.draw(thisSprite, x, y + h/4, w, w)
			render.setFont("DermaLarge")
			render.drawText(x + w/2, y + h/4*3, tostring(enemy.placement), 1)
		else

			render.setRenderTargetTexture(enemy.RT)
			render.drawTexturedRectUV(x, y, w, h, 0, 0, 64/1024, 128/1024)

		end

		return x, y, w, h


	end

	GAME.game = game
	GAME.garbageOther = {}
	GAME.garbageUs = {}
	GAME.garbageSent = {}
	local dieTime
	local lastFrame = -2
	function GAME.draw(x, y, w, h, frame)
	
		render.setRGBA(128, 128, 128, 255)
		render.drawRect(x, y, w, h)
		if lastFrame == -2 then
			renderGame()
			lastFrame = -1
		end
		
		if not game.dead then
			
			if frame then
				render.setRGBA(255, 0, 0, 255)
				render.setFont("DermaLarge")
				render.drawText(96, h / 3 * 2, tostring(math.ceil(frame)), 1)
				game:update(frame)
			end
			
			if game.frame ~= lastFrame then
				lastFrame = game.frame
				renderGame()
			end

			for id, enemy in pairs(game.arena) do
				if enemy.matrix.invalid then
					enemy.matrix.invalid = false
					renderEnemy(enemy)
				end
			end
			
		end
		
		local watchout_x, watchout_y = x + w / 2, y + h - 48
		local attackers = {}
		if #game.attackers > 0 then

			render.setRGBA(255, 0, 0, 255)
			render.setFont("DermaLarge")
			render.drawText(watchout_x, watchout_y, "WATCH OUT!", 1)

			for _, id in pairs(game.attackers) do
				attackers[id] = true
			end

		end


		for id, enemy in pairs(game.arena) do

			local ex, ey, ew, eh = drawEnemy(enemy, x, y, w, h)
			if not enemy.dead then
				if game.target == id or game.target == 0 and attackers[id] then
					render.setRGBA(255, 0, 255, 64)
					render.drawRect(ex - 8, ey - 8, ew + 16, eh + 16)
				end

				render.setRGBA(255, 255, 255, 255)
				if attackers[id] then
					render.setRGBA(255, 255, 0, 255)
					render.drawLine(watchout_x, watchout_y, ex + ew/2, ey + eh)
				end

			end
				
		end

		
		
		render.setRGBA(255, 255, 255, 255)
		local toRemove = {}
		for k, garbage in pairs(GAME.garbageOther) do
			if garbage.finish < frame then
				table.insert(toRemove, k)
			else

				local percent = (frame - garbage.start) / (garbage.finish - garbage.start)
				local fromX, fromY, fromW, fromH = getEnemyPos(garbage.attacker, x, y, w, h)
				local toX, toY, toW, toH = getEnemyPos(garbage.victim, x, y, w, h)
				fromX = fromX + fromW / 2
				fromY = fromY + fromH / 2
				toX = toX + toW / 2
				toY = toY + toH / 2

				local garbageX, garbageY = lerp2d(percent, fromX, fromY, toX, toY)
				local size = 20 + garbage.lines
				render.drawRect(garbageX - size/2, garbageY - size/2, size, size)

			end
		end
		for i = 1, #toRemove do
			table.remove(GAME.garbageOther, toRemove[i] - i + 1)
		end


		
		local height = h
		if dieTime then
			height = h * (1 - (timer.realtime() - dieTime) / 4)
			height = math.max(0, height)
		end
		render.setRGBA(255, 0, 255, 255)
		render.setRenderTargetTexture(rt)
		render.setRGBA(255, 255, 255, 255)
		render.drawTexturedRectUV(x, y, w, height, 0, 0, 1, height/h)


		if GAME.game.selfEnemy.matrix.invalid then
			GAME.game.selfEnemy.matrix.invalid = false
			renderEnemy(GAME.game.selfEnemy)
		end
		render.setRenderTargetTexture(GAME.game.selfEnemy.RT)
		render.drawTexturedRectUV(x + w, y, 128, 256, 0, 0, 64/1024, 128/1024)
		
		if not dieTime then
		
			sprite.setSheet(1)
			local garbage_x, garbage_y, garbage_size = unpack(sprite.sheets[3].field_garbage)
			local scaleW, scaleH = w / 1024, h / 1024
			garbage_x = x + garbage_x * scaleW
			garbage_y = y + garbage_y * scaleH
			-- garbage
			local ypos = 0
			for cluster = 1, #game.garbage do
			
				local g = game.garbage[cluster]
				if g.stage == 2 then
					render.setRGBA(255, (timer.realtime() % 0.2 > 0.1) and 255 or 0, 0, 255)
				elseif g.stage == 1 then
					render.setRGBA(255, 0, 0, 255)
				else
					render.setRGBA(255, 255, 0, 255)
				end
				
				for i = 1, g.lines do
					drawBlock(8, garbage_x, garbage_y - ypos, garbage_size)
					ypos = ypos + garbage_size
				end
				ypos = ypos + garbage_size / 8
			
			end
		
		end

		
		
		render.setRGBA(255, 255, 255, 255)
		toRemove = {}
		for k, garbage in pairs(GAME.garbageUs) do
			if garbage.finish < frame then
				table.insert(toRemove, k)
			else

				local percent = (frame - garbage.start) / (garbage.finish - garbage.start)
				local fromX, fromY, fromW, fromH = getEnemyPos(garbage.attacker, x, y, w, h)
				local toX, toY = x + w/2, y + w/2
				fromX = fromX + fromW / 2
				fromY = fromY + fromH / 2

				local garbageX, garbageY = lerp2d(percent, fromX, fromY, toX, toY)
				local size = 20 + garbage.lines
				render.drawRect(garbageX - size/2, garbageY - size/2, size, size)

			end
		end
		for i = 1, #toRemove do
			table.remove(GAME.garbageUs, toRemove[i] - i + 1)
		end
		
		render.setRGBA(255, 255, 0, 255)
		toRemove = {}
		for k, garbage in pairs(GAME.garbageSent) do
			if garbage.finish < frame then
				table.insert(toRemove, k)
			else

				local percent = (frame - garbage.start) / (garbage.finish - garbage.start)
				local fromX, fromY = x + w/2, y + h/2
				local toX, toY, toW, toH = getEnemyPos(garbage.victim, x, y, w, h)
				toX = toX + toW / 2
				toY = toY + toH / 2

				local garbageX, garbageY = lerp2d(percent, fromX, fromY, toX, toY)
				local size = 20 + garbage.lines*2
				render.drawRect(garbageX - size/2, garbageY - size/2, size, size)

			end
		end
		for i = 1, #toRemove do
			table.remove(GAME.garbageSent, toRemove[i] - i + 1)
		end
		
		
	end

	game.hook("arenaFinalized", function()
	
		local i = 1
		for id, enemy in pairs(game.arena) do
			if i > 14 then
				error("Too many players to make rendertargets!")
			end
			enemy.RT = enemyRT[i]
			print("player", id, enemy.RT)
			i = i + 1
		end
		game.selfEnemy.RT = enemyRT[i]
		print("Created " .. (i - 1) .. " rendertargets")

		lastFrame = -1

	end)
		
	game.hook("pieceSpawn", function()
	
		local id = game.pieceQueue[1]
		id = brix.normalPiece(id)
	
	end)
	
	
	game.hook("lock", function(tricks, combo, sent, cleared)
	
		sound.play("se_piece_lock")
		if #cleared > 0 then
			sound.play("se_game_clear")
		end
		if flagGet(tricks, brix.tricks.TSPIN) or flagGet(tricks, brix.tricks.MINI_TSPIN) or flagGet(tricks, brix.tricks.QUAD) then
			sound.play("se_piece_special")
			if flagGet(tricks, brix.tricks.TSPIN) then
				print("TSPIN")
			elseif flagGet(tricks, brix.tricks.MINI_TSPIN) then
				print("MINI TSPIN")
			end
		end
	
	end)
	
	game.hook("matrixFall", function()
		sound.play("se_game_fall")
	end)
	
	game.hook("garbageDump", function()
		-- vibrate
	end)
	
	game.hook("garbageCancelled", function()
		local n = math.random(1, 2)
		sound.play("se_game_offset" .. n)
	end)
	
	game.hook("garbageNag", function(second)
		sound.play(second and "se_game_nag2" or "se_game_nag1")
	end)
	
	game.hook("garbageActivate", function()
		sound.play("se_game_nag1")
	end)
	
	game.hook("garbageQueue", function(lines)
		local severe = lines > 5
		sound.play(severe and "se_game_damage2" or "se_game_damage1")
	end)
	
	game.hook("pieceRotate", function()
		sound.play("se_piece_rotate")
	end)
	
	game.hook("pieceHold", function()
		sound.play("se_piece_hold")
	end)
	
	game.hook("pieceTranslate", function()
		sound.play("se_piece_translate")
	end)
	
	game.hook("pieceSoftDrop", function()
		sound.play("se_piece_softdrop")
	end)
	
	game.hook("pieceHardDrop", function()
		sound.play("se_piece_harddrop")
	end)
	
	game.hook("pieceLand", function()
		sound.play("se_piece_contact")
	end)

	game.hook("playerDie", function(victimID, killerID)
	
		if killerID == game.uniqueID then
			sound.play("se_game_ko1")
		else
			sound.play("se_game_ko2")
		end

	end)

	local lastAttackers = 0
	game.hook("attackersChanged", function(attackers)

		local c = #attackers
		if c ~= lastAttackers then
			if c > 0 then
				sound.play("se_target_warn")
			end
			lastAttackers = c
		end

	end)

	game.hook("changeTarget", function()
	
		sound.play("se_target_found")

	end)

	game.hook("phaseChange", function(phase)
	
		print("Remaining: " .. tostring(game.remainingPlayers) .. " player(s)!")

	end)

	game.hook("changeTargetMode", function(mode)
		sound.play("se_target_adjust")
	end)

	game.hook("garbageSend", function(lines)
	
		local targets = {game.target}
		if game.target == 0 then
			targets = game.attackers
		end

		lines = math.ceil(lines / #targets)

		for _, id in pairs(targets) do
			print("CLIENT send garbage", game.uniqueID, id, lines)
			table.insert(GAME.garbageSent, {
				start = game.frame,
				finish = game.frame + ARENA.garbageSendDelay,
				victim = id,
				lines = lines
			})
		end

	end)
	

	game.hook("playerGarbage", function(attacker, lines, victims)

		if attacker == game.uniqueID then return end
		local frame = game.frame
		for _, id in pairs(victims) do
			local tab = id == game.uniqueID and GAME.garbageUs or GAME.garbageOther
			table.insert(tab, {
				start = frame,
				finish = frame + ARENA.garbageSendDelay,
				attacker = attacker,
				lines = lines,
				victim = id
			})
		end

	end)
	
	game.hook("die", function()
		--GAME.snd:stop()
		sound.play("se_game_lose")
		dieTime = timer.realtime()
	end)
	
	
	return GAME
	
end

	function makeHUD(arenaObj)

		local GAME = createGame(arenaObj)
		local hookName = "brixClient" .. math.random(2^31-1)
		lastDraw = -1

		GAME.game.hook("finish", function()
		
			hook.remove("calcview", hookName)
			hook.remove("inputPressed", hookName)
			hook.remove("inputReleased", hookName)
			hook.remove("xinputStick", hookName)
			hook.remove("brixPressed", hookName)
			hook.remove("brixReleased", hookName)

		end)
		
		hook.add("calcview", hookName, function()
			if GAME.game.started and not GAME.game.diedAt then
			
				return {
					origin = Vector(0, 0, -128000),
					angles = Angle(-90, 0, 0),
					fov = 45,
					znear = 10,
					zfar = 100
				}
			
			end
		end)

		
		local curPending = 0
		hook.add("net", hookName, function(name)
			if name ~= "brix_debug" then return end
			local count = net.readUInt(6)
			for i = 1, count do
				local id, pending = net.readUInt(6), net.readUInt(8)
				if id == GAME.game.uniqueID then
					curPending = pending
					break
				end
			end
		end)

		hook.add("postdrawhud", "", function()
		
			local t = timer.realtime()

			render.setFont("DermaLarge")
			render.setRGBA(255, 255, 0, 255)
			render.drawText(0, 12, "Pending snapshots: " .. tostring(curPending), 0)

			local frame
			if GAME.game.started then
				frame = brix.getFrame(t - GAME.game.startTime)
			end

			local w, h = render.getGameResolution()
			
			GAME.draw(w/4, h/2 - w/4, w/2, w/2, frame)
			--games[1].draw(1920/2, 0, 1920/2, 1920/2, t)
			
			render.setFont("DermaLarge")
			render.setRGBA(255, 255, 255, 255)
			render.drawText(96, h/2, "LEVEL\n" .. GAME.game.level, 1)
			render.drawText(96, h/3, tostring(GAME.game.frame), 1)
			
			local perc = math.ceil( quotaAverage() / quotaMax() * 1000 ) / 10
			
			render.drawText(w - 96, h/2, perc .. "%", 1)
			render.drawText(w - 96, h/2 + 24, "Players: " .. tostring(GAME.game.remainingPlayers) .. "/" .. tostring(GAME.game.playerCount), 1)


			
			local timers = GAME.game.timers
			local i = 0
			for name, finish in pairs(timers) do
				render.drawText(96, h / 6 * 1 + 24*i, name .. ": " .. finish, 0)
				i = i + 1
			end

			
			if GAME.game.startTime then
				local countdown = math.ceil(GAME.game.startTime - timer.realtime())
				if countdown > 0 then
					render.setFont("Trebuchet24")
					render.drawText(w/2, h/2, "Start: " .. tostring(countdown), 1)
				end
			end
			
			lastDraw = timer.realtime()
			--render.drawText(1920 - 96, 1080/2, "LEVEL\n" .. games[1].game.level, 1)
		
		end)
		

		
		local inputMap2 = {
		
			[33] = brix.inputEvents.HARDDROP,
			[65] = brix.inputEvents.HARDDROP,
			[29] = brix.inputEvents.SOFTDROP,
			[11] = brix.inputEvents.MOVELEFT,
			[14] = brix.inputEvents.MOVERIGHT,
			[91] = brix.inputEvents.ROT_CW,
			[89] = brix.inputEvents.ROT_CCW,
			[79] = brix.inputEvents.HOLD,
			[88] = brix.inputEvents.HOLD
			
		}
		
		hook.add("inputPressed", hookName, function(button)

			if input.getCursorVisible() then return end
			if timer.realtime() - lastDraw > 1 then return end
			local game = GAME
			
			if game.game.started and inputMap2[button] then
				game.game:userInput(inputMap2[button], true)
			elseif game.game.started and button >= 2 and button <= 5 then
				game.game:userInput(button + 6)
			end
		end)
		
		hook.add("inputReleased", hookName, function(button)
		
			if timer.realtime() - lastDraw > 1 then return end
			local game = GAME
			
			if inputMap2[button] and game.game.started then
				game.game:userInput(inputMap2[button], false)
			end
		end)
		
		

		local inputMap = {
		
			[0x0001] = brix.inputEvents.HARDDROP,
			[0x0002] = brix.inputEvents.SOFTDROP,
			[0x0004] = brix.inputEvents.MOVELEFT,
			[0x0008] = brix.inputEvents.MOVERIGHT,
			[0x2000] = brix.inputEvents.ROT_CW,
			[0x1000] = brix.inputEvents.ROT_CCW,
			[0x4000] = brix.inputEvents.ROT_CW,
			[0x8000] = brix.inputEvents.ROT_CCW,
			[0x0100] = brix.inputEvents.HOLD,
			[0x0200] = brix.inputEvents.HOLD,


			
		}

		GAME.lastTargetMode = 0

		hook.add("xinputStick", hookName, function(controller, x, y, stick, when)

			if controller == 0 and stick == 1 and GAME.game.started then
				local radius = math.sqrt(x^2 + y^2)
				local angle = math.deg(-math.atan(y/x))
				if x > 0 then
					angle = angle + 90
				else
					angle = angle + 270
				end

				angle = (angle + 45) % 360
				if radius >= 16384 then

					local mode = math.floor(angle / 90) + ARENA.targetModes.ATTACKER
					if mode ~= GAME.lastTargetMode then
						GAME.game:changeTargetMode(mode)
						GAME.lastTargetMode = mode
					end

				else
					GAME.lastTargetMode = 0
				end

			else
				GAME.lastTargetMode = 0
			end

		end)
		
		hook.add("brixPressed", hookName, function(controller, button, when)
		
			if timer.realtime() - lastDraw > 1 then return end
			local game = GAME
			
			if game.game.started and inputMap[button] then
				game.game:userInput(inputMap[button], true)
			end
		end)
		
		hook.add("brixReleased", hookName, function(controller, button, when)
		
			if timer.realtime() - lastDraw > 1 then return end
			local game = GAME
			
			if inputMap[button] and game.game.started then
				game.game:userInput(inputMap[button], false)
			end
		end)

	end

	hook.add("think", "tryConnect", function()

		if isValid(player():getVehicle()) or true then
			hook.remove("think", "tryConnect")
			br.connectToServer(makeHUD)
		end

	end)

