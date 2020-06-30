local PANEL = {}

PANEL.animDuration = 0.1
local colorA = Vector(255, 255, 255)
local colorB = Vector(145, 255, 103)

local function lerpColorVector(delta, from, to)

	if ( delta > 1 ) then return to end
	if ( delta < 0 ) then return from end

	return Vector((from[1]^2 + (to[1]^2 - from[1]^2) * delta)^0.5,
		(from[2]^2 + (to[2]^2 - from[2]^2) * delta)^0.5,
		(from[3]^2 + (to[3]^2 - from[3]^2) * delta)^0.5)

end


function PANEL:Init()

	self.brickSize = 48
	self.start = timer.realtime()

end

function PANEL:SetBrickSize(size)
	self.brickSize = size
end

function PANEL:SetLine(line)
	self:SetPos(self.brickSize*5, -self.brickSize * (line + 1))
end

function PANEL:Paint()

	local frac = (timer.realtime() - self.start) / self.animDuration

	if frac >= 1 then
		self:Remove()
		return
	end

	local col = lerpColorVector(frac, colorA, colorB)
	local s = self.brickSize

	local wide = s * 10 * (1 + frac * 0.45)
	local tall = s * (1 - frac*0.8)

	render.setRGBA(col[1], col[2], col[3], 255 - frac*255)
	
	gui.startGlow()
	render.drawRect(wide / -2, s * 0.5 + tall/-2, wide, tall)
	gui.endGlow()

	render.drawRect(wide / -2, s * 0.5 + tall/-2, wide, tall)

end

gui.Register("LineClear", PANEL, "Control")
