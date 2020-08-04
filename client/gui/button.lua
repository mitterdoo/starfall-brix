local PANEL = {}

local focusedButton -- The current button that has focus and will receive input
local hotButtons = {} -- {[action] = button} table of buttons to immediately press when the action is pushed

function PANEL:Init()

	self.branches = {}
	self.focused = false

end

function PANEL:SetBranch(iname, button)
	if iname == "ui_accept" then
		error("Cannot set branch action to ui_accept")
	end
	self.branches[iname] = button
end

function PANEL:Focus()
	self.focused = true
	if focusedButton ~= self then
		focusedButton = self
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

function PANEL:DoPress()
end

hook.add("action", "ButtonControl", function(action, pressed)

	if not pressed then return end
	if focusedButton then
		local branch = focusedButton.branches[action]
		if branch then
			branch:Focus()
		elseif action == "ui_accept" then
			focusedButton:DoPress()
		end
	end
	local hot = hotButtons[action]
	if hot then
		hot:Focus()
		hot:DoPress()
	end

end)

hook.add("sceneClosing", "ButtonControl", function(sceneName)
	if focusedButton then
		focusedButton.focused = false
		focusedButton = nil
	end
end)

hook.add("sceneClose", "ButtonControl", function(sceneName)
	hotButtons = {}
end)

gui.Register("Button", PANEL, "Control")