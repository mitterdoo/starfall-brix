--[[
	A special asset downloader library with basic file versioning.
	Saves downloaded assets to disk, and redownloads updated files
]]

--@client

assets = {}
local assetFolder = "brix/"
local indexFile = assetFolder .. "brix_index.txt"
if not file.exists(assetFolder) then
	file.createDir(assetFolder)
end

assets.versionIndex = {}
if file.exists(indexFile) then
	assets.versionIndex = json.decode(file.read(indexFile))
end
assets.files = {}

local function normalizePath(path)

	if path:sub(-3):lower() == "png" then
		return path
	else
		return path .. ".dat"
	end

end

function assets.download(url)

	-- First, download the index file

	loader.status = "Getting asset list online..."

	local index
	http.get(url .. "index.json", function(body, length, headers, code)
	
		if code ~= 200 then
			error("Could not get index.json. Error code " .. tostring(code))
		end
		index = json.decode(body)
		loader.resume()

	end, function(err)
		error("Error when fetching index.json: " .. tostring(err))
	end, {["Cache-Control"] = "no-cache"})
	loader.await()

	assets.queue = {}
	for path, version in pairs(index) do
		local current = assets.versionIndex[path]
		if not current or current ~= version then
			-- Outdated or new. download it
			table.insert(assets.queue, {
				url = url .. path,
				path = path
			})
		else
			assets.files[path] = normalizePath(assetFolder .. path)
		end
	end
	local count = #assets.queue
	if count == 0 then return end

	loader.curStep = 0
	loader.stepCount = count

	for i, info in pairs(assets.queue) do
		assets.currentDownloadIndex = k
		assets.currentDownloadInfo = info
		loader.status = "DOWNLOADING ASSETS:\n" .. info.path

		hook.add("think", "downloading", function()
			if http.canRequest() then
				hook.remove("think", "downloading")
				loader.resume()
			end
		end)
		loader.await()
		http.get(info.url, function(body, length, headers, code)
		
			if code ~= 200 then
				error("Could not get file " .. info.url .. ": error code " .. tostring(code))
			end

			local path = normalizePath(assetFolder .. info.path)
			file.write(path, body)
			assets.files[info.path] = path
			loader.resume()
		end, function(err)
			error("Error when fetching " .. info.url .. ": " .. tostring(err))
		end, {["Cache-Control"] = "no-cache"})
		loader.await()
		loader.curStep = loader.curStep + 1
	end

	assets.versionIndex = index
	file.write(indexFile, json.encode(index))

end
