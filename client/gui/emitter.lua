local PANEL = {}

local function lerp( delta, from, to )

	if ( delta > 1 ) then return to end
	if ( delta < 0 ) then return from end

	return from + ( to - from ) * delta

end

--[[

	Particles rewrite

	Paint:
		Calculate position of each particle
		Create list of particle positions and sizes
		For each position entry, run their callbacks with (x, y, w, h, frac, isGlow)


]]

local g_particles = {}		-- Particle information. This should only be iterated once.
local g_positions = {}		-- Particle positions. Structure: {x, y, w, h, frac, callback, glow}

function PANEL:Init()
	self.glow = false
end

function PANEL:SetGlow(glow)
	self.glow = glow
end

-- Emit a particle. Positions and sizes must be vectors
function PANEL:Emit(startPos, endPos, startSize, endSize, duration, callback, centered)

	if centered then
		startPos = startPos - startSize/2
		endPos = endPos - endSize/2
	end

	local p1x, p1y = gui.AbsolutePos(startPos[1], startPos[2])
	local p2x, p2y = gui.AbsolutePos(endPos[1], endPos[2])
	startPos = Vector(p1x, p1y, 0)
	endPos = Vector(p2x, p2y, 0)


	local t = timer.realtime()
	local particle = {
		startPos = startPos,
		endPos = endPos,
		startSize = startSize,
		endSize = endSize,
		start = t,
		finish = t + duration,
		callback = callback,
		glow = self.glow
	}

	table.insert(g_particles, particle)

end

hook.add("guiPostDraw", "emitter", function()

	
	local t = timer.realtime()

	-- Purge dead particles
	while true do

		local p = g_particles[1]
		if p ~= nil and t > p.finish then
			table.remove(g_particles, 1)
		else
			break
		end

	end

	-- Calculate particle positions
	for _, p in pairs(g_particles) do

		local frac = (t - p.start) / (p.finish - p.start)
		local pos = lerp(frac, p.startPos, p.endPos)
		local size = lerp(frac, p.startSize, p.endSize)
		table.insert(g_positions, {pos[1], pos[2], size[1], size[2], frac, p.callback, p.glow})

	end

	-- Now draw
	gui.startGlow()
	for _, p in pairs(g_positions) do
		if p[7] then
			p[6](p[1], p[2], p[3], p[4], p[5], true)
		end
	end

	gui.endGlow()

	while true do
		local p = table.remove(g_positions, 1)
		if p ~= nil then
			p[6](p[1], p[2], p[3], p[4], p[5], false)
		else
			break
		end
	end

end)

gui.Register("Emitter", PANEL, "Control")
