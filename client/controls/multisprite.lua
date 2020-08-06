if LITE then return end
local PANEL = {}

function PANEL:Init()

	PANEL.super.Init(self)
	self.refSprite = 0

end

function PANEL:SetRef(ref)
	self.refSprite = ref
end

function PANEL:SetValue(value)

	self:SetSprite(self.refSprite + value)

end

gui.Register("MultiSprite", PANEL, "Sprite")
