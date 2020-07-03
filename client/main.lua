--@clinet
--@include brix/client/loader.lua
--@include brix/client/game.lua
--[[
	Runs the loader asynchronously, and then initializes the main game once everything has finished loading.
]]

local create = render.createRenderTarget
RTCount = 0
function render.createRenderTarget(rt)
	RTCount = RTCount + 1
	return create(rt)
end

function timeFrac(delta, from, to)

	return (delta - from) / (to - from)

end

function lerp( delta, from, to )

	if ( delta > 1 ) then return to end
	if ( delta < 0 ) then return from end

	return from + ( to - from ) * delta

end

require("brix/client/loader.lua")

hook.add("load", "", function()

	require("brix/client/game.lua")


end)
