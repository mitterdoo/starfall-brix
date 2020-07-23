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

local offset_background = sprite.sheets[1].strategyIndicator

local fadeOutStart = 1
local fadeOutDuration = 0.2

function PANEL:Init()

	self.strategy = 0
	self.lastChange = 0

end

function PANEL:SetStrategy(strat)
	if strat ~= self.strategy then
		self.lastChange = timer.realtime()
		self.strategy = strat
	end
end

local centerSpacing = 32
local sprObj_indicator = sprite.sheets[1][offset_background]
local indicator_w, indicator_h = sprObj_indicator[3], sprObj_indicator[4]

function PANEL:Paint(w, h)

	local strat = self.strategy

	local t = timer.realtime()
	local frac = timeFrac(t, self.lastChange + fadeOutStart, self.lastChange + fadeOutStart + fadeOutDuration)
	frac = math.max(0, math.min(1, frac))
	local alpha = 255 - frac*240

	render.setRGBA(255, 255, 255, alpha)

	sprite.setSheet(1)

	-- Random
	local x, y = -centerSpacing - indicator_w/2, 0
	local spr = offset_background + (strat == TARGET_RANDOM and 1 or 0)
	sprite.draw(spr, x, y, nil, nil, 0, 0)
	sprite.draw(spr_labels[TARGET_RANDOM], x, y, nil, nil, 0, 0)

	-- Badges
	x, y = centerSpacing + indicator_w/2, 0
	spr = offset_background + (strat == TARGET_BADGES and 1 or 0)
	sprite.draw(spr, x, y, nil, nil, 0, 0)
	sprite.draw(spr_labels[TARGET_BADGES], x, y, nil, nil, 0, 0)

	-- KO's
	x, y = 0, -centerSpacing - indicator_h/2
	spr = offset_background + (strat == TARGET_KO and 1 or 0)
	sprite.draw(spr, x, y, nil, nil, 0, 0)
	sprite.draw(spr_labels[TARGET_KO], x, y, nil, nil, 0, 0)

	-- Attackers
	x, y = 0, centerSpacing + indicator_h/2
	spr = offset_background + (strat == TARGET_ATTACKER and 1 or 0)
	sprite.draw(spr, x, y, nil, nil, 0, 0)
	sprite.draw(spr_labels[TARGET_ATTACKER], x, y, nil, nil, 0, 0)

end

gui.Register("Strategy", PANEL, "Control")
