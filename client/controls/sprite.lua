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

local setSheet = sprite.setSheet
local drawSprite = sprite.draw

function PANEL:Init()
	self.sheet = 1
	self.sprite = 0
	self.trueSize = true
	self.color = Color(255, 255, 255)
	self.halign = -1
	self.valign = -1
end

function PANEL:SetAlign(h, v)
	self.halign = h
	self.valign = v
end

function PANEL:SetHAlign(h)
	self.halign = h
end

function PANEL:SetVAlign(v)
	self.valign = v
end

function PANEL:SetColor(col)
	self.color = col
end

function PANEL:SetSheet(sheet)
	assert(type(sheet) == "number", "sheet must be number")
	self.sheet = sheet
end

function PANEL:SetSprite(sprite)
	assert(type(sprite) == "number", "sprite must be number")
	self.sprite = sprite
end

function PANEL:OnSizeChanged(w, h)
	self.trueSize = false
end

function PANEL:SetTrueSize(isTrue)
	self.trueSize = isTrue
end

function PANEL:RealSize()

	local _, _, w, h = sprite.sheets[self.sheet][self.sprite]
	self:SetSize(w, h)

end

function PANEL:Paint(w, h)

	setSheet(self.sheet)
	render.setColor(self.color)
	if self.trueSize then
		drawSprite(self.sprite, 0, 0, nil, nil, self.halign, self.valign)
	else
		drawSprite(self.sprite, 0, 0, w, h, self.halign, self.valign)
	end

end

gui.Register("Sprite", PANEL, "Control")
