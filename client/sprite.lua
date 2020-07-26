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
local sheetsToLoad = {}

local function loadSheets()

	local count = #sheetsToLoad

	loader.stepCount = count
	for i = 1, count do

		local idx, path, coords = unpack(sheetsToLoad[i])

		loader.curStep = i
		loader.status = "Loading spritesheet\n" .. path

		if not file.exists(path) then
			error("Attempt to create spritesheet from unknown path: " .. tostring(path))
		end

		local start = timer.systime()
		local mat = material.createFromImage("data/sf_filedata/" .. path, "smooth")
		local loadTime = timer.systime() - start
		sheets[idx] = {mat = mat, coords = coords}
		sprite.mats[idx] = mat
		allCoords[idx] = coords


		loader.sleep(loadTime * 8)
	end

	loader.curStep = 0
	loader.stepCount = 1

end

local function createSheet(idx, path, coords)

	table.insert(sheetsToLoad, {idx, path, coords})

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
	enemy_outline = 57,

	ko = 19, -- KO icon
	[19] = {64, 192, 64, 64},
	ko_us = 20, -- Our KO icon
	[20] = {64, 256, 64, 64},

	-- 16 badge bit progress sprites
	badgeBits = 21,
	[21] = {0, 320, 48, 48},
	[22] = {0, 320 + 48 * 1, 48, 48},
	[23] = {0, 320 + 48 * 2, 48, 48},
	[24] = {0, 320 + 48 * 3, 48, 48},
	[25] = {0, 320 + 48 * 4, 48, 48},
	[26] = {0, 320 + 48 * 5, 48, 48},
	[27] = {0, 320 + 48 * 6, 48, 48},
	[28] = {0, 320 + 48 * 7, 48, 48},
	[29] = {48, 320, 48, 48},
	[30] = {48, 320 + 48 * 1, 48, 48},
	[31] = {48, 320 + 48 * 2, 48, 48},
	[32] = {48, 320 + 48 * 3, 48, 48},
	[33] = {48, 320 + 48 * 4, 48, 48},
	[34] = {48, 320 + 48 * 5, 48, 48},
	[35] = {48, 320 + 48 * 6, 48, 48},
	[36] = {48, 320 + 48 * 7, 48, 48},

	watchOut = 37,
	[37] = {0, 832, 354, 38},
	[38] = {0, 880, 354, 38},

	[39] = {128, 192 + 80*5, 64, 80}, -- slash
	digits = 40, -- numeric digits 0-9
	[40] = {128, 192 + 80*0, 64, 80},
	[41] = {128, 192 + 80*1, 64, 80},
	[42] = {128, 192 + 80*2, 64, 80},
	[43] = {128, 192 + 80*3, 64, 80},
	[44] = {128, 192 + 80*4, 64, 80},
	[45] = {192, 192 + 80*0, 64, 80},
	[46] = {192, 192 + 80*1, 64, 80},
	[47] = {192, 192 + 80*2, 64, 80},
	[48] = {192, 192 + 80*3, 64, 80},
	[49] = {192, 192 + 80*4, 64, 80},

	bigButton = 50,
	[50] = {480, 96, 256, 80},
	[51] = {192, 96, 256, 48}, -- play
	[52] = {192, 144, 256, 48}, -- next

	smallButton = 53,
	[53] = {480, 192, 128, 48},
	[54] = {320, 192 + 48*1, 128, 48}, -- about
	[55] = {320, 192 + 48*2, 128, 48}, -- controls
	[56] = {320, 192 + 48*3, 128, 48}, -- back

	[57] = {365, 703, 70, 130}, -- enemy outline

	[58] = {449, 353, 80, 140}, -- target outline
	[59] = {530, 353, 64, 124}, -- target blip effect

	attack = 60,
	[60] = {480+96*4, 256, 96, 96}, -- outgoing attack raw
	[61] = {480+96*3, 256, 96, 96}, -- outgoing attack 25%
	[62] = {480+96*2, 256, 96, 96}, -- outgoing attack 50%
	[63] = {480+96*1, 256, 96, 96}, -- outgoing attack 75%
	[64] = {480, 256, 96, 96}, -- outgoing attack 100%

	matchmaking = 65,
	[65] = {512, 512 + 64*0, 512, 64}, -- matching
	[66] = {512, 512 + 64*1, 512, 64}, -- get ready

	phase = 67,
	[67] = {512, 640 + 96*0, 512, 96}, -- ready
	[68] = {512, 640 + 96*1, 512, 96}, -- go
	[69] = {449, 0, 318, 64}, -- players remaining
	[70] = {512, 640 + 96*2, 512, 96}, -- victory

	killCount = 71,
	[71] = {320, 624, 144, 32},
	playerCount = 72,
	[72] = {320, 656, 144, 32},

	finalPlaces = 73,
	[73] = {0, 784, 320, 32},
	
	badgeBonus = 74,
	[74] = {336, 432 + 48*0, 96, 48},
	[75] = {336, 432 + 48*1, 96, 48},
	[76] = {336, 432 + 48*2, 96, 48},
	[77] = {336, 432 + 48*3, 96, 48},

	particles = 78,
	[78] = {224, 592, 80, 80}, -- star
	[79] = {128, 672, 64, 64}, -- glow

	garbageIdle = 80,
	[80] = {192, 720, 48, 48},
	garbageLit = 81,
	[81] = {240, 720, 48, 48},

	blockout = 82,
	[82] = {192, 672, 48, 48},

	knockout = 83,
	[83] = {368, 848, 64, 64},

	strategy = 84,
	[84] = {832, 0, 192, 48},
	[85] = {832, 48 * 1, 192, 48},
	[86] = {832, 48 * 2, 192, 48},
	[87] = {832, 48 * 3, 192, 48},

	strategyIndicator = 88,
	[88] = {600, 353, 160, 38},
	[89] = {595, 406, 170, 48},

	strategyStick = 90,
	[90] = {768, 352, 64, 64},

	credits = 100,
	[100] = {0, 960, 512, 64}


})

createSheet(2, assets.files["skin2.png"], {
	clears = 0,
	[0] = {0, 0 * 112, 512, 112},
	[1] = {0, 1 * 112, 512, 112},
	[2] = {0, 2 * 112, 512, 112},
	[3] = {0, 3 * 112, 512, 112},
	
	tricks = 4,
	[4] = {0, 4 * 112, 512, 112},
	[5] = {0, 5 * 112, 512, 112},
	[6] = {0, 6 * 112, 512, 112},
	[7] = {0, 7 * 112, 512, 112},
})

createSheet(3, assets.files["playfield.png"], {
	
	field = 0,
	[0] = {0, 0, 1024, 1024},
	-- The rest of these are mainly reference points for placing down elements
		field_main = {292, 952, 44}, -- x, y, brickSize
		field_main_clip = {292, 72 - 17, 440, 880 + 17}, -- x, y, w, h
		field_garbage = {216, 948, 44},
		field_next = {756, 574, 24},
		field_hold = {172, 190, 24},

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
	watchOutAttachRight = {335 + 353, 976 + 38/2}

})

for i = 1, 11 do

	createSheet(19 + i, assets.files["level_" .. i .. "_bg.png"], {
		[0] = {0, 0, 1024, 1024}
	})

end




loadSheets()

local defaultData = {0, 0, 0, 0}

local curSheet

function sprite.setSheet(idx, customMatFunc)
	curSheet = sheets[idx]
	if customMatFunc then
		customMatFunc(curSheet.mat)
	else
		render.setMaterial(curSheet.mat)
	end
end

local drawFast = render.drawTexturedRectUVFast

local scale = 1025 / 1024

function sprite.draw(idx, x, y, w, h, halign, valign)

	local data = curSheet.coords[idx] or defaultData
	if w == nil then
		w = data[3]
		h = data[4]
	elseif h == nil then
		h = data[4] * w
		w = data[3] * w
	end
	
	halign = halign or -1
	valign = valign or -1
	if halign == 0 then
		x = x - w/2
	elseif halign == 1 then
		x = x - w
	end
	if valign == 0 then
		y = y - h/2
	elseif valign == 1 then
		y = y - h
	end

	local sx, sy, sw, sh = data[1], data[2], data[3], data[4]
	--[[sx = sx - 0.5
	sy = sy - 0.5]]

	local u0, v0, u1, v1 = sx / 1024,
		sy / 1024,
		(sx + sw) / 1024,
		(sy + sh) / 1024

	u0 = (u0-0.5) * scale + 0.5
	v0 = (v0-0.5) * scale + 0.5
	u1 = (u1-0.5) * scale + 0.5
	v1 = (v1-0.5) * scale + 0.5

	drawFast(x, y, w, h, u0, v0, u1, v1)

end
