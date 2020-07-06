--[[

	Graphical effects for Brix 33

]]

gfx = {}


--[[

	Particles rewrite

	Paint:
		Calculate position of each particle
		Create list of particle positions and sizes
		For each position entry, run their callbacks with (x, y, w, h, frac, isGlow)


]]



local g_particles = {}		-- Particle information. This should only be iterated once.
local g_positions = {}		-- Particle positions. Structure: {x, y, w, h, frac, callback, glow}


local function keyframe(keys, frac)

	local lastKey, lastValue
	while true do
		local nextKey, nextValue = next(keys, lastKey)
		if nextKey == nil then return lastValue[2] end
		if lastKey ~= nil and frac <= nextValue[1] then
			return lerp(timeFrac(frac, lastValue[1], nextValue[1]), lastValue[2], nextValue[2])
		end
		lastKey = nextKey
		lastValue = nextValue
	end

end

--[[
	startPos, endPos,
	startSize, endSize,
	startOffset, duration,
	callback,
	glow,
	centered
]]
-- Emit a particle. Positions and sizes must be vectors
function gfx.EmitParticle(keys_Pos, keys_Size, startOffset, duration, callback, glow, centered)

	if type(keys_Pos[1]) ~= "table" then
		local count = #keys_Pos - 1
		for k, value in pairs(keys_Pos) do
			local key = count ~= 0 and ((k-1) / count) or 0
			keys_Pos[k] = {key, value}
		end
	end

	if type(keys_Size[1]) ~= "table" then
		local count = #keys_Size - 1
		for k, value in pairs(keys_Size) do
			local key = count ~= 0 and ((k-1) / count) or 0
			keys_Size[k] = {key, value}
		end
	end

	if centered then
		for key, pos in pairs(keys_Pos) do
			pos[2] = pos[2] - keyframe(keys_Size, pos[1])/2
		end
	end

	local t = timer.realtime() + startOffset
	local particle = {
		keys_Pos = keys_Pos,
		keys_Size = keys_Size,
		start = t,
		finish = t + duration,
		callback = callback,
		glow = glow
	}

	local i = 1
	while true do
		local p = g_particles[i]
		if p == nil or p.start >= t then
			table.insert(g_particles, particle)
			break
		end
		i = i + 1
	end

	return particle

end

function gfx.KillParticles(refs) -- keys must be refs to particle

	local i = 1
	while true do
		local p = g_particles[i]
		if p == nil then break end
		if refs[p] then
			table.remove(g_particles, i)
		else
			i = i + 1
		end
	end

end

hook.add("guiPostDraw", "emitter", function()

	
	local t = timer.realtime()

	-- Purge dead particles
	local i = 1
	while true do

		local p = g_particles[i]
		if p ~= nil and t > p.finish then
			table.remove(g_particles, i)
		elseif p == nil then
			break
		else
			i = i + 1
		end

	end

	-- Calculate particle positions
	for _, p in pairs(g_particles) do

		if t >= p.start then
			local frac = (t - p.start) / (p.finish - p.start)
			local pos = keyframe(p.keys_Pos, frac)
			local size = keyframe(p.keys_Size, frac)
			table.insert(g_positions, {pos[1], pos[2], size[1], size[2], frac, p.callback, p.glow})
		end

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


do
	local duration = 1
	local colorA = Vector(255, 255, 255)
	local colorB = Vector(145, 255, 103)

	function gfx.Draw_LineClear(x, y, w, h, frac, glow)

		local col = lerp(frac, colorA, colorB)
		render.setRGBA(col[1], col[2], col[3], (1-frac)*255)
		render.drawRectFast(x, y, w, h)

	end

	function gfx.Emit_LineClear(pos, brickSize)

		local startSize = Vector(brickSize * 10, brickSize, 0)
		local endSize = Vector(brickSize * 10 * 1.45, brickSize * 0.8, 0)

		gfx.EmitParticle(startPos, startPos,
			startSize, endSize,
			0, duration,
			DrawLineClear,
			true, true
		)

	end

end



