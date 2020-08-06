if LITE then return end
local PANEL = {}
--[[
	InputIcon Control
	Generates a spritesheet for all allowed inputs for the game
	Allows setting the input name to display it
]]

local sheet = sprite.sheets[4]
local gp_lookup = {
	gp_a = sheet.gp_buttons + 0,
	gp_b = sheet.gp_buttons + 1,
	gp_x = sheet.gp_buttons + 2,
	gp_y = sheet.gp_buttons + 3,
	lb = sheet.gp_bumpers + 0,
	rb = sheet.gp_bumpers + 1,
	back = sheet.gp_back,
	start = sheet.gp_start,
	dpadup = sheet.gp_directional + 0,
	dpadright = sheet.gp_directional + 1,
	dpaddown = sheet.gp_directional + 2,
	dpadleft = sheet.gp_directional + 3,
	ls = sheet.gp_sticks + 0,
	rs = sheet.gp_sticks + 1
}

local kb_RT = "inputicons"
render.createRenderTarget(kb_RT)
local rtIndices = {
	["0"] =		1,
	["1"] =		2,
	["2"] =		3,
	["3"] =		4,
	["4"] =		5,
	["5"] =		6,
	["6"] =		7,
	["7"] =		8,
	["8"] =		9,
	["9"] =		10,
	["a"] =		11,
	["b"] =		12,
	["c"] =		13,
	["d"] =		14,
	["e"] =		15,
	["f"] =		16,
	["g"] =		17,
	["h"] =		18,
	["i"] =		19,
	["j"] =		20,
	["k"] =		21,
	["l"] =		22,
	["m"] =		23,
	["n"] =		24,
	["o"] =		25,
	["p"] =		26,
	["q"] =		27,
	["r"] =		28,
	["s"] =		29,
	["t"] =		30,
	["u"] =		31,
	["v"] =		32,
	["w"] =		33,
	["x"] =		34,
	["y"] =		35,
	["z"] =		36,
	["kp_0"] =		37,
	["kp_1"] =		38,
	["kp_2"] =		39,
	["kp_3"] =		40,
	["kp_4"] =		41,
	["kp_5"] =		42,
	["kp_6"] =		43,
	["kp_7"] =		44,
	["kp_8"] =		45,
	["kp_9"] =		46,
	["kp_divide"] =		47,
	["kp_multiply"] =		48,
	["kp_minus"] =		49,
	["kp_plus"] =		50,
	["kp_enter"] =		51,
	["kp_decimal"] =		52,
	["["] =		53,
	["]"] =		54,
	["semicolon"] =		55,
	["'"] =		56,
	["`"] =		57,
	[","] =		58,
	["."] =		59,
	["/"] =		60,
	["\\"] =		61,
	["-"] =		62,
	["="] =		63,
	["enter"] =		64,
	["space"] =		65,
	["backspace"] =		66,
	["tab"] =		67,
	["capslock"] =		68,
	["numlock"] =		69,
	["escape"] =		70,
	["scrolllock"] =		71,
	["ins"] =		72,
	["del"] =		73,
	["home"] =		74,
	["end"] =		75,
	["pgup"] =		76,
	["pgdn"] =		77,
	["pause"] =		78,
	["shift"] =		79,
	["rshift"] =		80,
	["alt"] =		81,
	["ralt"] =		82,
	["ctrl"] =		83,
	["rctrl"] =		84,
	["uparrow"] =		88,
	["leftarrow"] =		89,
	["downarrow"] =		90,
	["rightarrow"] =		91,
	["f1"] =		92,
	["f2"] =		93,
	["f3"] =		94,
	["f4"] =		95,
	["f5"] =		96,
	["f6"] =		97,
	["f7"] =		98,
	["f8"] =		99,
	["f9"] =		100,
	["f10"] =		101,
	["f11"] =		102,
	["f12"] =		103,
	lb = 			104,
	rb = 			105,
	back = 			106,
	start = 		107,
	dpadup = 		108,
	dpadright = 	109,
	dpaddown = 		110,
	dpadleft = 		111,
	gp_a = 			112,
	gp_b = 			113,
	gp_x = 			114,
	gp_y = 			115,
	rs =			117,
	ls =			118,
}

local kb_special = {
	kp_0 = {"0", kp=true},
	kp_1 = {"1", kp=true},
	kp_2 = {"2", kp=true},
	kp_3 = {"3", kp=true},
	kp_4 = {"4", kp=true},
	kp_5 = {"5", kp=true},
	kp_6 = {"6", kp=true},
	kp_7 = {"7", kp=true},
	kp_8 = {"8", kp=true},
	kp_9 = {"9", kp=true},
	kp_divide = {"/", kp=true},
	kp_multiply = {"*", kp=true},
	kp_minus = {"-", kp=true},
	kp_plus = {"+", kp=true},
	kp_enter = {spr=sheet.kb_labels + 6, kp=true},
	kp_decimal = {".", kp=true},
	semicolon = ";",
	enter = {spr=sheet.kb_labels + 6, wide=true},
	space = {spr=sheet.kb_labels + 0, wide=true},
	backspace = {spr=sheet.kb_labels + 7, wide=true},
	tab = {spr=sheet.kb_labels + 8, wide=true},
	capslock = "CAPS\nLOCK",
	numlock = "NUM\nLOCK",
	scrolllock = "SCRL\nLOCK",
	escape = "ESC",
	pgup = "PAGE\nUP",
	pgdn = "PAGE\nDOWN",
	shift = {spr=sheet.kb_labels + 1, wide=true},
	rshift = {"RIGHT\nSHIFT", wide=true},
	ralt = "RIGHT\nALT",
	rctrl = "RIGHT\nCTRL",
	uparrow = {spr=sheet.kb_labels + 2},
	leftarrow = {spr=sheet.kb_labels + 5},
	downarrow = {spr=sheet.kb_labels + 4},
	rightarrow = {spr=sheet.kb_labels + 3},

}

local kb_normal = sheet.kb_icon + 0
local kb_wide = sheet.kb_icon + 1
local kb_kp = sheet.kb_icon + 2

function PANEL:Init()
	self.input = "0"
end

function PANEL:SetInput(inp)
	self.input = inp
end

local keySize = 64
local sectionSize = keySize+1
local nativeWidth, nativeHeight = render.getGameResolution()
nativeWidth = math.min(1024, nativeWidth)
nativeHeight = math.min(1024, nativeHeight)
local function getKeyPos(idx)
	local w, h = math.floor(nativeWidth / sectionSize), math.floor(nativeHeight / sectionSize)
	if idx < 1 or idx > w*h then
		error("getKeyPos: index " .. idx .. " out of range (max " .. (w*h) .. ")")
	end
	local row = (idx - 1)%h
	local col = math.floor((idx - 1)/h)

	return col * sectionSize, row * sectionSize

end
local keyFont = render.createFont("Roboto", 64, 900)
local padding = 8
hook.add("renderoffscreen", "inputicon", function()

	hook.remove("renderoffscreen", "inputicon")
	gui.pushRT(kb_RT)
	render.clear(Color(0, 0, 0, 0), true)

	for iname, index in pairs(rtIndices) do

		render.setRGBA(255, 255, 255, 255)
		local x, y = getKeyPos(index)
		local w, h = keySize, keySize

		sprite.setSheet(4)
		local gp = gp_lookup[iname]
		local kb = kb_special[iname]

		if gp then
			sprite.draw(gp, x, y, w, h)
		else -- this is a key
			local spr, wide, isKP, label
			local fitH = h
			label = iname:upper()
			if kb then -- there is info on this key
				if type(kb) == "string" then
					label = kb
				else
					spr, wide, isKP, label = kb.spr, kb.wide, kb.kp, kb[1] or label
				end
			end
			if wide then fitH = h/2 end
			sprite.draw(wide and kb_wide or kb_normal, x, y, w, h)
			if isKP then
				sprite.draw(kb_kp, x, y, w, h)
			end

			if spr then
				sprite.draw(spr, x, y, w, h)
			else
				render.setFont(keyFont)
				local tw, th = render.getTextSize(label)
				local scale = gui.getFitScale(tw + padding*2, th + padding*2, w, fitH)
				local mat
				if isKP then
					mat = gui.getMatrix(x + w, y + h, scale, scale)
				else
					mat = gui.getMatrix(x + w/2, y + h/2, scale, scale)
				end
				gui.pushMatrix(mat)
				render.setRGBA(0, 0, 0, 255)
				if isKP then
					render.drawText(tw/-2 - padding, -th - padding, label, 1)
				else
					render.drawText(0, th/-2, label, 1)
				end
				gui.popMatrix(mat)

			end


		end

	end

	do
		local x, y = getKeyPos(116)
		render.setRGBA(255, 0, 0, 255)
		render.drawRectFast(x, y, keySize, keySize)
	end

	gui.popRT()

end)

local const = (7/16) / 1024 -- cut off ugly pixels that have blended in
function drawBinding(x, y, w, h, inp)
	local found = rtIndices[inp]
	found = found or 116

	render.setRGBA(255, 255, 255, 255)

	local ox, oy = getKeyPos(found)
	local sw, sh = keySize, keySize
	render.setRenderTargetTexture(kb_RT)
	render.setRGBA(255, 255, 255, 255)

	local u1, v1 = ox / 1024, oy / 1024
	local u2, v2 = (ox + sw) / 1024, (oy + sh) / 1024

	render.drawTexturedRectUV(x, y, w, h, u1 + const, v1 + const, u2 - const, v2 - const)
end


function PANEL:Paint(w, h)
	drawBinding(0, 0, w, h, self.input)
end

gui.Register("InputIcon", PANEL, "Control")
