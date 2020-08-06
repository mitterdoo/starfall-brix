if LITE then return end
local PANEL = {}

local blipDuration = 0.3
local bigBlipDuration = 0.25

function PANEL:Init()

	self.lerpFrom = Vector(0, 0, 0)
	self.lerpTo = Vector(0, 0, 0)
	self.lerpStart = 0
	self.lerpFinish = 0.1

	self.lastBlip = timer.realtime()
	self.lastBigBlip = 0

	self.finished = true

end

function PANEL:Think()
	local t = timer.realtime()

	if t >= self.lastBlip + blipDuration then
		self.lastBlip = t
	end

	if self.finished then return end

	local frac = timeFrac(t, self.lerpStart, self.lerpFinish)
	frac = math.max(0, math.min(1, frac))

	if frac == 1 and not self.finished then
		self.finished = true
	end

	local newPos = lerp(frac, self.lerpFrom, self.lerpTo)
	self:SetPos(newPos[1], newPos[2])

end

function PANEL:MoveTo(x, y)

	self.lerpFrom = Vector(self.x, self.y, 0)
	self.lerpTo = Vector(x, y, 0)
	self.lerpStart = timer.realtime()
	self.lerpFinish = self.lerpStart + 0.25
	self.finished = false

end

function PANEL:Flash()

	self.lastBigBlip = timer.realtime()

end

local spr_target = sprite.sheets[1].targetReticle
local spr_targetBlip = sprite.sheets[1].targetBlip
local spr_targetBigBlip = sprite.sheets[1].targetBigBlip
local target_w, target_h = sprite.sheets[1][spr_target][3], sprite.sheets[1][spr_target][4]

function PANEL:Paint(w, h)

	render.setRGBA(255, 255, 255, 255)
	sprite.setSheet(1)
	sprite.draw(spr_target, 0, 0, nil, nil, 0, 0)

	local t = timer.realtime()
	local blipFrac = timeFrac(t, self.lastBlip, self.lastBlip + blipDuration, true)
	if blipFrac < 1 then

		render.setRGBA(255, 255, 255, 255*(1-blipFrac)^2)
		local size = target_w * (1 + blipFrac)
		sprite.draw(spr_targetBlip, 0, 0, size, size, 0, 0)

	end

	local bigFrac = timeFrac(t, self.lastBigBlip, self.lastBigBlip + bigBlipDuration, true)
	if bigFrac < 1 then
		render.setRGBA(255, 255, 255, 255*(1-bigFrac)^2)
		local size = target_w * (1 + bigFrac * 5)
		sprite.draw(spr_targetBigBlip, 0, 0, size, size, 0, 0)
	end
	
end

gui.Register("Reticle", PANEL, "Control")