local SCENE = {}
SCENE.Entry = true

local uiFont = render.createFont("Roboto", 36, 200)

function SCENE.Open()

	local w, h = render.getGameResolution()
	local logo_w, logo_h = 1920, 1080
	local logo_scale = gui.getFitScale(logo_w, logo_h, w, h)
	local root = gui.Create("Control")
	root:SetSize(w, h)
	local Logo = gui.Create("Material", root)
	Logo:SetMaterial(sprite.mats.logo)
	Logo:SetSize(logo_w * logo_scale, logo_h * logo_scale)
	Logo:SetPos(w / 2 - logo_w * logo_scale/2, h / 2 - logo_h * logo_scale/2)


	local MoveButtons = gui.Create("ActionLabel", root)
	MoveButtons:SetPos(32, h - 96)
	MoveButtons:SetAlign(-1, 1)
	MoveButtons:SetFont(uiFont)
	MoveButtons:SetText("{ui_up} {ui_down} {ui_left} {ui_right} to select")

	local SelectButtons = gui.Create("ActionLabel", root)
	SelectButtons:SetPos(w - 32, h - 96)
	SelectButtons:SetAlign(1, 1)
	SelectButtons:SetFont(uiFont)
	SelectButtons:SetText("{ui_accept} to accept, {ui_cancel} to go back")

	return function()
		root:Remove()
	end

end

scene.Register("Title", SCENE)
