if LITE then return end
local PANEL = {}

local offset_label = sprite.sheets[1].strategy

local TARGET_ATTACKER = ARENA.targetModes.ATTACKER
local TARGET_BADGES = ARENA.targetModes.BADGES
local TARGET_KO = ARENA.targetModes.KO
local TARGET_RANDOM = ARENA.targetModes.RANDOM

local spr_labels = {
	[TARGET_ATTACKER] = offset_label + 0,
	[TARGET_BADGES] = offset_label + 2,
	[TARGET_KO] = offset_label + 1,
	[TARGET_RANDOM] = offset_label + 3
}

local spr_key = 7
local spr_stick = sprite.sheets[1].strategyStick

local offset_background = sprite.sheets[1].strategyIndicator
local field_x, field_bottom, brickSize = unpack(sprite.sheets[3].field_main)

local fadeOutStart = 1
local fadeOutDuration = 0.2
local blipDuration = 0.1
local flickDuration = 0.15

local binds = {
	target_attacker = "?",
	target_random = "?",
	target_ko = "?",
	target_badges = "?"
}

function PANEL:Init()

	PANEL.super.Init(self)
	self.strategy = 0
	self.stickPos = 0
	self.lastChange = 0
	self.lastStickChange = 0
	self.foreground = false

	binds.target_attacker = binput.getBinding("target_attacker", false)
	binds.target_random = binput.getBinding("target_random", false)
	binds.target_ko = binput.getBinding("target_ko", false)
	binds.target_badges = binput.getBinding("target_badges", false)

end

function PANEL:SetStrategy(strat)
	self.lastChange = timer.realtime()
	self.lastStickChange = timer.realtime()
	self.strategy = strat
end

local centerSpacing = 32
local sprObj_indicator = sprite.sheets[1][offset_background]
local indicator_w, indicator_h = sprObj_indicator[3], sprObj_indicator[4]

local keyFontSize = 24
local keyFont = render.createFont("Roboto", keyFontSize, 900)
local stickFontSize = 36
local stickFont = render.createFont("Roboto", stickFontSize, 100)


function PANEL:Think()

	local t = timer.realtime()

	local isActive = binput.isPressed("target_attacker") or
		binput.isPressed("target_random") or
		binput.isPressed("target_ko") or
		binput.isPressed("target_badges")

	if isActive then
		self.lastStickChange = t
	end


	local frac = timeFrac(t, self.lastStickChange + fadeOutStart, self.lastStickChange + fadeOutStart + fadeOutDuration)
	if frac <= 1 then
		self.invalid = true

		if self.foreground == false then
			self.foreground = true
			if self.RequestLayerChange then
				self.RequestLayerChange(true)
			end
		end

	end

	frac = math.max(0, math.min(1, frac))


	local alpha = 255 - frac*240

	self.alpha = alpha

	if frac == 1 and self.foreground then
		self.foreground = false
		if self.RequestLayerChange then
			self.RequestLayerChange(false)
		end
	end

end

local keySize = 20

function PANEL:Paint(w, h)

	local strat = self.strategy

	render.setRGBA(255, 255, 255, 255)

	sprite.setSheet(1)

	local t = timer.realtime()
	local frac = timeFrac(t, self.lastChange, self.lastChange + blipDuration)
	frac = math.max(0, math.min(1, frac))

	local cx, cy = brickSize*5, brickSize*2

	if not binput.isController then


		sprite.draw(spr_key, cx, cy - centerSpacing, keySize, keySize, 0, -1)
		sprite.draw(spr_key, cx, cy + centerSpacing, keySize, keySize, 0, 1)
		sprite.draw(spr_key, cx - centerSpacing, cy, keySize, keySize, -1, 0)
		sprite.draw(spr_key, cx + centerSpacing, cy, keySize, keySize, 1, 0)
		render.setRGBA(0, 0, 0, 255)

		render.setFont(keyFont)
		render.drawText(cx, cy - centerSpacing + keySize/2 - keyFontSize/2, binds.target_ko, 1)
		render.drawText(cx, cy + centerSpacing - keySize/2 - keyFontSize/2, binds.target_attacker, 1)
		render.drawText(cx - centerSpacing + keySize/2, cy - keyFontSize/2, binds.target_random, 1)
		render.drawText(cx + centerSpacing - keySize/2, cy - keyFontSize/2, binds.target_badges, 1)
		render.setRGBA(255, 255, 255, 255)

		sprite.setSheet(1)

	else

		render.setFont(stickFont)

		sprite.draw(spr_stick, cx, cy, 64, 64, 0, 0)

		local stick_x, stick_y = cx, cy
		local stickDistance = (64 - 36)* 0.5

		if binput.isPressed("target_random") then
			stick_x, stick_y = cx - stickDistance, cy
		elseif binput.isPressed("target_badges")  then
			stick_x, stick_y = cx + stickDistance, cy
		elseif binput.isPressed("target_ko")  then
			stick_x, stick_y = cx, cy - stickDistance
		elseif binput.isPressed("target_attacker")  then
			stick_x, stick_y = cx, cy + stickDistance
		end

		sprite.draw(spr_stick, stick_x, stick_y, 36, 36, 0, 0)
		render.drawText(stick_x, stick_y - stickFontSize/2, "R", 1)
		sprite.setSheet(1)

	end

	-- Random
	local x, y = cx - centerSpacing - indicator_w/2 - 1, cy
	local spr = offset_background + (strat == TARGET_RANDOM and 1 or 0)
	local scale = strat == TARGET_RANDOM and (2 - frac) or 1
	sprite.draw(spr, x, y, scale, nil, 0, 0)
	sprite.draw(spr_labels[TARGET_RANDOM], x, y, scale, nil, 0, 0)

	-- Badges
	x, y = cx + centerSpacing + indicator_w/2 + 1, cy
	spr = offset_background + (strat == TARGET_BADGES and 1 or 0)
	scale = strat == TARGET_BADGES and (2 - frac) or 1
	sprite.draw(spr, x, y, scale, nil, 0, 0)
	sprite.draw(spr_labels[TARGET_BADGES], x, y, scale, nil, 0, 0)

	-- KO's
	x, y = cx, cy - centerSpacing - indicator_h/2 - 1
	spr = offset_background + (strat == TARGET_KO and 1 or 0)
	scale = strat == TARGET_KO and (2 - frac) or 1
	sprite.draw(spr, x, y, scale, nil, 0, 0)
	sprite.draw(spr_labels[TARGET_KO], x, y, scale, nil, 0, 0)

	-- Attackers
	x, y = cx, cy + centerSpacing + indicator_h/2 + 1
	spr = offset_background + (strat == TARGET_ATTACKER and 1 or 0)
	scale = strat == TARGET_ATTACKER and (2 - frac) or 1
	sprite.draw(spr, x, y, scale, nil, 0, 0)
	sprite.draw(spr_labels[TARGET_ATTACKER], x, y, scale, nil, 0, 0)


end

gui.Register("Strategy", PANEL, "RTControl")
