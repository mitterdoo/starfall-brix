--@includedir brix/client/scenes

scene = {}
scene.Registry = {}
function scene.Register(name, tab)
	scene.Registry[name] = tab
	if tab.Entry then
		scene.Entry = name
	end
end

requiredir("brix/client/scenes")

if not scene.Entry then
	error("Entry scene not found! Did you set SCENE.Entry to true on one scene?")
end

hook.add("think", "sceneTransitions", function()

	local t = timer.realtime()
	local s = scene.NextScene
	if s and t >= s.finish then
		scene.Active = scene.Registry[s.name]
		scene.Active = scene.Active.Open()
		gui.fadeIn(s.transition)
		scene.NextScene = nil
	end

end)

function scene.Open(name, transition)

	if not scene.Registry[name] then
		error("Attempt to open nil scene \"" .. tostring(name) .. "\"")
	end

	local isFirst = not scene.Active
	if scene.Active then
		if transition then
			if not scene.NextScene then
				scene.NextScene = {name = name, start = timer.realtime(), finish = timer.realtime() + transition, transition = transition}
				gui.fadeOut(transition)
			end
		else
			scene.Active()
		end
	end
	
	scene.Active = scene.Registry[name]
	scene.Active = scene.Active.Open()
	if isFirst and transition then
		gui.fadeIn(transition)
	end

end

scene.Open(scene.Entry)
