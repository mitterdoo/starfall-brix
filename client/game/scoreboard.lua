
local spr_playerCount = sprite.sheets[1].playerCount
local spr_killCount = sprite.sheets[1].killCount
local off_badgeBonus = sprite.sheets[1].badgeBonus

local function padNumber(num, padding)

	return string.format("%0" .. (tonumber(padding) or 0) .. "d", num)

end

local function badgeEase(frac)

	return (frac - 1)^3 + 1

end

hook.add("brConnect", "scoreboard", function(game, arena)

	local Scoreboard = game.controls.Scoreboard

	if not game.badgeBitsUpdate then
		function game.badgeBitsUpdate(new, old)

		end
	end

	local w, h = Scoreboard.w, Scoreboard.h
	local RemainingHeight = 24
	local RemainingLabel = gui.Create("Sprite", Scoreboard)
	RemainingLabel:SetSheet(1)
	RemainingLabel:SetSprite(spr_playerCount)
	RemainingLabel:SetPos(4, RemainingHeight)
	RemainingLabel:SetSize(100, 24)

	local Remaining = gui.Create("Number", Scoreboard)
	Remaining:SetSize(20, 30)
	Remaining:SetAlign(0)
	Remaining:SetValue("01/33")
	Remaining:SetPos(w/2, RemainingHeight + 24)
	Remaining:SetColor(Color(200, 255, 255))

	local KOHeight = 96
	local KOLabel = gui.Create("Sprite", Scoreboard)
	KOLabel:SetSheet(1)
	KOLabel:SetSprite(spr_killCount)
	KOLabel:SetPos(4, KOHeight)
	KOLabel:SetSize(100, 24)

	local KO = gui.Create("Number", Scoreboard)
	KO:SetAlign(1)
	KO:SetValue("00")
	KO:SetPos(w-4, KOHeight)
	KO:SetSize(24, 30)
	KO:SetColor(Color(255, 200, 200))

	local BadgeBonus = gui.Create("Sprite", Scoreboard)
	BadgeBonus:SetAlign(0, 1)
	BadgeBonus:SetSheet(1)
	BadgeBonus:SetVisible(false)
	BadgeBonus:SetPos(w/2, h-4)
	BadgeBonus:SetSize(w-8, 48)

	local BadgeSprites = {}
	
	local badgeHeight = 164
	local badgeSize = 48

	local badgeSpacingSize = w/3 - 2/3*badgeSize

	function Scoreboard:GetBadgePos(badge, absolute)

		local x, y = 0, 0
		if badge == 1 then
			x, y = badgeSpacingSize + badgeSize/2, badgeHeight
		elseif badge == 2 then
			x, y = w - badgeSpacingSize - badgeSize/2, badgeHeight
		elseif badge == 3 then
			x, y = badgeSpacingSize + badgeSize/2, badgeHeight + badgeSpacingSize + badgeSize
		else
			x, y = w - badgeSpacingSize - badgeSize/2, badgeHeight + badgeSpacingSize + badgeSize
		end

		if absolute then
			return self:AbsolutePos(x, y)
		else
			return x, y
		end

	end

	for i = 1, 4 do
		local Badge = gui.Create("Sprite", Scoreboard)
		Badge:SetPos(Scoreboard:GetBadgePos(i))
		Badge:SetSheet(1)
		Badge:SetVisible(false)
		Badge:SetAlign(0, 0)
		Badge:SetSize(badgeSize, badgeSize)
		BadgeSprites[i] = Badge
	end

	local off_badgeBits = sprite.sheets[1].badgeBits
	local spr_fullBadge = off_badgeBits + 15
	local curBadgeBits = 0
	function Scoreboard:SetBadgeBits(totalBits)

		local badges, bits = br.getBadgeCount(totalBits)
		for i = 1, 4 do
			if i <= badges then
				BadgeSprites[i]:SetVisible(true)
				BadgeSprites[i]:SetSprite(spr_fullBadge)
			elseif i == badges + 1 and bits > 0 then
				BadgeSprites[i]:SetVisible(true)
				BadgeSprites[i]:SetSprite(math.floor(off_badgeBits - 1 + bits * 16))
			else
				BadgeSprites[i]:SetVisible(false)
			end
		end

		if badges > 0 then
			BadgeBonus:SetSprite(off_badgeBonus + badges - 1)
			BadgeBonus:SetVisible(true)
		else
			BadgeBonus:SetVisible(false)
		end

		game.badgeBitsUpdate(totalBits, curBadgeBits)
		curBadgeBits = totalBits


	end

	local function fx_Badge(x, y, w, h, frac, glow)

		render.setRGBA(255, 255, 255, 255)
		sprite.setSheet(1)
		sprite.draw(spr_fullBadge, x, y, w, h)

	end

	function Scoreboard:AddBadgeBit()
		self:SetBadgeBits(curBadgeBits + 1)
	end

	local badgeTravelTime = 0.5
	local badgeDelay = 0.1
	function Scoreboard:AwardBitsFromAbsolutePos(badgeBits, startPos)

		local startBadgeBits = curBadgeBits
		for i = 1, badgeBits do

			local nextBadgeCount, nextBadgeBitCount = br.getBadgeCount(curBadgeBits + i)
			-- where does this badge go?
			local curBadge = nextBadgeCount + math.ceil(nextBadgeBitCount)
			local bx, by, bsw, bsh = self:GetBadgePos(curBadge, true)
			local badgePos = Vector(bx, by, 0)
			local scale = Vector(bsw, bsh, 0)

			gfx.EmitParticle(
				{startPos + Vector(math.random()-0.5, math.random(0.5), 0) * 2 * 20 * scale, badgePos},
				{Vector(48, 48, 0) * scale},
				badgeDelay * (i-1), badgeTravelTime,
				fx_Badge, false, true, badgeEase
			)

			timer.simple(badgeDelay * (i-1) + badgeTravelTime, function()
				self:AddBadgeBit()
			end)


		end

	end

	local arenaSize = 33
	local KOCount = 0
	local function setPlayerCount(count, max)

		max = max or arenaSize
		arenaSize = max
		Remaining:SetValue(padNumber(count, 2) .. "/" .. padNumber(max, 2))

	end
	arena.hook("playerConnect", function(playerID)
		setPlayerCount(arena.playerCount)
	end)

	arena.hook("playerDisconnect", function(playerID)
		setPlayerCount(arena.playerCount)
	end)

	arena.hook("arenaFinalized", function()
	
		setPlayerCount(arena.remainingPlayers, arena.playerCount)

	end)

	arena.hook("playerDie", function(victim, killer)
	
		if victim == arena.uniqueID or arena.dead then return end

		if killer == arena.uniqueID then
			KOCount = KOCount + 1
			KO:SetValue(padNumber(KOCount, 2))
		end
		setPlayerCount(arena.remainingPlayers)

	end)

	arena.hook("badgeBits", function(count, sourceID)

		local badges = br.getBadgeCount(arena.badgeBits)
		if badges > 0 then
			BadgeBonus:SetSprite(off_badgeBonus + badges - 1)
			BadgeBonus:SetVisible(true)
		else
			BadgeBonus:SetVisible(false)
		end
	
	end)


end)
