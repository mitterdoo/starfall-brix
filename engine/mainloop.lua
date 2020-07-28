--@name BRIX: Main Coroutine
--@shared

brix.onInit(function(self)
	self.level = 1
end)


function BRIX:checkBackToBack(lines, tspin, noupdate)

	if tspin or lines == 4 then
		if not noupdate then self.backToBack = true end
		--self.backToBack = true
		return true
	else
		if not noupdate then self.backToBack = false end
		--self.backToBack = false
		return false
	end

end


function BRIX:checkCombo(cleared)

	if not cleared then self.currentCombo = nil return end
	if not self.currentCombo then
		self.currentCombo = 0
	else
		self.currentCombo = self.currentCombo + 1
	end

end

function BRIX:checkAttempts(attempts, lowest, rotating)

	local p = self.currentPiece
	local newLow = self:_lowestPoint(p.piece, p.rot, p.x, p.y)
	if newLow < lowest then
		lowest = newLow
		attempts = 0
		self:startTimer("lock", self.params.lockDelay)
	elseif attempts < self.params.lockResets then
		attempts = attempts + 1
		self:startTimer("lock", self.params.lockDelay)
	elseif p.spin and not rotating then
		p.spin = false
	end
	
	return attempts, lowest

end

function BRIX:levelUpCheck()
	return false
end

-- Overridable function that runs within coroutine. Allows for pregame setup (ready, 3, 2, 1, go)
function BRIX:onGameStart()

end

function BRIX:co_main()

	self:populatePieceQueue()
	self.hook:run("init")
	self:onGameStart()
	self.hook:run("start")

	local cevents = brix.inputEvents
	while true do
	
		local attempts = 0
		local lowest = brix.trueHeight
		local instantLock = false
		local dropFrames, p, px, py, event, what, down, newLow, lockedVisibly, tspin, forceDropped
	::startOver::
		
		--generation
			--random bag
			--spawn piece in position

		self.heldThisPhase = false
		if self.params.holdBuffering and self.inputs[cevents.HOLD] then
			self:hold(true)
		else
			self:newPiece()
		end
		
	::beginTimer::
		p = self.currentPiece
		if not self:_fits(p.piece, p.rot, p.x, p.y) then
			break
		end -- block out
		if not self:fitsDown() then goto locking end
		
		--self:startTimer("drop", self:getFramesPerDrop())
		dropFrames = self:getFramesPerDrop()
		
		attempts = 0				-- Number of lock resets that have been made
		lowest = brix.trueHeight	-- The lowest point the current piece has reached.
		instantLock = false			-- Whether the current piece should instantly lock when touching down
		
		if dropFrames <= 1 / 20 then -- 20G, drop to bottom immediately
			px, py = self:getFallLocation()
			forceDropped = py ~= p.y
			p.x = px
			p.y = py
			if forceDropped then
				self.hook:run("pieceFall")
			end
			goto locking
		else
			self:startTimer("drop", 0) -- drops immediately
		end
		
	::falling::
		while self:fitsDown() do
			
			event, what = self:pullEvent()

			if event == "timer" and what == "drop" then
				self:moveDown()
				if not self:fitsDown() then -- touched ground
					self.hook:run("pieceLand")
					break
				end
				self:startTimer("drop", self:getFramesPerDrop())
				
			elseif event == "timer" and what == "lock" then
				instantLock = true
				
			elseif event == "timer" and what == "moveleft" then
				self:moveLeft()
				self:startTimer("moveleft", self.params.autoRepeatSpeed)
				--if not self:fitsDown() then break end
				
			elseif event == "timer" and what == "moveright" then
				self:moveRight()
				self:startTimer("moveright", self.params.autoRepeatSpeed)
				--if not self:fitsDown() then break end
				
			elseif event == "inputDown" or event == "inputUp" then
			
				down = event == "inputDown"
				if down then
					if what == cevents.MOVELEFT then
						self:moveLeft()
						self:startTimer("moveleft", self.params.autoRepeatBegin)
						self:cancelTimer("moveright")
						--if not self:fitsDown() then break end
						
					elseif what == cevents.MOVERIGHT then
						self:moveRight()
						self:startTimer("moveright", self.params.autoRepeatBegin)
						self:cancelTimer("moveleft")
						--if not self:fitsDown() then break end
					
					elseif what == cevents.SOFTDROP then
						self:moveDown()
						self:startTimer("drop", self:getFramesPerDrop())
						
					elseif what == cevents.HARDDROP then
						self:cancelTimer("moveleft")
						self:cancelTimer("moveright")
						self:hardDrop()
						self:cancelTimer("drop")
						goto lock
						
					elseif what == cevents.HOLD and self:hold() then
						goto beginTimer
					
					elseif what == cevents.ROT_CW then
						self:rotateClockwise()
						
					elseif what == cevents.ROT_CCW then
						self:rotateAntiClockwise()
					   
					-- handle targeting events outside coroutine 
					end
						
				else -- button released
				
					if what == cevents.MOVELEFT then
						self:cancelTimer("moveleft")
					
					elseif what == cevents.MOVERIGHT then
						self:cancelTimer("moveright")
					
					elseif what == cevents.SOFTDROP then
						-- todo: start timer in reference to the last frame the piece fell?
						self:startTimer("drop", self:getFramesPerDrop())
					
					end
				
				end
				
			end
			
			--local p = self.currentPiece defined earlier near top of loop
			newLow = self:_lowestPoint(p.piece, p.rot, p.x, p.y)
			if newLow < lowest then
				lowest = newLow
				attempts = 0
				instantLock = false -- new addition--could this break?
			end
				
		end
		
	self.hook:run("pieceLockNag")
	::locking::
		-- We have made contact with a surface
		
		if attempts < self.params.lockResets then
			self:startTimer("lock", self.params.lockDelay)
		elseif instantLock then
			goto lock
		end

		--lock
		while true do
		
			event, what = self:pullEvent()
			if event == "timer" then
			
				if what == "lock" then 
					--if not self:fitsDown() then
						break
					--else
					--    print("would have locked")
					--end
				elseif what == "drop" and self:fitsDown() then
					self:startTimer("drop", 0)
					goto falling -- this will drop the piece and reset the counter
					
				elseif what == "moveleft" then
					self:startTimer("moveleft", self.params.autoRepeatSpeed)
					if self:moveLeft() then
						attempts, lowest = self:checkAttempts(attempts, lowest)
						if self:fitsDown() then
							self:startTimer("drop", self:getFramesPerDrop())
							goto falling
						end
					end
					
				elseif what == "moveright" then
					self:startTimer("moveright", self.params.autoRepeatSpeed)
					if self:moveRight() then
						attempts, lowest = self:checkAttempts(attempts, lowest)
						if self:fitsDown() then
							self:startTimer("drop", self:getFramesPerDrop())
							goto falling
						end
					end
				end
			
			elseif event == "inputDown" then
				
				if what == cevents.MOVELEFT then
					self:startTimer("moveleft", self.params.autoRepeatBegin)
					self:cancelTimer("moveright")
					if self:moveLeft() then
						attempts, lowest = self:checkAttempts(attempts, lowest)
						if self:fitsDown() then
							self:startTimer("drop", self:getFramesPerDrop())
							goto falling
						else
							self.hook:run("pieceLockNag")
						end
					end
				
				elseif what == cevents.MOVERIGHT then
					self:startTimer("moveright", self.params.autoRepeatBegin)
					self:cancelTimer("moveleft")
					if self:moveRight() then
						attempts, lowest = self:checkAttempts(attempts, lowest)
						if self:fitsDown() then
							self:startTimer("drop", self:getFramesPerDrop())
							goto falling
						else
							self.hook:run("pieceLockNag")
						end
					end
				
				elseif what == cevents.HARDDROP then
					self:cancelTimer("moveleft")
					self:cancelTimer("moveright")
					self.hook:run("pieceHardDrop", self.currentPiece)
					break
					
				elseif what == cevents.HOLD and self:hold() then
					goto beginTimer
					
				elseif what == cevents.ROT_CW and self:rotateClockwise() then
					attempts, lowest = self:checkAttempts(attempts, lowest, true)
					if self:fitsDown() then
						self:startTimer("drop", self:getFramesPerDrop())
						goto falling
					else
						self.hook:run("pieceLockNag")
					end
					
				elseif what == cevents.ROT_CCW and self:rotateAntiClockwise() then
					attempts, lowest = self:checkAttempts(attempts, lowest, true)
					if self:fitsDown() then
						self:startTimer("drop", self:getFramesPerDrop())
						goto falling
					else
						self.hook:run("pieceLockNag")
					end
					
				end
				
			elseif event == "inputUp" then
			
				if what == cevents.MOVELEFT then
					self:cancelTimer("moveleft")
				elseif what == cevents.MOVERIGHT then
					self:cancelTimer("moveright")
				end 
			
			end
		
		end
		
	::lock::
		lockedVisibly, tspin = self:lock()
		if not lockedVisibly then
			break
		end
		
		
	::lineClears::
		
		local lines = self.matrix:check()
		
		self:checkCombo(#lines > 0)
		
		if #lines > 0 then
			self.matrix:clear(lines, true) -- true to skip collapsing
			
			local tricks = self:calculateTricks(#lines, tspin)
			local linesSent = self:calculateLinesSent(tricks)
			if linesSent > 0 then
				tricks = flagSet(tricks, brix.tricks.SENT)
			end
			
			linesSent = self:clearGarbage(linesSent)
			self.hook:run("lock", tricks, self.currentCombo, linesSent, lines)
			if linesSent > 0 then

				self.hook:run("preGarbageSend", linesSent)

				self.hook:run("garbageSend", linesSent)
			end
			
			self:checkBackToBack(#lines, tspin)

			self:sleep("lineClear", self.params.clearDelay)
			
			self.matrix:collapse(lines)
			self.hook:run("matrixFall")
		
		else
		
			local tricks = 0
			if tspin == 2 then
				tricks = flagSet(tricks, brix.tricks.TSPIN)
			elseif tspin == 1 then
				tricks = flagSet(tricks, brix.tricks.MINI_TSPIN)
			end
			self.hook:run("lock", tricks, 0, 0, {})
		
			if self:garbageDumpPending() then
				self:sleep("dumpDelay", self.params.garbageDumpDelay)
				if not self:dumpCurrentGarbage() then
					break
				end
			end
		
		end

		self.hook:run("completion")

		if self.solidGarbage > 0 and not self:dumpSolidGarbage() then
			break
		end
		
		self:updateDanger()
		
		local levelUp = self:levelUpCheck()
		if levelUp then
			self.level = self.level + 1
			self.hook:run("levelUp", self.level)
		end

		if self.params.are_charge then
			self:sleep("spawnDelay", self.params.are)
		else
			-- Without ARE charging, it's a bit more complicated to tell whether to DAS the next piece

			self:startTimer("spawnDelay", self.params.are)
			while true do

				event, what = self:pullEvent()
				if event == "timer" and what == "spawnDelay" then
					break
				elseif event == "inputDown" then
					if what == cevents.MOVELEFT then
						self.areCancel_Left = true
					elseif what == cevents.MOVERIGHT then
						self.areCancel_Right = true
					end
				end

			end
		
		end
		
		
		--detect line clears
		--animate 
		--eliminate phase (collapsing) OR garbage dump
		
		--do break end
		
	end

	self:killGame()

end

function BRIX:killGame()

	self.diedAt = self.frame
	self.dead = true
	self.currentPiece.piece = nil
	self.currentPiece.type = -1
	self.kickReason = "died at frame " .. self.diedAt
	self.hook:run("die", self.lastGarbageSender)
	self.hook:run("gameover", "die")

end
