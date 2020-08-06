if LITE then return end
local PANEL = {}

local fadeTime = 0.5
function PANEL:Init()

	self.inDanger = false
	self.lerpEnd = 0

end

function PANEL:SetInDanger(danger)
	if danger == self.inDanger then return end
	self.inDanger = danger
	self.lerpEnd = timer.realtime() + fadeTime
end

function PANEL:Paint(w, h)

	local t = timer.realtime()
	local percent = 1
	if t > self.lerpEnd then
		percent = self.inDanger and 1 or 0
	else

		percent = (t - (self.lerpEnd - fadeTime)) / fadeTime
		if not self.inDanger then
			percent = 1 - percent
		end

	end

	if percent == 0 then return end
	render.setRGBA(255, 0, 0, 20 * percent)
	render.drawRectFast(0, 0, w, h)

end

gui.Register("Danger", PANEL, "Control")