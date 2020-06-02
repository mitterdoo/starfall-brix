--[[
	GUI library to render hierarchial elements on-screen
]]

--@name GUI
--@author Ranthos
--@client


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
	gui.Classes[className] = panelTable

end

local function getControlMatrix(ctrl)

	local m = Matrix()
	m:setTranslation(Vector(ctrl.x, ctrl.y, 0))
	m:setScale(Vector(ctrl.scale_w, ctrl.scale_h, 0))
	return m

end

function CTRL:Draw()

	self:Paint(self.w, self.h)
	self:DrawChildren()

end

function CTRL:Init()

end

function CTRL:OnRemove()

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

function CTRL:Paint(w, h)
	render.setRGBA(255, 255, 0, 255)
	render.drawRectFast(0, 0, w, h)
	render.setRGBA(255, 0, 0, 255)
	render.drawRectFast(0, 0, w/2, h/2)
	
	render.setRGBA(0, 0, 0, 255)
	render.drawText(0, 0, "Hello, world", 0)
end

function CTRL:Add(child)
	child.parent = self
	table.insert(self.children, child)
end

function CTRL:DrawChildren()

	for _, child in pairs(self.children) do
	
		local m = getControlMatrix(child)
		render.pushMatrix(m)
		
		child:Draw()
		
		render.popMatrix()
	
	end

end

gui.Classes["Control"] = CTRL

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
	if parent ~= nil then
		parent:Add(ctrl)
	end
	ctrl:Init()
	
	return ctrl
	

end

local root = gui.Create("Control")
root:SetPos(400, 400)
root:SetSize(200, 200)

local whoa = gui.Create("Control", root)
whoa:SetPos(100, 100)
whoa:SetSize(50, 50)


hook.add("postdrawhud", "gui", function()

	local w, h = render.getGameResolution()
	
	root.scale_w = math.sin(timer.realtime() * math.pi) * 0.5 + 1
	root.scale_h = root.scale_w
	
	local m = getControlMatrix(root)
	render.pushMatrix(m)
	
	root:Draw()
	
	render.popMatrix()

end)
