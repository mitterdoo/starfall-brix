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
local settingsFolder = "brix/"
local settingsFile = "settings.txt"
local settingsPath = settingsFolder .. settingsFile

if not file.exists(settingsFolder) then
	file.createDir(settingsFolder)
end

local _data = {}
local function loadSettings()
	local contents = file.read(settingsPath)
	if contents then
		_data = json.decode(contents)
	end
end

local function saveSettings()
	local contents = json.encode(_data, true)
	file.write(settingsPath, contents)
end

local function checkType(v)
	return type(v) == "string" or type(v) == "number" or type(v) == "boolean"
end

settings = setmetatable({}, {
	__newindex = function(self, k, v)
		if checkType(k) and checkType(v) then
			_data[k] = v
			saveSettings()
		end
	end,
	__index = function(self, k)
		return _data[k]
	end
})

loadSettings()
