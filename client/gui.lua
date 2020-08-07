--[[
	GUI library to render hierarchial elements on-screen
]]

--@name GUI
--@author Ranthos
--@client
--@includedir brix/client/controls

local PROFILING = false--owner() == player()
VIEW_W, VIEW_H = render.getGameResolution()
local glow_scaleW, glow_scaleH

gui = {}
gui.Classes = {}
gui.SmallResolution = ({render.getGameResolution()})[2] < 1024

local CTX

local protected = {
	"DrawChildren",
	"Remove",
	"RemoveFromParent",
	"Add",
	"SetSize",
	"SetPos",
	"SetScale",
	"SetParent",
	"ReconstructMatrix",
	"_matrix",
	"SetWide",
	"SetTall",
	"SetVisible",
	"GetPos",
	"GetSize",
	"GetWide",
	"GetTall",
	"AbsolutePos"
}

local matrices = {}
	
function gui.getMatrix(x, y, sw, sh)

	local m = Matrix()
	m:setTranslation(Vector(x, y, 0))
	m:setScale(Vector(sw, sh, 0))
	return m

end

function gui.getFitScale(w, h, bound_w, bound_h, allowOversize)
	if allowOversize then
		return math.max(bound_w / w, bound_h / h)
	else
		return math.min(bound_w / w, bound_h / h)
	end
end

local function round( num, idp )

	local mult = 10 ^ ( idp or 0 )
	return math.floor( num * mult + 0.5 ) / mult

end

function gui.AbsolutePos(ox, oy)

	local x, y, sw, sh = 0, 0, 1, 1
	for _, mat in pairs(matrices) do
	
		local tr, scale = mat:getTranslation(), mat:getScale()
		x = x + tr[1] * sw
		y = y + tr[2] * sh

		sw = sw * scale[1]
		sh = sh * scale[2]

	end

	return round(x + ox * sw, 0), round(y + oy * sh, 0)

end

function gui.pushMatrix(mat)

	table.insert(matrices, mat)
	render.pushMatrix(mat)

end

function gui.popMatrix()
	if #matrices == 0 then return end
	local matrix = table.remove(matrices, #matrices)

	render.popMatrix()

	return matrix
end

function gui.popAllMatrices()

	local toReturn = {}
	for i = #matrices, 1, -1 do
		local matrix = gui.popMatrix()
		table.insert(toReturn, 1, matrix)
	end

	return toReturn

end

function gui.pushMatrices(list)

	for _, mat in pairs(list) do
		gui.pushMatrix(mat)
	end

end

local scissorStack = {}
function gui.pushScissor(x1, y1, x2, y2)
	x1, y1 = gui.AbsolutePos(x1, y1)
	x2, y2 = gui.AbsolutePos(x2, y2)
	table.insert(scissorStack, {x1, y1, x2, y2})
	render.enableScissorRect(x1, y1, x2, y2)
end

function gui.popScissor()
	local ret = table.remove(scissorStack, #scissorStack)
	if #scissorStack == 0 then
		render.disableScissorRect()
	else
		render.enableScissorRect(unpack(scissorStack[#scissorStack]))
	end
	return ret
end


local RTStack = {}
function gui.pushRT(name)
	table.insert(RTStack, 1, name)
	render.selectRenderTarget(name)
end

function gui.popRT()
	table.remove(RTStack, 1)
	render.selectRenderTarget(RTStack[1])
end

local glowRT = "guiGlow"
if not render.renderTargetExists(glowRT) then
	render.createRenderTarget(glowRT)
end

function gui.clearGlow()
	gui.pushRT(glowRT)
	render.clear(Color(0, 0, 0, 0), true)
	gui.popRT()
end

local prevMatrixStack

gui.isGlowing = false
function gui.startGlow()

	if prevMatrixStack ~= nil then
		error("already started glow")
	end

	prevMatrixStack = gui.popAllMatrices()
	local m = gui.getMatrix(0, 0, glow_scaleW, glow_scaleH)
	gui.pushRT(glowRT)
	gui.pushMatrix(m)
	gui.pushMatrices(prevMatrixStack)

	gui.isGlowing = true

end

function gui.endGlow()

	if prevMatrixStack == nil then
		error("glow not started")
	end

	gui.popAllMatrices()
	gui.popRT()

	gui.pushMatrices(prevMatrixStack)
	prevMatrixStack = nil

	gui.isGlowing = false

end


local CTRL = {}
CTRL.__index = CTRL
CTRL.className = "Control"

function gui.Register(className, panelTable, baseName)

	for _, name in pairs(protected) do
		local property = panelTable[name]
		if property ~= nil and property ~= CTRL[name] then
			error("class may not contain protected property/method \"" .. tostring(name) .. "\"")
		end
	end

	if baseName == nil then baseName = "Control" end
	
	local baseTable = gui.Classes[baseName]
	if baseTable then
		if baseName == className then
			error("cannot inherit gui element from itself")
		end
		panelTable.super = baseTable
		setmetatable(panelTable, {__index = baseTable})
	end
	panelTable.className = className
	panelTable.__index = panelTable
	gui.Classes[className] = panelTable

end

function CTRL:Draw()

	self:Paint(self.w, self.h)
	self:DrawChildren()
	self:PostPaint(self.w, self.h)

end

-- Called after the control has been created.
function CTRL:Init()

end

-- Called when the control is about to be removed.
function CTRL:OnRemove()

end

-- Called when the size has changed
function CTRL:OnSizeChanged(w, h)

end

-- Called before draw
function CTRL:Think()

end

-- Called when the control must be drawn. This is drawn before children.
function CTRL:Paint(w, h)

end

-- Same as Paint, but called after children have been drawn.
function CTRL:PostPaint(w, h)

end

function CTRL:RemoveFromParent()

	if self.parent then
	
		for k, v in pairs(self.parent.children) do
			if v == self then
				table.remove(self.parent.children, k)
				break
			end
		end
	
	end

end

function CTRL:Remove()

	self:OnRemove()
	self:RemoveFromParent()
	
	local children = {}
	for k, v in pairs(self.children) do table.insert(children, v) end
	
	for k, v in pairs(children) do
		v:Remove()
	end
end

function CTRL:ReconstructMatrix()

	self._matrix = gui.getMatrix(self.x, self.y, self.scale_w, self.scale_h)

end

function CTRL:SetSize(w, h)
	self.w = w
	self.h = h
	local f = self.OnSizeChanged
	if type(f) == "function" then
		f(self, w, h)
	end
end

function CTRL:SetWide(w)
	self.w = w
	local f = self.OnSizeChange
	if type(f) == "function" then
		f(self, w, self.h)
	end
end

function CTRL:SetTall(h)
	self.h = h
	local f = self.OnSizeChange
	if type(f) == "function" then
		f(self, self.w, h)
	end
end

function CTRL:GetSize()
	return self.w, self.h
end

function CTRL:GetWide()
	return self.w
end

function CTRL:GetTall()
	return self.h
end

function CTRL:SetPos(x, y)
	self.x = x
	self.y = y
	self:ReconstructMatrix()
end

function CTRL:GetPos()
	return self.x, self.y
end

function CTRL:SetScale(w, h)

	if h == nil then
		h = w
	end
	
	self.scale_w = w
	self.scale_h = h
	self:ReconstructMatrix()

end

function CTRL:SetVisible(visible)
	self.visible = visible
end

function CTRL:SetGlow(isGlowing)
	self.glow = isGlowing
end

function CTRL:Add(child)
	child.parent = self
	table.insert(self.children, child)
end

function CTRL:SetParent(newParent)

	if self.parent == nil then
		error("Cannot set parent of root Control")
	end

	self:RemoveFromParent()
	newParent:Add(self)

end

local sys = timer.systime
function CTRL:DrawChildren()

	for _, child in pairs(self.children) do
	
		if child.visible then
			gui.pushMatrix(child._matrix)
			
			local start = sys()
			child:Think()
			local totalTime = sys() - start
			if child.glow and not gui.isGlowing then
				gui.startGlow()
				start = sys()
				child:Draw()
				totalTime = totalTime + (sys() - start)
				gui.endGlow()
			end
			start = sys()
			child:Draw()
			totalTime = totalTime + (sys() - start)

			if PROFILING then
				child.perf_total = totalTime
				child.perf_average = child:perf_movingAvg()
				child.perf_total = 0
				child.perf_drawn = true
			end
			
			gui.popMatrix()
		end
	
	end

end

function CTRL:AbsolutePos(ox, oy)

	local isVec = false
	if type(ox) == "Vector" then
		oy = ox[2]
		ox = ox[1]
		isVec = true
	end

	local mats = {}
	local cur = self
	while cur do
		table.insert(mats, 1, cur._matrix)
		cur = cur.parent
	end

	local x, y, sw, sh = 0, 0, 1, 1
	for _, mat in pairs(mats) do
	
		local tr, scale = mat:getTranslation(), mat:getScale()
		x = x + tr[1] * sw
		y = y + tr[2] * sh

		sw = sw * scale[1]
		sh = sh * scale[2]

	end

	local resultX, resultY = round(x + ox * sw, 0), round(y + oy * sh, 0)
	if isVec then
		return Vector(resultX, resultY, 0), Vector(sw, sh, 0)
	else
		return resultX, resultY, sw, sh
	end

end

gui.Classes["Control"] = CTRL

dodir("brix/client/controls", {
	[0] = "_____",
	"number.lua",
	"rtcontrol.lua",
	"piece.lua",
	"sprite.lua",
	"field.lua",
	"enemyfield.lua",
	"inputicon.lua",
	"button.lua",
	"blockbutton.lua"
})
_G.PANEL = nil


local root
local _noParent_reference = {} -- store a reference to this table we only created here


function gui.Create(className, parent)

	if not gui.Classes[className] then
		error("attempt to create gui element of unknown class \"" .. tostring(className) .. "\"")
	end
	
	local ctrl = {}
	ctrl.x = 0
	ctrl.y = 0
	ctrl.w = 64
	ctrl.h = 64
	ctrl.scale_w = 1
	ctrl.scale_h = 1
	ctrl.visible = true
	ctrl.children = {}

	if PROFILING then
		ctrl.perf_total = 0
		ctrl.perf_average = 0
	end

	function ctrl:perf_movingAvg()
		return self.perf_average + (self.perf_total - self.perf_average) * 1/100
	end
	
	setmetatable(ctrl, gui.Classes[className])
	if parent == nil then
		parent = root
	end
	if parent ~= _noParent_reference then
		parent:Add(ctrl)
	end
	ctrl:ReconstructMatrix()
	ctrl:Init()
	
	return ctrl
	

end

-- Creates a new GUI context with the given resolution.
-- Can be used to make a separate GUI for a starfall screen
function gui.NewContext(context_w, context_h)

	local ctx = gui.Create("Control", _noParent_reference)
	ctx:SetSize(context_w, context_h)
	ctx.blurw, ctx.blurh = 8, 8
	if context_h < 1024 then
		ctx.blurw, ctx.blurh = 4, 4
	end
	ctx.glow_scaleW, ctx.glow_scaleH = 1024 / context_w, 1024 / context_h

	return ctx

end

local fade = {
	start = 0,
	finish = 1,
	col = Color(0, 0, 0),
	active = false
}
function gui.fadeOut(duration, col)
	duration = duration or 1
	
	fade.start = timer.realtime()
	fade.finish = timer.realtime() + duration
	fade.col = col or fade.col
	fade.active = true
end
function gui.fadeIn(duration, col)
	duration = duration or 1
	
	fade.start = timer.realtime()
	fade.finish = timer.realtime() + duration
	fade.col = col or fade.col
	fade.active = false
end

root = gui.NewContext(VIEW_W, VIEW_H)

local perf_x, perf_y = 32, 32 + 64 + 8
local perf_tab = 24
local function drawProfile(ctrl, info, parentMax)

	if not ctrl.perf_drawn then
		ctrl.perf_total = 0
		ctrl.perf_average = ctrl:perf_movingAvg()
	end
	ctrl.perf_drawn = nil

	render.drawText(perf_x + info[1]*perf_tab, perf_y + info[2]*12, ctrl.className)
	render.drawLine(perf_x + info[1]*perf_tab + 64, perf_y + info[2]*12+6, perf_x + perf_tab*19, perf_y + info[2]*12+6)
	render.drawLine(perf_x + perf_tab*9, perf_y + info[2]*12+1, perf_x + perf_tab*9, perf_y + info[2]*12+10)
	render.drawLine(perf_x + perf_tab*19, perf_y + info[2]*12+1, perf_x + perf_tab*19, perf_y + info[2]*12+10)

	local perf = ctrl.perf_average / parentMax
	local totalPerf = ctrl.perf_average / 0.006
	if perf ~= perf then
		perf = 0
	end
	render.drawRectFast(perf_x + perf_tab*9+1, perf_y+info[2]*12+2, (perf_tab*10-2)*perf, 4)
	render.drawRectFast(perf_x + perf_tab*9+1, perf_y+info[2]*12+6, (perf_tab*10-2)*totalPerf, 4)

	render.drawText(perf_x + perf_tab*20, perf_y + info[2]*12, tostring(math.ceil(perf*10000)/100))
	info[2] = info[2] + 1
	if ctrl.className ~= "Enemy" then
		for k, child in pairs(ctrl.children) do
			info[1] = info[1] + 1
			drawProfile(child, info, ctrl.perf_average)
			info[1] = info[1] - 1
		end
	end

end

local fakeGFXControl = {
	perf_total = 0,
	perf_average = 0,
	perf_movingAvg = function(self)
		return self.perf_average + (self.perf_total - self.perf_average) * 1/100
	end,
	children = {},
	className = "GFX"
		
}

function gui.Draw(context)

	context = context or root
	CTX = context
	glow_scaleW = context.glow_scaleW
	glow_scaleH = context.glow_scaleH
	local cw, ch, bw, bh = context.w, context.h, context.blurw, context.blurh

	hook.run("guiPreDraw")
	gui.clearGlow()
	gui.pushMatrix(context._matrix)
	
	local ctxStart = timer.systime()
	context:Draw()
	local CONTEXT_TIME = timer.systime() - ctxStart
	if PROFILING then
		context.perf_total = CONTEXT_TIME
		context.perf_average = context:perf_movingAvg()
		context.perf_total = 0
		context.perf_drawn = true
	end
	
	gui.popMatrix()

	ctxStart = timer.systime()
	hook.run("guiPostDraw")

	if PROFILING then
		local total = timer.systime() - ctxStart
		fakeGFXControl.perf_total = total
		fakeGFXControl.perf_average = fakeGFXControl:perf_movingAvg()
		fakeGFXControl.perf_total = 0
		fakeGFXControl.perf_drawn = true
	end
	gui.pushRT(glowRT)


	render.drawBlurEffect(bw * glow_scaleW, bh * glow_scaleH, 1)
	render.setMaterialEffectBloom(glowRT, 1, 1, 1, 10)
	gui.popRT()

	render.setMaterialEffectAdd(glowRT)
	render.setRGBA(255, 255, 255, 255)
	for i = 1, 2 do
		render.drawTexturedRect(0, 0, cw, ch)
	end

	if context == root then
		local frac = timeFrac(timer.realtime(), fade.start, fade.finish, true)
		if frac < 1 then
			local alpha
			if fade.active then
				alpha = frac*255
			else
				alpha = (1-frac)*255
			end
			fade.col.a = alpha
			render.setColor(fade.col)
			render.drawRect(-1, -1, cw, ch)
		elseif fade.active then
			fade.col.a = 255
			render.setColor(fade.col)
			render.drawRect(-1, -1, cw, ch)
		end
	end






	if PROFILING then
		context.count = context.count and (context.count + 1) or 1
		local info = {0, 0, context.count}
		render.setFont("DermaDefault")
		drawProfile(fakeGFXControl, info, 0.006)
		drawProfile(context, info, 0.006)
	end

	--render.drawText(32 + 128/2, 32+32, tostring(RTCount), 1)

	if input.isControlLocked() then
		render.setFont("DermaDefault")
		render.setRGBA(255, 255, 255, 255)
		render.drawText(4, context.h-2-16, "Press ALT to exit")
	end

	CTX = nil

	

	render.setRGBA(128, 128, 128, 128)
	render.drawRect(32, 32, 128, 64)
	render.setRGBA(255, 255, 255, 255)
	render.setFont("DermaLarge")
	local perc = math.ceil(quotaAverage() / quotaMax() * 100)
	render.drawText(32 + 128/2, 32 + 16, perc .. "%", 1)

end
