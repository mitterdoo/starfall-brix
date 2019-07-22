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

function BRIX:takePieceFromQueue()

	while #self.pieceQueue < brix.pieceQueueSize do
		table.insert(self.pieceQueue, self:takePieceFromBag())
	end
	return table.remove(self.pieceQueue, 1)

end

function brix.normalPiece(piece)
	return bit.band(0x7, piece)
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
	p.x = brix.w / 2 - math.ceil(p.piece.size / 2)
	if self.inputs[brix.inputEvents.MOVELEFT] then
		--p.x = p.x - 1			this only charges DAS. does not affect spawn
		self:startTimer("moveleft", self.params.autoRepeatSpeed)
	elseif self.inputs[brix.inputEvents.MOVERIGHT] then
		--p.x = p.x + 1			this only charges DAS. does not affect spawn
		self:startTimer("moveright", self.params.autoRepeatSpeed)
	end
	
	
	if brix.normalPiece(p.type) == pid.i then
		p.y = brix.h - 3
	else
		p.y = brix.h - p.piece.size
	end
	p.y = p.y + 1

	self.hook:run("pieceSpawn", p.piece, p.rot, p.x, p.y)

end
