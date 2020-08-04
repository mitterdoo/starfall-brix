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
