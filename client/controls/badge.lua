local PANEL = {}

function PANEL:Init()
	self.index = 16
	self.halign = -1
	self.valign = -1
end

function PANEL:SetAlign(h, v)
	self.halign = h
	self.valign = v
end

function PANEL:SetIndex(idx)
	self.index = idx
end

if LITE then
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

		render.setRGBA(255, 200, 0, 255)

		local badgeHeight = math.floor(self.index / 16 * h)

		render.drawRectFast(offset_x, offset_y + h - badgeHeight, w, badgeHeight)

	end
else
	local off_badgeBits = sprite.sheets[1].badgeBits
	function PANEL:Paint(w, h)
		render.setRGBA(255, 255, 255, 255)
		sprite.setSheet(1)
		sprite.draw(off_badgeBits-1+self.index, 0, 0, w, h, self.halign, self.valign)
	end
end

gui.Register("Badge", PANEL, "Control")
