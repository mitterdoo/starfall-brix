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
hook.add("brConnect", "strategy", function(game, arena)

	local HUD = game.controls.HUD
	local Background = game.controls.Field_UnderMatrix

	local field_x, field_bottom, brickSize = unpack(sprite.sheets[3].field_main)


	local Strategy = gui.Create("Strategy", Background)
	Strategy:SetPos(0, -brickSize*20)
	Strategy.foreground = false
	game.controls.Strategy = Strategy

	-- Define functions to call when this HUD element switches between foreground and background
	local function requestLayerChange(foreground)

		if foreground then
			Strategy:SetPos(field_x, field_bottom - brickSize*20)
			Strategy:SetParent(HUD)
		else
			Strategy:SetPos(0, -brickSize*20)
			Strategy:SetParent(Background)
		end
	end


	Strategy:SetSize(brickSize*10, brickSize*4)
	Strategy.RequestLayerChange = requestLayerChange
	Strategy:SetVisible(false)

	arena.hook("changeTargetMode", function(newMode)
	
		if arena.dead then return end
		Strategy:SetStrategy(newMode)

	end)

	arena.hook("init", function()
	
		Strategy:SetVisible(true)

	end)

end)
