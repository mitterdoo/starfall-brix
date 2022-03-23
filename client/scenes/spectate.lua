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
local SCENE = {}


local backFont = render.createFont("Roboto", 36, 100)
function SCENE.Open(from)

	
	local root = gui.Create("Control")
	local gw, gh = render.getGameResolution()
	root:SetSize(gw, gh)

	local Background = gui.Create("Background", root)
	Background:SetSize(render.getGameResolution())

	local SpectateLabel = gui.Create("Sprite", root)
	SpectateLabel:SetSheet(2)
	SpectateLabel:SetSprite(sprite.sheets[2].spectating)
	SpectateLabel:SetAlign(0, -1)
	SpectateLabel:SetPos(gw/2, 8)

	local Arena = gui.Create("ArenaControl", root)
	Arena:SetPos(gw/2 - Arena.w/2, gh/2 - Arena.h/2)

	local BackLabel = gui.Create("ActionLabel", root)
	BackLabel:SetPos(8, root.h - 8)
	BackLabel:SetAlign(-1, 1)
	BackLabel:SetFont(backFont)
	BackLabel:SetText("{ui_cancel} Main Menu")

	local BackButton = gui.Create("Button", root)
	BackButton:SetVisible(false)
	BackButton:SetHotAction("ui_cancel")
	function BackButton:DoPress()
		if BackLabel.visible then
			scene.Open("Title", 1)
		end
	end

	local function gameOver()

		hook.remove("think", "spectate")
		local PlayLabel = gui.Create("ActionLabel", root)
		PlayLabel:SetPos(root.w - 8, root.h - 8)
		PlayLabel:SetAlign(1, 1)
		PlayLabel:SetFont(backFont)
		PlayLabel:SetText("{ui_accept} Join Next Match")

		local PlayButton = gui.Create("Button", root)
		PlayButton:SetVisible(false)
		PlayButton:SetHotAction("ui_accept")
		function PlayButton:DoPress()
			scene.Open("Game", 1)
		end

	end

	local levelTimerStart
	local levelDuration = 20
	local lastLevel

	Arena:StartListening(function(time)
		levelTimerStart = time
	end, gameOver, function()
		scene.Open("Title", 0.5)
	end)

	hook.add("think", "spectate", function()

		if levelTimerStart then
			local t = timer.realtime() - levelTimerStart
			local level = math.floor((t+levelDuration/2) / levelDuration) + 1
			if level ~= lastLevel then
				lastLevel = level
				Background:SetLevel(level)
			end
		end

	end)

	return function()
		hook.remove("net", "spectate")
		hook.remove("think", "spectate")
		root:Remove()

		gfx.KillAllParticles()
	end

end

scene.Register("Spectate", SCENE)
