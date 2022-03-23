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

	self.hookName = "lobbytimer" .. math.random(2^31-1)
	self.finish = timer.curtime() + ARENA.lobbyWaitTime

end

function PANEL:SetFinish(time)
	if time == nil then
		self:SetValue(ARENA.lobbyWaitTime)
		self.finish = nil
	else
		self.finish = time
	end
end

function PANEL:Think()

	if self.finish then
		local t = self.finish - timer.curtime()
		t = math.max(0, math.ceil(t))

		if t ~= self.lastValue then
			self.lastValue = t
			self:SetValue(t)
		end
	end

end

gui.Register("LobbyTimer", PANEL, "Number")
