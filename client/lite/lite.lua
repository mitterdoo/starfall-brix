--@include brix/br/arena_cl.lua
--@include brix/client/gui.lua
--@include brix/client/gfx.lua

LITE = true

do
	local ghostAlpha = 50
	local cols = {
		[0] = Color(50, 255, 255),
		[1] = Color(50, 50, 255),
		[2] = Color(255, 128, 50),
		[3] = Color(255, 255, 50),
		[4] = Color(50, 255, 50),
		[5] = Color(173, 50, 255),
		[6] = Color(255, 50, 50),
		[7] = Color(200, 200, 200),

		[15] = Color(72, 72, 72),
		[16] = Color(255, 255, 255),
		[17] = Color(255, 255, 255, ghostAlpha),
		[82] = Color(255, 0, 0, 50)

	}

	for i = 0, 6 do
		local c = Color(cols[i].r, cols[i].g, cols[i].b, ghostAlpha)
		cols[8+i] = c
	end

	local darken = 0.8
	function drawBlock(id, x, y, w, h)
		local c = cols[id] or Color(255, 0, 255)
		local cdark = Color(c.r*darken, c.g * darken, c.b*darken, c.a)
		render.setColor(cdark)
		render.drawRectFast(x, y, w, h)
		render.setColor(c)
		render.drawRectFast(x+4, y+4, w-8, h-8)
	end
end

require("brix/br/arena_cl.lua")
dofile("brix/client/gui.lua")
--[[
	Allowed controls:
		Control
		ArenaControl
		Material
		Piece
		PieceIcon
		RTControl
		DividedRTControl
		Field
		EnemyField
		Enemy
]]
dofile("brix/client/gfx.lua")

local liteCtx = gui.NewContext(1024, 1024)

local BG = gui.Create("Material", liteCtx)
BG:SetSize(1024, 1024)
BG:SetMaterial(material.createFromImage("gui/dupe_bg.png", ""))

local Arena

local function reloadArena()
	if Arena then Arena:Remove() end
	Arena = gui.Create("ArenaControl", liteCtx)
	Arena:SetPos(0, 0)
	Arena:SetScale(1, 1)

	Arena:StartListening()
end
reloadArena()

local titleFont = render.createFont("Roboto", 64, 900)
local subtitleFont = render.createFont("Roboto", 36, 900)
local loading = false

local liteRT = "liteRT"
render.createRenderTarget(liteRT)

hook.add("renderoffscreen", "lite", function()
	if not loading then

		if CUR_ARENA_CTRL == nil and not render.isHUDActive() then
			reloadArena()
		end

		gui.pushRT(liteRT)
		render.clear(Color(0, 0, 0, 0), true)
		gui.Draw(liteCtx)
		gui.popRT()

	end
end)

hook.add("render", "lite", function()
	local ent = render.getScreenEntity()
	if ent:getModel():find("4x4") and not loading then

		local delta = chip():worldToLocal(ent:getPos())
		local isTopScreen = delta.x < -128

		render.setRGBA(255, 255, 255, 255)
		render.setRenderTargetTexture(liteRT)
		render.drawTexturedRectFast(0, 0, 512, 512)

		if isTopScreen then

			render.setFont(titleFont)
			render.setRGBA(0, 0, 0, 255)
			render.drawText(256+4, 8+4, "BRIX", 1)
			render.setRGBA(255, 255, 255, 255)
			render.drawText(256, 8, "BRIX", 1)

			render.setFont(subtitleFont)
			render.setRGBA(0, 0, 0, 255)
			render.drawText(256+2, 512 - 8 - 64 + 2, "STACK TO THE DEATH", 1)
			render.setRGBA(255, 128, 0, 255)
			render.drawText(256, 512 - 8 - 64, "STACK TO THE DEATH", 1)

		end

	end
end)

hook.add("inputPressed", "debug", function(button)
	if button == 50 and player() == owner() then
		net.start("BRIX_BOT")
		net.send()
	elseif button == 51 and player() == owner() then
		net.start("brixBegin")
		net.send()
	end
end)

hook.add("preload", "lite", function()

	liteCtx:Remove()
	Arena = nil
	LITE = false
	loading = true

end)

hook.add("postload", "lite", function()
	loading = false
	liteCtx = gui.NewContext(1024, 1024)

	BG = gui.Create("Material", liteCtx)
	BG:SetSize(1024, 1024)
	BG:SetMaterial(material.createFromImage("gui/dupe_bg.png", ""))
	reloadArena()

end)
