if LITE then return end
local PANEL = {}

function PANEL:Init()
	PANEL.super.Init(self)
	self.col = Color(255, 255, 255)
	self.value = false
	self:SetSize(80, 80)
end

function PANEL:SetValue(v)
	self.value = v
end

function PANEL:SetColor(col)
	self.col = col
end

local spr_tickboxOff = sprite.sheets[2].tickbox
local spr_tickboxOn = sprite.sheets[2].tickbox + 1
function PANEL:DrawButtonSprite(x, y, w, h)

	render.setColor(self.col)
	sprite.setSheet(2)
	sprite.draw(self.value and spr_tickboxOn or spr_tickboxOff, x, y, w, h)

end

gui.Register("Tickbox", PANEL, "BlockButton")
