if LITE then return end
local PANEL = {}

local focusedButton -- The current button that has focus and will receive input
local hotButtons = {} -- {[action] = button} table of buttons to immediately press when the action is pushed

function PANEL:Init()

	self.branches = {}
	self.focused = false
	self.nofocus = false

end

function PANEL:SetDisallowFocus(disallow)
	self.nofocus = disallow
end

function PANEL:SetBranch(iname, button)
	if iname == "ui_accept" then
		error("Cannot set branch action to ui_accept")
	end
	self.branches[iname] = button
end

function PANEL:SetUp(button)
	self.branches.ui_up = button
end
function PANEL:SetDown(button)
	self.branches.ui_down = button
end
function PANEL:SetLeft(button)
	self.branches.ui_left = button
end
function PANEL:SetRight(button)
	self.branches.ui_right = button
end

function PANEL:Focus()
	self.focused = true
	if focusedButton ~= self then
		if focusedButton then
			focusedButton.focused = false
		end
		focusedButton = self
		self:OnFocus()
		hook.run("buttonFocus", self)
	end
end

function PANEL:SetHotAction(action)
	hotButtons[action] = self
end

function PANEL:Paint(w, h)
	render.setRGBA(255, 0, 255, 255)
	render.drawRectFast(0, 0, w, h)
end

function PANEL:OnFocus()
end

function PANEL:DoPress()
end

function PANEL:InternalDoPress() -- To be handled by any subclasses
end

hook.add("action", "ButtonControl", function(action, pressed)

	if not pressed then return end
	if focusedButton then
		local branch = focusedButton.branches[action]
		if branch then
			if not branch.nofocus and branch.visible then branch:Focus() end
		elseif action == "ui_accept" then
			if focusedButton.className == "Tickbox" then
				focusedButton:SetValue(not focusedButton.value)
			end
			focusedButton:InternalDoPress()
			focusedButton:DoPress()
		end
	end
	local hot = hotButtons[action]
	if hot then
		if not hot.nofocus and hot.visible then hot:Focus() end
		if hot.className == "Tickbox" then
			hot:SetValue(not hot.value)
		end
		hot:InternalDoPress()
		hot:DoPress()
	end

end)

hook.add("sceneClosing", "ButtonControl", function(sceneName)
	if focusedButton then
		focusedButton.focused = false
		focusedButton = nil
	end
	hotButtons = {}
end)

hook.add("sceneClose", "ButtonControl", function(sceneName)
end)

gui.Register("Button", PANEL, "Control")