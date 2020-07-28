local PANEL = {}

local spr_finalPlaces = sprite.sheets[1].finalPlaces
local spr_ko = sprite.sheets[1].ko_us

local cardHeight = 32
local cardSpacing = 2
local font_cardNick = render.createFont("Roboto", 24, 100)
local font_cardPlace = render.createFont("Roboto", 30, 900)
local headerBaseline = 80
local cardsBegin = 120

local placeColors = {
	[1] = {255, 255, 100, 255},
	[2] = {200, 200, 200, 255},
	[3] = {192, 144, 69, 255}
}

function PANEL:Init()

	self.super.Init(self)
	self.placements = {} -- [place] = {nick, attribute}
	self.max = 1

	self.place = gui.Create("Number", self)
	self.place:SetSize(52, 64)
	self.place:SetAlign(1)
	self.place:SetValue(33)
	self.maxVisibleCards = 1

	self.scroll = 1

	hook.add("inputPressed", "tet", function(button)
	
		if button == 88 then
			self:Scroll(-1)
		elseif button == 90 then
			self:Scroll(1)
		end

	end)

end

function PANEL:Scroll(dir)

	local maxScroll = self.max - self.maxVisibleCards + 1
	self.scroll = math.max(1, math.min(maxScroll, self.scroll + dir))
	self.invalid = true

end

function PANEL:ScrollTo(where)

	local maxScroll = self.max - self.maxVisibleCards + 1
	local delta = math.floor(self.maxVisibleCards / 2)
	where = where - delta
	self.scroll = math.max(1, math.min(maxScroll, where))
	self.invalid = true

end

function PANEL:OnSizeChanged(w, h)
	self.super.OnSizeChanged(self, w, h)
	self.place:SetPos(w, headerBaseline - self.place.h)
	self.maxVisibleCards = math.min(self.max, math.floor((h - cardsBegin) / (cardHeight + cardSpacing)))
	self.invalid = true
end

function PANEL:SetPlacement(place)
	self.place:SetValue(place)
	if placeColors[place] then
		self.place:SetColor(Color(unpack(placeColors[place])))
	else
		self.place:SetColor(Color(255, 255, 255))
	end
	self.invalid = true
end

function PANEL:SetMaxPlacement(place)
	self.max = place
	self.invalid = true
end

local function undecorateNick(nick)
	return nick:gsub("<.-=%[?.-%]?>", "")
				:gsub("%^[0-9][1-5]?", "")
				:gsub("<[^<]->", "")
				:gsub("%:[A-Za-z0-9%_]+%:","")
end

function PANEL:AddPlacement(place, who, attr)
	self.placements[place] = {undecorateNick(who), attr}
	self.invalid = true
end

function PANEL:Paint(w, h)

	render.setRGBA(255, 255, 255, 255)
	sprite.setSheet(1)
	sprite.draw(spr_finalPlaces, 0, headerBaseline - 32, 320, 32)

	for i = 1, self.maxVisibleCards do
		
		local place = self.scroll + i - 1
		local info = self.placements[place]
		if info and info[2] == "us" then
			render.setRGBA(128, 128, 128, 220)
		else
			if place % 2 == 1 then
				render.setRGBA(32, 32, 32, 220)
			else
				render.setRGBA(48, 48, 48, 220)
			end
		end
		local yPos = cardsBegin + (i-1)*(cardHeight + cardSpacing)
		render.drawRectFast(0, yPos, w, cardHeight)

		if placeColors[place] then
			render.setRGBA(unpack(placeColors[place]))
		else
			render.setRGBA(255, 255, 255, 255)
		end
		render.setFont(font_cardPlace)
		render.drawText(8, yPos + cardHeight/2 - 30/2, place .. ".")
		if info then

			render.setRGBA(255, 255, 255, 255)
			render.setFont(font_cardNick)
			render.drawText(64, yPos + cardHeight/2 - 24/2, info[1])

			if info[2] == "ko" then
				sprite.setSheet(1)
				sprite.draw(spr_ko, w - 8, yPos + cardHeight/2, 30, 30, 1, 0)
			end

		end
	end

end

gui.Register("Placements", PANEL, "RTControl")
