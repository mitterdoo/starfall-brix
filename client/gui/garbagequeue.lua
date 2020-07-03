local PANEL = {}

--[[
$	Dump
	Offset
$	Activate (0)
$	Nag (1)
$	Nag (2, flaming)
]]

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

	local c = (1-frac)*255
	--frac = (frac - 0.6) / 0.6
	render.setRGBA(0, 255, 255, c)
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
		gfx.EmitParticle(
			{pos, pos},
			{Vector(brickSize, brickSize, 0)*scale,
			Vector(brickSize * 1.4, brickSize*0.9, 0)*scale},
			0, animDuration,
			fx_FlashOffset, true, true
		)

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





function PANEL:Enqueue(lines)

	local brickSize = self.brickSize
	local height = self:GetHeightOfCluster(#self.clusters + 1)


	local g = gui.Create("GarbageCluster", self)
	g:SetBrickSize(brickSize)
	g:SetPos(0, -height)
	g:SetCount(lines)
	table.insert(self.clusters, g)

end

gui.Register("GarbageQueue", PANEL, "Control")
