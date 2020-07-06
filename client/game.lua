--@client
--@include brix/client/gui.lua
--@include brix/client/gfx.lua
--@include brix/br/arena_cl.lua
--@include brix/client/input.lua
--@includedir brix/client/game

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
$	Garbage meter (with effects)
	Countdown timer
	Line clear messages (quad, allclear, tspin, etc.)
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
requiredir("brix/client/game")
--[[

	Background
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

function createGame()
	local game = {}
	game.controls = {}

	local Background = gui.Create("Background")
	Background:SetSize(render.getGameResolution())
	game.controls.Background = Background

	local root = gui.Create("Control")
	root:SetSize(1024, 1024)
	root:SetScale(1, 1)
	root:SetPos(1920 / 2 - 1024/2, 1080 / 2 - 1024/2)
	game.controls.root = root

	local x, y, brickSize = unpack(sprite.sheets[3].field_main)

	local Board = gui.Create("Sprite", root) -- Board sprite
	Board:SetSheet(3)
	Board:SetSprite(0)
	game.controls.Board = Board


	local Field_UnderMatrix = gui.Create("Control", root) -- Draw this underneath the matrix
	Field_UnderMatrix:SetPos(x, y)
	game.controls.Field_UnderMatrix = Field_UnderMatrix

		local fieldDanger = gui.Create("Danger", Field_UnderMatrix)
		fieldDanger:SetPos(0, brickSize * -20)
		fieldDanger:SetSize(brickSize * 10, brickSize * 20)
		game.controls.fieldDanger = fieldDanger

	local RT = gui.Create("RTControl", root) -- This contains everything that is rendered discretely
	RT:SetSize(1024, 1024)
	game.controls.RT = RT

		local FieldPos = gui.Create("Control", RT)
		FieldPos:SetPos(x, y)
		game.controls.FieldPos = FieldPos

			local fieldCtrl = gui.Create("Field", FieldPos)
			fieldCtrl:SetPos(0, -brickSize * 21)
			fieldCtrl:SetBrickSize(brickSize)
			game.controls.fieldCtrl = fieldCtrl

			local pieceGhost = gui.Create("Piece", FieldPos)
			pieceGhost:SetBrickSize(brickSize)
			pieceGhost:SetVisible(false)
			pieceGhost:SetIsGhost(true)
			game.controls.pieceGhost = pieceGhost

			local piece = gui.Create("Piece", FieldPos)
			piece:SetBrickSize(brickSize)
			piece:SetVisible(false)
			game.controls.piece = piece

			local blockoutPiece = gui.Create("Piece", FieldPos)
			blockoutPiece:SetBrickSize(brickSize)
			blockoutPiece:SetVisible(false)
			blockoutPiece:SetIsBlockout(true)
			game.controls.blockoutPiece = blockoutPiece
		

		local HoldPiece = gui.Create("PieceIcon", RT)
		game.controls.HoldPiece = HoldPiece
		do

			local x, y, brickSize = unpack(sprite.sheets[3].field_hold)
			HoldPiece:SetPos(x, y)
			HoldPiece:SetBrickSize(brickSize)
			HoldPiece:SetVisible(false)

		end
	game.controls.NextPieces = {}
	local NextPieceRT = gui.Create("RTControl", root)
	do
		local x, y, brickSize = unpack(sprite.sheets[3].field_next)

		NextPieceRT:SetPos(x, y - brickSize * 4 * 5)
		NextPieceRT:SetSize(1024, 1024)
		game.controls.NextPieceRT = NextPieceRT

		for i = 1, 5 do
			local p = gui.Create("PieceIcon", NextPieceRT)
			local thisSize = i == 1 and brickSize or (brickSize - 4)
			p:SetBrickSize(thisSize)
			p:SetVisible(false)

			p:SetPos(i == 1 and 0 or 2, i * brickSize * 4)
			game.controls.NextPieces[i] = p
		end

	end

	local Garbage = gui.Create("GarbageQueue", root)
	do
		local x, y, garbageBrickSize = unpack(sprite.sheets[3].field_garbage)

		Garbage:SetBrickSize(garbageBrickSize)
		Garbage:SetPos(x, y)
		game.controls.Garbage = Garbage
	end

	local Field_OverMatrix = gui.Create("Control", root) -- Draw this on top of the matrix
	Field_OverMatrix:SetPos(x, y)
	game.controls.Field_OverMatrix = Field_OverMatrix

	br.connectToServer(function(arena)

		game.arena = arena
		local mat = arena.matrix
		local lastFrame = -1
		fieldCtrl:SetField(mat)

		hook.run("brConnect", game, arena)




		arena.hook("die", function(killer)
			hook.remove("postdrawhud", "brix")
		end)

		arena.hook("levelUp", function(newLevel)
		
			Background:SetLevel(newLevel)

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
			if arena.started then
				render.setRGBA(0, 255, 0, 255)
				render.drawRectFast(0, 0, 64, 64)
			end

		end)

		hook.add("calcview", "fps", function(pos, ang, fov, znear, zfar)

			if not arena.dead then
				return {
					origin = Vector(0, 0, -60000),
					angles = Angle(90, 0, 0),
					znear = 1,
					zfar = 2
				}
			end

		end)


	end)

end

createGame()
