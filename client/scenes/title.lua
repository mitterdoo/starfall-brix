local SCENE = {}

local uiFont = render.createFont("Roboto", 36, 200)

function SCENE.Open(from)

	local w, h = render.getGameResolution()
	local logo_w, logo_h = 2040, 1020
	local logo_scale = math.min(1, gui.getFitScale(logo_w, logo_h, w, h, true))
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
	b_play:SetBGColor(Color(100, 255, 100))

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
	function b_options:DoPress()
		scene.Open("Options", 1)
	end

	if not settings.lookedAtOptions then
		local controlsTip = gui.Create("Control", b_options)
		controlsTip:SetPos(0, -114)
		function controlsTip:Paint()
			render.setRGBA(255, 255, 255, 255)
			render.setFont(uiFont)
			render.drawText(0, 0, "You should review the\ncontrols before playing!", 1)
		end
	end
	
	b_options:SetRight(b_play)
	b_play:SetLeft(b_options)
	b_play:SetRight(b_about)
	b_about:SetLeft(b_play)

	local c_ongoing = gui.Create("Control", b_play)
	c_ongoing:SetPos(0, 84)
	c_ongoing:SetVisible(false)
		local s_ongoing = gui.Create("Sprite", c_ongoing)
		s_ongoing:SetSheet(2)
		s_ongoing:SetSprite(sprite.sheets[2].ongoingMatch)
		s_ongoing:SetAlign(0, 1)

		local n_ongoing = gui.Create("Number", c_ongoing)
		n_ongoing:SetSize(32, 40)
		n_ongoing:SetAlign(0)
		n_ongoing:SetValue("0/0")


	function b_play:DoPress()
		if c_ongoing.visible then
			scene.Open("Spectate", 1)
		else
			scene.Open("Game", 1)
		end
	end
	if from == "Options" then
		b_options:Focus()
	elseif from == "About" then
		b_about:Focus()
	else
		b_play:Focus()
	end
	local CreatorInfo = gui.Create("Sprite", root)
	CreatorInfo:SetAlign(0, -1)
	CreatorInfo:SetPos(w/2, 0)
	CreatorInfo:SetSheet(2)
	CreatorInfo:SetSprite(sprite.sheets[2].credit)

	local conn = {}
	local function getServerInfo()
		conn = br.getServerStatus(function(info)
		
			if not info then
				b_play:SetBGColor(Color(100, 100, 100))
				if b_play.focused then
					b_about:Focus()
				end
				b_about:SetLeft(b_options)
				b_options:SetRight(b_about)
			else
				b_play:SetBGColor(Color(100, 255, 100))
				b_about:SetLeft(b_play)
				b_options:SetRight(b_play)

				if info.remainingPlayers then
					c_ongoing:SetVisible(true)
					n_ongoing:SetValue(info.remainingPlayers .. "/" .. info.playerCount)
				else
					c_ongoing:SetVisible(false)
				end

			end

		end)
	end
	timer.create("title_requestServer", 5, 0, getServerInfo)
	getServerInfo()


	return function()
		if conn.close then
			conn.close()
		end
		root:Remove()
		timer.remove("title_requestServer")
	end

end

scene.Register("Title", SCENE)
