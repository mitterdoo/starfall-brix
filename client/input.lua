--@name BRIX 33: Input
--@client
--@include brix/client/xinput_nooverlap.lua

DPAD_NO_OVERLAP = false
XINPUT_GAMEPAD_DPAD_UP =		0x0001
XINPUT_GAMEPAD_DPAD_DOWN =		0x0002
XINPUT_GAMEPAD_DPAD_LEFT =		0x0004
XINPUT_GAMEPAD_DPAD_RIGHT =		0x0008
XINPUT_GAMEPAD_START =			0x0010
XINPUT_GAMEPAD_BACK =			0x0020
XINPUT_GAMEPAD_LEFT_THUMB =		0x0040
XINPUT_GAMEPAD_RIGHT_THUMB =	0x0080
XINPUT_GAMEPAD_LEFT_SHOULDER =	0x0100
XINPUT_GAMEPAD_RIGHT_SHOULDER =	0x0200
XINPUT_GAMEPAD_A =				0x1000
XINPUT_GAMEPAD_B =				0x2000
XINPUT_GAMEPAD_X =				0x4000
XINPUT_GAMEPAD_Y =				0x8000

binput = {}

local keymap_UI = {
	ui_up = "uparrow",
	ui_down = "downarrow",
	ui_left = "leftarrow",
	ui_right = "rightarrow",
	ui_accept = "enter",
	ui_cancel = {"escape", "backspace"}
}

local keymap_Guideline = { -- Keyboard input mappings
	game_moveleft =		"leftarrow",
	game_moveright =	"rightarrow",
	game_rot_ccw =		{"a", "ctrl", "rctrl"},
	game_rot_cw =		{"s", "uparrow"},
	game_softdrop =		"downarrow",
	game_harddrop =		"space",
	game_hold =			{"d", "shift", "rshift"},
	target_attacker =	"1",
	target_badges =		"2",
	target_ko =			"3",
	target_random =		"4",
	target_manualPrev = "r",
	target_manualNext = "f"
}

local keymap_wasd = {

	game_moveleft =		"a",
	game_moveright =	"d",
	game_rot_ccw =		"leftarrow",
	game_rot_cw =		{"uparrow", "rightarrow"},
	game_softdrop =		"s",
	game_harddrop =		"w",
	game_hold =			"shift",
	target_attacker =	"1",
	target_badges =		"2",
	target_ko =			"3",
	target_random =		"4",
	target_manualPrev = "r",
	target_manualNext = "f"

}

binput.keyboardMap = keymap_wasd




local KEYS = {
	[37]	= "kp_0",
	[38]	= "kp_1",
	[39]	= "kp_2",
	[40]	= "kp_3",
	[41]	= "kp_4",
	[42]	= "kp_5",
	[43]	= "kp_6",
	[44]	= "kp_7",
	[45]	= "kp_8",
	[46]	= "kp_9",
	[47]	= "kp_divide",
	[48]	= "kp_multiply",
	[49]	= "kp_minus",
	[50]	= "kp_plus",
	[51]	= "kp_enter",
	[52]	= "kp_decimal"
}

function binput.getFirstBinding(action, map)

	local found = map[action]
	if found then
		return type(found) == "table" and found[1] or found
	end

end

function binput.getKeyName(key)
	return KEYS[key] or input.getKeyName(key)
end

local CUR_ACTIONS = {
	ui_up = false,
	ui_down = false,
	ui_left = false,
	ui_right = false,
	ui_accept = false,
	ui_cancel = false,
	game_moveleft = false,
	game_moveright = false,
	game_rot_ccw = false,
	game_rot_cw = false,
	game_softdrop = false,
	game_harddrop = false,
	game_hold = false,
	target_attacker = false,
	target_badges = false,
	target_ko = false,
	target_random = false,
	target_manualPrev = false,
	target_manualNext = false,
	manual_up =			false,
	manual_down =		false,
	manual_left =		false,
	manual_right =		false
}

local function execAction(action, pressed)
	CUR_ACTIONS[action] = pressed
	hook.run("action", action, pressed)
end

function binput.isPressed(action)
	return CUR_ACTIONS[action]
end

local function processInput(iname, map, pressed)

	iname = iname:lower()
	for action, trigger in pairs(map) do
		if type(trigger) == "table" then
			for _, inp in pairs(trigger) do
				if inp == iname then
					execAction(action, pressed)
					break
				end
			end
		elseif trigger == iname then
			execAction(action, pressed)
		end
	end

end

hook.add("inputPressed", "binput", function(key)
	if input.getCursorVisible() then return end
	key = binput.getKeyName(key)
	processInput(key, keymap_UI, true)
	processInput(key, binput.keyboardMap, true)
end)

hook.add("inputReleased", "binput", function(key)
	if input.getCursorVisible() then return end
	key = binput.getKeyName(key)
	processInput(key, keymap_UI, false)
	processInput(key, binput.keyboardMap, false)
end)

local gpmap_UI = {
	ui_up = {"dpadup", "lsup"},
	ui_down = {"dpaddown", "lsdown"},
	ui_left = {"dpadleft", "lsleft"},
	ui_right = {"dpadright", "lsright"},
	ui_accept = {"start", "a"},
	ui_cancel = {"back", "b"}
}
local gpmap_Guideline = {
	game_moveleft =		"dpadleft",
	game_moveright =	"dpadright",
	game_rot_ccw =		{"a", "y"},
	game_rot_cw =		{"b", "x"},
	game_softdrop =		"dpaddown",
	game_harddrop =		"dpadup",
	game_hold =			{"lb", "rb"},
	target_attacker =	"rsdown",
	target_badges =		"rsright",
	target_ko =			"rsup",
	target_random =		"rsleft",

	manual_up =			"lsup",
	manual_down =		"lsdown",
	manual_left =		"lsleft",
	manual_right =		"lsright"
}

binput.gamepadMap = gpmap_Guideline

function binput.isUsingController()

	if xinput and xinput.getControllers()[0] then return true end
	return false

end

--[[
	dpadup
	dpaddown
	dpadleft
	dpadright
	start
	back
	lsclick
	rsclick
	lb
	rb
	a
	b
	x
	y
	lsup
	lsdown
	lsleft
	lsright
	rsup
	rsdown
	rsleft
	rsright
	ltdown
	rtdown
]]


hook.add("gamepadButton", "binput", function(button, pressed)
	processInput(button, gpmap_UI, pressed)
	processInput(button, binput.gamepadMap, pressed)
end)


local GAMEPAD_INPUT = {
	[XINPUT_GAMEPAD_DPAD_UP] =			"dpadup",
	[XINPUT_GAMEPAD_DPAD_DOWN] =		"dpaddown",
	[XINPUT_GAMEPAD_DPAD_LEFT] =		"dpadleft",
	[XINPUT_GAMEPAD_DPAD_RIGHT] =		"dpadright",
	[XINPUT_GAMEPAD_START] =			"start",
	[XINPUT_GAMEPAD_BACK] =				"back",
	[XINPUT_GAMEPAD_LEFT_THUMB] =		"lsclick",
	[XINPUT_GAMEPAD_RIGHT_THUMB] =		"rsclick",
	[XINPUT_GAMEPAD_LEFT_SHOULDER] =	"lb",
	[XINPUT_GAMEPAD_RIGHT_SHOULDER] =	"rb",
	[XINPUT_GAMEPAD_A] =				"a",
	[XINPUT_GAMEPAD_B] =				"b",
	[XINPUT_GAMEPAD_X] =				"x",
	[XINPUT_GAMEPAD_Y] =				"y"
}

local function gamepadInput(name, pressed)
	hook.run("gamepadButton", name, pressed)
end


local directions = {
	[1] = "down",
	[2] = "right",
	[3] = "up",
	[4] = "left"
}
local function stickDirectionName(stick, dir)
	return (stick == 0 and "ls" or "rs") .. directions[dir]
end

local lastStick = {[0] = 0, [1] = 0}

hook.add("xinputStick", "xinput2brix", function(controller, x, y, stick, when)

	if controller == 0 then
		local radius = math.sqrt(x^2 + y^2)
		local angle = math.deg(math.atan(y/x))
		if x > 0 then
			angle = angle + 90
		else
			angle = angle + 270
		end

		angle = (angle + 45) % 360
		if radius >= 16384 then

			local mode = math.ceil(angle / 90)
			if mode ~= lastStick[stick] then
				if lastStick[stick] ~= 0 then
					gamepadInput(stickDirectionName(stick, lastStick[stick]), false)
				end
				gamepadInput(stickDirectionName(stick, mode), true)
				lastStick[stick] = mode
			end

		else
			if lastStick[stick] ~= 0 then
				gamepadInput(stickDirectionName(stick, lastStick[stick]), false)
			end

			lastStick[stick] = 0
		end

	else
		if lastStick[stick] ~= 0 then
			gamepadInput(stickDirectionName(stick, lastStick[stick]), false)
		end
		lastStick[stick] = 0
	end

end)

local function xinputPressed(button, noOverlap)

	if noOverlap ~= DPAD_NO_OVERLAP then return end
	local map = GAMEPAD_INPUT[button]
	if map ~= nil then
		gamepadInput(map, true)
	end

end

local function xinputReleased(button, noOverlap)

	if noOverlap ~= DPAD_NO_OVERLAP then return end

	local map = GAMEPAD_INPUT[button]
	if map ~= nil then
		gamepadInput(map, false)
	end

end

hook.add("xinputPressed", "xinput2brix", function(controller, button, when)

	if controller == 0 then
		xinputPressed(button, false)
	end

end)

hook.add("xinputPressedNoOverlap", "xinput2brix", function(controller, button, when)

	if controller == 0 then
		xinputPressed(button, true)
	end

end)


hook.add("xinputReleased", "xinput2brix", function(controller, button, when)

	if controller == 0 then
		xinputReleased(button, false)
	end

end)

hook.add("xinputReleasedNoOverlap", "xinput2brix", function(controller, button, when)

	if controller == 0 then
		xinputReleased(button, true)
	end

end)


do return end
DPAD_NO_OVERLAP = false

binput.stickEvents = {
	MODE_DOWN = ARENA.targetModes.ATTACKER,
	MODE_RIGHT = ARENA.targetModes.BADGES,
	MODE_UP = ARENA.targetModes.KO,
	MODE_LEFT = ARENA.targetModes.RANDOM,

	MANUAL_DOWN = 12,
	MANUAL_RIGHT = 13,
	MANUAL_UP = 14,
	MANUAL_LEFT = 15,

	MANUAL_PREV = 16,
	MANUAL_NEXT = 17
}

KEYBOARD_INPUT = { -- Keyboard input mappings
	[89] = brix.inputEvents.MOVELEFT,	-- leftarrow
	[91] = brix.inputEvents.MOVERIGHT,	-- rightarrow

	[11] = brix.inputEvents.ROT_CCW,	-- a
	[83] = brix.inputEvents.ROT_CCW,	-- lctrl
	[84] = brix.inputEvents.ROT_CCW,	-- rctrl

	[29] = brix.inputEvents.ROT_CW,		-- s
	[88] = brix.inputEvents.ROT_CW,		-- uparrow

	[90] = brix.inputEvents.SOFTDROP,	-- downarrow

	[65] = brix.inputEvents.HARDDROP,	-- spacebar

	[14] = brix.inputEvents.HOLD,		-- s
	[79] = brix.inputEvents.HOLD,		-- lshift
	[80] = brix.inputEvents.HOLD,		-- rshift

	[2] = ARENA.targetModes.ATTACKER,	-- 1
	[3] = ARENA.targetModes.BADGES,		-- 2
	[4] = ARENA.targetModes.KO,			-- 3
	[5] = ARENA.targetModes.RANDOM,		-- 4

	[28] = binput.stickEvents.MANUAL_PREV,
	[16] = binput.stickEvents.MANUAL_NEXT

}

KEYBOARD_INPUTMAP = {}

function binput.updateMap()
	for key, binding in pairs(KEYBOARD_INPUT) do

		if not KEYBOARD_INPUTMAP[binding] then
			KEYBOARD_INPUTMAP[binding] = {}
		end
		table.insert(KEYBOARD_INPUTMAP[binding], key)

	end
end

binput.updateMap()

function binput.isUsingController()

	if xinput and xinput.getControllers()[0] then return true end
	return false

end

hook.add("inputPressed", "input2brix", function(button)

	if input.getCursorVisible() then return end
	if binput.isUsingController() then return end
	local map = KEYBOARD_INPUT[button]
	if map ~= nil then
		hook.run("brixPressed", map)
	end

end)

hook.add("inputReleased", "input2brix", function(button)

	if input.getCursorVisible() then return end
	if binput.isUsingController() then return end
	local map = KEYBOARD_INPUT[button]
	if map ~= nil then
		hook.run("brixReleased", map)
	end

end)


local GAMEPAD_INPUT = {
		
	[0x0001] = brix.inputEvents.HARDDROP,
	[0x0002] = brix.inputEvents.SOFTDROP,
	[0x0004] = brix.inputEvents.MOVELEFT,
	[0x0008] = brix.inputEvents.MOVERIGHT,
	[0x2000] = brix.inputEvents.ROT_CW,
	[0x1000] = brix.inputEvents.ROT_CCW,
	[0x4000] = brix.inputEvents.ROT_CW,
	[0x8000] = brix.inputEvents.ROT_CCW,
	[0x0100] = brix.inputEvents.HOLD,
	[0x0200] = brix.inputEvents.HOLD,


	
}

local lastStick = {[0] = 0, [1] = 0}
binput.stickState = lastStick

hook.add("xinputStick", "xinput2brix", function(controller, x, y, stick, when)

	if controller == 0 then
		local eventOffset = stick == 1 and binput.stickEvents.MODE_DOWN or binput.stickEvents.MANUAL_DOWN
		local radius = math.sqrt(x^2 + y^2)
		local angle = math.deg(math.atan(y/x))
		if x > 0 then
			angle = angle + 90
		else
			angle = angle + 270
		end

		angle = (angle + 45) % 360
		if radius >= 16384 then

			local mode = math.floor(angle / 90) + eventOffset
			if mode ~= lastStick[stick] then
				hook.run("brixPressed", mode)
				lastStick[stick] = mode
			end

		else
			lastStick[stick] = 0
		end

	else
		lastStick[stick] = 0
	end

end)

local function xinputPressed(button, noOverlap)

	if noOverlap ~= DPAD_NO_OVERLAP then return end
	local map = GAMEPAD_INPUT[button]
	if map ~= nil then
		hook.run("brixPressed", map)
	end

end

local function xinputReleased(button, noOverlap)

	if noOverlap ~= DPAD_NO_OVERLAP then return end
	local map = GAMEPAD_INPUT[button]
	if map ~= nil then
		hook.run("brixReleased", map)
	end

end

hook.add("xinputPressed", "xinput2brix", function(controller, button, when)

	if controller == 0 then
		xinputPressed(button, false)
	end

end)

hook.add("xinputPressedNoOverlap", "xinput2brix", function(controller, button, when)

	if controller == 0 then
		xinputPressed(button, true)
	end

end)


hook.add("xinputReleased", "xinput2brix", function(controller, button, when)

	if controller == 0 then
		xinputReleased(button, false)
	end

end)

hook.add("xinputReleasedNoOverlap", "xinput2brix", function(controller, button, when)

	if controller == 0 then
		xinputReleased(button, true)
	end

end)
