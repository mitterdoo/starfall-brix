if LITE then return end
local PANEL = {}

--[[
$	Dump
	Offset
$	Activate (0)
$	Nag (1)
$	Nag (2, flaming)
]]

local fireFlashFrequency = 0.5

local clusterSpacing = 8
function PANEL:Init()

	self.brickSize = 48
	self.clusters = {}

end

function PANEL:SetBrickSize(size)
	self.brickSize = size
end

function PANEL:GetHeightOfCluster(cluster)

	local height = 0
	local brickSize = self.brickSize
	for k, c in pairs(self.clusters) do
		if k == cluster then return height end
		height = height + brickSize*c.count + clusterSpacing
	end

	return height

end

local function fx_FlashCluster(x, y, w, h, frac, glow)

	render.setRGBA(255, 255, 255, (1-frac)*255)
	render.drawRectFast(x, y, w, h)

end

local function fx_FlashClusterYellow(x, y, w, h, frac, glow)

	local c = (1-frac)*255
	--frac = (frac - 0.6) / 0.6
	render.setRGBA(255, 255, c, c)
	render.drawRectFast(x, y, w, h)

end

local function fx_FlashClusterRed(x, y, w, h, frac, glow)

	local c = (1-frac)*255
	--frac = (frac - 0.6) / 0.6
	render.setRGBA(255, c, c, c)
	render.drawRectFast(x, y, w, h)

end

local function fx_FlashOffset(x, y, w, h, frac, glow)

	--frac = (frac - 0.6) / 0.6
	render.setRGBA((1-frac)^2*255, 255, 255, math.sqrt(1-frac)*255)
	render.drawRectFast(x, y, w, h)

end


local function fx_Fire(x, y, w, h, frac, glow)

	local c = (1-frac)*255
	--frac = (frac - 0.6) / 0.6
	if glow then
		render.setRGBA(255, 255, 0, c/2)
	else
		render.setRGBA(255, c*0.7, 0, c)
	end
	render.drawRectFast(x, y, w, h)

end

local col_yellow = Vector(255, 255, 0)
local col_red = Vector(255, 0, 0)
local function fx_BlockDump(x, y, w, h, frac, glow)

	local step = 1/2
	if glow then
		frac = timeFrac(frac, 0, step)
		if frac > 1 then return end
		render.setRGBA(255, 255, 255, (1-frac)^2*255)
		render.drawRectFast(x, y, w, h)
	else

		if frac < 1/3 then
			render.setRGBA(255, 255, 255, 255)
			render.drawRectFast(x, y, w, h)
		else
			frac = timeFrac(frac, 1/3, 1)
			local col = lerp(frac, col_yellow, col_red)
			render.setRGBA(col[1], col[2], col[3], (1-frac)*255)
			render.drawRectFast(x, y, w, h)
		end

	end

end

local function fx_BlockDumpRaise(x, y, w, h, frac, glow)

	local c = (1-frac)^2*255
	render.setRGBA(255, 255, c, c)
	render.drawRectFast(x, y, w, h)

end

local function random2D()

	local rad = math.random() * math.pi * 2
	return Vector(math.sin(rad), math.cos(rad), 0)

end

function PANEL:Anim_BrickSplode(pos, anim, startSize, endSize, speed, count)

	count = count or 4
	local scale
	pos, scale = self:AbsolutePos(pos)
	local brickSize = self.brickSize

	local size = {
		Vector(startSize, startSize, 0) * scale,
		Vector(endSize, endSize, 0) * scale
	}
	for i = 1, count do

		local startPos = pos + Vector(math.random() * brickSize, math.random() * -brickSize, 0)
		local delta = (startPos - (pos + Vector(brickSize/2, brickSize/-2, 0))):getNormalized()

		local keys_Pos = {startPos, startPos + delta * speed}

		gfx.EmitParticle(
			keys_Pos,
			size,
			0,
			1/3,
			anim,
			true, true
		)

	end

end

function PANEL:Anim_Flash(isRed)

	local animDuration = 1/3
	local c = self.clusters[1]
	if c == nil then return end

	local count = c.count
	local brickSize = self.brickSize
	local colorFunc = isRed and fx_FlashClusterRed or fx_FlashClusterYellow
	for i = 1, count do

		local pos, scale = Vector(brickSize/2, brickSize/2 - brickSize*i, 0)
		pos, scale = self:AbsolutePos(pos)
		gfx.EmitParticle(
			{pos, pos},
			{Vector(brickSize, brickSize, 0)*scale,
			Vector(brickSize * 1.4, brickSize*0.9, 0)*scale},
			0, animDuration*0.4,
			fx_FlashCluster, true, true
		)

	end

	local pos, scale = self:AbsolutePos(Vector(brickSize/2, brickSize * -count/2, 0))
	gfx.EmitParticle(
		{pos, pos},
		{Vector(brickSize, brickSize*count, 0)*scale,
		Vector(brickSize * 1.2, brickSize*count, 0)*scale},
		0, animDuration,
		colorFunc, true, true
	)

end
function PANEL:Anim_Fire()

	local animDuration = 1/4
	local c = self.clusters[1]
	if c == nil then return end

	local count = c.count
	local brickSize = self.brickSize

	local pos, scale = self:AbsolutePos(Vector(brickSize/2, brickSize * -count/2, 0))
	gfx.EmitParticle(
		{pos, pos},
		{Vector(brickSize, brickSize*count, 0)*scale,
		Vector(brickSize * 1.2, brickSize*count, 0)*scale},
		0, animDuration,
		fx_Fire, true, true
	)

end

function PANEL:Anim_Offset(count)

	local animDuration = 1/3
	local brickSize = self.brickSize

	local heights = {}
	for k, cluster in pairs(self.clusters) do

		local h = self:GetHeightOfCluster(k)
		if cluster.count < count then
			for i = 1, cluster.count do
				table.insert(heights, h + brickSize * (i-1))
			end
			count = count - cluster.count
		else
			for i = 1, count do
				table.insert(heights, h + brickSize * (i-1))
			end
			break
		end

	end
	
	for _, y in pairs(heights) do

		local pos, scale = Vector(brickSize/2, -y - brickSize/2, 0)
		pos, scale = self:AbsolutePos(pos)
		local bsize = Vector(brickSize, brickSize, 0)*scale
		gfx.EmitParticle(
			{pos, pos, pos, pos, pos, pos, pos},
			{bsize, bsize*1.5, bsize, bsize*1.5, bsize, bsize*1.5, bsize},
			0, animDuration,
			fx_FlashOffset, false, true
		)

		self:Anim_BrickSplode(Vector(0, -y, 0), fx_FlashOffset, 20, 15, 30, 4)

	end

end


local deltaGarbageToMatrixCenter -- The distance from the garbage absolute pos, to the center of the matrix.
do
	local garbage = sprite.sheets[3].field_garbage
	local field = sprite.sheets[3].field_main

	deltaGarbageToMatrixCenter = Vector(field[1] + field[3]*5 - (garbage[1] + garbage[3]/2),
		field[2] - field[3]/2 - (garbage[2] - garbage[3]/2), 0)
end

function PANEL:Anim_Dump()
	local brickSize = self.brickSize

	do
		self:Anim_BrickSplode(Vector(0, 0, 0), fx_BlockDump, 20, 15, 60, 3)
	end

	do
		local pos, scale = self:AbsolutePos(Vector(brickSize/2, brickSize/-2, 0))
		local startSize = Vector(brickSize, brickSize, 0)
		local endSize = startSize * 1.3

		gfx.EmitParticle(
			{pos, pos},
			{startSize*scale, endSize*scale},
			0, 1/3,
			fx_BlockDump,
			true, true
		)
	end

	do

		local startPos, scale = self:AbsolutePos(Vector(brickSize/2, brickSize/-2, 0))
		local endPos = startPos + deltaGarbageToMatrixCenter * scale

		local keys_Pos = {
			{0, startPos},
			{0.5, endPos},
			{1, endPos}
		}

		local keys_Size = {
			{0, Vector(brickSize, brickSize, 0)},
			{0.5, Vector(brickSize * 10, brickSize, 0)},
			{1, Vector(brickSize * 5, brickSize * 0.8, 0)}
		}

		gfx.EmitParticle(keys_Pos, keys_Size,
			0, 1/3,
			fx_BlockDump,
			true, true
		)

	end

	do

		local startPos = self:AbsolutePos(Vector(brickSize/2, 0, 0) + deltaGarbageToMatrixCenter)
		local endPos = startPos - Vector(0, brickSize * 4, 0)
		local size = Vector(brickSize * 10, brickSize * 0.5, 0)

		gfx.EmitParticle({startPos, endPos},
			{size, size},
			0, 1/4,
			fx_BlockDumpRaise,
			true, true)

	end


end

function PANEL:RemoveBlocks(count)

	for i = 1, count do
		local cur = self.clusters[1]
		if not cur then break end

		cur.count = cur.count - 1
		if cur.count == 0 then
			cur:Remove()
			table.remove(self.clusters, 1)
		end

	end

	for k, cluster in pairs(self.clusters) do
		cluster:SetPos(0, -self:GetHeightOfCluster(k))
	end

end

function PANEL:Think()

	local c = self.clusters[1]
	if not c then return end

	if c.state == 3 then
		local t = timer.realtime()
		if not c.nextFlash or t >= c.nextFlash then
			c.nextFlash = t + fireFlashFrequency
			self:Anim_Fire()
		end
	end


end




function PANEL:Enqueue(lines)

	local brickSize = self.brickSize
	local height = self:GetHeightOfCluster(#self.clusters + 1)


	local g = gui.Create("GarbageCluster", self)
	g:SetBrickSize(brickSize)
	g:SetPos(0, -height)
	g:SetCount(lines)
	table.insert(self.clusters, g)

end

function PANEL:SetState(newState)

	local c = self.clusters[1]
	if not c then return end
	if c.state == newState then return end

	c:SetState(newState)
	if newState == 1 then
		self:Anim_Flash()
	elseif newState == 2 or newState == 3 then
		self:Anim_Flash(true)
	end

end

function PANEL:Offset(count)

	self:Anim_Offset(count)
	self:RemoveBlocks(count)

end

function PANEL:Dump()

	self:Anim_Dump()
	self:RemoveBlocks(1)

end

gui.Register("GarbageQueue", PANEL, "Control")
