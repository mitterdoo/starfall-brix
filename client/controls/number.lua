if LITE then return end
local PANEL = {}

function PANEL:Init()

	self.color = Color(255, 255, 255)
	self.value = "0"
	self.align = -1

end

function PANEL:SetValue(value)
	self.value = tostring(value):gsub("[^%d/:]", "")
end

function PANEL:SetAlign(alignment)

	self.align = alignment

end

function PANEL:SetColor(col)
	self.color = col
end

local spr_digit = sprite.sheets[1].digits
function PANEL:Paint(w, h)

	local length = #self.value
	local origin_x
	local align = self.align
	if align == -1 then
		origin_x = 0
	elseif align == 0 then
		origin_x = w * length / -2
	else
		origin_x = w * -length
	end

	
	sprite.setSheet(1)
	render.setColor(self.color)


	for i = 1, length do

		local char = self.value:byte(i)
		if 47 <= char and char <= 58 then
			sprite.draw(spr_digit + char - 48, origin_x + (i - 1) * w, 0, w, h)
		else
			error("Number: malformed value (" .. tostring(self.value) .. ")")
		end

	end


end

gui.Register("Number", PANEL, "Control")
