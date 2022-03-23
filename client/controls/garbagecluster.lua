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

local nagDuration = 0.2

function PANEL:Init()

	self.brickSize = 48
	self.count = 1
	self.state = 0

end

function PANEL:SetBrickSize(size)
	self.brickSize = size
end

function PANEL:SetCount(count)
	self.count = count
end

function PANEL:SetState(state)
	self.state = state
end

local garbageWaiting = sprite.sheets[1].garbage
local garbageArmed = sprite.sheets[1].garbageIdle
local garbageLit = sprite.sheets[1].garbageLit

function PANEL:Paint()

	sprite.setSheet(1)
	local brickSize = self.brickSize

	local spr
	if self.state == 0 then
		render.setRGBA(255, 255, 255, 255)
		spr = garbageWaiting
	elseif self.state == 1 then
		render.setRGBA(255, 255, 0, 255)
		spr = garbageArmed
	else
		spr = garbageLit
		render.setRGBA(255, 0, 0, 255)
	end
	for i = 1, self.count do
	
		sprite.draw(spr, 0, i * -brickSize, brickSize, brickSize)

	end

end


gui.Register("GarbageCluster", PANEL, "Control")
