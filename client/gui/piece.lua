local PANEL = {}

local pieces = brix.pieces
function PANEL:Init()

	self.pieceID = 0
	self.piece = pieces[0]
	self.size = self.piece.size
	self.mono = false
	self.ghost = false
	self.holdLocked = false
	self.rot = 0
	self.brickSize = 48

end

function PANEL:SetIsHoldLocked(lock)
	self.holdLocked = lock
end

function PANEL:SetIsMono(mono)
	self.mono = mono
end

function PANEL:SetIsGhost(ghost)
	self.ghost = ghost
end

local normal_piece = brix.normalPiece
function PANEL:SetPieceID(id)

	self.mono = id > 7
	if id > 7 then
		id = normal_piece(id)
	end

	self.pieceID = id
	self.piece = pieces[id]
	self.size = self.piece.size
end

function PANEL:SetRotation(rot)
	self.rot = rot
end

function PANEL:SetBrickSize(size)
	self.brickSize = size
end

-- Returns a pixel position relative to the bottom-left corner of the matrix
function PANEL:GetPiecePos(x, y)

	local s = self.brickSize

	local px, py = x * s, -(y) * s
	return px, py

end

local sub = string.sub
local getShapeIndex = brix.getShapeIndex
function PANEL:Paint(w, h)

	render.setRGBA(255, 255, 255, 255)
	sprite.setSheet(1)
	local p = self.piece
	local size = p.size

	local mono, ghost, locked, rot, brickSize = self.mono, self.ghost, self.holdLocked, self.rot, self.brickSize
	local spr
	if mono then
		if not ghost then
			spr = 16
		else
			spr = 17
		end
	elseif locked then
		spr = 7
	else
		spr = (ghost and 8 or 0) + self.pieceID
	end

	local shape = p.shape

	for y = 0, size-1 do
		for x = 0, size-1 do
			local i = getShapeIndex(x, y, rot, size)
			if sub(shape, i, i) == "x" then
				sprite.draw(spr, x * brickSize, (y + 1) * -brickSize, brickSize, brickSize)
			end
		end
	end

end


gui.Register("Piece", PANEL, "Control")
