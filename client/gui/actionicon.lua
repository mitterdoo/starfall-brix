local PANEL = {}

function PANEL:Init()
	PANEL.super.Init(self)
	self.action = "ui_accept"
end

function PANEL:SetAction(action)
	self.action = action
end

function PANEL:Think()
	local binding = binput.getBinding(self.action, binput.isController)

	if binding then
		self.input = binding
	end

end

gui.Register("ActionIcon", PANEL, "InputIcon")
