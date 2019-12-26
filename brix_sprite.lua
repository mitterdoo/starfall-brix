--@client

local sheets = {}
local neededSheets = 0
local loadedSheets = 0
local allCoords = {}

local function errFunc(txt)
	hook.add("render", "err", function()
		
		render.setRGBA(255,0,0, 255)
		render.drawRect(0, 0, 512, 512)
		render.setRGBA(255, 255, 255, 255)
		--render.setFont("DermaLarge")
		render.drawText(0, 0, txt)

	end)
end

local function createSheet(idx, url, coords)

	neededSheets = neededSheets + 1
	local m = material.create("UnlitGeneric")
	local function success(body, len, headers, code)
	
		if code ~= 200 then
			errFunc("HTTP code " .. tostring(code))
			return
		end

		body = http.base64Encode(body):gsub("\n", "")
		body = "data:image/png;base64," .. body
		local tryApply

		local attempts = 0
		tryApply = function()
			attempts = attempts + 1
			if attempts > 10 then
				errFunc("Downloaded asset, but could not load!\nURL: " .. tostring(url))
				return
			end
			local ok, err = pcall(function()
				m:setTextureURL("$basetexture", body, function(mat, _, w, h, performLayout)

					if not mat then
						print("trying again")
						tryApply()
					else

						sheets[idx] = {mat = mat, coords = coords}
						allCoords[idx] = coords

					end

				end, function()
					loadedSheets = loadedSheets + 1
					if loadedSheets == neededSheets then
						hook.run("spritesLoaded")
					end
				end)
			end)

			if not ok then
				if type(err) == "table" then
					err = err.message
				end
				errFunc(tostring(err))
			end
		end
		tryApply()



	end
	local function fail(reason)

		errFunc("HTTP error: " .. tostring(reason))

	end

	timer.create("http" .. url, 0.5, 0, function()
	
		if http.canRequest() then
			timer.remove("http" .. url)
			http.get(url, success, fail, {["Cache-Control"] = "no-cache"})
		end

	end)

	

end

sprite = {}
sprite.sheets = allCoords

createSheet(1, "http://mitterdoo.net/u/brix/skin1.png", {

	pieces = 0, -- reference value for ordered sprites
	[0] = {0, 0, 48, 48},
	[1] = {48, 0, 48, 48},
	[2] = {48 * 2, 0, 48, 48},
	[3] = {48 * 3, 0, 48, 48},
	[4] = {0, 48, 48, 48},
	[5] = {48, 48, 48, 48},
	[6] = {48 * 2, 48, 48, 48},

	garbage = 7,
	[7] = {48 * 3, 48, 48, 48},

	pieceGhosts = 8,
	[8] = {0, 48 * 2, 48, 48},
	[9] = {48, 48 * 2, 48, 48},
	[10] = {48 * 2, 48 * 2, 48, 48},
	[11] = {48 * 3, 48 * 2, 48, 48},
	[12] = {0, 48 * 3, 48, 48},
	[13] = {48, 48 * 3, 48, 48},
	[14] = {48 * 2, 48 * 3, 48, 48},

	garbageSolid = 15,
	[15] = {48 * 3, 48 * 3, 48, 48},

	classicPiece = 16,
	classicPieceGhost = 17,
	[16] = {320, 384, 48, 48},
	[17] = {368, 384, 48, 48}
})
createSheet(2, "http://mitterdoo.net/u/brix/skin2.png", {


	logo = 1,
	[1] = {0, 512, 512, 512},

	menu = 2,
	[2] = {512, 512, 512, 512},

	t_matching = 3,
	[3] = {512, 0, 512, 64},

	t_getReady = 4,
	[4] = {512, 64, 512, 64},

	t_ready = 5,
	[5] = {512, 128, 512, 96},

	t_go = 6,
	[6] = {512, 128 + 96, 512, 96},

	t_victory = 7,
	[7] = {512, 128 + 96 * 2, 512, 96}
})

createSheet(3, "http://mitterdoo.net/u/brix/playfield.png", {
	
	field = 0,
	[0] = {0, 0, 1024, 1024},
		field_main = {146 * 2, 476 * 2, 22 * 2}, -- x, y, brickSize
		field_garbage = {108 * 2, 474 * 2, 22 * 2},
		field_next = {378 * 2, 287 * 2, 12 * 2},
		field_hold = {86 * 2, 95 * 2, 12 * 2},
})
local defaultData = {0, 0, 0, 0}

local curSheet

function sprite.setSheet(idx)
	curSheet = sheets[idx]
	render.setMaterial(curSheet.mat)
end

local const = 0.4 / 1024 -- cut off ugly pixels that have blended in
function sprite.draw(idx, x, y, w, h)

	local data = curSheet.coords[idx] or defaultData
	render.drawTexturedRectUV(x, y, w, h, data[1] / 1024 + const, data[2] / 1024 + const, (data[1] + data[3]) / 1024 - const, (data[2] + data[4]) / 1024 - const)

end


--[[
local brixBlockData = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAABTUlEQVRoge3Zv6rCMBiG8adpFenk4mV5p66O3omDk4P/iCVGpEjOcIh4NK2eQb8WvmdsKLw/2i3ZYrEghBAulwt9KssynHNZ4ZwL0+mUuq7x3kvveitjDN57ZrNZMM45drsdg8GAsiylt70sjl8ulxyPRwyAtbYXiPvx+/3+91k87DoiNR7uANBdRNN4eABA9xBt4wGK1EvWWgAmkwnD4fCzC190Op0ax0PiC8SstZzP548Ne7f1et04HloAfUkB0ilAOgVIpwDpFCCdAqRTgHQKkE4B0ilAOgVIpwDpFCCdAqRTgHTJC47Ydrtls9l8a0syYwx5nnO9XpPnjYCqqlitVq2XC9+oLEvG43EjIvkLdWU8gPf+duWV5/nT+ROgS+NjbYg/gC6OjzUhboAuj4+lEAb6MT72iCgOh0M2n89DVVXC0/7XaDSiKIrsB4Dj3GnjnS3HAAAAAElFTkSuQmCC"
local assetAttempts = 0
function attemptCreateBlockAsset()
    brixBlock = render.getTextureID( brixBlockData, function(mat, url, w, h, performLayout)
        if mat then
            performLayout(0, 0, 1024,1024)
        elseif assetAttempts < 10 then
            assetAttempts = assetAttempts + 1
            --error("could not load the image")
            attemptCreateBlockAsset()
        end
    end, function()
        ready = true
    end )
end
attemptCreateBlockAsset()
]]