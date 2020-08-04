-- Show tricks (such as tspin, quad, combo, etc)
local offset_clears = sprite.sheets[2].clears
local offset_tricks = sprite.sheets[2].tricks

local SPR_TSPIN = offset_tricks + 0
local SPR_TSPIN_MINI = offset_tricks + 1
local SPR_BACKTOBACK = offset_tricks + 2
local SPR_COMBO = offset_tricks + 3

local T = brix.tricks
local trickHeight = sprite.sheets[2][offset_clears][4]

hook.add("brConnect", "tricks", function(game, arena)

	local root = game.controls.HUD
	local Field_OverMatrix = game.controls.Field_OverMatrix
	local LineClearCenter = gui.Create("Control", Field_OverMatrix)
	game.controls.LineClearCenter = LineClearCenter
	
	local Ctrl_Tricks = gui.Create("Control", root)
	Ctrl_Tricks:SetPos(-120, 150)

	local comboChange = 0
	local comboAnimDuration = 0.3

	local Ctrl_Combo = gui.Create("Sprite", Ctrl_Tricks)
	Ctrl_Combo:SetSheet(2)
	Ctrl_Combo:SetSprite(SPR_COMBO)
	Ctrl_Combo:SetAlign(0, -1)
	Ctrl_Combo:SetColor(Color(200, 100, 255))
	Ctrl_Combo:SetVisible(false)
	local Ctrl_ComboCount = gui.Create("Number", Ctrl_Combo)
	Ctrl_ComboCount:SetPos(0, trickHeight)
	Ctrl_ComboCount:SetSize(64, 80)
	Ctrl_ComboCount:SetAlign(0)
	Ctrl_ComboCount:SetColor(Color(255, 255, 100))

	local clearedChange = 0
	local clearedDuration = 2

	local Ctrl_Cleared = gui.Create("Sprite", Ctrl_Tricks)
	Ctrl_Cleared:SetPos(0, trickHeight*3)
	Ctrl_Cleared:SetSheet(2)
	Ctrl_Cleared:SetSprite(offset_clears)
	Ctrl_Cleared:SetVisible(false)
	Ctrl_Cleared:SetAlign(0, 1)

	local Ctrl_Cleared2 = gui.Create("Sprite", Ctrl_Cleared) -- second line
	Ctrl_Cleared2:SetPos(0, 0)
	Ctrl_Cleared2:SetSheet(2)
	Ctrl_Cleared2:SetSprite(offset_tricks)
	Ctrl_Cleared2:SetVisible(false)
	Ctrl_Cleared2:SetAlign(0, -1)

	local Ctrl_B2B = gui.Create("Sprite", Ctrl_Cleared)
	Ctrl_B2B:SetPos(0, trickHeight)
	Ctrl_B2B:SetSheet(2)
	Ctrl_B2B:SetSprite(SPR_BACKTOBACK)
	Ctrl_B2B:SetVisible(false)
	Ctrl_B2B:SetAlign(0, -1)

	local Ctrl_Sent = gui.Create("Number", Field_OverMatrix)
	Ctrl_Sent:SetPos(Field_OverMatrix.w / 2, 0)
	Ctrl_Sent:SetSize(50, 60)
	Ctrl_Sent:SetValue(2)
	Ctrl_Sent:SetAlign(0)
	Ctrl_Sent:SetVisible(false)

	local sentNumberChange = 0
	local sentNumberDuration = 1
	local sentNumberHoverHeight = 100
	local sentNumberStartHeight = 0

	function Ctrl_Tricks:Think()

		local t = timer.realtime()
		do
			local frac = timeFrac(t, comboChange, comboChange + comboAnimDuration)
			if frac >= 0 then

				if frac > 1 then
					if Ctrl_Combo.y ~= 0 then
						Ctrl_Combo:SetPos(0, 0)
					end
				else
					Ctrl_Combo:SetPos(0, -math.sin(frac * math.pi * 3) * (1-frac) * 80)
				end

			end
		end

		do

			local frac = timeFrac(t, clearedChange, clearedChange + clearedDuration)

			if frac > 1 and Ctrl_Cleared.visible then
				Ctrl_Cleared:SetVisible(false)
			end

			frac = timeFrac(frac, 0, 0.15 / clearedDuration)
			if frac >= 0 then
				if frac > 1 then
					if not Ctrl_Cleared.reset then
						Ctrl_Cleared.reset = true
						Ctrl_Cleared:SetScale(1, 1)
					end
					if Ctrl_B2B.visible ~= Ctrl_B2B.isb2b then
						Ctrl_B2B:SetVisible(Ctrl_B2B.isb2b)
					end
				else
					Ctrl_Cleared.reset = nil
					Ctrl_Cleared:SetScale(frac, frac)
				end
			end

		end

		do

			local frac = timeFrac(t, sentNumberChange, sentNumberChange + sentNumberDuration)
			if frac > 1 then
				if Ctrl_Sent.visible then
					Ctrl_Sent:SetVisible(false)
				end
			elseif frac >= 0 then
				if not Ctrl_Sent.visible then
					Ctrl_Sent:SetVisible(true)
				end
				Ctrl_Sent:SetPos(Ctrl_Sent.x, sentNumberStartHeight - sentNumberHoverHeight * frac)

				local alphaFrac = timeFrac(frac, 0.5, 1)
				Ctrl_Sent.color.a = math.min(255, (1-alphaFrac)^2*255)

			end

		end

	end

	arena.hook("lock", function(tricks, combo, linesSent, linesCleared)

		local brickSize = sprite.sheets[3].field_main[3]

		local clearedCount = flagGet(tricks, T.SINGLE) and 1 or
			flagGet(tricks, T.DOUBLE) and 2 or
			flagGet(tricks, T.TRIPLE) and 3 or
			flagGet(tricks, T.QUAD) and 4 or 0

		if combo > 0 then
			Ctrl_Combo:SetVisible(true)
			Ctrl_ComboCount:SetValue(combo)
			comboChange = timer.realtime()
		else
			Ctrl_Combo:SetVisible(false)
		end

		local tspin, mini, b2b = flagGet(tricks, T.TSPIN), flagGet(tricks, T.MINI_TSPIN), flagGet(tricks, T.BACK_TO_BACK)
		if clearedCount > 0 then
			Ctrl_Cleared:SetVisible(true)
			Ctrl_B2B:SetVisible(false)

			local Line_Count

			Ctrl_B2B.isb2b = b2b

			if tspin or mini then
				Line_Count = Ctrl_Cleared2
				Ctrl_Cleared:SetSprite(tspin and SPR_TSPIN or SPR_TSPIN_MINI)
				Ctrl_Cleared:SetAlign(0, 1)
				Ctrl_Cleared:SetColor(Color(200, 100, 255))
				Ctrl_Cleared2:SetAlign(0, -1)
				Ctrl_Cleared2:SetVisible(true)
			else
				Line_Count = Ctrl_Cleared
				Ctrl_Cleared:SetAlign(0, 0)
				Ctrl_Cleared2:SetVisible(false)
			end

			Line_Count:SetColor(clearedCount == 4 and Color(100, 255, 100) or Color(255, 255, 100))
			Line_Count:SetSprite(offset_clears - 1 + clearedCount)
			clearedChange = timer.realtime()
		
		elseif tspin or mini then

			Ctrl_B2B:SetVisible(false)
			Ctrl_B2B.isb2b = false

			Ctrl_Cleared:SetVisible(true)
			Ctrl_Cleared:SetSprite(tspin and SPR_TSPIN or SPR_TSPIN_MINI)
			Ctrl_Cleared:SetAlign(0, 0)
			Ctrl_Cleared:SetColor(Color(200, 100, 255))

			clearedChange = timer.realtime()

		end

		if linesSent > 0 then

			sentNumberChange = timer.realtime()

			local avg = 0
			for _, line in pairs(linesCleared) do
				avg = avg + line
			end
			avg = avg / #linesCleared

			LineClearCenter:SetPos(brickSize*5, -brickSize * (avg + 0.5))

			sentNumberStartHeight = (avg + 0.5) * -brickSize - 30

			Ctrl_Sent:SetValue(linesSent)

		end


	end)

end)

