--[[
	GUI library to render hierarchial elements on-screen
]]

--@name GUI
--@author Ranthos
--@client
--@include brix/client/gui/rtcontrol.lua
--@include brix/client/gui/sprite.lua
--@include brix/client/gui/multisprite.lua
--@include brix/client/gui/number.lua
--@include brix/client/gui/emitter.lua
--@include brix/client/gui/field.lua
--@include brix/client/gui/piece.lua
--@include brix/client/gui/pieceicon.lua
--@include brix/client/gui/lineclear.lua
--@include brix/client/gui/danger.lua
--@include brix/client/gui/background.lua
--@include brix/client/gui/garbagecluster.lua
--@include brix/client/gui/garbagequeue.lua

local loadControls = {
	"RTControl",
	"Sprite",
	"MultiSprite",
	"Number",
	"Emitter",
	"Field",
	"Piece",
	"PieceIcon",
	"LineClear",
	"Danger",
	"Background",
	"GarbageCluster",
	"GarbageQueue"
}

gui = {}
gui.Classes = {}
gui.SmallResolution = ({render.getGameResolution()})[2] < 1024

local protected = {
	"DrawChildren",
	"Remove",
	"Add",
	"SetSize",
	"SetPos",
	"SetScale",
	"ReconstructMatrix",
	"_matrix",
	"SetWide",
	"SetTall",
	"SetVisible",
	"GetPos",
	"GetSize",
	"GetWide",
	"GetTall"
}

local matrices = {}
	
function gui.getMatrix(x, y, sw, sh)

	local m = Matrix()
	m:setTranslation(Vector(x, y, 0))
	m:setScale(Vector(sw, sh, 0))
	return m

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
render.createRenderTarget(glowRT)

function gui.clearGlow()
	gui.pushRT(glowRT)
	render.clear(Color(0, 0, 0, 0), true)
	gui.popRT()
end

local game_w, game_h = render.getGameResolution()
local glow_scaleW, glow_scaleH = 1024 / game_w, 1024 / game_h

local prevMatrixStack
function gui.startGlow()

	if prevMatrixStack ~= nil then
		error("already started glow")
	end

	prevMatrixStack = gui.popAllMatrices()
	local m = gui.getMatrix(0, 0, glow_scaleW, glow_scaleH)
	gui.pushRT(glowRT)
	gui.pushMatrix(m)
	gui.pushMatrices(prevMatrixStack)

end

function gui.endGlow()

	if prevMatrixStack == nil then
		error("glow not started")
	end

	gui.popAllMatrices()
	gui.popRT()

	gui.pushMatrices(prevMatrixStack)
	prevMatrixStack = nil

end


local CTRL = {}
CTRL.__index = CTRL

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



function CTRL:Remove()

	self:OnRemove()

	if self.parent then
	
		for k, v in pairs(self.parent.children) do
			if v == self then
				table.remove(self.parent.children, k)
				break
			end
		end
	
	end
	
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
	local f = self.OnSizeChange
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

function CTRL:Add(child)
	child.parent = self
	table.insert(self.children, child)
end

function CTRL:DrawChildren()

	for _, child in pairs(self.children) do
	
		if child.visible then
			gui.pushMatrix(child._matrix)
			
			child:Think()
			child:Draw()
			
			gui.popMatrix()
		end
	
	end

end

gui.Classes["Control"] = CTRL


for _, name in pairs(loadControls) do

	require("brix/client/gui/" .. name:lower() .. ".lua")

end
_G.PANEL = nil


local root
local _noParent_reference = {} -- store a reference to this table we only created here


function gui.Create(className, parent)

	if not gui.Classes[className] then
		error("attempt to create gui element of unknown class \"" .. tostring(classname) .. "\"")
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

root = gui.Create("Control", _noParent_reference)
root:SetSize(render.getGameResolution())

function gui.Draw()
	hook.run("guiPreDraw")
	gui.clearGlow()
	gui.pushMatrix(root._matrix)
	
	root:Draw()
	
	
	gui.popMatrix()
	hook.run("guiPostDraw")

	gui.pushRT(glowRT)

	local blurw, blurh = 8, 8

	render.drawBlurEffect(blurw * glow_scaleW, blurh * glow_scaleH, 1)
	render.setMaterialEffectBloom(glowRT, 1, 1, 1, 10)
	gui.popRT()

	render.setMaterialEffectAdd(glowRT)
	render.setRGBA(255, 255, 255, 255)
	for i = 1, 2 do
		render.drawTexturedRect(0, 0, game_w, game_h)
	end

end
