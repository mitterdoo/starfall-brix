local SCENE = {}
SCENE.Entry = true

function SCENE.Open()

	local w, h = render.getGameResolution()
	local root = gui.Create("Control")
	local s = gui.Create("Material", root)
	s:SetMaterial(sprite.mats.logo)
	s:SetSize(1024, 1024)

	local c = gui.Create("ActionIcon", root)
	c:SetAction("ui_accept")
	c:SetPos(512, 512)

	return function()
		root:Remove()
	end

end

scene.Register("Title", SCENE)
