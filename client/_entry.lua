--@include brix/client/scenes/scene.lua
--@include brix/client/gui.lua
--@include brix/client/gfx.lua
--@include brix/br/arena_cl.lua
--@include brix/client/input.lua

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
hook.add("postdrawhud", "brix", function()

	render.setRGBA(0, 0, 0, 255)
	render.drawRectFast(0, 0, 1920, 1080)
	lastHudDraw = timer.realtime()
	gui.Draw()

end)
