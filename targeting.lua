--@name BRIX: Targeting
--@shared

--[[

	If only target is K.O.'d, re-run target condition

	K.O.s
		On Retarget/attack: 

	Badges
		On Retarget/attack: Targets the player with the most badges. If there is a tie, the player is chosen randomly at the time of targeting
		(target time is when the player selects "Badges", or sends an attack with "Badges" active)

	Attackers
		All attackers, or hovers on a random person
	
	Randoms
		Randomizes the instant before an attack is sent

]]

brix.battlefieldWidth = 4
brix.battlefieldHeight = 8
brix.targetModes = {
	KO = 0,
	BADGES = 1,
	ATTACKERS = 2,
	RANDOM = 3,
	MANUAL = 4
}
local w, h = brix.battlefieldWidth, brix.battlefieldHeight
local modes = brix.targetModes

brix.onInit(function(self)

	self.targets = {}		-- UniqueIDs of targets
	self.attackers = {}		-- UniqueIDs of attackers
	self.targetMode = brix.targetModes.KO

end)

-- With the provided coordinates (x = 0 = left, y = 0 = top), returns the uniqueId of the player at the given position
function BRIX:getUniqueIDFromCoord(x, y)
	local id = y * w + x
	if id >= self.uniqueId then
		return id + 1
	else
		return id
	end
end

-- Returns the enemy at the coordinates (x = 0 = left, y = 0 = top), or nil if the enemy does NOT exist (dead enemies are not nil)
function BRIX:getEnemyFromCoord(x, y)
	return self.arena.playerLookup[self:getUniqueIDFromCoord(x, y)]
end

function BRIX:changeTargetMode(mode)

	self.targetMode = mode
	self:updateTargets()

end

function BRIX:updateTargets()

	local mode = self.targetMode
	if mode == modes.KO then
		local inDanger = {}
		for _, ply in pairs(self.arena.players) do
			if ply.danger and ply.alive then table.insert(inDanger, ply.uniqueId) end
		end
		if #inDanger == 0 then
			
		local idx = math.ceil(self:rng(true) * #inDanger)
		self.targets = {inDanger[idx]}

	elseif mode == modes.BADGES then


end

