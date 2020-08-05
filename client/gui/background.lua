local PANEL = {}
local fadeTime = 0.5

local function getBGFromLevel(lvl)
	return 19 + math.min(11, math.max(1, lvl))
end

function PANEL:Init()

	self.bg = 20
	self.lastBg = 20
	self.lerpEnd = 0

end

function PANEL:SetLevel(lvl)
	lvl = getBGFromLevel(lvl)
	if lvl == self.bg then return end
	local dyn = settings.dynamicBackground
	if dyn == nil then dyn = true end
	if not dyn then return end
	
	self.lastBg = self.bg
	self.bg = lvl
	self.lerpEnd = timer.realtime() + fadeTime
end

function PANEL:Paint(w, h)

	local t = timer.realtime()
	local sheet = self.bg
	if t > self.lerpEnd then
		render.setRGBA(255, 255, 255, 255)
		sprite.setSheet(sheet)
		local scale = gui.getFitScale(1920, 1080, w, h)

		local nw, nh = w * scale, h*scale
		sprite.draw(0, w/2 - nw/2, h/2 - nh/2, nw, nh)
		return
	end

	local percent = (t - (self.lerpEnd - fadeTime)) / fadeTime
	render.setRGBA(255, 255, 255, 255)
	sprite.setSheet(self.lastBg)
	sprite.draw(0, 0, 0, w, h)

	render.setRGBA(255, 255, 255, percent * 255)
	sprite.setSheet(sheet)
	sprite.draw(0, 0, 0, w, h)

end


gui.Register("Background", PANEL, "Control")
