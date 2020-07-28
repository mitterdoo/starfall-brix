-- Graphics for rendering the active, next, and hold pieces
local sub = string.sub
local getShapeIndex = brix.getShapeIndex

hook.add("brConnect", "piece", function(game, arena)

	local piece = game.controls.piece
	local pieceGhost = game.controls.pieceGhost
	local NextPieces = game.controls.NextPieces
	local NextPieceRT = game.controls.NextPieceRT
	local HoldPiece = game.controls.HoldPiece
	local blockoutPiece = game.controls.blockoutPiece
	local Field_OverMatrix = game.controls.Field_OverMatrix
	local mat = arena.matrix

	local _, _, brickSize = unpack(sprite.sheets[3].field_main)

	arena.hook("gameover", function(reason)
	
		piece:Remove()
		pieceGhost:Remove()
		blockoutPiece:Remove()
		game.controls.RT.invalid = true

	end)

	arena.hook("pieceSpawn", function(p, rot, x, y)

		local type = arena.currentPiece.type
		piece:SetVisible(true) pieceGhost:SetVisible(true)
		x, y = piece:GetPiecePos(x, y)
		piece:SetPos(x, y)
		local ghostX, ghostY = arena:getFallLocation()
		ghostX, ghostY = pieceGhost:GetPiecePos(ghostX, ghostY)
		pieceGhost:SetPos(ghostX, ghostY)
		piece:SetPieceID(type) pieceGhost:SetPieceID(type)
		piece:SetRotation(rot)
		pieceGhost:SetRotation(rot)

		if arena.held ~= -1 then

			HoldPiece:SetVisible(true)
			HoldPiece:SetPieceID(arena.held)
			HoldPiece:SetIsHoldLocked(arena.heldThisPhase)

		end

		if mat.highestPoint > 16 then
			local nextType = arena.pieceQueue[1]
			blockoutPiece:SetPieceID(nextType)
			local bx, by = blockoutPiece:GetPiecePos(brix.getPieceSpawnPos(nextType))
			blockoutPiece:SetPos(bx, by)
			blockoutPiece:SetVisible(true)
		else
			blockoutPiece:SetVisible(false)
		end


	end)

	arena.hook("pieceRotate", function()
	
		piece:SetRotation(arena.currentPiece.rot)
		piece:SetPos(piece:GetPiecePos(arena.currentPiece.x, arena.currentPiece.y))

		pieceGhost:SetRotation(piece.rot)
		pieceGhost:SetPos(pieceGhost:GetPiecePos(arena:getFallLocation()))

	end)

	arena.hook("pieceTranslate", function()
		piece:SetPos(piece:GetPiecePos(arena.currentPiece.x, arena.currentPiece.y))
		pieceGhost:SetPos(pieceGhost:GetPiecePos(arena:getFallLocation()))
	end)

	arena.hook("pieceFall", function()
		piece:SetPos(piece:GetPiecePos(arena.currentPiece.x, arena.currentPiece.y))
		pieceGhost:SetPos(pieceGhost:GetPiecePos(arena:getFallLocation()))
	end)

	arena.hook("pieceQueueUpdate", function()
	
		for i = 1, 5 do

			local ctrl = NextPieces[i]
			ctrl:SetPieceID(arena.pieceQueue[i])
			ctrl:SetVisible(true)

		end
		NextPieceRT.invalid = true

	end)

	arena.hook("lock", function(tricks, combo, linesSent, linesCleared)
	
		piece:SetVisible(false)
		pieceGhost:SetVisible(false)

		for _, line in pairs(linesCleared) do

			local pos, scale = Field_OverMatrix:AbsolutePos(Vector(brickSize*5, brickSize/-2 - line*brickSize, 0))
			local startSize = Vector(brickSize*10, brickSize, 0)
			local endSize = Vector(brickSize * 10 * 1.45, brickSize * 0.1, 0)

			gfx.EmitParticle(
				{pos, pos},
				{startSize*scale, endSize*scale},
				0, 0.1,
				gfx.Draw_LineClear,
				true, true)

		end

	end)

	local function fx_HardDrop(x, y, w, h, frac, isGlow)

		if not isGlow then return end
		render.setRGBA(255, 255, 255, (1-frac)^2*40)
		render.drawRectFast(x, y, w, h)

	end

	local function fx_HardDropSparkle(x, y, w, h, frac, isGlow)

		render.setRGBA(255, 255, 150, (1-frac)^2*255)
		render.drawRectFast(x, y, w, h)
		--sprite.setSheet(1)
		--sprite.draw(78, x, y, w, h)

	end

	local curSparkles = {}

	arena.hook("pieceHardDrop", function(p)

		local obbmins, obbmaxs = Vector(16, 16, 0), Vector(-1, -1, 0)

		local rot, size = p.rot, p.piece.size

		local shape = p.piece.shape

		local ox, oy = p.x, p.y
		for y = 0, size-1 do
			for x = 0, size-1 do
				local i = getShapeIndex(x, y, rot, size)
				if sub(shape, i, i) == "x" then
					if x < obbmins[1] then
						obbmins[1] = x
					end
					if y < obbmins[2] then
						obbmins[2] = y
					end

					if x > obbmaxs[1] then
						obbmaxs[1] = x
					end
					if y > obbmaxs[2] then
						obbmaxs[2] = y
					end
					
				end
			end
		end

		local obbsize = (obbmaxs + Vector(1, 1, 0) - obbmins)
		local matSize = obbsize * brickSize
		local matPos = (Vector(ox, oy + obbsize[2], 0) + obbmins) * brickSize * Vector(1, -1, 0)

		local pos, scale = Field_OverMatrix:AbsolutePos(matPos)
		local endPos = pos - Vector(0, 10, 0) * brickSize
		local startSize = matSize
		local endSize = startSize + (pos - endPos)
		gfx.EmitParticle(
			{pos, endPos},
			{startSize*scale, endSize*scale},
			0, 1/4,
			fx_HardDrop,
			true, false
		)

		local sparkleBounds = startSize + Vector(2, 0, 0) * brickSize * scale
		local sparklePos = pos - Vector(1, 0, 0) * brickSize * scale

		gfx.KillParticles(curSparkles)
		curSparkles = {}
		local sparkleSize = Vector(brickSize, brickSize, 0) * 0.2 * scale
		for i = 1, 6 do
			local pos = sparklePos + sparkleBounds * Vector(math.random(), math.random(), 0)
			local p = gfx.EmitParticle(
				{pos, pos - Vector(0, brickSize * (1 + math.random()*4), 0)*scale},
				{sparkleSize * (1 + math.random() * 0.2), Vector(0, 0, 0)},
				0, 0.5 + math.random() * 0.2,
				fx_HardDropSparkle,
				true, true
			)
			curSparkles[p] = true
		end


	end)

	arena.hook("die", function(killer)
	
		piece:SetVisible(false)
		pieceGhost:SetVisible(false)
		blockoutPiece:SetVisible(false)
	
	end)

end)