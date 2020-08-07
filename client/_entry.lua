--@include brix/client/scenes/scene.lua
--@include brix/client/gui.lua
--@include brix/client/gfx.lua
--@include brix/br/arena_cl.lua
--@include brix/client/settings.lua
--@include brix/client/input.lua

--@includedir brix/client/game


require("brix/client/settings.lua")
require("brix/br/arena_cl.lua")
require("brix/client/gui.lua")
require("brix/client/gfx.lua")
require("brix/client/input.lua")
require("brix/client/scenes/scene.lua")
requiredir("brix/client/game", {
	"scoreboard.lua"
})

local lastHudDraw = 0

hook.add("calcview", "fps", function()
	if timer.realtime() - lastHudDraw < 1 then
		return {
			origin = Vector(0, 0, -60000),
			angles = Angle(90, 0, 0),
			znear = 1,
			zfar = 2
		}
	end
end)

hook.add("huddisconnected", "brix", function()
	scene.Close()
end)

local sentExitMsg = false
hook.add("predrawhud", "brix", function()

	local w, h = render.getGameResolution()
	local info = {
		x = 0,
		y = 0,
		w = w,
		h = h,
		type = "2D"
	}
	render.pushViewMatrix(info)
	if not isValid(player():getVehicle()) then
		render.setRGBA(255, 0, 0, 128)
		render.drawRectFast(0, 0, w, h)
		render.setRGBA(255, 255, 255, 255)
		render.setFont("DermaLarge")
		render.drawText(w/2, h/2-64, "Please sit in a seat instead of\nmanually connecting to this HUD.\nPress ALT to unlink from this.", 1)
	else
		if not input.isControlLocked() then
			if not sentExitMsg then
				sentExitMsg = true
				net.start("exitVehicle")
				net.send()
			end
		else
			sentExitMsg = false
			if not scene.Active then
				if CUR_ARENA_CTRL then
					CUR_ARENA_CTRL:Remove() -- Don't let this interfere with net messages
				end
				scene.Open()
			end

			render.setRGBA(0, 0, 0, 255)
			render.drawRectFast(0, 0, w, h)
			lastHudDraw = timer.realtime()
			gui.Draw()
		end

	end
	render.popViewMatrix()

end)

local disallow = {
	CHudGMod = true,
	CHudAmmo = true,
	CHudBattery = true,
	CHudChat = true,
	CHudCrosshair = true,
	CHudCloseCaption = true,
	CHudDamageIndicator = true,
	CHudDeathNotice = true,
	CHudGeiger = true,
	CHudHealth = true,
	CHudHintDisplay = true,
	CHudMessage = true,
	CHudPoisonDamageIndicator = true,
	CHudSecondaryAmmo = true,
	CHudSquadStatus = true,
	CHudTrain = true,
	CHudWeapon = true,
	CHudVehicle = true,
	CHudWeaponSelection = true,
	CHudZoom = true,
	CHUDQuickInfo = true,
	CHudSuitPower = true
}

hook.add("hudshoulddraw", "brix", function(name)

	if disallow[name] and render.isHUDActive() then return false end

end)


hook.add("inputPressed", "debug", function(button)
	if button == 50 and player() == owner() then
		net.start("BRIX_BOT")
		net.send()
	elseif button == 48 and player() == owner() then
		net.start("brixBegin")
		net.send()
	end
end)
