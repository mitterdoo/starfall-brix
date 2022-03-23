--[[
BRIX: Stack to the Death, a multiplayer brick stacking game written for the Starfall addon in Garry's Mod.
Copyright (C) 2022  Connor Ashcroft

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see LICENSE.md).
If not, see <https://www.gnu.org/licenses/>.
]]
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
binput.isController = false

local keymap_UI = {
	ui_up = "uparrow",
	ui_down = "downarrow",
	ui_left = "leftarrow",
	ui_right = "rightarrow",
	ui_accept = "enter",
	ui_cancel = "backspace"
}

local keymap_Guideline = { -- Keyboard input mappings
	game_moveleft =		"leftarrow",
	game_moveright =	"rightarrow",
	game_rot_ccw =		{"z", "ctrl", "rctrl"},
	game_rot_cw =		{"x", "uparrow"},
	game_softdrop =		"downarrow",
	game_harddrop =		"space",
	game_hold =			{"c", "shift", "rshift"},
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


binput.keymaps = {
	guideline = keymap_Guideline,
	wasd = keymap_wasd
}

function binput.setKeyboardMap(map)
	local cur = binput.keyboardMap
	if binput.keymaps[map] then
		binput.keyboardMap = binput.keymaps[map]
	else
		binput.keyboardMap = map
	end

	if binput.keyboardMap ~= cur then
		settings.keyboardMap = map
		hook.run("keyboardMapChanged", binput.keyboardMap)
	end
end

local loadedMap = settings.keyboardMap or "guideline"
binput.setKeyboardMap(loadedMap)

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
	local triggered = false
	for action, trigger in pairs(map) do
		if type(trigger) == "table" then
			for _, inp in pairs(trigger) do
				if inp == iname then
					execAction(action, pressed)
					triggered = true
					break
				end
			end
		elseif trigger == iname then
			execAction(action, pressed)
			triggered = true
		end
	end
	return triggered

end

hook.add("inputPressed", "binput", function(key)
	if not render.isHUDActive() then return end
	if input.getCursorVisible() then return end
	key = binput.getKeyName(key)
	processInput(key, keymap_UI, true)
	processInput(key, binput.keyboardMap, true)
	binput.isController = false
end)

hook.add("inputReleased", "binput", function(key)
	if not render.isHUDActive() then return end
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
	ui_accept = {"gp_a", "start"},
	ui_cancel = {"gp_b", "back"}
}
local gpmap_Guideline = {
	game_moveleft =		"dpadleft",
	game_moveright =	"dpadright",
	game_rot_ccw =		{"gp_a", "gp_y"},
	game_rot_cw =		{"gp_b", "gp_x"},
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

function binput.getBinding(action, isGamepad, customMap)

	local found
	if isGamepad then
		found = (customMap and customMap[action]) or binput.gamepadMap[action] or gpmap_UI[action]
	else
		found = (customMap and customMap[action]) or binput.keyboardMap[action] or keymap_UI[action]
	end
	if found then
		if type(found) == "table" then
			return unpack(found)
		else
			return found
		end
	end

end


hook.add("gamepadButton", "binput", function(button, pressed)
	processInput(button, gpmap_UI, pressed)
	processInput(button, binput.gamepadMap, pressed)
	if pressed then binput.isController = true end
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
	[XINPUT_GAMEPAD_A] =				"gp_a",
	[XINPUT_GAMEPAD_B] =				"gp_b",
	[XINPUT_GAMEPAD_X] =				"gp_x",
	[XINPUT_GAMEPAD_Y] =				"gp_y"
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

	if not render.isHUDActive() then return end
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

	if not render.isHUDActive() then return end
	if controller == 0 then
		xinputPressed(button, false)
	end

end)

hook.add("xinputPressedNoOverlap", "xinput2brix", function(controller, button, when)

	if not render.isHUDActive() then return end
	if controller == 0 then
		xinputPressed(button, true)
	end

end)


hook.add("xinputReleased", "xinput2brix", function(controller, button, when)

	if not render.isHUDActive() then return end
	if controller == 0 then
		xinputReleased(button, false)
	end

end)

hook.add("xinputReleasedNoOverlap", "xinput2brix", function(controller, button, when)

	if not render.isHUDActive() then return end
	if controller == 0 then
		xinputReleased(button, true)
	end

end)

