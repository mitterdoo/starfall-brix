--@include brix/client/game/game.lua

require("brix/client/game/game.lua")

createGame()

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

	lastHudDraw = timer.realtime()
	gui.Draw()

end)
