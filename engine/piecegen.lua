--@name BRIX: Piece Generation
--@shared

brix.pieceQueueSize = 6
function BRIX:takePieceFromBag()

	if #self.pieceBag == 0 then
		local bag = {}
		for i = 0, 6 do
			table.insert(bag, i)
		end
		for i = 0, 6 do
			local idx = math.ceil(self:rng() * #bag)
			table.insert(self.pieceBag, table.remove(bag, idx))
		end
	end
	local removed = table.remove(self.pieceBag, 1)
	if self.params.monochrome then
		removed = bit.bor(removed, 0x8)
	end

	return removed

end

function BRIX:populatePieceQueue()
	local modified = false
	while #self.pieceQueue < brix.pieceQueueSize do
		table.insert(self.pieceQueue, self:takePieceFromBag())
		modified = true
	end
	if modified then
		self.hook:run("pieceQueueUpdate")
	end
end

function BRIX:takePieceFromQueue()

	self:populatePieceQueue()
	local id, index = table.remove(self.pieceQueue, 1)
	self.hook:run("pieceQueueUpdate")
	return id, index

end

function brix.normalPiece(piece)
	return bit.band(0x7, piece)
end

function brix.getPieceSpawnPos(type)

	local piece = brix.pieces[brix.normalPiece(type)]
	local x = brix.w / 2 - math.ceil(piece.size / 2)
	local y
	if brix.normalPiece(type) == pid.i then
		y = brix.h - 3
	else
		y = brix.h - piece.size
	end
	return x, y + 1

end

function BRIX:newPiece(type)

	if self.currentPiece.type >= 0 then
		error("Attempt to generate new piece when last one has not been cleared!")
	end
	self.currentPiece = {}
	local p = self.currentPiece
	
	p.type = type or self:takePieceFromQueue()
	p.rot = 0

	if self.params.rotateBuffering then
		if self.inputs[brix.inputEvents.ROT_CW] then
			p.rot = 1
			self.hook:run("pieceBufferRotate")
		elseif self.inputs[brix.inputEvents.ROT_CCW] then
			p.rot = 3
			self.hook:run("pieceBufferRotate")
		end
	end


	p.piece = brix.pieces[ brix.normalPiece(p.type) ]

	local delay, are = self.params.autoRepeatSpeed, self.params.are_charge
	if self.inputs[brix.inputEvents.MOVELEFT] then
		--p.x = p.x - 1			this only charges DAS. does not affect spawn
		if not are then
			delay = self.areCancel_Left and self.params.autoRepeatBegin or delay
		end
		self:startTimer("moveleft", delay)
	elseif self.inputs[brix.inputEvents.MOVERIGHT] then
		--p.x = p.x + 1			this only charges DAS. does not affect spawn
		if not are then
			delay = self.areCancel_Right and self.params.autoRepeatBegin or delay
		end
		self:startTimer("moveright", delay)
	end

	if not are then
		self.areCancel_Left = nil
		self.areCancel_Right = nil
	end
	
	p.x, p.y = brix.getPieceSpawnPos(p.type)

	self.hook:run("pieceSpawn", p.piece, p.rot, p.x, p.y)

end
