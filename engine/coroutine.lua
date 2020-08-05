--@name BRIX: Coroutine Elements
--@shared

brix.onInit(function(self)

	self.inputs = {}
	self.timers = {}
	self.timerCallbacks = {}
	self.started = false
	
end)

function BRIX:sleep(uniqueTimer, delay)

	self:startTimer(uniqueTimer, delay)
	
	while true do
	
		local event, what = self:pullEvent()
		if event == "timer" and what == uniqueTimer then
			break
		end
	end

end

function BRIX:start()

	local func = self.co_main
	
	local function wrapper()
	
		local ok, err = xpcall(func, function(err, stack)
			if type(err) ~= "string" then return err end
			return tostring(err) .. "\n" .. tostring(stack)
		end, self)
		if not ok then
			if type(err) == "table" then
				for k, v in pairs(err) do
					print("error\t" .. tostring(k) .. ":\t" .. tostring(v))
				end
				error(tostring(err))
			else
				error(err)
			end
		end
		
	end

	self.mainCoroutine = coroutine.create(wrapper)
	self.timers["begin"] = 0
	self.started = true
	self:update(0)

end


local function timerSort(a,b)
	return a.finish < b.finish
end


-- returns whether game is alive
function BRIX:update(frame)

	if not self.started then
		error("Must call BRIX:start() before updating!")
	end
	
	frame = math.ceil(frame)
	while true do
	
		local timers = {}
		for timerName, timerFinish in pairs( self.timers ) do
			table.insert(timers, {name = timerName, finish = timerFinish})
		end

		if #timers == 0 then
			return true
		end

		
		if #timers == 0 then
			--print("no timers")
			self.dead = true
			self.diedAt = frame
			return false
		end
		
		table.sort(timers, timerSort)
		local thisTimer = timers[1]
		if thisTimer.finish > frame then break end -- not ready yet
		self.timers[thisTimer.name] = nil
		
		if not self:callEvent(thisTimer.finish, "timer", thisTimer.name) then
			--print("coroutine finished")
			return false
		end
		
		
	end
	
	return true

end

function BRIX:onUpdate(frame)

	self.frame = frame

end

function BRIX:callEvent(frame, name, ...)

	if coroutine.status(self.mainCoroutine) == "dead" then self.dead = true return false end

	if frame < self.frame then
		error("CONTRADICTION (" .. tostring(frame) .. ", " .. tostring(name) .. " [" .. tostring(self.name) .. "])")
	end

	self:onUpdate(frame)
	self.lastEvent = {frame, name, ...}
	coroutine.resume(self.mainCoroutine, name, ...)
	if coroutine.status(self.mainCoroutine) == "dead" then self.dead = true return false end
	return true

end

function BRIX:pullEvent()

	while true do
		local ret = {coroutine.yield()}
		if ret[1] == "timer" and self.timerCallbacks[ret[2]] then
			local args = self.timerCallbacks[ret[2]]
			local func = table.remove(args, 1)
			func(self, unpack(args))
			self.timerCallbacks[ret[2]] = nil
		else
			return unpack(ret)
		end
	end
			

end

function BRIX:startTimer(name, duration, callback, ...)

	self.timers[name] = self.frame + math.max(0, duration)
	if callback then
		self.timerCallbacks[name] = {callback, ...}
	end

end

function BRIX:cancelTimer(name)

	self.timers[name] = nil
	if self.timerCallbacks[name] then
		self.timerCallbacks[name] = nil
	end
	
end

brix.inputEvents = {
	MOVELEFT = 0,
	MOVERIGHT = 1,
	SOFTDROP = 2,
	HARDDROP = 3,
	HOLD = 4,
	ROT_CW = 5,
	ROT_CCW = 6
}

function BRIX:userInput(when, inp, down)

	if not self.started or self.dead then return end
	when = math.ceil(when)
	
	if down == nil then down = true end

	self.hook:run("preInput", when, inp, down)
	
	
	self:update(when)
	local event = down and "inputDown" or "inputUp"
	self.inputs[inp] = down
	self:callEvent(when, event, inp)
	
	self.hook:run("postInput", when, down, inp)

end
