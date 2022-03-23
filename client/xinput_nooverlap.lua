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
--@name XInput no overlap D-Pad
--@author mitterdoo
--@client


local dpads = {
	[0] = 0,
	[1] = 0,
	[2] = 0,
	[3] = 0
}

local function dpadCheck(id, when)

	local u, d, l, r = xinput.getButton(id, 0x0001), xinput.getButton(id, 0x0002), xinput.getButton(id, 0x0004), xinput.getButton(id, 0x0008)
	local dir = -1
	if u and not (d or l or r) then
		dir = 0x0001
	elseif d and not (l or r or u) then
		dir = 0x0002
	elseif l and not (r or u or d) then
		dir = 0x0004
	elseif r and not (u or d or l) then
		dir = 0x0008
	end
	
	local lastDir = dpads[id]
	if lastDir ~= dir then
		if lastDir > 0 then
			hook.run("xinputReleasedNoOverlap", id, lastDir, when)
		end
		if dir > 0 then
			hook.run("xinputPressedNoOverlap", id, dir, when)
		end
		dpads[id] = dir
	end
	
end

hook.add("xinputPressed", "", function(id, button, when)

	if bit.band(button, 0x000F) > 0 then -- pressed dpad
		dpadCheck(id, when)
	else
		hook.run("xinputPressedNoOverlap", id, button, when)
	end

end)
hook.add("xinputReleased", "", function(id, button, when)

	if bit.band(button, 0x000F) > 0 then
		dpadCheck(id, when)
	else
		hook.run("xinputReleasedNoOverlap", id, button, when)
	end

end)
