local PANEL = {}

local function lerp( delta, from, to )

	if ( delta > 1 ) then return to end
	if ( delta < 0 ) then return from end

	return from + ( to - from ) * delta

end

local function lerpColorVector(delta, from, to)

	if ( delta > 1 ) then return to end
	if ( delta < 0 ) then return from end

	return Vector((from[1]^2 + (to[1]^2 - from[1]^2) * delta)^0.5,
		(from[2]^2 + (to[2]^2 - from[2]^2) * delta)^0.5,
		(from[3]^2 + (to[3]^2 - from[3]^2) * delta)^0.5)

end
function PANEL:Init()

	self.particles = {}
	self.sheet = 1
	self.sprite = 0

	self.spriteW = 1
	self.spriteH = 1

	self.emissionRate = 1
	self.lastEmission = 0
	self.lifetime = 1

	self.angleInitial = 0
	self.angleSpeed = 0

	self.sizeA = 32
	self.sizeB = 32

	self.colorA = Vector(255, 255, 255)
	self.colorB = Vector(255, 255, 255)

	self.randAngle = false
	self.randAngleSpeedMin = 0
	self.randAngleSpeedMax = 0
	self.randVel = 0

	self.alphaA = 255
	self.alphaB = 255

	self.velX = 0
	self.velY = 0
	self.gravX = 0
	self.gravY = 0

	self.lastThink = timer.realtime()

end

function PANEL:SetSheet(sheet)
	assert(type(sheet) == "number", "sheet must be number")
	self.sheet = sheet
end

function PANEL:SetSprite(spriteIdx)
	self.sprite = spriteIdx
	if spriteIdx ~= nil then
		local _, _, w, h = unpack(sprite.sheets[self.sheet][spriteIdx])
		self.spriteW, self.spriteH = w, h
	else
		self.spriteW, self.spriteH = 1, 1
	end
end

function PANEL:SetEmissionRate(frames)
	self.emissionRate = frames
end

function PANEL:SetLifetime(frames)
	self.lifetime = frames
end

function PANEL:SetInitialAngle(ang)
	self.angleInitial = ang
end

function PANEL:SetRandAngle(useRand)
	self.randAngle = useRand
end

function PANEL:SetRandAngleSpeed(min, max)
	self.randAngleSpeedMin = min
	self.randAngleSpeedMax = max
end

function PANEL:SetRandVelocity(scale)
	if not scale then
		self.randVel = 0
	else
		self.randVel = scale
	end
end

function PANEL:SetAngleSpeed(speed)
	self.angleSpeed = speed
end

function PANEL:SetInitialVelocity(vx, vy)
	self.velX = vx
	self.velY = vy
end

function PANEL:SetGravity(gx, gy)
	self.gravX = gx
	self.gravY = gy
end

function PANEL:SetSizeEnvelope(a, b)
	self.sizeA = a
	self.sizeB = b
end

function PANEL:SetColorEnvelope(a, b)
	self.colorA = Vector(a.r, a.g, a.b)
	self.colorB = Vector(b.r, b.g, b.b)
end

function PANEL:SetAlphaEnvelope(a, b)
	self.alphaA = a
	self.alphaB = b
end

function PANEL:Emit(time)

	local vel = Vector(self.velX, self.velY)
	vel = Vector(math.random()*2-1, math.random()*2-1, 0):getNormalized() * self.randVel + vel

	local particle = {
		x = math.random(0, self.w),
		y = math.random(0, self.h),
		vx = vel[1],
		vy = vel[2],
		angleSpeed = self.angleSpeed + math.random(self.randAngleSpeedMin, self.randAngleSpeedMax),
		birth = time,
		death = time + self.lifetime,
		angle = self.randAngle and math.random(0, 359) or self.angleInitial
	}
	table.insert(self.particles, particle)

end

function PANEL:Think()

	local time = timer.realtime()
	local dt = time - self.lastThink
	self.lastThink = time


	if time >= self.lastEmission + self.emissionRate then

		self.lastEmission = time
		self:Emit(time)

	end

	while true do
		local particle = self.particles[1]
		if particle ~= nil and particle.death <= time then
			table.remove(self.particles, 1)
		else
			break
		end
	end

	local gravX = self.gravX * dt
	local gravY = self.gravY * dt
	for _, particle in pairs(self.particles) do

		particle.angle = particle.angle + particle.angleSpeed * dt
		particle.vx = particle.vx + gravX
		particle.vy = particle.vy + gravY
		particle.x = particle.x + particle.vx * dt
		particle.y = particle.y + particle.vy * dt

	end

end

function PANEL:Paint(w, h)

	local spr = self.sprite
	if spr then
		sprite.setSheet(self.sheet)
	end

	local ratio = self.spriteW / self.spriteH
	local isWide = self.spriteW >= self.spriteH
	local m = Matrix()

	local time = timer.realtime()

	local sizeA, sizeB = self.sizeA, self.sizeB
	local colorA, colorB = self.colorA, self.colorB
	local alphaA, alphaB = self.alphaA, self.alphaB

	for _, particle in pairs(self.particles) do

		local perc = (time - particle.birth) / (particle.death - particle.birth)
		local x, y = particle.x, particle.y

		local size = lerp(perc, sizeA, sizeB)
		local col = lerpColorVector(perc, colorA, colorB)
		local alpha = lerp(perc, alphaA, alphaB)
		render.setRGBA(col[1], col[2], col[3], alpha)

		local sw, sh
		if isWide then
			sw, sh = size, size / ratio
		else
			sw = size * ratio, sh
		end

		local sx, sy = x - sw/2, y - sh/2

		local angle = particle.angle
		if angle == 0 then
			if spr then
				sprite.draw(spr, sx, sy, sw, sh)
			else
				render.drawRect(sx, sy, sw, sh)
			end
		else
			m:setTranslation(Vector(sx, sy, 0))
			m:setAngles(Angle(0, angle, 0))

			gui.pushMatrix(m)
			if spr then
				sprite.draw(spr, sw/-2, sh/-2, sw, sh)
			else
				render.drawRect(sw/-2, sh/-2, sw, sh)
			end
			gui.popMatrix()
		end


	end

end


gui.Register("Emitter", PANEL, "Control")
