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
local fadeTime = 0.5

local function getBGFromLevel(lvl)
	return 19 + math.min(11, math.max(1, lvl))
end

function PANEL:Init()

	self.bg = 20
	self.lastBg = 20
	self.lerpEnd = 0

end

function PANEL:SetLevel(lvl)
	lvl = getBGFromLevel(lvl)
	if lvl == self.bg then return end
	local dyn = settings.dynamicBackground
	if dyn == nil then dyn = true end
	if not dyn then return end
	
	self.lastBg = self.bg
	self.bg = lvl
	self.lerpEnd = timer.realtime() + fadeTime
end

function PANEL:Paint(w, h)

	local t = timer.realtime()
	local sheet = self.bg
	local scale = gui.getFitScale(1920, 1080, w, h)
	local nw, nh = 1920 * scale, 1080*scale
	if t > self.lerpEnd then
		render.setRGBA(255, 255, 255, 255)
		sprite.setSheet(sheet)

		sprite.draw(0, w/2 - nw/2, h/2 - nh/2, nw, nh)
		return
	end

	local percent = (t - (self.lerpEnd - fadeTime)) / fadeTime
	render.setRGBA(255, 255, 255, 255)
	sprite.setSheet(self.lastBg)
	sprite.draw(0, w/2 - nw/2, h/2 - nh/2, nw, nh)

	render.setRGBA(255, 255, 255, percent * 255)
	sprite.setSheet(sheet)
	sprite.draw(0, w/2 - nw/2, h/2 - nh/2, nw, nh)

end


gui.Register("Background", PANEL, "Control")
