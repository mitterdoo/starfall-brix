--@include brix/client/scenes/scene.lua
--@include brix/client/gui.lua
--@include brix/client/gfx.lua
--@include brix/br/arena_cl.lua
--@include brix/client/settings.lua
--@include brix/client/input.lua

require("brix/client/settings.lua")
require("brix/br/arena_cl.lua")
require("brix/client/gui.lua")
require("brix/client/gfx.lua")
require("brix/client/input.lua")
require("brix/client/scenes/scene.lua")

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

local firstDraw = false

hook.add("predrawhud", "brix", function()

	if not firstDraw then
		firstDraw = true

		scene.Open()

	end

	local info = {
		x = 0,
		y = 0,
		w = 1920,
		h = 1080,
		type = "2D"
	}
	render.pushViewMatrix(info)
	render.setRGBA(0, 0, 0, 255)
	render.drawRectFast(0, 0, 1920, 1080)
	lastHudDraw = timer.realtime()
	gui.Draw()
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


end)
