--@name BRIX: Stack To The Death
--@client
--@include brix/client/lite/lite.lua
--@include brix/client/loader.lua
--@include brix/client/_entry.lua
--[[
	Runs the loader asynchronously, and then initializes the main game once everything has finished loading.
]]

local create = render.createRenderTarget
RTCount = 0
function render.createRenderTarget(rt)
	RTCount = RTCount + 1
	return create(rt)
end

function timeFrac(delta, from, to, clamp)
	
	if clamp then
		return math.max(0, math.min(1, (delta - from) / (to - from)))
	else
		return (delta - from) / (to - from)
	end

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

function render.resetStencil()

	render.setStencilWriteMask(0xFF)
	render.setStencilTestMask(0xFF)
	render.setStencilReferenceValue(0)
	render.setStencilCompareFunction(STENCIL_ALWAYS)
	render.setStencilPassOperation(STENCIL_KEEP)
	render.setStencilFailOperation(STENCIL_KEEP)
	render.setStencilZFailOperation(STENCIL_KEEP)
	render.clearStencil()

end

-- Returns additions and removals from table a to table b
function table.delta(a, b)
	
	local ai = {}
	local bi = {}
	
	for k,v in pairs(a) do ai[v] = k end
	for k,v in pairs(b) do bi[v] = k end
	
	local removed = {}
	local added = {}
	
	for k, v in pairs(a) do
		if not bi[v] then
			table.insert(removed, v)
		end
	end
	
	for k, v in pairs(b) do
		if not ai[v] then
			table.insert(added, v)
		end
	end
	
	return added, removed
	
end

require("brix/client/lite/lite.lua")
--[[
require("brix/client/loader.lua")

hook.add("load", "", function()

	require("brix/client/_entry.lua")


end)]]
