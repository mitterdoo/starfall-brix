if LITE then return end
local PANEL = {}
function PANEL:Init()
	PANEL.super.Init(self)
	self.halign = 0
	self.valign = 0
	self.label = 11
	self.bgcol = Color(255, 255, 255)
	self.fgcol = Color(255, 255, 255)
	self:SetSize(256, 80)
end

function PANEL:SetBGColor(col)
	self.bgcol = col
end
function PANEL:SetFGColor(col)
	self.fgcol = col
end

function PANEL:SetLabel(label)
	self.label = label
end

function PANEL:SetAlign(h, v)
	self.halign = h
	self.valign = v
end
local spr_button = sprite.sheets[2].button
local outlineSize = 4
local glowSize = 16
function PANEL:Paint(w, h)

	local offset_x, offset_y
	local halign, valign = self.halign, self.valign
	if halign == -1 then
		offset_x = 0
	elseif halign == 0 then
		offset_x = w/-2
	elseif halign == 1 then
		offset_x = -w
	end

	if valign == -1 then
		offset_y = 0
	elseif valign == 0 then
		offset_y = h/-2
	elseif valign == 1 then
		offset_y = -h
	end

	if self.focused then
		render.setRGBA(255, 128, 0, 255)
		local bx, by, bw, bh = offset_x - outlineSize, offset_y - outlineSize, w + outlineSize*2, h + outlineSize*2
		render.drawRectFast(bx, by, bw, outlineSize)
		render.drawRectFast(bx, by + bh - outlineSize, bw, outlineSize)
		render.drawRectFast(bx, by + outlineSize, outlineSize, bh - outlineSize*2)
		render.drawRectFast(bx + bw - outlineSize, by + outlineSize, outlineSize, bh - outlineSize*2)
		gui.startGlow()
		render.drawRectFast(bx, by, bw, glowSize)
		render.drawRectFast(bx, by + bh - glowSize, bw, glowSize)
		render.drawRectFast(bx, by + glowSize, glowSize, bh - glowSize*2)
		render.drawRectFast(bx + bw - glowSize, by + glowSize, glowSize, bh - glowSize*2)
		gui.endGlow()
	end
	self:DrawButtonSprite(offset_x, offset_y, w, h)
end

function PANEL:DrawButtonSprite(x, y, w, h)

	sprite.setSheet(2)
	render.setColor(self.bgcol)
	sprite.draw(spr_button, x, y, w, h)
	local labelHeight = h / 80 * 64
	render.setColor(self.fgcol)
	sprite.draw(self.label, x, y + h/2 - labelHeight/2, w, labelHeight)

end

local function fx_Accept(x, y, w, h, frac, glow)

	render.setRGBA(255, 255, 255, (1-frac)^2*255)
	render.drawRectFast(x, y, w, h)

end

function PANEL:InternalDoPress()

	local w, h = self.w, self.h
	local offset_x, offset_y
	local halign, valign = self.halign, self.valign
	if halign == -1 then
		offset_x = 0
	elseif halign == 0 then
		offset_x = w/-2
	elseif halign == 1 then
		offset_x = -w
	end

	if valign == -1 then
		offset_y = 0
	elseif valign == 0 then
		offset_y = h/-2
	elseif valign == 1 then
		offset_y = -h
	end
	local pos, scale = self:AbsolutePos(Vector(offset_x + w/2, offset_y + h/2, 0))

	gfx.EmitParticle(
		{pos, pos},
		{Vector(w, h, 0) * scale, Vector(w, h, 0) * scale * 2},
		0, 0.5,
		fx_Accept,
		true, true
	)

end

gui.Register("BlockButton", PANEL, "Button")
