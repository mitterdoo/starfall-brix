--@client

local PANEL = {}
local SmallResScale = gui.SmallResolution and 0.5 or 1
local RTStack = {}
local function pushRT(name)
	table.insert(RTStack, 1, name)
	render.selectRenderTarget(name)
end

local function popRT()
	table.remove(RTStack, 1)
	render.selectRenderTarget(RTStack[1])
end


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
		--gui.pushMatrix(gui.getMatrix(0, 0, SmallResScale, SmallResScale))

		self:Paint(self.w, self.h)
		self:DrawChildren()

		--gui.popMatrix()
		popRT()

		gui.pushMatrices(memory)

		self.invalid = false

	end

	render.setRenderTargetTexture(self.RTName)
	render.setRGBA(255, 255, 255, 255)
	render.drawTexturedRectUV(0, 0, self.w, self.h, 0, 0, self.w * SmallResScale / 1024, self.h * SmallResScale / 1024)
	

end

gui.Register("RTControl", PANEL, "Control")



local BufferRT = "DividedRTControl_Buffer"
render.createRenderTarget(BufferRT)

-- Clears a rectangle on a RT without clearing the area around it
local function clearRTSection(rt, x, y, w, h)

	pushRT(BufferRT)
	render.clear(transparent, true)

	render.setStencilWriteMask(0xFF)
	render.setStencilTestMask(0xFF)
	render.setStencilPassOperation(1)
	render.setStencilFailOperation(1)
	render.setStencilZFailOperation(1)
	render.clearStencil()

	render.setStencilEnable(true)
	render.setStencilReferenceValue(1)
	render.setStencilCompareFunction(6)
	render.clearStencilBufferRectangle(x, y, x + w, y + h, 1)

	render.setRGBA(255, 255, 255, 255)
	render.setRenderTargetTexture(rt)
	render.drawTexturedRect(0, 0, 1024, 1024)

	render.setStencilEnable(false)

	popRT()
	pushRT(rt)

	render.clear(transparent, true)
	render.setRenderTargetTexture(BufferRT)
	render.drawTexturedRect(0, 0, 1024, 1024)

	popRT()


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


local const = 0.4 / 1024 -- cut off ugly pixels that have blended in
function PANEL:Draw()

	if self.RTName == nil then
		error("DividedRTControl: RTName not assigned!")
	end

	local x, y = self:GetDivisionCoordinates()

	if self.invalid then

		local memory = gui.popAllMatrices()

		clearRTSection(self.RTName, x * SmallResScale, y * SmallResScale, self.dw * SmallResScale, self.dh * SmallResScale)
		pushRT(self.RTName)

		gui.pushScissor(x * SmallResScale, y * SmallResScale, (x + self.dw) * SmallResScale, (y + self.dh) * SmallResScale)
		gui.pushMatrix(gui.getMatrix(x * SmallResScale, y * SmallResScale, SmallResScale, SmallResScale))
		self:Paint(self.dw, self.dh)
		self:DrawChildren()
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
