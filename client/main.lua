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

STENCIL_NEVER = 1
STENCIL_LESS = 2
STENCIL_EQUAL = 3
STENCIL_LESSEQUAL = 4
STENCIL_GREATER = 5
STENCIL_NOTEQUAL = 6
STENCIL_GREATEREQUAL = 7
STENCIL_ALWAYS = 8

STENCIL_KEEP = 1
STENCIL_ZERO = 2
STENCIL_REPLACE = 3
STENCIL_INCRSAT = 4
STENCIL_DECRSAT = 5
STENCIL_INVERT = 6
STENCIL_INCR = 7
STENCIL_DECR = 8

require("brix/client/loader.lua")

hook.add("load", "", function()

	require("brix/client/game.lua")


end)
