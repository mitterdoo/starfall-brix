local PANEL = {}

local function fx_Kill(x, y, w, h, frac, glow)

	frac = (1-frac)^2
	render.setRGBA(255, frac*255, 0, frac*255)
	render.drawRectFast(x, y, w, h)

end

local enemyRT = "brix_Enemies"
if not render.renderTargetExists(enemyRT) then
	render.createRenderTarget(enemyRT)
end

local badgeSize = 14
local badgeSpacing = (60 - 4*badgeSize)/5

function PANEL:Init()

	PANEL.super.Init(self)
	self.RTName = enemyRT
	self:SetDivisionSize(64, 128)
	self:SetSize(64, 128)

	if self.divisionCount < 33 then
		error("Your current game resolution is too low to play BRIX: Stack To The Death")
	end

end

function PANEL:SetEnemy(enemy)
	self.enemy = enemy
	self:SetDivision(enemy.uniqueID)
	
	if not self.fieldCtrl then
		self.fieldCtrl = gui.Create("EnemyField", self)
		self.fieldCtrl:SetScale(1/8, 1/8)
		self.fieldCtrl:SetPos(2, 4)

		self.badges = {}
		for i = 1, 4 do

			local Badge = gui.Create("Badge", self)
			Badge:SetSize(badgeSize, badgeSize)
			Badge:SetVisible(false)
			Badge:SetPos(2 + badgeSpacing + (i-1) * (badgeSpacing + badgeSize), 4 + badgeSpacing)
			self.badges[i] = Badge

		end

	end

	self.fieldCtrl.field = enemy.matrix


end

function PANEL:SetBadgeBits(totalBits)

	local badges, bits = br.getBadgeCount(totalBits)
	local spr = self.badges
	for i = 1, 4 do

		if i <= badges then
			spr[i]:SetVisible(true)
			spr[i]:SetIndex(16)
		elseif i == badges + 1 and bits > 0 then
			spr[i]:SetVisible(true)
			spr[i]:SetIndex(math.floor(bits * 16))
		else
			spr[i]:SetVisible(false)
		end
	end

end

local KOFont = render.createFont("Roboto", 24, 900)
local PlaceFont = render.createFont("Roboto", 48, 900)
function PANEL:Kill()

	while #self.children > 0 do

		self.children[1]:Remove()

	end
	self.fieldCtrl = nil
	self.badges = nil

	local enemy = self.enemy

	if not LITE then
		local spr_ko = sprite.sheets[1].ko
		local spr_ko_us = sprite.sheets[1].ko_us
		local spr = gui.Create("Sprite", self)
		spr:SetSheet(1)
		if enemy.killedByUs then
			spr:SetSprite(spr_ko_us)
		else
			spr:SetSprite(spr_ko)
		end
		spr:SetAlign(0, 0)
		spr:SetPos(32, 64 - 16)

		local placement = gui.Create("Number", self)
		placement:SetValue(enemy.placement or 0)
		placement:SetAlign(0)
		placement:SetPos(32, 64 + 8)
		placement:SetSize(16, 24)

	else
		local label = gui.Create("Control", self)
		label:SetPos(32, 64-16)
		label:SetSize(64, 24)

		function label:Paint(w, h)
			render.setRGBA(0, 0, 0, 255)
			render.drawRectFast(w/-2, h/-2, w, h)
			render.setRGBA(85, 140, 174, 255)
			render.drawRectFast(w/-2 + 2, h/-2 + 2, w-4, h-4)

			render.setRGBA(255, 255, 255, 255)
			render.setFont(KOFont)
			render.drawText(0, -12, "K.O.", 1)

			render.setFont(PlaceFont)
			render.drawText(0, 22, tostring(enemy.placement), 1)

		end

	end

	self.invalid = true
	if self.parent then
		self.parent.invalid = true
	end

	if enemy.killedByUs then
		local fxPos, scale = self:AbsolutePos(Vector(self.w/2, self.h/2, 0))
		local fxSize = Vector(self.w, self.h, 0) * scale

		gfx.EmitParticle(
			{fxPos, fxPos},
			{fxSize*1.5, fxSize*3},
			0, 0.5,
			fx_Kill,
			true, true
		)
	end

end

function PANEL:Think()

	if self.fieldCtrl and self.fieldCtrl.field.invalid then

		if quotaAverage() < quotaMax() * 0.8 then
			self.invalid = true
			self.fieldCtrl.field.invalid = false
			if self.parent then
				self.parent.invalid = true
			end
		end

		self:SetBadgeBits(self.enemy.badgeBits)

	end

	PANEL.super.Think(self)

end

function PANEL:Paint(w, h)
	if self.enemy and self.enemy.dead then return end
	if LITE then
		render.setRGBA(0, 0, 0, 220)
		render.drawRect(0, 0, w, h)
	else
		render.setRGBA(255, 255, 255, 255)
		sprite.setSheet(1)
		sprite.draw(18, 0, 0, w, h)
	end
	if self.enemy and self.enemy.danger > 0 then
		render.setRGBA(255, 0, 0, 64)
		render.drawRect(2, 4, 60, 120)
	end
end

gui.Register("Enemy", PANEL, "DividedRTControl")
