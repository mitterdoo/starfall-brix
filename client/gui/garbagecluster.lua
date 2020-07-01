local PANEL = {}

local nagDuration = 0.2

local function lerp( delta, from, to )

	if ( delta > 1 ) then return to end
	if ( delta < 0 ) then return from end

	return from + ( to - from ) * delta

end

function PANEL:Init()

	self.brickSize = 48
	self.count = 1
	self.state = 0
	self.stateChange = 0

end

function PANEL:SetBrickSize(size)
	self.brickSize = size
end

function PANEL:SetCount(count)
	self.count = count
end

function PANEL:SetState(state)
	if state == self.state then return end
	self.state = state
	self.stateChange = timer.realtime()
end

local garbageSprite = sprite.sheets[1].garbage

local col_white = Vector(255, 255, 255)
local col_yellow = Vector(255, 255, 0)
local col_orange = Vector(255, 200, 0)
local col_red = Vector(255, 0, 0)

function PANEL:PaintGlowing(frac, isGlow)

	local brickSize = self.brickSize
	local state = self.state
	
	if state == 3 and isGlow then
		local col = lerp(frac, col_white, col_orange)
		render.setRGBA(col[1], col[2], col[3], math.sin(timer.realtime() * math.pi * 2 * 4) * 127.5 + 127.5)
		render.drawRectFast(0, brickSize * -self.count, brickSize, brickSize * self.count)
	end


	if frac >= 1 then return end

	do
		local frac = math.max(0, frac * 1.5 - 0.5)
		local col = lerp(frac, col_white, state == 1 and col_yellow or col_red)
		render.setRGBA(col[1], col[2], col[3], (1 - frac)*255)
		
		local w, h = brickSize * (1 + frac*0.2), brickSize * self.count + brickSize*frac*0.2
		local x, y = brickSize / 2 - w / 2, brickSize * -self.count/2 - h/2

		render.drawRectFast(x, y, w, h)
	end


	if frac < 0.75 then
		frac = frac / 0.75
		render.setRGBA(255, 255, 255, (1 - frac)^2*255)
		for i = 1, self.count do

			local w, h = brickSize * (1 + frac), brickSize * (1 - frac*0.3)
			local x, y = brickSize / 2 - w/2, i * -brickSize + brickSize/2 - h/2
			render.drawRectFast(x, y, w, h)

		end
	end

end

function PANEL:Paint()

	sprite.setSheet(1)
	local brickSize = self.brickSize

	if self.state == 0 then
		render.setRGBA(255, 255, 255, 255)
	elseif self.state == 1 then
		render.setRGBA(255, 255, 0, 255)
	else
		render.setRGBA(255, 0, 0, 255)
	end
	for i = 1, self.count do
	
		sprite.draw(garbageSprite, 0, i * -brickSize, brickSize, brickSize)

	end
	if self.state ~= 0 then
		local frac = math.min(1, (timer.realtime() - self.stateChange) / nagDuration)

		gui.startGlow()
		self:PaintGlowing(frac, true)
		gui.endGlow()

		self:PaintGlowing(frac, false)

	end

end


gui.Register("GarbageCluster", PANEL, "Control")
