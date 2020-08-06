local PANEL = {}


function PANEL:Init()

	PANEL.super.Init(self)
	self:SetSize(1022, 1022)
	self.allowSkyline = true
	self.brickSize = 48

end

function PANEL:SetField(field)
	self.field = field
end

function PANEL:SetBrickSize(size)
	self.brickSize = size
end

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

local _blockFunc = drawBlock
if not LITE then
	_blockFunc = sprite.draw
end

function PANEL:Paint(w, h)

	if not self.field then return end
	local BRICK_SIZE = self.brickSize
	local sky = self.allowSkyline
	if not LITE then sprite.setSheet(1) end
	render.setRGBA(220, 220, 220, 255)
	local bottomY = BRICK_SIZE * (sky and 21 or 20)

	if sky then
		gui.pushScissor(0, BRICK_SIZE/2, BRICK_SIZE * 10, BRICK_SIZE*21)
	end
	for x = 0, 9 do
		for y = 0, (sky and 20 or 19) do

			local spr = SPRITE_LOOKUP[self.field:get(x, y)]
			if spr then
				_blockFunc(spr, x * BRICK_SIZE, bottomY - BRICK_SIZE * (y+1), BRICK_SIZE, BRICK_SIZE)
			end

		end
	end
	if sky then
		gui.popScissor()
	end

end

gui.Register("Field", PANEL, "RTControl")
