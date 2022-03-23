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
--@includedir brix/client/scenes

scene = {}
scene.Registry = {}
function scene.Register(name, tab)
	scene.Registry[name] = tab
end

requiredir("brix/client/scenes")
scene.Entry = "Title"

local function closeActiveScene()

	local name = scene.ActiveName
	scene.Active()
	scene.Active = nil
	scene.ActiveName = nil
	hook.run("sceneClose", name)

end

local function setActiveScene(name, from)

	scene.ActiveName = name
	scene.Active = scene.Registry[name]
	scene.Active = scene.Active.Open(from)
	hook.run("sceneOpen", name)

end

hook.add("think", "sceneTransitions", function()

	local t = timer.realtime()
	local s = scene.NextScene
	if s and t >= s.finish then
		local curName = scene.ActiveName
		closeActiveScene()
		setActiveScene(s.name, curName)
		gui.fadeIn(s.transition)
		scene.NextScene = nil
	end

end)

function scene.Open(name, transition)

	if name == nil then
		name = scene.Entry
		transition = 1
	end

	if not scene.Registry[name] then
		error("Attempt to open nil scene \"" .. tostring(name) .. "\"")
	end

	if scene.Active then
		if transition then
			if not scene.NextScene then
				hook.run("sceneClosing", scene.ActiveName)
				scene.NextScene = {name = name, start = timer.realtime(), finish = timer.realtime() + transition, transition = transition}
				gui.fadeOut(transition)
			end
		else
			local curName = scene.ActiveName
			hook.run("sceneClosing", curName)
			closeActiveScene()
			setActiveScene(name, curName)
		end
	else
		setActiveScene(name)
		if transition then
			gui.fadeIn(transition)
		end
	end

end

function scene.Close()

	if scene.Active then
		hook.run("sceneClosing", scene.ActiveName)
		closeActiveScene()
		scene.NextScene = nil
	end

end

