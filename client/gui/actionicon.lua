if LITE then return end
local PANEL = {}

function PANEL:Init()
	PANEL.super.Init(self)
	self.action = "ui_accept"
	self.showAll = false
	self.halign = -1
end

-- Manually set which input method this will use
function PANEL:SetController(isController)
	self.isController = isController
end

-- Automatically change depending on current input method
function PANEL:SetAuto()
	self.isController = nil
end

function PANEL:SetHAlign(h)
	self.halign = h
end

function PANEL:SetShowAll(shouldShow)
	self.showAll = shouldShow
end

function PANEL:SetAction(action)
	self.action = action
end

function PANEL:Paint(w, h)

	local size = h
	if self.showAll then
		local spaceSize = h/2
		
		local binds = {binput.getBinding(self.action, self.isController or binput.isController, self.map)}
		local count = #binds
		local width = count * size + (count-1) * spaceSize

		local offset_x = 0
		if self.halign == 0 then
			offset_x = width/-2
		elseif self.halign == 1 then
			offset_x = -width
		end

		for i = 1, count do
			local bind = binds[i]
			drawBinding(offset_x + (i-1)*(size+spaceSize), 0, size, size, bind)
		end
	else
		local offset_x = 0
		if self.halign == 0 then
			offset_x = size/-2
		elseif self.halign == 1 then
			offset_x = -size
		end
		local bind = binput.getBinding(self.action, self.isController or binput.isController, self.map)
		drawBinding(offset_x, 0, size, size, bind)
	end

end

gui.Register("ActionIcon", PANEL)
