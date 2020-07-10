--@client

local PANEL = {}
local SmallResScale = gui.SmallResolution and 0.5 or 1
local pushRT = gui.pushRT
local popRT = gui.popRT


function PANEL:Init()
	self.invalid = true
	self.RTName = "gui_RT" .. math.random(1, 2^31-1)
	render.createRenderTarget(self.RTName)
end

local transparent = Color(0, 0, 0, 0)

function PANEL:Draw()

	if self.invalid then
	
		local memory = gui.popAllMatrices()

		pushRT(self.RTName)
		render.clear(transparent, true)
		gui.pushMatrix(gui.getMatrix(0, 0, SmallResScale, SmallResScale))

		self:Paint(self.w, self.h)
		self:DrawChildren()
		self:PostPaint(self.w, self.h)

		gui.popMatrix()
		popRT()

		gui.pushMatrices(memory)

		self.invalid = false

	end

	render.setRenderTargetTexture(self.RTName)
	render.setRGBA(255, 255, 255, 255)
	render.drawTexturedRectUV(0, 0, self.w, self.h, 0, 0, self.w * SmallResScale / 1024, self.h * SmallResScale / 1024)
	

end

gui.Register("RTControl", PANEL, "Control")


local BLEND_ZERO = 0
local BLENDFUNC_MIN = 3
-- Clears a rectangle on a RT without clearing the area around it
local function clearRTSection(x, y, w, h)

	render.overrideBlend(true, 
		BLEND_ZERO, BLEND_ZERO, BLENDFUNC_MIN,
		BLEND_ZERO, BLEND_ZERO, BLENDFUNC_MIN)
	render.setRGBA(0, 0, 0, 0)
	render.drawRect(x, y, w, h) -- only works with non-fast rect
	render.overrideBlend(false)

end



PANEL = {}
function PANEL:Init()

	self.invalid = true
	self.dw = 128 -- Width of a division
	self.dh = 128 -- Height of a division
	self.division = 1
	self.divisionCount = 64

end

function PANEL:SetDivisionSize(w, h)
	self.dw = w
	self.dh = h
	self.divisionCount = math.floor(1024 / w) * math.floor(1024 / h)
end

function PANEL:SetDivision(div)
	self.division = div
end

function PANEL:GetDivisionCoordinates()

	local w, h = math.floor(1024 / self.dw), math.floor(1024 / self.dh)
	if self.division < 1 or self.division > self.divisionCount then
		error("DividedRTControl: division out of range: " .. tostring(self.division))
	end

	local row = (self.division - 1) % h
	local col = math.floor((self.division - 1) / h)

	return col * self.dw, row * self.dh

end


local const = (7/16) / 1024 -- cut off ugly pixels that have blended in
function PANEL:Draw()

	if self.RTName == nil then
		error("DividedRTControl: RTName not assigned!")
	end

	local x, y = self:GetDivisionCoordinates()

	if self.invalid then

		local memory = gui.popAllMatrices()

		pushRT(self.RTName)
		clearRTSection(x * SmallResScale, y * SmallResScale, self.dw * SmallResScale, self.dh * SmallResScale)

		gui.pushScissor(x * SmallResScale, y * SmallResScale, (x + self.dw) * SmallResScale, (y + self.dh) * SmallResScale)
		gui.pushMatrix(gui.getMatrix(x * SmallResScale, y * SmallResScale, SmallResScale, SmallResScale))
		self:Paint(self.dw, self.dh)
		self:DrawChildren()
		self:PostPaint(self.dw, self.dh)
		gui.popMatrix()
		gui.popScissor()

		popRT()

		gui.pushMatrices(memory)

		self.invalid = false

	end


	render.setRenderTargetTexture(self.RTName)
	render.setRGBA(255, 255, 255, 255)

	local u1, v1 = x * SmallResScale / 1024, y * SmallResScale / 1024
	local u2, v2 = (x + self.dw) * SmallResScale / 1024, (y + self.dh) * SmallResScale / 1024

	render.drawTexturedRectUV(0, 0, self.w, self.h, u1 + const, v1 + const, u2 - const, v2 - const)

end

gui.Register("DividedRTControl", PANEL, "RTControl")
