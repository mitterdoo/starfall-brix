--@client
--@include brix/client/gui.lua
--@include brix/client/gfx.lua
--@include brix/br/arena_cl.lua
--@include brix/client/input.lua

--[[
	Optimize Particles. Particles needed:
		Outgoing attack with sparkles
		Incoming/standby attacks
		Full badge sparkles
		Hard drop whoosh and sparkles

$	Next piece spawnpoint outline when nearing blockout
$	Danger indicator
$	Level backgrounds
$	Glow rendering layer (with gameboard outline)
$	Next pieces
$	Hold piece
	Garbage meter (with effects)
	Line clear messages (quad, allclear, tspin, etc.)
	Countdown timer
	Bonus multiplier
	"x players remain!"
	Badges
	Remaining players
	KO count
	Enemies
	KO icons on enemies
	Attacker lines
	"Watch Out!"
	Outgoing attacks
	Attack strategy
	Manual targeting
	KO between other players shown on battlefield

	SFX

	Title screen
	Spectator screen
	Controls configurator
]]

require("brix/br/arena_cl.lua")
require("brix/client/gui.lua")
require("brix/client/gfx.lua")
require("brix/client/input.lua")
--[[

	bg
	root
		Board
		Field_UnderMatrix
			fieldDanger
		RT
			FieldPos
				fieldCtrl
				pieceGhost
				piece
				blockoutPiece
			HoldPiece
		NextPieceRT
			{nextPieces}
		Field_OverMatrix


]]
local bg = gui.Create("Background")
bg:SetSize(render.getGameResolution())

local root = gui.Create("Control")
root:SetSize(1024, 1024)
root:SetScale(1, 1)
root:SetPos(1920 / 2 - 1024/2, 1080 / 2 - 1024/2)

local x, y, brickSize = unpack(sprite.sheets[3].field_main)

local Board = gui.Create("Sprite", root) -- Board sprite
Board:SetSheet(3)
Board:SetSprite(0)


local Field_UnderMatrix = gui.Create("Control", root) -- Draw this underneath the matrix
Field_UnderMatrix:SetPos(x, y)

	local fieldDanger = gui.Create("Danger", Field_UnderMatrix)
	fieldDanger:SetPos(0, brickSize * -20)
	fieldDanger:SetSize(brickSize * 10, brickSize * 20)

local RT = gui.Create("RTControl", root) -- This contains everything that is rendered discretely
RT:SetSize(1024, 1024)

	local FieldPos = gui.Create("Control", RT)
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
	

	local HoldPiece = gui.Create("PieceIcon", RT)
	do

		local x, y, brickSize = unpack(sprite.sheets[3].field_hold)
		HoldPiece:SetPos(x, y)
		HoldPiece:SetBrickSize(brickSize)
		HoldPiece:SetVisible(false)

	end
local NextPieces = {}
local NextPieceRT = gui.Create("RTControl", root)
do
	local x, y, brickSize = unpack(sprite.sheets[3].field_next)

	NextPieceRT:SetPos(x, y - brickSize * 4 * 5)
	NextPieceRT:SetSize(1024, 1024)

	for i = 1, 5 do
		local p = gui.Create("PieceIcon", NextPieceRT)
		local thisSize = i == 1 and brickSize or (brickSize - 4)
		p:SetBrickSize(thisSize)
		p:SetVisible(false)

		p:SetPos(i == 1 and 0 or 2, i * brickSize * 4)
		NextPieces[i] = p
	end

end



local Field_OverMatrix = gui.Create("Control", root) -- Draw this on top of the matrix
Field_OverMatrix:SetPos(x, y)

br.connectToServer(function(arena)

	local mat = arena.matrix
	local lastFrame = -1
	fieldCtrl:SetField(mat)


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

		for i = 1, 5 do

			local ctrl = NextPieces[i]
			ctrl:SetPieceID(arena.pieceQueue[i])
			ctrl:SetVisible(true)

		end

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

		hook.remove("postdrawhud", "brix")

	end)

	arena.hook("levelUp", function(newLevel)
	
		bg:SetLevel(newLevel)

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
		render.setRGBA(255, 0, 255, 255)
		render.drawText(64, 500, perc .. "%", 1)

	end)


end)


