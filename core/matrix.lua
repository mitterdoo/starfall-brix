--@name BRIX: Matrix Operations
--@shared

function brix.makeMatrix(w, h)

	-- First row is bottom row
	local mat = {data = string.rep(" ", w * h)}
	function mat:setrow(row, data)
		if #data ~= w then error("matrix:setrow(): data length " .. #data .. " mismatches with width " .. w) end
		if row < 0 or row >= h then error("matrix:setrow(): row " .. row .. " out of range") end

		local rowBegin = row * w + 1
		local rowEnd = (row + 1) * w
		self.data = self.data:sub(1, rowBegin - 1) .. data .. self.data:sub(rowEnd + 1)
	end
	function mat:getrow(row)
		if row < 0 or row >= h then error("matrix:getrow(): row " .. row .. " out of range") end

		local rowBegin = row * w + 1
		local rowEnd = (row + 1) * w
		return self.data:sub(rowBegin, rowEnd)
	end
	function mat:get(x, y)
		if x < 0 or x >= w or y < 0 or y >= h then return "" end
		local idx = y * w + x + 1
		return self.data[idx]
	end
	function mat:set(x, y, char)
		if x < 0 or x >= w or y < 0 or y >= h then error("matrix:set(): coordinates out of range (" .. x .. ", " .. y .. ")") end
		char = tostring(char)
		if #char > 1 then char = char[1]
		elseif #char == 0 then error("matrix:set(): char is empty") end
		local idx = y * w + x + 1
		self.data = self.data:sub(1, idx - 1) .. char .. self.data:sub(idx + 1)
	end

	return mat

end

brix.onInit(function(self)
	self.matrix = brix.makeMatrix(brix.w, brix.trueHeight)
end)

brix.pieceIDs = {
	i = 0,
	j = 1,
	l = 2,
	o = 3,
	s = 4,
	t = 5,
	z = 6
}
pid = brix.pieceIDs

--[[
	rotations: 
	0->R
	R->0
	R->2
	2->R
	2->L
	L->2
	L->0
	0->L
]]
local rotLookup = {
	[0] = {[1] = 1, [3] = 8},
	[1] = {[0] = 2, [2] = 3},
	[2] = {[1] = 4, [3] = 5},
	[3] = {[2] = 6, [0] = 7}
}
-- y is up, so flip
brix.rotations = {
	i = { { {0,0}, {-2, 0}, {1, 0}, {1, 2}, {-2, -1}},
		  {{0,0}, {2, 0}, {-1, 0}, {2, 1}, {-1, -2}},
		  {{0,0}, {-1, 0}, {2, 0}, {-1, 2}, {2, -1}},
		  {{0,0}, {-2, 0}, {1, 0}, {-2, 1}, {1, -1}},
		  {{0,0}, {2, 0}, {-1, 0}, {2, 1}, {-1, -1}},
		  {{0,0}, {1, 0}, {-2, 0}, {1, 2}, {-2, -1}},
		  {{0,0}, {-2, 0}, {1, 0}, {-2, 1}, {1, -2}},
		  {{0,0}, {2, 0}, {-1, 0}, {-1, 2}, {2, -1}}},
		
	common = {{{0,0}, {-1, 0}, {-1, 1}, {0, -2}, {-1, -2}},
			 {{0,0}, {1, 0}, {1, -1}, {0, 2}, {1, 2}},
			 {{0,0}, {1, 0}, {1, -1}, {0, 2}, {1, 2}},
			 {{0,0}, {-1, 0}, {-1, 1}, {0, -2}, {-1, -2}},
			 {{0,0}, {1, 0}, {1, 1}, {0, -2}, {1, -2}},
			 {{0,0}, {-1, 0}, {-1, -1}, {0, 2}, {-1, 2}},
			 {{0,0}, {-1, 0}, {-1, -1}, {0, 2}, {-1, 2}},
			 {{0,0}, {1, 0}, {1, 1}, {0, -2}, {1, -2}}}
}

brix.pieces = {
	
	[pid.i] = {
		shape = {"    ",
				 "xxxx",
				 "    ",
				 "    "},
		rotations = brix.rotations.i,
		size = 4,
		type = pid.i
	},
		
	[pid.j] = {
		shape = {"x  ",
				 "xxx",
				 "   "},
		rotations = brix.rotations.common,
		size = 3,
		type = pid.j
	},
	
	[pid.l] = {
		shape = {"  x",
				 "xxx",
				 "   "},
		rotations = brix.rotations.common,
		size = 3,
		type = pid.l
	},
	
	[pid.o] = {
		shape = {"xx",
				 "xx"},
		size = 2,
		type = pid.o
	},        
	
	[pid.s] = {
		shape = {" xx",
				 "xx ",
				 "   "},
		rotations = brix.rotations.common,
		size = 3,
		type = pid.s
	},
	
	[pid.t] = {
		shape = {"AxB",
				 "xxx",
				 "C D"},
		rotations = brix.rotations.common,
		size = 3,
		type = pid.t
	},
	
	[pid.z] = {
		shape = {"xx ",
				 " xx",
				 "   "},
		rotations = brix.rotations.common,
		size = 3,
		type = pid.z
	}
	
}

for k, piece in pairs(brix.pieces) do
	local str = ""
	for _, line in pairs(piece.shape) do
		str = str .. line
	end
	piece.shape = str
end

brix.w = 10
brix.h = 20
brix.bufferHeight = 20
brix.trueHeight = brix.h + brix.bufferHeight

brix.dangerHeight = brix.h - 3


---------------------------------------
-- HELPER FUNCTIONS

local function getShapeIndex( x, y, rot, size )
	y = size-y - 1 -- comment if Y is up to down
	if rot % 4 == 0 then
		return y * size + x + 1
	elseif rot % 4 == 1 then
		return size * (size-1) + y - (x * size) + 1
	elseif rot % 4 == 2 then
		return size * size - 1 - size * y - x + 1
	else
		return size-1 - y + x * size + 1
	end
end

brix.getShapeIndex = getShapeIndex

function BRIX:_lowestPoint( piece, rot, x, y )
	local lowest = brix.trueHeight
	for px = 0, piece.size-1 do
		for py = 0, piece.size-1 do
			local i = getShapeIndex( px, py, piece.rotations and rot or 0, piece.size )
			if piece.shape[i] == "x" and y + py < lowest then
				lowest = y + py
			end
		end
	end
	return lowest
end

-- Checks whether the contact points in a T piece are touching
function BRIX:_getTRefPoints(rot, x, y)

	local mat = self.matrix
	local piece = brix.pieces[pid.t]
	local refPoints = {
		a = false,
		b = false,
		c = false,
		d = false
	}
	for px = 0, piece.size-1 do
		for py = 0, piece.size-1 do
			local i = getShapeIndex( px, py, piece.rotations and rot or 0, piece.size )
			local gx, gy = px + x, py + y
			local ref = piece.shape[i]:lower()
			
			if refPoints[ref] ~= nil and (gx < 0 or gy < 0 or gx >= brix.w or gy >= brix.trueHeight or mat:get(gx, gy) ~= " ") then
				refPoints[ref] = true
			
			end
			
		end
	end
	
	return refPoints.a, refPoints.b, refPoints.c, refPoints.d

end

function BRIX:_checkTSpin(rot, x, y)

	local a, b, c, d = self:_getTRefPoints(rot, x, y)
	return a and b and (c ~= d)

end

function BRIX:_checkMiniTSpin(rot, x, y)

	local a, b, c, d = self:_getTRefPoints(rot, x, y)
	--return c and d and (a and (not b) or (not a) and b)
	return c and d and (a ~= b) -- (a ~= b <=> !xor)

end

function BRIX:_fits( piece, rot, x, y)
	local mat = self.matrix
	for px = 0, piece.size-1 do -- piece x coord in shape
		for py = 0, piece.size-1 do -- piece y coord in shape
			local i = getShapeIndex( px, py, piece.rotations and rot or 0, piece.size )
			local gx, gy = px + x, py + y -- global coords
			local shapeCollision = piece.shape[i]
			if shapeCollision == "x" and ((gx < 0 or gy < 0 or gx >= brix.w or gy >= brix.trueHeight) or mat:get(gx, gy) ~= " " ) then
				return false
			end
		end
	end
	return true

end

-- Checks if the piece will fit into a spot after rotating. Returns the piece's new position and whether rotation point 5 was used
function BRIX:_fitsRotation( piece, oldrot, newrot, x, y )

	-- return the new x and y
	if not piece.rotations then
		if self:_fits(piece, 0, x, y) then
			return x, y, false
		else
			return false
		end
	end
	
	local rotIdx = rotLookup[oldrot][newrot]
	for rotPoint, attempt in pairs( piece.rotations[rotIdx] ) do
		local ox, oy = attempt[1], attempt[2]
		if self:_fits(piece, newrot, x + ox, y + oy) then
			return x + ox, y + oy, rotPoint == 5
		end
	end
	return false

end

-- Checks if the piece will fit after being translated in space. Returns the piece's new position, or false if it doesn't fit.
function BRIX:_fitsTranslation( piece, rot, x, y, ox, oy )

	if oy == 0 then -- X must be 1
		if x ~= 1 and x ~= -1 then error("Can only do horizontal translation of 1 column", 2) end
		return self:_fits(piece, rot, x + ox, y)
	elseif ox == 0 then

		assert(oy <= 0, "Vertical translation can only go down", 2)
		local shortest = -math.huge
		for px = 0, piece.size-1 do 
			--for py = piece.size-1, 0, -1 do
			for py = 0, piece.size-1 do
				local idx = getShapeIndex(px, py, piece.rotations and rot or 0, piece.size)
				local shapeCollision = piece.shape[idx]
				if shapeCollision == "x" then
					for i = 0, oy, -1 do
						local cell = self.matrix:get(x + px, y + py + i)
						--print(x+px, y+py+i, "\"" .. tostring(cell) .. "\"", i)
						if cell ~= " " then
							if i == 0 then
								--print("collide at original")
								return x, y
							elseif i + 1 > shortest then
								shortest = i + 1
								--print("collide at dist", shortest)
								break
							end
						end
					end
					break
				end
			end
		end
		if shortest == -math.huge then
			return false
		end
		return x, y + shortest


		--[[
		local thisY = y
		while thisY >= oy do
			local fitsHere = self:_fits(piece, rot, x, thisY)
			local fitsBelow = self:_fits(piece, rot, x, thisY - 1)
			if fitsHere and not fitsBelow then
				return x, thisY
			elseif not fitsHere and not fitsBelow then
				return false
			end
			thisY = thisY - 1
		end
		]]
	end
	error("fitsTranslation can only be given either horizontal, or vertical values", 2)

end

-- Locks a piece into the matrix
function BRIX:_lock( piece, rot, x, y, mono )
	
	local idx = piece.type
	local char = mono and "[" or idx

	local lockedVisibly = false
	for px = 0, piece.size-1 do
		for py = 0, piece.size-1 do
			local i = getShapeIndex( px, py, piece.rotations and rot or 0, piece.size )
			local gx, gy = px + x, py + y -- global coords
			if piece.shape[i] == "x" then
				if 0 <= gx and gx < brix.w and 0 <= gy and gy < brix.trueHeight then
					if gy < brix.h then lockedVisibly = true end
					self.matrix:set(gx, gy, char)
				else
					return false
				end
			end
		end
	end
	if not lockedVisibly then return false end
	return true

end

function BRIX:_isRowClear(row)
	return #self.matrix:getrow(row):gsub(" ", "") == 0
end

function BRIX:_isClear()

	return #self.matrix.data:gsub(" ","") == 0

end

function BRIX:_highestPoint()

	for row = brix.trueHeight-1, 0, -1 do
		if not self:_isRowClear(row) then
			return row + 1
		end
	end
	return 0

end

function BRIX:updateDanger()
	
	local g = self:getGarbageCount()
	local inDanger = self:_highestPoint() + g >= brix.dangerHeight
	if inDanger ~= self.danger then
		self.hook:run("pinch", inDanger)
	end
	self.danger = inDanger
	return self.danger

end

