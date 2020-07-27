--@client
--@include brix/client/gui.lua
--@include brix/client/gfx.lua
--@include brix/br/arena_cl.lua
--@include brix/client/input.lua
--@includedir brix/client/game

--[[
	Optimize Particles. Particles needed:
$		Outgoing attack with sparkles
		Incoming/standby attacks
		Full badge sparkles
$		Hard drop whoosh and sparkles

$	Next piece spawnpoint outline when nearing blockout
$	Danger indicator
$	Level backgrounds
$	Glow rendering layer (with gameboard outline)
$	Next pieces
$	Hold piece
$	Garbage meter (with effects)
$	Countdown timer
$	Line clear messages (quad, allclear, tspin, etc.)
$	Lines sent
$	Bonus multiplier
$	"x players remain!"
$	Badges
$	Remaining players
$	KO count
$	Enemies
$	KO icons on enemies
$	Target reticle
$	"Watch Out!"
$	Attacker lines
$	Outgoing attacks

$	Particle groups
$		Allow creation of particle group table contains open and close functions (such as setting color or sprite)
$		When creating a particle, this table can be referenced as the group it is in.
$		Particles in a group will first have the group open function called, then the particles drawn, finally the close function

$	Attacks between enemies
$	Connect particle effect
$	K.O. Effect when you kill an enemy
$	Attack strategy
$	Match stick anim to actual stick position

	Reticle flash:
		When changing targets (should be big, short, and easy to spot)
		Every half-second (much smaller and less distracting)

$	Manual targeting
$	KO between other players shown on battlefield

	End screen with final places
	Improve outgoing attack graphics

	On death, all badges are depleted and fed to the killer in an animation

X	Loop points in music?
		(Cannot do without having sounds playable by Source engine)
	Royalty-free BGM
		(Going to use some tracks that tetr.io uses as well)
		Song credit in a conspicuous but not distracting spot
	SFX

	Title screen
	Spectator screen
	Controls configurator
		Test sub-menu
	Handling settings (are, das, etc.)
	Option to turn off changing background

	Endless matches
]]

require("brix/br/arena_cl.lua")
require("brix/client/gui.lua")
require("brix/client/gfx.lua")
require("brix/client/input.lua")
requiredir("brix/client/game", {
	"scoreboard.lua"
})
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

	do

		local desiredHeight = 1024
		local game_w, game_h = render.getGameResolution()
		local actualHeight = math.min(desiredHeight, game_h)
		local scale = math.min(1, actualHeight / desiredHeight)
		root:SetScale(scale, scale)

		root:SetPos(game_w / 2 - actualHeight/2, game_h / 2 - actualHeight/2)

	end

	game.controls.root = root

	game.controls.Attacks_Below = gui.Create("Control", root)
	game.controls.Attacks_Below:SetSize(root.w, root.h)

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
	Field_OverMatrix:SetSize(brickSize * 10, brickSize * -20)
	game.controls.Field_OverMatrix = Field_OverMatrix

	local Scoreboard = gui.Create("Control", root)
	local scoreboardPos = sprite.sheets[3].arena_stats
	Scoreboard:SetPos(scoreboardPos[1], scoreboardPos[2])
	Scoreboard:SetSize(scoreboardPos[3], scoreboardPos[4])
	game.controls.Scoreboard = Scoreboard

	game.controls.Attacks_Above = gui.Create("Control", root)
	game.controls.Attacks_Above:SetSize(root.w, root.h)

	game.controls.HUD = gui.Create("Control", root)
	game.controls.HUD:SetSize(root.w, root.h)

	br.connectToServer(function(arena)

		game.arena = arena
		local mat = arena.matrix
		local lastFrame = -1
		fieldCtrl:SetField(mat)

		hook.run("brConnect", game, arena)

		arena.hook("levelUp", function(newLevel)
		
			Background:SetLevel(newLevel)

		end)

		arena.hook("danger", function(danger)
		
			fieldDanger:SetInDanger(danger)

		end)

		hook.add("brixPressed", "", function(button)

			if arena.started and button < binput.stickEvents.MANUAL_DOWN then
				arena:userInput(button, true)
			end


		end)

		hook.add("xinputPressed", "", function(controller, button, when)
			if button == 0x0010 and player() == owner() and not arena.started then -- start
				net.start("brixBegin")
				net.send()
			elseif button == 0x0020 and player() == owner() then
				if not arena.started then
					net.start("BRIX_BOT")
					net.send()
				else
					hook.run("DEBUG")
				end
			end
		end)

		hook.add("inputPressed", "debug", function(button)
			if button == 50 and player() == owner() and not arena.started then
				net.start("brixBegin")
				net.send()
			elseif button == 51 and player() == owner() then
				if not arena.started then
					net.start("BRIX_BOT")
					net.send()
				else
					hook.run("DEBUG")
				end
			end
		end)

		hook.add("brixReleased", "", function(button)

			if arena.started and button < binput.stickEvents.MANUAL_DOWN then
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
