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
	MoveButtons:SetPos(32, h - 32)
	MoveButtons:SetAlign(-1, 1)
	MoveButtons:SetFont(uiFont)
	MoveButtons:SetText("{ui_up} {ui_down} {ui_left} {ui_right} Select")

	local SelectButtons = gui.Create("ActionLabel", root)
	SelectButtons:SetPos(w - 32, h - 32)
	SelectButtons:SetAlign(1, 1)
	SelectButtons:SetFont(uiFont)
	SelectButtons:SetText("{ui_accept} Accept   {ui_cancel} Back")

	local b1 = gui.Create("BlockButton", root)
	b1:SetLabel(sprite.sheets[2].b_play)
	b1:SetPos(w/2, h - 128 - 80)
	b1:SetAlign(0, 0)
	b1:Focus()
	b1:SetBGColor(Color(100, 255, 100))
	function b1:DoPress()
		scene.Open("Game", 1)
	end

	local b2 = gui.Create("BlockButton", root)
	b2:SetLabel(sprite.sheets[2].b_about)
	b2:SetPos(w/2 + 300, h - 128 - 80)
	b2:SetAlign(0, 0)
	b2:SetBGColor(Color(255, 255, 100))
	function b2:DoPress()
		scene.Open("About", 1)
	end
	
	b1:SetRight(b2)
	b2:SetLeft(b1)


	local CreatorInfoShadow = gui.Create("Sprite", root)
	CreatorInfoShadow:SetAlign(0, 1)
	CreatorInfoShadow:SetPos(w/2 + 2, h + 2)
	CreatorInfoShadow:SetSheet(2)
	CreatorInfoShadow:SetSprite(sprite.sheets[2].credit)
	CreatorInfoShadow:SetColor(Color(0, 0, 0))
	local CreatorInfo = gui.Create("Sprite", root)
	CreatorInfo:SetAlign(0, 1)
	CreatorInfo:SetPos(w/2, h)
	CreatorInfo:SetSheet(2)
	CreatorInfo:SetSprite(sprite.sheets[2].credit)


	return function()
		root:Remove()
	end

end

scene.Register("Title", SCENE)
