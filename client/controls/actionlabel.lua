if LITE then return end
--[[
	A single-line label that allows insertion of action icons.
	{action_name} to insert
]]
local PANEL = {}

function PANEL:Init()
	self.font = "DermaDefault"
	self.text = "ActionLabel"
	self.halign = -1
	self.valign = -1
	self:SetSize(0, 0)

	self:Update()
	self:Tokenize()
end

function PANEL:SetMap(map)
	self.map = map
end

function PANEL:AutoMap()
	self.map = nil
end

function PANEL:SetController(is)
	self.isController = is
end

function PANEL:AutoController()
	self.isController = nil
end

function PANEL:Update()
	render.setFont(self.font)
	local _, th = render.getTextSize(" ")
	self.size = th
end

function PANEL:SetFont(font)
	self.font = font
	self:Update()
end

function PANEL:SetAlign(h, v)
	self.halign = h
	self.valign = v
end

function PANEL:Tokenize()
	local info = {}
	info.h = self.size

	local str = self.text
	local split = {}
	local current_pos = 1

	for i = 1, string.len( str ) do
		local start_pos, end_pos, actionName = string.find( str, "{(.-)}", current_pos )
		if ( !start_pos ) then break end

		local prefix = string.sub( str, current_pos, start_pos - 1 )

		table.insert(split, prefix) -- insert everything before the token
		table.insert(split, actionName)
		current_pos = end_pos + 1
	end

	local suffix = string.sub( str, current_pos )
	table.insert(split, suffix)

	render.setFont(self.font)
	local count = #split
	local curW = 0
	info.text = {}
	info.actions = {}
	for i = 1, count do

		local entry = split[i]
		local isAction = i % 2 == 0
		local w
		if isAction then
			w = self.size
			info.actions[curW] = entry
		else
			w = render.getTextSize(entry)
			info.text[curW] = entry
		end
		curW = curW + w

	end

	info.w = curW
	self.info = info

end

function PANEL:SetText(text)
	self.text = text
	self:Tokenize()
end

function PANEL:Paint(w, h)
	local tw, th = self.info.w, self.info.h
	local offset_x, offset_y = 0, 0
	local halign, valign = self.halign, self.valign
	if halign == -1 then
		offset_x = 0
	elseif halign == 0 then
		offset_x = w/2 - tw/2
	elseif halign == 1 then
		offset_x = w - tw
	end

	if valign == -1 then
		offset_y = 0
	elseif valign == 0 then
		offset_y = h/2 - th/2
	elseif valign == 1 then
		offset_y = h - th
	end
	render.setRGBA(255, 255, 255, 255)
	render.setFont(self.font)
	for x, text in pairs(self.info.text) do
		render.drawText(offset_x + x, offset_y, text)
	end
	local map = self.map ~= nil and self.map
	local controller
	if self.isController ~= nil then
		controller = self.isController
	else
		controller = binput.isController
	end
	for x, action in pairs(self.info.actions) do
		local binding = binput.getBinding(action, controller, map)
		drawBinding(offset_x + x, offset_y, self.size, self.size, binding)
	end
end

gui.Register("ActionLabel", PANEL, "Control")
