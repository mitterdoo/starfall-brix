--@name BRIX: Enemy object
--@client

--[[
	This is an object that describes an opponent. It contains:
		A Matrix		(matrix)
		Badge count		(number)
		Unique ID		(number)
		Danger			(bool)
	The following can be performed on the object (which will all update the pinch state accordingly):
		Add piece		(type, rotation, x, y)
		Add garbage		(list of gaps)
		Clear lines		(list of lines)
		Kill			(killer, placement)

]]

local E_ADD = 0
local E_GARBAGE = 1
local E_CLEAR = 2

ENEMY = {}
ENEMY.__index = ENEMY
function ENEMY:AddPiece(piece, rot, x, y)

    for px = 0, piece.size-1 do
        for py = 0, piece.size-1 do
            local i = brix.getShapeIndex( px, py, piece.rotations and rot or 0, piece.size )
            local gx, gy = px + x, py + y -- global coords
            if piece.shape[i] == "x" then
                if 0 <= gx and gx < brix.w and 0 <= gy and gy < brix.trueHeight then
                    if gy < brix.h then lockedVisibly = true end
                    self.matrix:set(gx, gy, piece.type)
                end
            end
        end
    end
	self._invalid = true
	self.danger = self:_highestPoint() >= brix.dangerHeight

end

function ENEMY:AddGarbage(gaps)
	
	for _, gap in ipairs(gaps) do
    	local data = self.matrix.data:sub(1, brix.w * (brix.trueHeight-1))
    	local newLine = string.rep("!", gap - 1) .. " " .. string.rep("!", brix.w - gap)
    	data = newLine .. data
    	self.matrix.data = data
	end
	self._invalid = true
	self.danger = self:_highestPoint() >= brix.dangerHeight

end

function ENEMY:ClearLines(lines)

	if #lines == 0 then return end
	local cleared = 0
	for _, line in pairs(lines) do

		for i = line, brix.trueHeight - 1 do
		
			i = i - cleared
			local fill = (" "):rep(brix.w)
			if i + 1 < brix.trueHeight then
				fill = self.matrix:getrow(i + 1)
			end
			self.matrix:setrow(i, fill)
		
		end
		cleared = cleared + 1

	end

	self._invalid = true
	self.danger = self:_highestPoint() >= brix.dangerHeight

end

function ENEMY:AddBadges(badges)

	self.badgeBits = self.badgeBits + badges
	self._invalid = true

end

function ENEMY:Kill(place, selfKiller)
	self.dead = true
	self.alive = false
	self.place = place
	if selfKiller then
		self.kill = true
	end
	self._invalid = true
end




function ENEMY:_isRowClear(row)
    return #self.matrix:getrow(row):gsub(" ", "") == 0
end

function ENEMY:_highestPoint()

    for row = brix.trueHeight-1, 0, -1 do
        if not self:_isRowClear(row) then
            return row + 1
        end
    end
    return 0

end

if CLIENT then

	local color_ok = Color(0,0,0,128)
	local color_danger = Color(255, 0, 0, 128)
	local color_garbage = Color(255,255,255)

	local border = 8

	local trueW, trueH = 256, 512

	local w, h = trueW - border*2, trueH - border*2
	local x, y = border, border
	local bsize = w / brix.w

	local colorscale = 0.6



	local brixKO = render.createFont("Verdana", 90, 900)
	local brixPlacement = render.createFont("Arial", 160, 0)
	local koBG = material.load("sgm/playercircle")

	local color_dead = Color(110, 140, 255)
	local color_ko = Color(200, 190, 0)

	function brix.drawBadge(x, y, size, percent)

		percent = math.max(0, math.min(1, percent))
		
		local slope = 1/3
		local height = percent * (1 - slope) * size
		
		
		local add = slope * size
		
		local chosenPoints = {}
		
		if percent == 1 then
			chosenPoints  = {
				{
					{x = x, y = y + size},
					{x = x, y = y + size - height},
					{x = x + size/2, y = y + size - height - add},
					{x = x + size/2, y = y + size - add}
				},
				{
					{x = x + size, y = y + size - height},
					{x = x + size, y = y + size},
					{x = x + size/2, y = y + size - add},
					{x = x + size/2, y = y + size - height - add}
				}
			}
			
		else
			local border = size/16
			local angBorder = border + border * slope
			height = percent * (1 - slope) * (size - angBorder)
			-- she looked like she had never seen anything quite so horrible in all her life
			chosenPoints = {
			
				{ -- left
					{x = x, y = y + size}, -- bottomleft
					{x = x, y = y + size - height}, -- topleft
					{x = x + border, y = y + size - height - border*slope*2}, -- topright
					{x = x + border, y = y + size - border*slope*2} -- bottomright
				},
				{ -- top left
					{x = x, y = y + size - angBorder - height + angBorder*slope*percent}, -- topleft
					{x = x + size/2, y = y + size - angBorder - height - add + angBorder*slope*percent}, -- topright
					{x = x + size/2, y = y + size - angBorder - height - add + angBorder + angBorder*slope*percent}, -- bottomright
					{x = x, y = y + size - angBorder - height + angBorder + angBorder*slope*percent} -- bottomleft
				},
				{ -- top right
					{x = x + size/2, y = y + size - angBorder - height - add + angBorder*slope*percent}, -- topleft
					{x = x+size, y = y + size - angBorder - height + angBorder*slope*percent}, -- topright
					{x = x+size, y = y + size - angBorder - height + angBorder + angBorder*slope*percent}, -- bottomright
					{x = x + size/2, y = y + size - angBorder - height - add + angBorder + angBorder*slope*percent} -- bottomleft
				},
				{ -- right
					{x = x+size, y = y + size - height}, -- topright
					{x = x+size, y = y + size}, -- bottomright
					{x = x+size - border, y = y + size - border*slope*2}, -- bottomleft
					{x = x+size - border, y = y + size - height - border*slope*2} -- topleft
				},
				{ -- bottom right
					{x = x+size, y = y + size - angBorder}, -- topright
					{x = x+size, y = y + size}, -- bototmright
					{x = x + size/2, y = y + size - add}, -- bottomleft
					{x = x + size/2, y = y + size - add - angBorder} -- topleft
				},
				{ -- bottom left
					{x = x, y = y + size}, -- bototmleft
					{x = x, y = y + size - angBorder}, -- topleft
					{x = x + size/2, y = y + size - add - angBorder}, -- topright
					{x = x + size/2, y = y + size - add} -- bottomright
				}
			}

		end    
		
		
		render.setRGBA(250, 255, 120, 255)
		render.setMaterial()
		
		for i = 1, #chosenPoints do
			render.drawPoly(chosenPoints[i])
		end

	end

	local badgeSpacing = 8
	local badgeSize = (w - badgeSpacing*5)/4

	function ENEMY:UpdateRT()

		render.selectRenderTarget(self._rt)
		render.clear(Color(0,0,0,0))

		if not self.dead then
			render.setColor(self.danger and color_danger or color_ok)
			render.drawRect(x, y, w, h)

			render.setRGBA(128,128,128,128)
			render.drawRect(0, 0, trueW, border)
			render.drawRect(0, trueH - border, trueW, border)
			render.drawRect(0, border, border, trueH - border*2)
			render.drawRect(trueW - border, border, border, trueH - border*2)

			render.setTexture(brixBlock)

			for gx = 0, brix.w - 1 do
				for gy = 0, brix.h - 1 do
					local cell = self.matrix:get(gx, gy)
					if cell ~= " " then
						local color = cell == "!" and color_garbage or brix.pieces[tonumber(cell)%7].color
						render.setRGBA(color.r * colorscale, color.g * colorscale, color.b * colorscale, 255)

						render.drawTexturedRect(x + gx/brix.w * w, y + h - (gy + 1)/brix.h * h, bsize + 1, bsize + 1)
					end
				end
			end

			local badges, percent = brix.getBadgeCount(self.badgeBits)
			if badges > 0 or percent > 0 then
				for i = 0, math.min(3, badges) do
					local perc = i < badges and 1 or percent
					if perc == 0 then break end
					brix.drawBadge(x + badgeSpacing + i*(badgeSize + badgeSpacing), y + badgeSpacing, badgeSize, perc)
				end
			end
		
		else
			local x, y, w, h = 0, 0, trueW, trueH

			--render.setRGBA(255,0,255,128)
			--render.drawRect(x, y, w, h)
			if self.kill then
				render.setColor(color_ko)
			else
				render.setColor(color_dead)
			end

			render.setMaterial(koBG)
			render.drawTexturedRect(x, y + h/3 - w/2, w, w)

			render.setFont(brixPlacement)
			render.setRGBA(0,0,0,255)
			render.drawSimpleText(x + w/2 + 8, y + 3/4 * h + 8, tostring(self.place), 1, 1)
			render.setFont(brixKO)
			for ox = -1, 1, 0.5 do
				for oy = -1, 1, 0.5 do
					if ox ~= 0 or oy ~= 0 then
						render.drawSimpleText(x + w/2 + ox*4, y + h/3 + oy*4, "K.O.", 1, 1)
					end
				end
			end
			render.setRGBA(255,255,255,255)
			render.setFont(brixPlacement)
			render.drawSimpleText(x + w/2, y + 3/4 * h, tostring(self.place), 1, 1)
			render.setFont(brixKO)
			render.drawSimpleText(x + w/2, y + h/3, "K.O.", 1, 1)
		end

		render.selectRenderTarget()

	end


	function ENEMY:Draw(cx, cy, h)

		if self._invalid then
			self._invalid = nil
			self:UpdateRT()
		end

		render.setRenderTargetTexture(self._rt)
		render.setRGBA(255,255,255,255)
		render.drawTexturedRectUV(cx - h/4, cy - h/2, h/2, h, 0, 0, 0.25, 0.5)

	end

end

function brix.createEnemy(uniqueId)

	local self = {}

	self.matrix = brix.makeMatrix(brix.w, brix.trueHeight)
	self.badgeBits = 0
	self.uniqueId = uniqueID
	self.danger = false
	self.place = -1
	self.dead = false
	self.alive = true

	if CLIENT then
		self.kill = false -- whether the local player killed this player
		self._invalid = true
		self._rt = "brix_enemy_rt" .. tostring(uniqueId)
		render.createRenderTarget(self._rt)
	end

	setmetatable(self, ENEMY)
	return self

end
