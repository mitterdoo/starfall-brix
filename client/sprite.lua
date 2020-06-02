--[[
	This should be run within a loader coroutine, as this code is blocking.
]]
--@name BRIX: Sprite loader
--@author mitterdoo
--@client

local sheets = {}
local allCoords = {}


local SMALL_RESOLUTION = true or ({render.getGameResolution()})[2] < 1024


local function errFunc(txt)
	print("ERROR", txt)
	hook.add("render", "err", function()
		
		render.setRGBA(255,0,0, 255)
		render.drawRect(0, 0, 512, 512)
		render.setRGBA(255, 255, 255, 255)
		--render.setFont("DermaLarge")
		render.drawText(0, 0, txt)

	end)
end

local function createSheet(idx, path, coords)

	if not file.exists(path) then
		error("Attempt to create spritesheet from unknown path: " .. tostring(path))
	end

	local mat = material.create("UnlitGeneric")
	local body = file.read(path)
	body = http.base64Encode(body):gsub("\n", "")
	body = "data:image/png;base64," .. body

	local tryApplyingTexture
	local tries = 0

	tryApplyingTexture = function()
		if tries > 10 then
			error("Too many attempts to apply spritesheet " .. tostring(path))
		end
		tries = tries + 1
		loader.status = "LOADING SPRITESHEET (attempt " .. tries .. ")\n" .. path
		mat:setTextureURL("$basetexture", body, function(newMat, _, w, h, performLayout)
			if not newMat then
				tryApplyingTexture()
				return
			end

			sheets[idx] = {mat = newMat, coords = coords}
			allCoords[idx] = coords
			if SMALL_RESOLUTION then
				performLayout(0, 0, 512, 512)
			end
		
		end, function()
		
			loader.resume()

		end)
	end
	tryApplyingTexture()
	loader.await()

end

sprite = {}
sprite.sheets = allCoords

createSheet(1, assets.files["skin1.png"], {

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
	[17] = {368, 384, 48, 48},

	enemy = 18,
	[18] = {0, 192, 64, 128},

	ko = 19,
	[19] = {64, 192, 64, 64},
	ko_us = 20,
	[20] = {64, 256, 64, 64},

	badgeBits = 21,
	[21] = {0, 320, 64, 64},
	[22] = {0, 320 + 64 * 1, 64, 64},
	[23] = {0, 320 + 64 * 2, 64, 64},
	[24] = {0, 320 + 64 * 3, 64, 64},
	[25] = {0, 320 + 64 * 4, 64, 64},
	[26] = {0, 320 + 64 * 5, 64, 64},
	[27] = {0, 320 + 64 * 6, 64, 64},
	[28] = {0, 320 + 64 * 7, 64, 64},
	[29] = {64, 320, 64, 64},
	[30] = {64, 320 + 64 * 1, 64, 64},
	[31] = {64, 320 + 64 * 2, 64, 64},
	[32] = {64, 320 + 64 * 3, 64, 64},
	[33] = {64, 320 + 64 * 4, 64, 64},
	[34] = {64, 320 + 64 * 5, 64, 64},
	[35] = {64, 320 + 64 * 6, 64, 64},
	[36] = {64, 320 + 64 * 7, 64, 64},

})

createSheet(3, assets.files["playfield.png"], {
	
	field = 0,
	[0] = {0, 0, 1024, 1024},
		field_main = {146 * 2, 476 * 2, 22 * 2}, -- x, y, brickSize
		field_main_clip = {292, 72 - 17, 440, 880 + 17}, -- x, y, w, h
		field_garbage = {108 * 2, 474 * 2, 22 * 2},
		field_next = {378 * 2, 287 * 2, 12 * 2},
		field_hold = {86 * 2, 95 * 2, 12 * 2},

		arena_stats = {752, 597, 104, 355},

	enemy = 1,
	[1] = {20, 52, 48, 96},
	[2] = {76, 52, 48, 96},
	[3] = {20, 168, 48, 96},
	[4] = {76, 168, 48, 96},
	[5] = {20, 286, 48, 96},
	[6] = {76, 286, 48, 96},
	[7] = {20, 404, 48, 96},
	[8] ={76, 404, 48, 96},
	[9] ={20, 522, 48, 96},
	[10] ={76, 522, 48, 96},
	[11] ={20, 640, 48, 96},
	[12] ={76, 640, 48, 96},
	[13] ={20, 758, 48, 96},
	[14] ={76, 758, 48, 96},
	[15] ={20, 876, 48, 96},
	[16] ={76, 876, 48, 96},

	
	[17] = {900, 52, 48, 96},
	[18] = {956, 52, 48, 96},
	[19] = {900, 168, 48, 96},
	[20] = {956, 168, 48, 96},
	[21] = {900, 286, 48, 96},
	[22] = {956, 286, 48, 96},
	[23] = {900, 404, 48, 96},
	[24] ={956, 404, 48, 96},
	[25] ={900, 522, 48, 96},
	[26] ={956, 522, 48, 96},
	[27] ={900, 640, 48, 96},
	[28] ={956, 640, 48, 96},
	[29] ={900, 758, 48, 96},
	[30] ={956, 758, 48, 96},
	[31] ={900, 876, 48, 96},
	[32] ={956, 876, 48, 96},

	watchOut = {335, 976, 354, 38},
	watchOutAttachLeft = {335, 976 + 38/2},
	watchOutAttachRight = {335 + 354, 976 + 38/2}

})
local defaultData = {0, 0, 0, 0}

local curSheet

function sprite.setSheet(idx)
	curSheet = sheets[idx]
	render.setMaterial(curSheet.mat)
end

local const = 0.4 / 1024 -- cut off ugly pixels that have blended in
function sprite.draw(idx, x, y, w, h)

	local scaling = SMALL_RESOLUTION and 0.5 or 1

	local data = curSheet.coords[idx] or defaultData
	render.drawTexturedRectUV(x, y, w, h, data[1] * scaling / 1024 + const, data[2] * scaling / 1024 + const, (data[1] + data[3]) * scaling / 1024 - const, (data[2] + data[4]) * scaling / 1024 - const)

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
