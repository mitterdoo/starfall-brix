--[[
	This should be run within a loader coroutine, as this code is blocking.

	Sprite library. Loads all required images and spritesheets, and exposes helper functions to render them to the screen.

	sprite.setSheet(sheetIndex)
	sprite.draw(spriteIndex, x, y, w, h)

]]
--@name BRIX: Sprite loader
--@author mitterdoo
--@client

local sheets = {}
local allCoords = {}


SMALL_RESOLUTION = ({render.getGameResolution()})[2] < 1024 or true


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
			sprite.mats[idx] = newMat
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
sprite.mats = {}

createSheet(1, assets.files["skin1.png"], {

	pieces = 0, -- reference value for ordered sprites
	-- Sprites for colored pieces
	[0] = {0, 0, 48, 48},
	[1] = {48, 0, 48, 48},
	[2] = {48 * 2, 0, 48, 48},
	[3] = {48 * 3, 0, 48, 48},
	[4] = {0, 48, 48, 48},
	[5] = {48, 48, 48, 48},
	[6] = {48 * 2, 48, 48, 48},

	garbage = 7, -- Garbage block
	[7] = {48 * 3, 48, 48, 48},

	pieceGhosts = 8, -- Ghosts of pieces
	[8] = {0, 48 * 2, 48, 48},
	[9] = {48, 48 * 2, 48, 48},
	[10] = {48 * 2, 48 * 2, 48, 48},
	[11] = {48 * 3, 48 * 2, 48, 48},
	[12] = {0, 48 * 3, 48, 48},
	[13] = {48, 48 * 3, 48, 48},
	[14] = {48 * 2, 48 * 3, 48, 48},

	garbageSolid = 15,
	[15] = {48 * 3, 48 * 3, 48, 48},

	-- Monochrome pieces for hardmode
	classicPiece = 16,
	classicPieceGhost = 17,
	[16] = {320, 384, 48, 48},
	[17] = {368, 384, 48, 48},

	-- Enemy matrix background
	enemy = 18,
	[18] = {0, 192, 64, 128},

	ko = 19, -- KO icon
	[19] = {64, 192, 64, 64},
	ko_us = 20, -- Our KO icon
	[20] = {64, 256, 64, 64},

	-- 16 badge bit progress sprites
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

	watchOut = 37,
	[37] = {0, 832, 354, 38},
	[38] = {0, 880, 354, 38},

	[39] = {128, 192 + 80*5, 96, 80}, -- slash
	digits = 40, -- numeric digits 0-9
	[40] = {128, 192 + 80*0, 96, 80},
	[41] = {128, 192 + 80*1, 96, 80},
	[42] = {128, 192 + 80*2, 96, 80},
	[43] = {128, 192 + 80*3, 96, 80},
	[44] = {128, 192 + 80*4, 96, 80},
	[45] = {224, 192 + 80*0, 96, 80},
	[46] = {224, 192 + 80*1, 96, 80},
	[47] = {224, 192 + 80*2, 96, 80},
	[48] = {224, 192 + 80*3, 96, 80},
	[49] = {224, 192 + 80*4, 96, 80},

	bigButton = 50,
	[50] = {192, 0, 256, 80},
	[51] = {192, 96, 256, 48}, -- play
	[52] = {192, 144, 256, 48}, -- next

	smallButton = 53,
	[53] = {320, 192, 128, 48},
	[54] = {320, 192 + 48*1, 128, 48}, -- about
	[55] = {320, 192 + 48*2, 128, 48}, -- controls
	[56] = {320, 192 + 48*3, 128, 48}, -- back

	clears = 57,
	[57] = {768, 64 * 0, 256, 64}, -- single
	[58] = {768, 64 * 1, 256, 64}, -- double
	[59] = {768, 64 * 2, 256, 64}, -- triple
	[60] = {768, 64 * 3, 256, 64}, -- quad
	
	tricks = 61,
	[61] = {768, 64 * 4, 256, 64}, -- tspin
	[62] = {768, 64 * 5, 256, 64}, -- mini tspin
	[63] = {768, 64 * 6, 256, 64}, -- b2b
	[64] = {768, 64 * 7, 256, 64}, -- combo

	matchmaking = 65,
	[65] = {512, 512 + 64*0, 512, 64}, -- matching
	[66] = {512, 512 + 64*1, 512, 64}, -- get ready

	phase = 67,
	[67] = {512, 640 + 96*0, 512, 96}, -- ready
	[68] = {512, 640 + 96*1, 512, 96}, -- go
	[69] = {448, 0, 320, 64}, -- players remaining
	[70] = {512, 640 + 96*2, 512, 96}, -- victory

	killCount = 71,
	[71] = {320, 624, 144, 32},
	playerCount = 72,
	[72] = {320, 656, 144, 32},

	finalPlaces = 73,
	[73] = {128, 784, 256, 48},
	
	badgeBonus = 74,
	[74] = {320, 432 + 48*0, 128, 48},
	[75] = {320, 432 + 48*1, 128, 48},
	[76] = {320, 432 + 48*2, 128, 48},
	[77] = {320, 432 + 48*3, 128, 48},

	credits = 100,
	[100] = {0, 960, 512, 64}


})

createSheet(3, assets.files["playfield.png"], {
	
	field = 0,
	[0] = {0, 0, 1024, 1024},
	-- The rest of these are mainly reference points for placing down elements
		field_main = {146 * 2, 476 * 2, 22 * 2}, -- x, y, brickSize
		field_main_clip = {292, 72 - 17, 440, 880 + 17}, -- x, y, w, h
		field_garbage = {108 * 2, 474 * 2, 22 * 2},
		field_next = {378 * 2, 287 * 2, 12 * 2},
		field_hold = {86 * 2, 95 * 2, 12 * 2},

		arena_stats = {752, 597, 104, 355},

	enemy = 1, -- 32 enemy locations
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
	if w == nil then
		w = data[3]
		h = data[4]
	end
	render.drawTexturedRectUV(x, y, w, h, data[1] * scaling / 1024 + const, data[2] * scaling / 1024 + const, (data[1] + data[3]) * scaling / 1024 - const, (data[2] + data[4]) * scaling / 1024 - const)

end
