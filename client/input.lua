--@name BRIX 33: Input
--@client
--@include brix/client/xinput_nooverlap.lua

DPAD_NO_OVERLAP = false

local KEYBOARD_INPUT = { -- Keyboard input mappings
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
	[5] = ARENA.targetModes.RANDOM		-- 4

	-- TODO: Add manual targeting

}

hook.add("inputPressed", "input2brix", function(button)

	if input.getCursorVisible() then return end
	if xinput.getControllers()[0] then return end
	local map = KEYBOARD_INPUT[button]
	if map ~= nil then
		hook.run("brixPressed", map)
	end

end)

hook.add("inputReleased", "input2brix", function(button)

	if input.getCursorVisible() then return end
	if xinput.getControllers()[0] then return end
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

local lastTargetMode = 0

hook.add("xinputStick", "xinput2brix", function(controller, x, y, stick, when)

	if controller == 0 and stick == 1 then
		local radius = math.sqrt(x^2 + y^2)
		local angle = math.deg(-math.atan(y/x))
		if x > 0 then
			angle = angle + 90
		else
			angle = angle + 270
		end

		angle = (angle + 45) % 360
		if radius >= 16384 then

			local mode = math.floor(angle / 90) + ARENA.targetModes.ATTACKER
			if mode ~= lastTargetMode then
				hook.run("brixPressed", mode)
				lastTargetMode = mode
			end

		else
			lastTargetMode = 0
		end

	else
		lastTargetMode = 0
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
