local PANEL = {}
local err = material.load("decals/eye_model")

function PANEL:Init()
	self.mat = err
end

function PANEL:SetMaterial(mat)
	self.mat = mat
end

function PANEL:Paint(w, h)
	render.setRGBA(255, 255, 255, 255)
	render.setMaterial(self.mat)
	render.drawTexturedRect(0, 0, w, h)
end

gui.Register("Material", PANEL, "Control")
