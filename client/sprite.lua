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

		loader.curStep = i
		local sheet = sheetsToLoad[i]
		if sheet.isMat then
			local path, name = sheet[1], sheet.name

			loader.status = "Loading material\n" .. path
			if not file.exists(path) then
				error("Attempt to create spritesheet from unknown path: " .. tostring(path))
			end
			local mat = material.createFromImage("data/sf_filedata/" .. path, "smooth")
			sprite.mats[name] = mat

			while quotaAverage() / quotaMax() >= 0.1 do
				loader.sleep(0.5)
			end

		else
			local idx, path, coords = unpack(sheet)

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
	end

	loader.curStep = 0
	loader.stepCount = 1

end

local function createSheet(idx, path, coords)

	table.insert(sheetsToLoad, {idx, path, coords})

end

local function createMaterial(path, name)
	table.insert(sheetsToLoad, {path, name = name, isMat = true})
end

sprite = {}
sprite.sheets = allCoords
sprite.mats = {}

createMaterial(assets.files["brix_logo.png"], "logo")

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
	[15] = {240, 0, 48, 48},

	-- Monochrome pieces for hardmode
	classicPiece = 16,
	classicPieceGhost = 17,
	[16] = {192, 96, 48, 48},
	[17] = {240, 96, 48, 48},

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

	[39] = {638, 544 + 80*5, 64, 80}, -- slash
	digits = 40, -- numeric digits 0-9
	[40] = {638, 544 + 80*0, 64, 80},
	[41] = {638, 544 + 80*1, 64, 80},
	[42] = {638, 544 + 80*2, 64, 80},
	[43] = {638, 544 + 80*3, 64, 80},
	[44] = {638, 544 + 80*4, 64, 80},
	[45] = {638+64, 544 + 80*0, 64, 80},
	[46] = {638+64, 544 + 80*1, 64, 80},
	[47] = {638+64, 544 + 80*2, 64, 80},
	[48] = {638+64, 544 + 80*3, 64, 80},
	[49] = {638+64, 544 + 80*4, 64, 80},

	[50] = {704, 966, 64, 80}, -- colon
	[51] = nil,
	[52] = nil,

	[53] = nil,
	[54] = nil,
	[55] = nil,
	[56] = nil,

	[57] = {97, 513, 70, 130}, -- enemy outline

	targetReticle = 58,
	[58] = {193, 289, 64, 64}, -- target outline
	targetBlip = 59,
	[59] = {193, 354, 144, 144}, -- target blip effect

	attack = 60,
	[60] = {480+96*4, 256, 96, 96}, -- outgoing attack raw
	[61] = {480+96*3, 256, 96, 96}, -- outgoing attack 25%
	[62] = {480+96*2, 256, 96, 96}, -- outgoing attack 50%
	[63] = {480+96*1, 256, 96, 96}, -- outgoing attack 75%
	[64] = {480, 256, 96, 96}, -- outgoing attack 100%

	matchmaking = 65,
	[65] = {767, 608 + 64*0, 256, 64}, -- matching
	[66] = {767, 608 + 64*1, 256, 64}, -- get ready

	phase = 67,
	[67] = {767, 736 + 96*0, 256, 96}, -- ready
	[68] = {767, 736 + 96*1, 256, 96}, -- go
	[69] = {320, 0, 318, 32}, -- players remaining
	[70] = {767, 736 + 96*2, 256, 96}, -- victory

	killCount = 71,
	[71] = {0, 704, 144, 32},
	playerCount = 72,
	[72] = {0, 736, 144, 32},

	finalPlaces = 73,
	[73] = {0, 784, 320, 32},
	
	badgeBonus = 74,
	[74] = {96, 320 + 48*0, 96, 48},
	[75] = {96, 320 + 48*1, 96, 48},
	[76] = {96, 320 + 48*2, 96, 48},
	[77] = {96, 320 + 48*3, 96, 48},

	particles = 78,
	[78] = {224, 592, 80, 80}, -- star
	[79] = {128, 672, 64, 64}, -- glow

	garbageIdle = 80,
	[80] = {192, 48, 48, 48},
	garbageLit = 81,
	[81] = {240, 48, 48, 48},

	blockout = 82,
	[82] = {194, 1, 46, 46},

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

	targetBigBlip = 91,
	[91] = {193, 498, 144, 144},
	targetHit = 92,
	[92] = {193 + 144, 354, 144, 144},

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

	button = 8,
	[8] = {512, 0, 256, 80},
	tickbox = 9,
	[9] = {944, 0, 80, 80},
	[10] = {864, 0, 80, 80},

	b_play = 11,
	[11] = {512, 96 + 64*0,		256, 64},
	b_options = 12,
	[12] = {512, 96 + 64*1,		256, 64},
	b_about = 13,
	[13] = {512, 96 + 64*2,		256, 64},
	b_test = 14,
	[14] = {768, 96 + 64*0,		256, 64},
	b_kbGuideline = 15,
	[15] = {768, 96 + 64*1,		256, 64},
	b_kbWasd = 16,
	[16] = {768, 96 + 64*2,		256, 64},
	b_gp = 17,
	[17] = {768, 96 + 64*3,		256, 64},
	ongoingMatch = 18,
	[18] = {512, 288, 256, 48},

	options = 19,
	[19] = {512, 352 + 32*0,	320, 32}, -- 0 move left
	[20] = {512, 352 + 32*1,	320, 32}, -- 1 move right
	[21] = {512, 352 + 32*2,	320, 32}, -- 2 soft drop
	[22] = {512, 352 + 32*3,	320, 32}, -- 3 hard drop
	[23] = {512, 352 + 32*4,	320, 32}, -- 4 rotate left
	[24] = {512, 352 + 32*5,	320, 32}, -- 5 rotate right
	[25] = {512, 352 + 32*6,	320, 32}, -- 6 swap hold piece
	[26] = {512, 352 + 32*7,	320, 32}, -- 7 targeting mode
	[27] = {512, 352 + 32*8,	320, 32}, -- 8 manual target
	[28] = {512, 352 + 32*9,	320, 32}, -- 9 dynamic background
	[29] = {512, 832, 320, 32},			  -- 10 dpad overlap

	credit = 30,
	[30] = {512, 688, 512, 128},

	xinputWarn = 31,
	[31] = {512, 864, 512, 112},

	spectating = 32,
	[32] = {0, 896, 512, 64}
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

createSheet(4, assets.files["controlicons.png"], {
	gp_buttons = 0,
	[0]  = {16 + 112 * 0,		16 + 112 * 0,		96, 96}, -- a
	[1]  = {16 + 112 * 1,		16 + 112 * 0,		96, 96}, -- b
	[2]  = {16 + 112 * 0,		16 + 112 * 1,		96, 96}, -- x
	[3]  = {16 + 112 * 1,		16 + 112 * 1,		96, 96}, -- y

	gp_triggers = 4,
	[4]  = {16 + 112 * 2,		16 + 112 * 0,		96, 96}, -- lt
	[5]  = {16 + 112 * 3,		16 + 112 * 0,		96, 96}, -- rt
	gp_bumpers = 6,
	[6]  = {16 + 112 * 2,		16 + 112 * 1,		96, 96}, -- lb
	[7]  = {16 + 112 * 3,		16 + 112 * 1,		96, 96}, -- rb

	gp_sticks = 8,
	[8]  = {16 + 112 * 4,		16 + 112 * 0,		96, 96}, -- l
	[9]  = {16 + 112 * 5,		16 + 112 * 0,		96, 96}, -- r
	gp_back = 10,
	[10] = {16 + 112 * 4,		16 + 112 * 1,		96, 96}, -- back
	gp_start = 11,
	[11] = {16 + 112 * 5,		16 + 112 * 1,		96, 96}, -- start

	gp_directional = 12,
	[12] = {16 + 112 * 6,		16 + 112 * 0,		96, 96}, -- up
	[13] = {16 + 112 * 7,		16 + 112 * 0,		96, 96}, -- right
	[14] = {16 + 112 * 7,		16 + 112 * 1,		96, 96}, -- down
	[15] = {16 + 112 * 6,		16 + 112 * 1,		96, 96}, -- left


	kb_icon = 16,
	[16] = {16 + 112 * 0,		16 + 112 * 2,		96, 96}, -- 0 key
	[17] = {16 + 112 * 1,		16 + 112 * 2,		96, 96}, -- 1 wide key
	[18] = {16 + 112 * 0,		16 + 112 * 3,		96, 96}, -- 2 numpad background

	kb_labels = 19,
	[19] = {16 + 112 * 2,		16 + 112 * 2,		96, 96}, -- 0 space
	[20] = {16 + 112 * 3,		16 + 112 * 2,		96, 96}, -- 1 shift
	[21] = {16 + 112 * 4,		16 + 112 * 2,		96, 96}, -- 2 up
	[22] = {16 + 112 * 5,		16 + 112 * 2,		96, 96}, -- 3 right
	[23] = {16 + 112 * 6,		16 + 112 * 2,		96, 96}, -- 4 down
	[24] = {16 + 112 * 7,		16 + 112 * 2,		96, 96}, -- 5 left
	[25] = {16 + 112 * 8,		16 + 112 * 2,		96, 96}, -- 6 return
	[26] = {16 + 112 * 1,		16 + 112 * 3,		96, 96}, -- 7 backspace
	[27] = {16 + 112 * 2,		16 + 112 * 3,		96, 96}, -- 8 tab
})

createSheet(5, assets.files["about1.png"], {
	[0] = {1, 1, 510, 510},
	[1] = {513, 1, 510, 510},
	[2] = {1, 513, 510, 510},
	[3] = {513, 513, 510, 510}
})

createSheet(6, assets.files["about2.png"], {
	[0] = {1, 1, 510, 510},
	[1] = {513, 1, 510, 510},
	[2] = {1, 513, 510, 510}
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
