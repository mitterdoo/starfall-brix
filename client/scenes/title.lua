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

	local b_play = gui.Create("BlockButton", root)
	b_play:SetLabel(sprite.sheets[2].b_play)
	b_play:SetPos(w/2, h - 128 - 80)
	b_play:SetAlign(0, 0)
	b_play:Focus()
	b_play:SetBGColor(Color(100, 255, 100))
	function b_play:DoPress()
		scene.Open("Game", 1)
	end

	local b_about = gui.Create("BlockButton", root)
	b_about:SetLabel(sprite.sheets[2].b_about)
	b_about:SetPos(w/2 + 298, h - 128 - 80)
	b_about:SetAlign(0, 0)
	b_about:SetBGColor(Color(255, 255, 100))
	function b_about:DoPress()
		scene.Open("About", 1)
	end

	local b_options = gui.Create("BlockButton", root)
	b_options:SetLabel(sprite.sheets[2].b_options)
	b_options:SetPos(w/2 - 298, h - 128 - 80)
	b_options:SetAlign(0, 0)
	b_options:SetBGColor(Color(190, 92, 255))
	
	b_options:SetRight(b_play)
	b_play:SetLeft(b_options)
	b_play:SetRight(b_about)
	b_about:SetLeft(b_play)


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
