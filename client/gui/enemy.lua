local PANEL = {}

local function fx_Kill(x, y, w, h, frac, glow)

	frac = (1-frac)^2
	render.setRGBA(255, frac*255, 0, frac*255)
	render.drawRectFast(x, y, w, h)

end

local enemyRT = "brix_Enemies"
render.createRenderTarget(enemyRT)

local badgeSize = 14
local badgeSpacing = (60 - 4*badgeSize)/5

function PANEL:Init()

	self.super.Init(self)
	self.RTName = enemyRT
	self:SetDivisionSize(64, 128)
	self:SetSize(64, 128)

	if self.divisionCount < 32 then
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

			local Badge = gui.Create("Sprite", self)
			Badge:SetSize(badgeSize, badgeSize)
			Badge:SetSheet(1)
			Badge:SetSprite(36)
			Badge:SetVisible(false)
			Badge:SetPos(2 + badgeSpacing + (i-1) * (badgeSpacing + badgeSize), 4 + badgeSpacing)
			self.badges[i] = Badge

		end

	end

	self.fieldCtrl.field = enemy.matrix


end

local off_badgeBits = sprite.sheets[1].badgeBits
local spr_fullBadge = off_badgeBits + 15
local spr_ko = sprite.sheets[1].ko
local spr_ko_us = sprite.sheets[1].ko_us
function PANEL:SetBadgeBits(totalBits)

	local badges, bits = br.getBadgeCount(totalBits)
	local spr = self.badges
	for i = 1, 4 do

		if i <= badges then
			spr[i]:SetVisible(true)
			spr[i]:SetSprite(spr_fullBadge)
		elseif i == badges + 1 and bits > 0 then
			spr[i]:SetVisible(true)
			spr[i]:SetSprite(math.floor(off_badgeBits - 1 + bits * 16))
		else
			spr[i]:SetVisible(false)
		end
	end

end

function PANEL:Kill()

	while #self.children > 0 do

		self.children[1]:Remove()

	end
	self.fieldCtrl = nil
	self.badges = nil

	local enemy = self.enemy
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
	placement:SetValue(enemy.placement)
	placement:SetAlign(0)
	placement:SetPos(32, 64 + 8)
	placement:SetSize(16, 24)

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
		self.invalid = true
		self.fieldCtrl.field.invalid = false
		if self.parent then
			self.parent.invalid = true
		end

		self:SetBadgeBits(self.enemy.badgeBits)

	end

	self.super.Think(self)

end

function PANEL:Paint(w, h)
	if self.enemy and self.enemy.dead then return end
	render.setRGBA(255, 255, 255, 255)
	sprite.setSheet(1)
	sprite.draw(18, 0, 0, w, h)
	if self.enemy and self.enemy.danger > 0 then
		render.setRGBA(255, 0, 0, 64)
		render.drawRect(2, 4, 60, 120)
	end
end

gui.Register("Enemy", PANEL, "DividedRTControl")
