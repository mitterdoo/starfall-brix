--@client
--@include brix/client/gui.lua
--@include brix/br/arena_cl.lua
--@include brix/client/input.lua


require("brix/br/arena_cl.lua")
require("brix/client/gui.lua")
require("brix/client/input.lua")

local root = gui.Create("Control")
root:SetSize(1024, 1024)
root:SetPos(1920 / 2 - 1024/2, 1080 / 2 - 1024/2)


local RT = gui.Create("RTControl", root)
RT:SetSize(1024, 1024)

local Board = gui.Create("Sprite", RT)
Board:SetSheet(3)
Board:SetSprite(0)


local x, y, brickSize = unpack(sprite.sheets[3].field_main)

local TopFieldPos = gui.Create("Control", root)
TopFieldPos:SetPos(x, y)

local fieldDanger = gui.Create("Danger", TopFieldPos)
fieldDanger:SetPos(0, brickSize * -20)
fieldDanger:SetSize(brickSize * 10, brickSize * 20)


local FieldPos = gui.Create("Control", Board)
FieldPos:SetPos(x, y)

local fieldCtrl = gui.Create("Field", FieldPos)
fieldCtrl:SetPos(0, -brickSize * 21)
fieldCtrl:SetBrickSize(brickSize)

local pieceGhost = gui.Create("Piece", FieldPos)
pieceGhost:SetBrickSize(brickSize)
pieceGhost:SetVisible(false)
pieceGhost:SetIsGhost(true)

local piece = gui.Create("Piece", FieldPos)
piece:SetBrickSize(brickSize)
piece:SetVisible(false)

local blockoutPiece = gui.Create("Piece", FieldPos)
blockoutPiece:SetBrickSize(brickSize)
blockoutPiece:SetVisible(false)
blockoutPiece:SetIsBlockout(true)


local normal_piece = brix.normalPiece

br.connectToServer(function(arena)

	local mat = arena.matrix
	local lastFrame = -1
	fieldCtrl:SetField(mat)


	arena.hook("pieceSpawn", function(p, rot, x, y)

		piece:SetVisible(true) pieceGhost:SetVisible(true)
		x, y = piece:GetPiecePos(x, y)
		piece:SetPos(x, y)
		local ghostX, ghostY = arena:getFallLocation()
		ghostX, ghostY = pieceGhost:GetPiecePos(ghostX, ghostY)
		pieceGhost:SetPos(ghostX, ghostY)
		piece:SetPieceID(p.type) pieceGhost:SetPieceID(p.type)
		piece:SetRotation(rot)
		pieceGhost:SetRotation(rot)

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

	arena.hook("lock", function(tricks, combo, linesSent, linesCleared)
	
		piece:SetVisible(false)
		pieceGhost:SetVisible(false)

		for _, line in pairs(linesCleared) do

			local anim = gui.Create("LineClear", TopFieldPos)
			anim:SetBrickSize(brickSize)
			anim:SetLine(line)

		end

	end)

	arena.hook("die", function(killer)
	
		piece:SetVisible(false)
		pieceGhost:SetVisible(false)
		blockoutPiece:SetVisible(false)

		hook.remove("postdrawhud", "brix")

	end)

	arena.hook("danger", function(danger)
	
		fieldDanger:SetInDanger(danger)

	end)

	hook.add("brixPressed", "", function(button)

		if arena.started then
			arena:userInput(button, true)
		end

	end)

	hook.add("brixReleased", "", function(button)

		if arena.started then
			arena:userInput(button, false)
		end

	end)
	hook.add("postdrawhud", "brix", function()

		local w, h = render.getGameResolution()
		sprite.setSheet(20 + math.min(11, arena:calcLevel()) - 1)
		sprite.draw(0, 0, 0, w, h)

		local perc = quotaAverage() / quotaMax()
		perc = math.ceil(perc * 1000) / 10
		render.setRGBA(255, 0, 255, 255)
		render.drawText(64, 500, perc .. "%", 1)

		if arena.started then
			local frame = brix.getFrame(timer.realtime() - arena.startTime)
			arena:update(frame)
		end

		if mat.invalid then
			fieldCtrl.invalid = true
			RT.invalid = true
			mat.invalid = false
		end

		if arena.frame ~= lastFrame then
			RT.invalid = true
			lastFrame = arena.frame
		end

		gui.Draw()

	end)


end)


