--@client

local PANEL = {}
local pushRT = gui.pushRT
local popRT = gui.popRT

local nativeWidth, nativeHeight = render.getGameResolution()
nativeWidth = math.min(1024, nativeWidth)
nativeHeight = math.min(1024, nativeHeight)

RTUniqueID = RTUniqueID or 0
function PANEL:Init()
	self.invalid = true
	self.RTName = "gui_RT" .. RTUniqueID
	RTUniqueID = RTUniqueID + 1
	self.alpha = 255
	render.createRenderTarget(self.RTName)
end

function PANEL:SetAlpha(alpha)
	self.alpha = alpha
end

local transparent = Color(0, 0, 0, 0)

function PANEL:OnRemove()

	if render.renderTargetExists(self.RTName) then
		render.destroyRenderTarget(self.RTName)
	end

end

function PANEL:Draw()

	if self.invalid then
	
		local memory = gui.popAllMatrices()

		pushRT(self.RTName)
		render.clear(transparent, true)

		self:Paint(self.w, self.h)
		self:DrawChildren()
		self:PostPaint(self.w, self.h)

		popRT()

		gui.pushMatrices(memory)

		self.invalid = false

	end

	render.setRenderTargetTexture(self.RTName)
	render.setRGBA(255, 255, 255, self.alpha)
	render.drawTexturedRectUV(0, 0, self.w, self.h, 0, 0, self.w / 1024, self.h / 1024)
	

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
	self.divisionCount = math.floor(nativeWidth / w) * math.floor(nativeHeight / h)
end

function PANEL:SetDivision(div)
	self.division = div
end

function PANEL:GetDivisionCoordinates()

	local w, h = math.floor(nativeWidth / self.dw), math.floor(nativeHeight / self.dh)
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
		clearRTSection(x, y, self.dw, self.dh)

		gui.pushScissor(x, y, x + self.dw, y + self.dh)
		gui.pushMatrix(gui.getMatrix(x, y, 1, 1))
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

	local u1, v1 = x / 1024, y / 1024
	local u2, v2 = (x + self.dw) / 1024, (y + self.dh) / 1024

	render.drawTexturedRectUV(0, 0, self.w, self.h, u1 + const, v1 + const, u2 - const, v2 - const)

	if self.PaintContinuous then
		self:PaintContinuous(self.w, self.h)
	end

end

function PANEL:OnRemove() end

gui.Register("DividedRTControl", PANEL, "RTControl")
