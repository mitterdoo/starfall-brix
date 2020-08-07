local SCENE = {}

local uiFont = render.createFont("Roboto", 36, 200)
local inputFont = render.createFont("Roboto", 32, 200)
function SCENE.Open()

	settings.lookedAtOptions = true


	local w, h = render.getGameResolution()
	local logo_w, logo_h = 1920, 1080
	local logo_scale = gui.getFitScale(logo_w, logo_h, w, h)
	local root = gui.Create("Control")
	root:SetSize(w, h)
	local BG = gui.Create("Material", root)
	BG:SetMaterial(sprite.mats[30])
	BG:SetSize(logo_w * logo_scale, logo_h * logo_scale)
	BG:SetPos(w / 2 - logo_w * logo_scale/2, h / 2 - logo_h * logo_scale/2)


	local function createInputList(self, parent, x, y, height, arg)

		local Ctrl = gui.Create("ActionIcon", parent)
		Ctrl:SetPos(x, y)
		Ctrl:SetSize(height, height)
		Ctrl:SetHAlign(1)
		Ctrl:SetAction(arg)
		Ctrl:SetController(false)
		Ctrl:SetShowAll(true)

		return Ctrl, function(new)
			Ctrl:SetController(new == "gamepad")
			if new == "gamepad" then
				Ctrl.map = nil
			else
				Ctrl.map = binput.keymaps[new]
			end
		end

	end

	local function createTickbox(self, parent, x, y, height, arg)

		local Ctrl = gui.Create("Tickbox", parent)
		Ctrl:SetPos(x, y)
		Ctrl:SetSize(height, height)
		Ctrl:SetAlign(1, -1)
		Ctrl:SetValue(settings[arg[1]] or arg[2])
		function Ctrl:DoPress()
			settings[arg[1]] = Ctrl.value
		end

		return Ctrl, function(new)
			if arg[1] == "dpadOverlap" then
				Ctrl:SetDisallowFocus(new ~= "gamepad")
				Ctrl:SetColor(new == "gamepad" and Color(255, 255, 255) or Color(128, 128, 128))
			end
		end

	end

	local function createAxisKeyboardMap(self, parent, x, y, height, arg)

		return nil, function(new)
			if self.ctrl then
				self.ctrl:Remove()
				self.ctrl = nil
			end
			local Ctrl
			if new == "gamepad" then
				Ctrl = gui.Create("InputIcon", parent)
				Ctrl:SetPos(x - height, y)
				Ctrl:SetInput(arg == "strategy" and "rs" or "ls")
				Ctrl:SetSize(height, height)
			else
				Ctrl = gui.Create("ActionLabel", parent)
				Ctrl:SetPos(x, y)
				Ctrl:SetController(false)
				Ctrl:SetMap(binput.keymaps[new])
				Ctrl:SetAlign(1, -1)
				Ctrl:SetFont(inputFont)
				Ctrl:SetText(arg == "strategy" and "{target_attacker} {target_badges} {target_ko} {target_random}" or "{target_manualPrev} {target_manualNext}")
			end
			self.ctrl = Ctrl
		end
	end

	local offset_options = sprite.sheets[2].options
	local optionTable = {
		{offset_options + 0,	"game_moveleft", setup=createInputList},
		{offset_options + 1,	"game_moveright", setup=createInputList},
		{offset_options + 2,	"game_softdrop", setup=createInputList},
		{offset_options + 3,	"game_harddrop", setup=createInputList},
		{offset_options + 4,	"game_rot_ccw", setup=createInputList},
		{offset_options + 5,	"game_rot_cw", setup=createInputList},
		{offset_options + 6,	"game_hold", setup=createInputList},
		{offset_options + 7,	"strategy", setup=createAxisKeyboardMap},
		{offset_options + 8,	"manual", setup=createAxisKeyboardMap},
		{offset_options + 9,	{"dynamicBackground", true}, setup=createTickbox},
		{offset_options + 10,	{"dpadOverlap", false}, setup=createTickbox},
	}
	
	local Scaled = gui.Create("Control", root)
	Scaled:SetSize(900, 800)
	function Scaled:Paint(w, h)
		render.setRGBA(0, 0, 0, 220)
		render.drawRectFast(0, 0, w, h)
	end

	local uiScale = math.min(1, gui.getFitScale(Scaled.w, Scaled.h, w-100, h-100))
	Scaled:SetScale(uiScale, uiScale)
	Scaled:SetPos(w/2 - Scaled.w/2 * uiScale, h/2 - Scaled.h/2 * uiScale)
	local padding = 16
	local paddingH = 128

		local b_guideline = gui.Create("BlockButton", Scaled)
		b_guideline:SetAlign(0, -1)
		b_guideline:SetLabel(sprite.sheets[2].b_kbGuideline)
		b_guideline:SetPos(Scaled.w/2 - 300, padding)

		local b_wasd = gui.Create("BlockButton", Scaled)
		b_wasd:SetAlign(0, -1)
		b_wasd:SetLabel(sprite.sheets[2].b_kbWasd)
		b_wasd:SetPos(Scaled.w/2, padding)

		local b_gamepad = gui.Create("BlockButton", Scaled)
		b_gamepad:SetAlign(0, -1)
		b_gamepad:SetLabel(sprite.sheets[2].b_gp)
		b_gamepad:SetPos(Scaled.w/2 + 300, padding)
		b_gamepad:SetBGColor(Color(190, 92, 255))

		b_guideline:SetRight(b_wasd)
		b_wasd:SetLeft(b_guideline)
		b_wasd:SetRight(b_gamepad)
		b_gamepad:SetLeft(b_wasd)

		local inputTableStart = 80 + padding*4
		local inputHeight = 32
		local inputSpace = 16

		local lastFocusable = xinput and b_gamepad or b_wasd
		if not xinput then
			b_gamepad:SetDisallowFocus(true)
			b_gamepad:SetBGColor(Color(128, 128, 128))

			local warn = gui.Create("Sprite", Scaled)
			warn:SetPos(b_gamepad.x, b_gamepad.y - 8)
			warn:SetSheet(2)
			warn:SetSprite(sprite.sheets[2].xinputWarn)
			warn:SetAlign(0, 1)
			warn:SetScale(0.75, 0.75)

		end

		for k, info in pairs(optionTable) do
			local Label = gui.Create("Sprite", Scaled)

			local x, y = Scaled.w - paddingH, inputTableStart + (k-1)*(inputHeight+inputSpace)
			Label:SetPos(paddingH, y)
			Label:SetSize(inputHeight/32*320, inputHeight)
			Label:SetSheet(2)
			Label:SetSprite(info[1])
			Label:SetAlign(-1, -1)

			if info.setup then
				local Ctrl, updateFunc = info:setup(Scaled, x, y, inputHeight, info[2])
				info.ctrl = Ctrl
				info.update = updateFunc
			end

			if info.ctrl and info.ctrl.Focus then

				local Ctrl = info.ctrl
				if lastFocusable == b_gamepad then
					b_guideline:SetDown(Ctrl)
					b_wasd:SetDown(Ctrl)
					b_gamepad:SetDown(Ctrl)
				end
				lastFocusable:SetDown(Ctrl)
				Ctrl:SetUp(lastFocusable)
				Ctrl:SetLeft(b_wasd)
				lastFocusable = Ctrl

			end

		end

		local MoveButtons = gui.Create("ActionLabel", Scaled)
		MoveButtons:SetPos(8, Scaled.h - 8)
		MoveButtons:SetAlign(-1, 1)
		MoveButtons:SetFont(uiFont)
		MoveButtons:SetText("{ui_cancel} Back")

	local back = gui.Create("Button", root)
	back:SetHotAction("ui_cancel")
	back:SetDisallowFocus(true)
	back:SetVisible(false)
	function back:DoPress()
		scene.Open("Title", 1)
	end

	local tabNames = {
		"guideline",
		"wasd",
		"gamepad"
	}
	local function changeTab(tab)

		for k, info in pairs(optionTable) do
			if info.update then
				info.update(tabNames[tab])
			end
		end

	end

	function b_guideline:OnFocus()
		b_guideline:SetFGColor(Color(255, 128, 0))
		b_wasd:SetFGColor(Color(255, 255, 255))
		b_gamepad:SetFGColor(Color(255, 255, 255))
		changeTab(1)
	end

	function b_wasd:OnFocus()
		b_guideline:SetFGColor(Color(255, 255, 255))
		b_wasd:SetFGColor(Color(255, 128, 0))
		b_gamepad:SetFGColor(Color(255, 255, 255))
		changeTab(2)
	end

	function b_gamepad:OnFocus()
		b_guideline:SetFGColor(Color(255, 255, 255))
		b_wasd:SetFGColor(Color(255, 255, 255))
		b_gamepad:SetFGColor(Color(255, 128, 0))
		changeTab(3)
	end

	if binput.isController then
		b_gamepad:Focus()
	else
		local curMap = settings.keyboardMap or "guideline"
		if curMap == "wasd" then
			b_wasd:Focus()
			b_wasd:SetBGColor(Color(50, 255, 50))
		else
			b_guideline:Focus()
			b_guideline:SetBGColor(Color(50, 255, 50))
		end
	end

	function b_guideline:DoPress()
		binput.setKeyboardMap("guideline")
		b_wasd:SetBGColor(Color(255, 255, 255))
		b_guideline:SetBGColor(Color(50, 255, 50))
	end

	function b_wasd:DoPress()
		binput.setKeyboardMap("wasd")
		b_wasd:SetBGColor(Color(50, 255, 50))
		b_guideline:SetBGColor(Color(255, 255, 255))
	end


	return function()
		root:Remove()
	end

end
scene.Register("Options", SCENE)
