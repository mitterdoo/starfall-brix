--[[
	BRIX: Engine
	This is the base BRIX game object which includes:
		Piece RNG
		Piece Stacking
		Piece Holding
		Next 6 Pieces
		T-Spin Recognition
		Combos
		Back to back
		Line clearing
	
	To create a game object, call brix.createGame(rngSeed[, params])
		rngSeed is the seed for the PRNG. Must be constant if creating multiple games for a multiplayer environment
		params is an optional table for parameters of the game. See brix.params
	
	A game MUST be started by BRIX:start(). For all hooks to work, create your hooks prior to calling this function.

	There are events that may be hooked into, to create an implementation of the game, such as a singleplayer mode, splitscreen multiplayer mode, or battle royale.
	Those events are listed further below, under "hooks"

	There are overrideable functions:
		(name)											(description)
		BRIX:calculateLinesSent(tricks)					Called when the game needs to calculate how many lines of garbage to send outside of the game.
														tricks is a bitflag. See brix.tricks in brix/engine/damage.lua
		BRIX:levelUpCheck()								The game calls this when it wants to know if it should level up. Return true if it should.

	These are the public methods that should be used to change the game
		(name)											(description)
		BRIX:queueGarbage(lines, sender)				Adds a garbage cluster to the queue. Lines is number of lines, and sender is a unique number
															of a player who sent it. The same number will be passed to the "die" hook, if the player died to that
															player's garbage.
		BRIX:queueGarbageDelayed(lines, sender, delay)	Adds garbage cluster as above, but waits the specified number of frames first.
		BRIX:queueSolidGarbage(lines)					Adds a SOLID garbage cluster to a hidden queue. It cannot be countered. After the lock phase, it will be dumped.
		BRIX:userInput(frame, input, pressed)			Pipes user input into the game.
															frame:		The frame at which this input was pressed. This will be rounded UP.
															input:		The enum for this specific input. See brix.inputEvents in brix/engine/coroutine.lua
															pressed:	Bool for whether this input is down, or up.
														This function MUST be called in chronological order of inputs. If this is called with a frame number
															less than the last frame calculated, a "CONTRADICTION" error will be thrown.
		BRIX:update(frame)							Simulates the game up until the specified frame. The same contradiction rule from above applies.
														This function is called automatically when calling BRIX:userInput()
														Returns true if the game is still alive. Returns false if the game has ended.
														Ideally, this should be called every time the game is about to be rendered.

	These are public members that are recommended for use in implementations, which are read-only:
		(name)											(description)
		BRIX.diedAt										Frame at which the game ended. nil if game isn't over
		BRIX.matrix										Constant reference to the underlying matrix object that describes what is on the playfield.
			matrix:getrow(row)							Gets the contents of the given row as a string. Row 0 is the very bottom.
			matrix.data									The entire contents of the matrix as a string. Begins with row 0 contents, then row 1, etc.
								A cell in the matrix can be as follows:
									" "		Empty space
									"!"		Garbage
									"0-6"	Locked piece (see brix.pieceIDs)
									"["		Monochromatic piece
									"="		Solid garbage (cannot be cleared)
		BRIX.pieceQueue									Constant reference to an ordered table that contains the next pieces (see brix.pieceIDs)
		BRIX.currentPiece								Dynamic reference to a piece table that describes the current piece in play.
			type											Type enum for the piece. See brix.pieceIDs
			rot												The rotation of the piece. 0 is default rotation, 1 is rotated clockwise, etc.
			piece											Constant reference to piece object that describes this type of piece. See brix.pieces
			x, y											Coordinates of this piece. This denotes the bottom-left corner of the piece's bounding box.
		BRIX.currentCombo								The length of the current line clear combo





]]

--@shared
--@include brix/engine/matrix.lua
--@include brix/engine/move.lua
--@include brix/engine/damage.lua
--@include brix/engine/piecegen.lua
--@include brix/engine/mainloop.lua
--@include brix/engine/coroutine.lua

inStarfall = ents ~= nil

if not bit and bit32 then -- outside gmod
	bit = bit32
end

brix = {}
BRIX = {} -- metatable
BRIX.__index = BRIX

BRIX.hookNames = { -- These are legal hooks in the game
	"prelock",              -- When the current piece locks down. This is for the SFX, and for any update-only rendering
		-- pieceObj
		-- number rot
		-- number x
		-- number y
	"lock",            		-- After the current piece has been locked into the matrix.
		-- brix.tricks
		-- number combo
		-- number linesSent
		-- table linesCleared
	"matrixFall",           -- When the matrix collapses from gravity.
	"garbageDump",          -- When a line of garbage has been dumped
		-- bool solid
		-- int gap			(only when non-solid)
	"garbageDumpFull",		-- Called on the first frame of a garbage cluster being dumped
		-- bool solid
		-- table gaps		(only when non-solid)
		-- [int count]		(only when solid)
	"garbageCancelled",     -- When lines of garbage have been cancelled. It is up to the listener to decide which line is in which cluster
	"garbageNag",           -- When a cluster of garbage is nagging the player.
		-- bool second		whether it's the second nag state
	"garbageActivate",      -- When the timer of a cluster of garbage has been activated
	"garbageQueue",         -- When garbage appears in the queue.
		-- number lines
		-- number senderUniqueID
		-- number frame
	"garbageReceive",       -- When the game has received a command to queue garbage (the beginning of the garbage "fly" animation)
	"garbageSend",			-- When the game has lines (leftover from clearing garbage queue) to send out
		-- number lines
	"pinch",                -- When the matrix enters/exits "the red".
		-- bool inPinch
	
	"pieceBufferRotate",	-- When the spawned piece has been pre-rotated
	"pieceBufferHold",		-- When the spawned piece was pre-held
	"pieceSpawn",			-- When a piece has spawned. Passes piece object, rotation, x, and y
		-- pieceObj
		-- number rot
		-- number x
		-- number y
	"pieceRotate",          -- When the piece has been rotated
	"pieceHold",            -- When the piece has been held
	"pieceTranslate",       -- When the piece has been translated laterally
	"pieceFall",			-- When the piece has fallen one line
	"pieceSoftDrop",        -- When the piece falls one line during soft drop
	"pieceHardDrop",        -- When the piece has been hard dropped.
		-- pieceState (game.currentPiece)
	"pieceLand",            -- When the piece touches down on the ground
	"pieceLockNag",			-- When the piece has begun lockdown timer, and has touched the ground, or rotated
	"die",                  -- When local player dies.
		-- number killerUniqueID (-1 when suicide)

	"completion",			-- Completion phase entered. Called before level up. Add instant solid garbage here
	"levelUp",				-- When the game has leveled up
		-- number newLevel

	"preInput",				-- when (frame), pressed (bool), event (enum)
	"postInput"
}

local function gravity(self, soft)

	local mult = soft and 1 / 20 or 1
	return mult * (0.8 - ((self.level - 1) * 0.007)) ^ (self.level - 1) * brix.frequency

end

brix.params = {
	autoRepeatBegin = 12,	-- Number of frames the left/right button must be held before auto-repeat begins
	autoRepeatSpeed = 2,	-- Number of frames spent in auto-repeat movements
	garbageLineDelay = 4,	-- Number of frames between each line of garbage being dumped
	garbageDumpDelay = 28,	-- Number of frames between lockdown (w/o clears) and garbage dumping
	garbageNagDelay = 150,	-- Number of frames between garbage stages
	maxGarbageIn = 12,		-- Ceiling for receiving garbage
	maxGarbageOut = 20,		-- Ceiling for sending garbage
	lockResets = 15,		-- Number of lock resets permitted before the active piece forcefully locks down
	lockDelay = 30,			-- Number of frames on the lock timer. After it has elapsed, the piece will lock down
	clearDelay = 40,		-- Number of frames between lines disappearing, and the matrix collapsing down on those lines
	pieceAppearDelay = 7,	-- Number of frames between matrix collapse (or lockdown, if no lines cleared), and the next piece appearing.
	gravityFunc = gravity,	-- Reference to function that returns the number of frames it takes for a piece to fall by one line. The function is given the BRIX object, and whether it is soft dropping
	monochrome = false,		-- Whether future pieces should be monochromatic
	rotateBuffering = true, -- Whether to allow input buffering for rotations
	holdBuffering = true	-- Whether to allow input buffering for hold actions
}



brix.frequency = 60

-- INIT callbacks
brix.initializers = {}
function brix.onInit(callback)

	table.insert(brix.initializers, callback)

end

function flagGet(a, b)
	if type(a) ~= "number" then error("argument #1 must be number", 2) end
	if type(b) ~= "number" then error("argument #2 must be number", 2) end
	return bit.band(a, b) > 0
end
flagSet = bit.bor


function BRIX:rng(noupdate)
	if not noupdate then
		self.rseed = bit.bxor( self.rseed, bit.lshift(self.rseed, 13) )
		self.rseed = bit.bxor( self.rseed, bit.rshift(self.rseed, 17) )
		self.rseed = bit.bxor( self.rseed, bit.lshift(self.rseed, 5)  )
	end
	return (self.rseed + 2^31) / (2^32-1)

end

local pathPrefix = ""
if isStarfall then
	pathPrefix = "brix/engine/"
end
require(pathPrefix .. "matrix.lua")
require(pathPrefix .. "move.lua")
require(pathPrefix .. "damage.lua")
require(pathPrefix .. "piecegen.lua")
require(pathPrefix .. "mainloop.lua")
require(pathPrefix .. "coroutine.lua")

--------------------------------------
-- GAME


local function initProfiler(self)
	self.profiler = {}
	local bad = {
		pullEvent = 1,
		sleep = 1,
		userInput = 1,
		callEvent = 1,
		update = 1,
		co_main = 1,
	}
	
	for fName, func in pairs(BRIX) do
		local thisFName = fName
		local thisFunc = func
		if type(func) == "function" then
			self.profiler[thisFName] = {
				f = function(...)
					if bad[thisFName] then
						return thisFunc(...)
					end
					local begin = timer.systime()
					local rets = {thisFunc(...)}
					local duration = timer.systime() - begin
					self.profiler[thisFName].total = self.profiler[thisFName].total + duration
					self.profiler[thisFName].count = self.profiler[thisFName].count + 1
					return unpack(rets)
				end,
				total = 0,
				count = 0
			}
		end
	end


	BRIX.__index = function(this, key)
		return this.profiler[key] and this.profiler[key].f
	end
end


function brix.hookObject(obj, hooks)

	local hookMeta = {}
	function hookMeta:run(hookName, ...)
		if obj.hooks[hookName] == nil then
			error("attempt to call nonexistant hook " .. tostring(hookName), 2)
		end
		for name, func in pairs(obj.hooks[hookName]) do
			local ret = {func(...)}
			if #ret > 0 then
				return unpack(ret)
			end
		end
	end
	function hookMeta:__call(hookName, func)
		if obj.hooks[hookName] == nil then
			error("attempt to hook into nonexistant hook " .. tostring(hookName), 2)
		end
		table.insert(obj.hooks[hookName], func)
	end

	for _, name in pairs(hooks) do
		obj.hooks[name] = {}
	end

	hookMeta.__index = hookMeta
	obj.hook = setmetatable({}, hookMeta)


end

--[[
	GameClass: the class to use for game creation. Must use BRIX or other classes that inherit it.
	seed: The PRNG seed
	params: Optional table of parameters to overwrite the brix.params
]]

function brix.createGame(GameClass, seed, params)


	if not seed then error("Attempt to create game without RNG seed!") end
	seed = math.max(1,seed)
	local game = {}
	--[[
	local thisBrix = game

	local hookMeta = {}
	function hookMeta:run(hookName, ...)
		if thisBrix.hooks[hookName] == nil then
			error("attempt to call nonexistant hook " .. tostring(hookName), 2)
		end
		for name, func in pairs(thisBrix.hooks[hookName]) do
			local ret = {func(...)}
			if #ret > 0 then
				return unpack(ret)
			end
		end
	end
	function hookMeta:__call(hookName, func)
		if thisBrix.hooks[hookName] == nil then
			error("attempt to hook into nonexistant hook " .. tostring(hookName), 2)
		end
		table.insert(thisBrix.hooks[hookName], func)
	end


	-- INIT CODE
	game.hooks = {}
	for _, name in pairs(hooks) do -- defined at top
		game.hooks[name] = {}
	end

	hookMeta.__index = hookMeta
	game.hook = setmetatable({}, hookMeta)
	]]

	brix.hookObject(game, self.hookNames)


	game.frame = 0 -- d
	game.rseed = seed -- d

	game.params = {}
	-- load defaults
	for name, value in pairs(brix.params) do
		game.params[name] = value
	end
	setmetatable(game.params, {
		__index = function(self, name) error("Attempt to index unknown parameter \"" .. tostring(name) .. "\"", 2) end,
		__newindex = function(self, name, value) error("Attempt to assign \"" .. tostring(value) .. "\" to unknown parameter \"" .. tostring(name) .. "\"", 2) end
	})

	-- now load any changes
	if params then
		for name, value in pairs(params) do
			if game.params[name] == nil then
				error("Attempt to pass unknown parameter name: " .. tostring(name), 2)
			end
			game.params[name] = value
		end
	end

	-- call init functions
	for _, callback in pairs(brix.initializers) do
		callback(game)
	end

	--initProfiler(game)
	setmetatable(game, GameClass)
	
	game:rng() -- shuffle once
	
	return game

end

