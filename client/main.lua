--[[
BRIX: Stack to the Death, a multiplayer brick stacking game written for the Starfall addon in Garry's Mod.
Copyright (C) 2022  Connor Ashcroft

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see LICENSE.md).
If not, see <https://www.gnu.org/licenses/>.
]]
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

local destroy = render.destroyRenderTarget
function render.destroyRenderTarget(rt)
	RTCount = RTCount - 1
	return destroy(rt)
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
require("brix/client/loader.lua")

hook.add("load", "", function()

	require("brix/client/_entry.lua")


end)
