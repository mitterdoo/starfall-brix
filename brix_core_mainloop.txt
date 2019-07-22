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

function BRIX:co_main()

	local cevents = brix.inputEvents
	while true do
	
		local attempts = 0
		local lowest = brix.trueHeight
		local instantLock = false
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
		local p = self.currentPiece
		if not self:_fits(p.piece, p.rot, p.x, p.y) then
			print("BLOCK OUT")
			break
		end -- block out
		if not self:fitsDown() then goto locking end
		
		--self:startTimer("drop", self:getFramesPerDrop())
		self:startTimer("drop", 0) -- drops immediately
		
		attempts = 0				-- Number of lock resets that have been made
		lowest = brix.trueHeight	-- The lowest point the current piece has reached.
		instantLock = false			-- Whether the current piece should instantly lock when touching down
		
	::falling::
		while self:fitsDown() do
			
			local event, what = self:pullEvent()

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
			
				local down = event == "inputDown"
				if down then
					if what == cevents.MOVELEFT then
						self:moveLeft()
						self:startTimer("moveleft", self.inputIsBuffered and self.params.autoRepeatSpeed or self.params.autoRepeatBegin)
						self:cancelTimer("moveright")
						--if not self:fitsDown() then break end
						
					elseif what == cevents.MOVERIGHT then
						self:moveRight()
						self:startTimer("moveright", self.inputIsBuffered and self.params.autoRepeatSpeed or self.params.autoRepeatBegin)
						self:cancelTimer("moveleft")
						--if not self:fitsDown() then break end
					
					elseif what == cevents.SOFTDROP then
						self:moveDown()
						self:startTimer("drop", self:getFramesPerDrop())
						
					elseif what == cevents.HARDDROP then
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
			local newLow = self:_lowestPoint(p.piece, p.rot, p.x, p.y)
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
		
			local event, what = self:pullEvent()
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
		local lockedVisibly, tspin = self:lock()
		if not lockedVisibly then
			print("LOCK OUT")
			break
		end
		
		
	::lineClears::
		
		local lines = {}
		for i = 0, brix.trueHeight - 1 do

			if i >= self.solidHeight and #self.matrix:getrow(i):gsub(" ","") == brix.w then
				table.insert(lines, i)
			end
		
		end
		
		self:checkCombo(#lines > 0)
		
		if #lines > 0 then
			for _, line in pairs(lines) do
				
				self.matrix:setrow(line, string.rep(" ", brix.w))
				
			end
			
			local tricks = self:calculateTricks(#lines, tspin)
			local linesSent = self:calculateLinesSent(tricks)
			linesSent = self:clearGarbage(linesSent)
			self.hook:run("lock", tricks, self.currentCombo, linesSent, lines)
			
			self:checkBackToBack(#lines, tspin)

			self:sleep("lineClear", self.params.clearDelay)
			
		
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
			
			if cleared > 0 then
				self.hook:run("matrixFall")
			end
		
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
					print("TOP OUT")
					break
				end
			end
		
		end

		self.hook:run("completion")

		if self.solidGarbage > 0 and not self:dumpSolidGarbage() then
			print("TOP OUT")
			break
		end
		
		self:updateDanger()
		
		local levelUp = self:levelUpCheck()
		if levelUp then
			self.level = self.level + 1
			self.hook:run("levelUp", self.level)
		end
		self:sleep("spawnDelay", self.params.pieceAppearDelay)
		
		
		--detect line clears
		--animate 
		--eliminate phase (collapsing) OR garbage dump
		
		--do break end
		
	end

	self.diedAt = self.frame
	self.hook:run("die", self.lastGarbageSender or -1)

end
