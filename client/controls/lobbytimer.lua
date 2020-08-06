if LITE then return end
local PANEL = {}

function PANEL:Init()
	PANEL.super.Init(self)

	self.hookName = "lobbytimer" .. math.random(2^31-1)
	self.finish = timer.curtime() + ARENA.lobbyWaitTime

end

function PANEL:SetFinish(time)
	if time == nil then
		self:SetValue(ARENA.lobbyWaitTime)
		self.finish = nil
	else
		self.finish = time
	end
end

function PANEL:Think()

	if self.finish then
		local t = self.finish - timer.curtime()
		t = math.max(0, math.ceil(t))

		if t ~= self.lastValue then
			self.lastValue = t
			self:SetValue(t)
		end
	end

end

gui.Register("LobbyTimer", PANEL, "Number")
