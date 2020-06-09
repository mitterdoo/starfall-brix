local PANEL = {}

function PANEL:SetField(field)
	self.field = field
end

local BLOCK_SIZE = 48

local SPRITE_LOOKUP = {
	["0"] = 0,
	["1"] = 1,
	["2"] = 2,
	["3"] = 3,
	["4"] = 4,
	["5"] = 5,
	["6"] = 6,
	["!"] = 7,
	["="] = 15,
	["["] = 16
}

function PANEL:Init()

	self.super.Init(self)
	self:SetSize(1022, 1022)
	self.allowSkyline = true

end

function PANEL:Paint(w, h)

	local sky = self.allowSkyline
	sprite.setSheet(1)
	render.setRGBA(220, 220, 220, 255)
	local bottomY = BLOCK_SIZE * (sky and 21 or 20)

	for x = 0, 9 do
		for y = 0, (sky and 20 or 19) do

			local spr = SPRITE_LOOKUP[self.field:get(x, y)]
			if spr then
				sprite.draw(spr, x * BLOCK_SIZE, bottomY - BLOCK_SIZE * (y+1), BLOCK_SIZE, BLOCK_SIZE)
			end

		end
	end

end

gui.Register("Field", PANEL, "RTControl")
