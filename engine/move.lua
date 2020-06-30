--@name BRIX: Movement
--@shared

brix.onInit(function(self)

	self.held = -1 -- d
	self.heldThisPhase = false -- d
	self.lockResetAttempts = 0 -- d
	self.pieceBag = {} -- d
	self.pieceQueue = {} -- d
	self.currentPiece = {
		type = -1,
		rot = 0,
		x = 0, y = 0
	} -- d

end)

function BRIX:fitsDown()
	
	local p = self.currentPiece
	local fit = self:_fits(p.piece, p.rot, p.x, p.y - 1)
	return fit

end

function BRIX:moveLeft()

	local p = self.currentPiece
	if self:_fits(p.piece, p.rot, p.x - 1, p.y) then
		p.x = p.x - 1
		self.hook:run("pieceTranslate")
		return true
	end
	return false
	
end

function BRIX:moveRight()

	local p = self.currentPiece
	if self:_fits(p.piece, p.rot, p.x + 1, p.y) then
		p.x = p.x + 1
		self.hook:run("pieceTranslate")
		return true
	end
	return false

end
-- Returns if it was successful
function BRIX:moveDown()

	local p = self.currentPiece
	local fitsDown = self:fitsDown()
	if fitsDown then
		p.y = p.y - 1
		self.hook:run("pieceFall")
		if self.inputs[brix.inputEvents.SOFTDROP] then
			self.hook:run("pieceSoftDrop")
		end
		return true
	end
	return false    

end

-- Returns x, y of where the current piece will fall
function BRIX:getFallLocation()
	local p = self.currentPiece
	if not p then return 0, 0 end

	local x, y = self:_fitsTranslation(p.piece, p.rot, p.x, p.y, 0, -brix.trueHeight)
	if not x then return 0, 0 end

	return x, y
end

-- Returns 2 if tspin, 1 if mini tspin, or false if no tspin at all
function BRIX:checkTSpin(fifthRot)

	local p = self.currentPiece
	if brix.normalPiece(p.type) ~= pid.t then return false end
	if fifthRot or p.foreverSpin then
		p.foreverSpin = true -- Any further rotations are considered a tspin
		p.spin = 2 -- flag that will actually be checked when piece locks down
		return 2
	end
	if self:_checkTSpin(p.rot, p.x, p.y) then
		p.spin = 2
		return 1
	end
	if self:_checkMiniTSpin(p.rot, p.x, p.y) then
		p.spin = 1
		return 1
	end
	return false

end

function BRIX:rotateClockwise()

	local p = self.currentPiece
	local old = p.rot
	local new = (p.rot + 1) % 4
	local px, py, fifth = self:_fitsRotation(p.piece, old, new, p.x, p.y)
	if px then
		p.x = px
		p.y = py
		p.rot = new
		self:checkTSpin(fifth)
		self.hook:run("pieceRotate")
		return true
	end
	
	return false

end

function BRIX:rotateAntiClockwise()

	local p = self.currentPiece
	local old = p.rot
	local new = (p.rot - 1) % 4
	local px, py, fifth = self:_fitsRotation(p.piece, old, new, p.x, p.y)
	if px then
		p.x = px
		p.y = py
		p.rot = new
		self:checkTSpin(fifth)
		self.hook:run("pieceRotate")
		return true
	end
	
	return false

end

function BRIX:hardDrop()

	local p = self.currentPiece
	local px, py = self:_fitsTranslation(p.piece, p.rot, p.x, p.y, 0, -brix.trueHeight)
	p.x = px or p.x
	p.y = py or p.y
	self.hook:run("pieceHardDrop", p)
	--self:lock()

end

function BRIX:lock()

	local p = self.currentPiece
	local mono = bit.band(0x8, p.type) > 0
	local p_obj, p_rot, p_x, p_y = p.piece, p.rot, p.x, p.y
	local visible = self.matrix:lock(p.piece, p.rot, p.x, p.y, mono)
	
	local spin = p.spin
	
	p.piece = nil
	p.type = -1

	self.lastPieceLocked = {piece = p_obj, rot = p_rot, x = p_x, y = p_y}
	self.hook:run("prelock", p_obj, p_rot, p_x, p_y, mono)
	return visible, spin or false
	
end

function BRIX:hold(buffered)

	if self.heldThisPhase then return false end

	local current = self.held

	local pieceToHold = self.currentPiece.type
	if buffered then
		pieceToHold = self:takePieceFromQueue()
	end

	self.held = pieceToHold
	
	self.currentPiece.type = -1
	self.currentPiece.piece = nil
	if current == -1 then current = nil end
	self.heldThisPhase = true
	self:newPiece(current)
	
	if not buffered then
		self.hook:run("pieceHold")
	else
		self.hook:run("pieceBufferHold")
	end
	return true

end

function BRIX:getFramesPerDrop()

	local soft = self.inputs[brix.inputEvents.SOFTDROP]
	return self.params.gravityFunc(self, soft)

end
