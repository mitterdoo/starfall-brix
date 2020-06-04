--[[
	GUI library to render hierarchial elements on-screen
]]

--@name GUI
--@author Ranthos
--@client
--@include brix/client/gui/rtcontrol.lua

local loadControls = {
	"RTControl"
}

gui = {}
gui.Classes = {}

local protected = {
	"DrawChildren",
	"Remove",
	"Add",
	"SetSize",
	"SetPos",
	"SetScale"
}

local transforms = {}
	
local function getMatrix(x, y, sw, sh)

	local m = Matrix()
	m:setTranslation(Vector(x, y, 0))
	m:setScale(Vector(sw, sh, 0))
	return m

end
function gui.pushTransform(x, y, sw, sh)

	local transform
	if y ~= nil then
		transform = {x = x, y = y, sw = sw, sh = sh}
	else
		transform = x
	end
	table.insert(transforms, transform)

	render.pushMatrix(getMatrix(transform.x, transform.y, transform.sw, transform.sh))

end

function gui.popTransform()
	if #transforms == 0 then return end
	local transform = table.remove(transforms, #transforms)

	render.popMatrix()

	return transform
end

function gui.popAllTransforms()

	local toReturn = {}
	for i = #transforms, 1, -1 do
		local transform = gui.popTransform()
		gui.popTransform()
		table.insert(toReturn, transform)
	end

	return toReturn

end

function gui.pushTransforms(list)

	for _, transform in pairs(list) do
		gui.pushTransform(transform)
	end

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

end

function CTRL:Init()

end

function CTRL:OnRemove()

end

function CTRL:Paint(w, h)

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

function CTRL:SetSize(w, h)
	self.w = w
	self.h = h
end

function CTRL:SetPos(x, y)
	self.x = x
	self.y = y
end

function CTRL:SetScale(w, h)

	if h == nil then
		h = w
	end
	
	self.scale_w = w
	self.scale_h = h

end

function CTRL:Add(child)
	child.parent = self
	table.insert(self.children, child)
end

function CTRL:DrawChildren()

	for _, child in pairs(self.children) do
	
		gui.pushTransform(child.x, child.y, child.scale_w, child.scale_h)
		
		child:Draw()
		
		gui.popTransform()
	
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
	ctrl.children = {}
	
	setmetatable(ctrl, gui.Classes[className])
	if parent == nil then
		parent = root
	end
	if parent ~= _noParent_reference then
		parent:Add(ctrl)
	end
	ctrl:Init()
	
	return ctrl
	

end

root = gui.Create("Control", _noParent_reference)
root:SetSize(render.getGameResolution())

function gui.Draw()
	gui.pushTransform(root.x, root.y, root.scale_w, root.scale_h)
	
	root:Draw()
	
	
	gui.popTransform()
end
