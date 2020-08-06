--[[
	gfx Library. Contains main code for creating/rendering particles.
]]

gfx = {}


local group_generic = {}

local g_groups = {}
--[[
	g_groups Structure:
	{
		[group_reference] = {particles = {}, positions = {}}
	}
]]


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
function gfx.EmitParticle(keys_Pos, keys_Size, startOffset, duration, callback, glow, centered, ease, group)

	group = group or group_generic
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
		glow = glow,
		ease = ease
	}

	if not g_groups[group] then
		g_groups[group] = {particles = {}, positions = {}}
	end
	local particles = g_groups[group].particles

	local i = 1
	while true do
		local p = particles[i]
		if p == nil or p.start >= t then
			table.insert(particles, particle)
			break
		end
		i = i + 1
	end

	return particle

end

function gfx.KillParticles(refs) -- keys must be refs to particle

	for _, group in pairs(g_groups) do
		local particles = group.particles
		local i = 1
		while true do
			local p = particles[i]
			if p == nil then break end
			if refs[p] then
				table.remove(particles, i)
			else
				i = i + 1
			end
		end

		if i == 1 and #particles == 0 then -- destroy group if no particles exist in it
			g_groups[groupRef] = nil
		end
	end

end

function gfx.KillAllParticles()

	g_groups = {}

end

hook.add("guiPostDraw", "emitter", function()

	
	local t = timer.realtime()

	-- Purge dead particles
	for groupRef, group in pairs(g_groups) do
		local particles = group.particles
		local i = 1
		while true do

			local p = particles[i]
			if p ~= nil and t > p.finish then
				table.remove(particles, i)
			elseif p == nil then
				break
			else
				i = i + 1
			end

		end

		if i == 1 and #particles == 0 then -- destroy group if no particles exist in it
			g_groups[groupRef] = nil
		end
	end

	-- Calculate particle positions
	for groupRef, group in pairs(g_groups) do
		local particles = group.particles
		local positions = group.positions
		for _, p in pairs(particles) do

			if t >= p.start then
				local frac = (t - p.start) / (p.finish - p.start)
				local ease = p.ease
				if type(ease) == "function" then
					frac = ease(frac)
				end
				local pos = keyframe(p.keys_Pos, frac)
				local size = keyframe(p.keys_Size, frac)
				table.insert(positions, {pos[1], pos[2], size[1], size[2], frac, p.callback, p.glow})
			end

		end
	end

	-- Now draw
	gui.startGlow()
	for groupRef, group in pairs(g_groups) do
		local positions, enter, exit = group.positions, groupRef.enter, groupRef.exit
		if enter then enter() end
		for _, p in pairs(positions) do
			if p[7] then
				p[6](p[1], p[2], p[3], p[4], p[5], true)
			end
		end
		if exit then exit() end
	end

	gui.endGlow()

	for groupRef, group in pairs(g_groups) do
		local positions, enter, exit = group.positions, groupRef.enter, groupRef.exit
		if enter then enter() end
		while true do
			local p = table.remove(positions, 1)
			if p ~= nil then
				p[6](p[1], p[2], p[3], p[4], p[5], false)
			else
				break
			end
		end
		if exit then exit() end
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



