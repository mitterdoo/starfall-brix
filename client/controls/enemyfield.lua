local PANEL = {}
local FIELD = gui.Classes["Field"]

function PANEL:Init()

	self.allowSkyline = false
	self.brickSize = 48

end

PANEL.SetField = FIELD.SetField
PANEL.SetBrickSize = FIELD.SetBrickSize
PANEL.Paint = FIELD.Paint

gui.Register("EnemyField", PANEL, "Control")
