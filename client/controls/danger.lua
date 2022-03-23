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
function PANEL:Init()

	self.inDanger = false
	self.lerpEnd = 0

end

function PANEL:SetInDanger(danger)
	if danger == self.inDanger then return end
	self.inDanger = danger
	self.lerpEnd = timer.realtime() + fadeTime
end

function PANEL:Paint(w, h)

	local t = timer.realtime()
	local percent = 1
	if t > self.lerpEnd then
		percent = self.inDanger and 1 or 0
	else

		percent = (t - (self.lerpEnd - fadeTime)) / fadeTime
		if not self.inDanger then
			percent = 1 - percent
		end

	end

	if percent == 0 then return end
	render.setRGBA(255, 0, 0, 20 * percent)
	render.drawRectFast(0, 0, w, h)

end

gui.Register("Danger", PANEL, "Control")