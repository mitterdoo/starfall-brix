--@client

sound = {}

local playingSounds = {}
local loopingSounds = {}
local soundID = 0

sound.soundNames = {
	se_game_badge = "data/sf_filedata/brix/se_game_badge.wav.dat",
	se_game_badgebit = "data/sf_filedata/brix/se_game_badgebit.wav.dat",
	se_game_clear = "data/sf_filedata/brix/se_game_clear.wav.dat",
	se_game_damage1 = "data/sf_filedata/brix/se_game_damage1.wav.dat",
	se_game_damage2 = "data/sf_filedata/brix/se_game_damage2.wav.dat",
	se_game_danger = "data/sf_filedata/brix/se_game_danger.wav.dat",
	se_game_fall = "data/sf_filedata/brix/se_game_fall.wav.dat",
	se_game_ko1 = "data/sf_filedata/brix/se_game_ko1.wav.dat",
	se_game_ko2 = "data/sf_filedata/brix/se_game_ko2.wav.dat",
	se_game_lose = "data/sf_filedata/brix/se_game_lose.wav.dat",
	se_game_match = "data/sf_filedata/brix/se_game_match.wav.dat",
	se_game_nag1 = "data/sf_filedata/brix/se_game_nag1.wav.dat",
	se_game_nag2 = "data/sf_filedata/brix/se_game_nag2.wav.dat",
	se_game_offset1 = "data/sf_filedata/brix/se_game_offset1.wav.dat",
	se_game_offset2 = "data/sf_filedata/brix/se_game_offset2.wav.dat",
	se_piece_contact = "data/sf_filedata/brix/se_piece_contact.wav.dat",
	se_piece_hold = "data/sf_filedata/brix/se_piece_hold.wav.dat",
	se_piece_lock = "data/sf_filedata/brix/se_piece_lock.wav.dat",
	se_piece_rotate = "data/sf_filedata/brix/se_piece_rotate.wav.dat",
	se_piece_softdrop = "data/sf_filedata/brix/se_piece_softdrop.wav.dat",
	se_piece_harddrop = "data/sf_filedata/brix/se_piece_harddrop.wav.dat",
	se_piece_special = "data/sf_filedata/brix/se_piece_special.wav.dat",
	se_piece_translate = "data/sf_filedata/brix/se_piece_translate.wav.dat",
	se_start_1 = "data/sf_filedata/brix/se_start_1.wav.dat",
	se_start_2 = "data/sf_filedata/brix/se_start_2.wav.dat",
	se_start_3 = "data/sf_filedata/brix/se_start_3.wav.dat",
	se_target_adjust = "data/sf_filedata/brix/se_target_adjust.wav.dat",
	se_target_found = "data/sf_filedata/brix/se_target_found.wav.dat",
	se_target_warn = "data/sf_filedata/brix/se_target_warn.wav.dat"
}

hook.add("think", "soundEngine", function()

	local toRemove = {}
	local time = timer.realtime()
	for id, info in pairs(playingSounds) do
		if time >= info.finish then
			info.obj:destroy()
			toRemove[id] = true
		elseif info.start then
			local percent = 1 - (timer.realtime() - info.start) / (info.finish - info.start)
			info.obj:setVolume(percent)

		end
	end
	for id, _ in pairs(toRemove) do
		playingSounds[id] = nil
	end

end)

function sound.checkLimit()

	if bass.soundsLeft() == 0 then
		local soonestID, soonestTime = 0, math.huge
		for id, info in pairs(playingSounds) do
			if info.finish < soonestTime then
				soonestID, soonestTime = id, info.finish
			end
		end
		if soonestTime == math.huge then
			error("Hit sounds limit, but could not find a sound to remove?")
		end
		playingSounds[soonestID].obj:destroy()
		playingSounds[soonestID] = nil
	end

end

function sound.play(soundName)

	if not soundName then
		error("Invalid soundname type. Must be string.")
	end
	local path = sound.soundNames[soundName]
	if not path then
		error("Invalid soundname: " .. tostring(soundName))
	end

	sound.checkLimit()

	bass.loadFile(path, "", function(obj, errCode, errStr)

		if errCode > 0 then
			error("Sound creation error. Path: \"" .. path .. "\", Code " .. errCode .. ": " .. errStr)
		end

		playingSounds[soundID] = {
			obj = obj,
			finish = timer.realtime() + obj:getLength()
		}
		soundID = soundID + 1

	end)

end

function sound.playLooped(soundName)

	if not soundName then
		error("Invalid soundname type. Must be string.")
	end
	local path = sound.soundNames[soundName]
	if not path then
		error("Invalid soundname: " .. tostring(soundName))
	end

	sound.checkLimit()
	if loopingSounds[path] then
		loopingSounds[path]:destroy()
	end

	bass.loadFile(path, "", function(obj, errCode, errStr)

		if errCode > 0 then
			error("Sound creation error. Path: \"" .. path .. "\", Code " .. errCode .. ": " .. errStr)
		end

		obj:setLooping(true)
		loopingSounds[path] = obj

	end)
end

function sound.stopLooped(soundName)

	if not soundName then
		error("Invalid soundname type. Must be string.")
	end
	local path = sound.soundNames[soundName]
	if not path then
		error("Invalid soundname: " .. tostring(soundName))
	end

	if loopingSounds[path] then
		loopingSounds[path]:destroy()
		loopingSounds[path] = nil
	end

end

function sound.fadeLooped(soundName, duration)

	if not soundName then
		error("Invalid soundname type. Must be string.")
	end
	local path = sound.soundNames[soundName]
	if not path then
		error("Invalid soundname: " .. tostring(soundName))
	end

	if loopingSounds[path] then

		local obj = loopingSounds[path]
		playingSounds[soundID] = {
			obj = obj,
			start = timer.realtime(),
			finish = timer.realtime() + duration
		}
		loopingSounds[path] = nil

	end

end


