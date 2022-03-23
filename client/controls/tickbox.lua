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
if LITE then return end
local PANEL = {}

function PANEL:Init()
	PANEL.super.Init(self)
	self.col = Color(255, 255, 255)
	self.value = false
	self:SetSize(80, 80)
end

function PANEL:SetValue(v)
	self.value = v
end

function PANEL:SetColor(col)
	self.col = col
end

local spr_tickboxOff = sprite.sheets[2].tickbox
local spr_tickboxOn = sprite.sheets[2].tickbox + 1
function PANEL:DrawButtonSprite(x, y, w, h)

	render.setColor(self.col)
	sprite.setSheet(2)
	sprite.draw(self.value and spr_tickboxOn or spr_tickboxOff, x, y, w, h)

end

gui.Register("Tickbox", PANEL, "BlockButton")
