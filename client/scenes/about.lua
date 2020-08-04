local SCENE = {}

local howto = {
	"Move and rotate pieces to stack them on the board.",
	"Clear lines to send garbage to your opponents.",
	"Other players can also send you garbage.\nTry to clear lines before it gets inserted on your field.",
	"Change your targeting strategy to send your\ngarbage to certain opponents.",
	"KO your opponents to steal their badges. Earning badges\nwill give you a bonus on outgoing attacks.",
	"The game will get faster as more opponents are KO'd.\nTry to be the last one standing!"
}

local uiFont = render.createFont("Roboto", 36, 200)
local howtoFont = render.createFont("Roboto", 48, 200)
function SCENE.Open()

	local w, h = render.getGameResolution()
	local logo_w, logo_h = 1920, 1080
	local logo_scale = gui.getFitScale(logo_w, logo_h, w, h)
	local root = gui.Create("Control")
	root:SetSize(w, h)
	local BG = gui.Create("Material", root)
	BG:SetMaterial(sprite.mats[28])
	BG:SetSize(logo_w * logo_scale, logo_h * logo_scale)
	BG:SetPos(w / 2 - logo_w * logo_scale/2, h / 2 - logo_h * logo_scale/2)


	local Scaled = gui.Create("Control", root)
	Scaled:SetPos(w/2, h/2)
	Scaled:SetSize(1124, 800)

	local uiScale = math.min(1, gui.getFitScale(Scaled.w, Scaled.h, w-100, h-100))
	Scaled:SetScale(uiScale, uiScale)

	function Scaled:Paint(w, h)
		render.setRGBA(0, 0, 0, 220)
		render.drawRectFast(w/-2, h/-2, w, h)
	end
	
		local Text = gui.Create("RTControl", Scaled)
		Text:SetPos(-512, -360)
		Text:SetSize(1024, 96)

		local About = gui.Create("Sprite", Scaled)
		About:SetSheet(5)
		About:SetSprite(0)
		About:SetSize(512, 512)
		About:SetAlign(0, 0)

		local About2 = gui.Create("Sprite", Scaled)
		About2:SetVisible(false)
		About2:SetSheet(5)
		About2:SetSprite(2)
		About2:SetSize(512, 512)
		About2:SetPos(261, 0)
		About2:SetAlign(0, 0)

		local PageNumber = gui.Create("Number", Scaled)
		PageNumber:SetPos(0, 266)
		PageNumber:SetSize(32, 40)
		PageNumber:SetAlign(0)
		PageNumber:SetValue("1/6")
		

		local MoveButtons = gui.Create("ActionLabel", Scaled)
		MoveButtons:SetPos(Scaled.w/-2 + 8, Scaled.h/2 - 8)
		MoveButtons:SetAlign(-1, 1)
		MoveButtons:SetFont(uiFont)
		MoveButtons:SetText("{ui_cancel} Back    {ui_left} {ui_right} Change page")


	local curPage = 1
	function Text:Paint(w, h)
		render.clear(Color(0, 0, 0, 0), true)
		local text = howto[curPage]
		render.setFont(howtoFont)
		render.setRGBA(255, 255, 255, 255)
		render.drawText(w/2, 0, text, 1)


	end

	local function setPage(page)

		if page == 2 then
			About2:SetVisible(true)
			About:SetSprite(1)
			About:SetSheet(5)
			About:SetPos(-261, 0)
		else
			About2:SetVisible(false)
			if page <= 3 then
				About:SetSheet(5)
				About:SetSprite(page == 1 and 0 or page)
			else
				About:SetSheet(6)
				About:SetSprite(page - 4)
			end
			About:SetPos(0, 0)
		end
		PageNumber:SetValue(page .. "/6")
		curPage = page
		Text.invalid = true

	end


	local back = gui.Create("Button", root)
	back:SetHotAction("ui_cancel")
	back:SetDisallowFocus(true)
	back:SetVisible(false)
	function back:DoPress()
		scene.Open("Title", 1)
	end

	local moveNext = gui.Create("Button", root)
	moveNext:SetHotAction("ui_right")
	moveNext:SetDisallowFocus(true)
	moveNext:SetVisible(false)
	function moveNext:DoPress()
		setPage(math.min(6, curPage + 1))
	end

	local movePrev = gui.Create("Button", root)
	movePrev:SetHotAction("ui_left")
	movePrev:SetDisallowFocus(true)
	movePrev:SetVisible(false)
	function movePrev:DoPress()
		setPage(math.max(1, curPage - 1))
	end



	return function()
		root:Remove()
	end

end

scene.Register("About", SCENE)