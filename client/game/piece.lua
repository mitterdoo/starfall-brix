-- Graphics for rendering the active, next, and hold pieces
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
			local endSize = Vector(brickSize * 10 * 1.45, brickSize * 0.8, 0)

			gfx.EmitParticle(
				{pos, pos},
				{startSize*scale, endSize*scale},
				0, 0.1,
				gfx.Draw_LineClear,
				true, true)

		end

	end)

	arena.hook("die", function(killer)
	
		piece:SetVisible(false)
		pieceGhost:SetVisible(false)
		blockoutPiece:SetVisible(false)
	
	end)

end)