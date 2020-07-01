local PANEL = {}

local clusterSpacing = 4
function PANEL:Init()

	self.brickSize = 48
	self.clusters = {}

end

function PANEL:SetBrickSize(size)
	self.brickSize = size
end

function PANEL:Enqueue(lines)

	local g = gui.Create("GarbageCluster", self)
	g:SetBrickSize(self.brickSize)
	g:SetPos(0, 0)
	g:SetCount(lines)
	table.insert(self.clusters, g)

	timer.simple(1/60, function()
	
		g:SetState(1)

	end)
	timer.simple(2, function()
	
		g:SetState(2)

	end)
	timer.simple(4, function()
	
		g:SetState(3)

	end)

end

gui.Register("GarbageQueue", PANEL, "Control")
