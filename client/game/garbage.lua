-- Graphics for garbage queue
hook.add("brConnect", "garbage", function(game, arena)

	local Garbage = game.controls.Garbage

	arena.hook("garbageQueue", function(lines, sender, frame)
		Garbage:Enqueue(lines)
	end)

	arena.hook("garbageActivate", function()
		Garbage:SetState(1)
	end)

	arena.hook("garbageNag", function(second)
		Garbage:SetState(second and 3 or 2)
	end)

	arena.hook("garbageCancelled", function(count)
		Garbage:Offset(count)
	end)

	arena.hook("garbageDump", function()
		Garbage:Dump()
	end)
end)
