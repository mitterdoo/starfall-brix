--[[
	An asynchronous loader library. Provides basic progress bar support.
	Once the loader is finished, calls the "load" hook.
]]

--@name Loader
--@author mitterdoo
--@client
--@include brix/client/sprite.lua
--@include brix/client/assets.lua
--@include brix/client/sound.lua

loader = {}

local co -- The main coroutine
loader.await = coroutine.yield
local shouldResume = false

function loader.resume(useHook)

	if not co then
		error("Attempt to resume loader coroutine when it doesn't exist!")
	end
	if useHook then 
		shouldResume = true
		return
	end
	coroutine.resume(co)
	if coroutine.status(co) == "dead" then
		-- Getting here implies the coroutine did not error. Errors would halt execution
		co = nil
		hook.remove("think", "loaderCoroutine")
		hook.run("load")
	end

end

function loader.run(func)

	local function wrapper()
		local ok, err = xpcall(func, function(err, stack)
			if type(err) ~= "string" then return err end
			return tostring(err) .. "\n" .. tostring(stack)
		end)
		if not ok then
			if type(err) == "table" then
				print("<LOADER ERROR>")
				print(tostring(err.message))
				for _, line in pairs(string.split(err.traceback, "\n")) do
					print(line)
				end
				error(tostring(err.message) .. "\nthe stack: " .. tostring(err.traceback))
			end
			error(tostring(err))
		end
	end

	co = coroutine.create(wrapper)
	hook.add("think", "loaderCoroutine", function()
		if shouldResume then
			loader.resume()
		end
	end)
	loader.resume()

end




loader.status = ""
loader.curStep = 0
loader.stepCount = 1


loader.run(function()


	-- Check for permissions first
    local perms = {
        "http.get",
        "input",
        "material.datacreate",
        "material.create",
        "render.renderView",
		"bass.loadFile",
		"bass.play2D",
		"file.read",
		"file.write",
		"file.exists"
    }
	for _, name in pairs(perms) do
		if not hasPermission(name, chip()) then
			setupPermissionRequest(perms, "BRIX 33 needs permission to download sounds and sprites online, save them locally, and load them from disk. Additionally, this game uses input for controls.", true)
			
			local function drawPerm(x, y)
				local w, h = 512, 512
				render.setFont("DermaLarge")
				render.setRGBA(0, 255, 255, 255)
				render.drawText(x + w/2, y + h * 0.25, "PERMISSION REQUEST", 1)
				render.setRGBA(255, 255, 0, 255)
				render.drawText(x + w/2, y + h * 0.5 - 24, [[BRIX 33 requires certain settings
to be enabled in order to run.
Please press USE on the chip
to temporarily change them.]], 1)
			end

			hook.add("postdrawhud", "loader", function()
				local w, h = render.getGameResolution()
				render.setRGBA(0, 0, 0, 255)
				render.drawRect(0, 0, w, h)
				drawPerm(w / 2 - 256, h / 2 - 256)
			end)

			hook.add("render", "loader", function()
				
				drawPerm(0, 0)

			end)

			hook.add("permissionrequest", "loader", function()
				if permissionRequestSatisfied() then
					hook.remove("permissionrequest", "loader")
					hook.remove("postdrawhud", "loader")
					loader.resume()
				end
			end)
			loader.await()
			break
		end
	end
	
	
	local title = render.createFont("Roboto", 64, 900)
	local subtitle = render.createFont("Roboto", 32, 500)
	local header = render.createFont("Roboto", 32, 400)

	hook.add("render", "loader", function()
	
		
		local percent = loader.curStep / loader.stepCount
		local percentStr = math.floor(percent * 100) .. "%"
		local status = loader.status

		local w, h = 512, 512
		render.setFont(title)
		render.setRGBA(255, 255, 255, 255)
		render.drawText(w/2, h * 0.15, "BRIX 33", 1)
		render.setFont(subtitle)
		render.setRGBA(255, 130, 0, 255)
		render.drawText(w/2, h * 0.15 + 64, "STACK TO THE DEATH", 1)
		
		local bw, bh = 300, 100
		local bx, by = w/2 - bw/2, h * 0.6
		local border = 4
		render.setRGBA(255, 255, 255, 255)
		render.drawRect(bx - border, by - border, bw + border*2, bh + border*2)
		render.setRGBA(0, 0, 0, 255)
		render.drawRect(bx, by, bw, bh)
		render.setRGBA(0, 255, 0, 255)
		render.drawRect(bx, by, bw * percent, bh)
		render.setFont(title)
		render.setRGBA(255, 255, 255, 255)
		render.drawText(bx + bw/2, by + bh * 0.2, percentStr, 1)
		
		render.setFont(header)
		render.setRGBA(255, 255, 0, 255)
		render.drawText(bx + bw/2, by - 72, status, 1)

	end)

	require("brix/client/assets.lua")

	assets.download("https://raw.githubusercontent.com/mitterdoo/starfall-brix/master/res/")

	require("brix/client/sprite.lua")
	require("brix/client/sound.lua")
	
	print("Finish")
	hook.remove("render", "loader")

end)

