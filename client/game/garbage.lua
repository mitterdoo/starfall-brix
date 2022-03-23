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
-- Graphics for garbage queue
hook.add("brConnect", "garbage", function(game, arena)

	local Garbage = game.controls.Garbage

	arena.hook("garbageQueue", function(lines, sender, frame)
		Garbage:Enqueue(lines)
	end)

	arena.hook("garbageActivate", function()
		Garbage:SetState(1)
	end)

	arena.hook("garbageNag", function(second)
		Garbage:SetState(second and 3 or 2)
	end)

	arena.hook("garbageCancelled", function(count)
		Garbage:Offset(count)
	end)

	arena.hook("garbageDump", function()
		Garbage:Dump()
	end)
end)
