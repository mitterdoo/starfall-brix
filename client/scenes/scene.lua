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

local function closeActiveScene()

	local name = scene.ActiveName
	scene.Active()
	scene.Active = nil
	scene.ActiveName = nil
	hook.run("sceneClose", name)

end

local function setActiveScene(name)

	scene.ActiveName = name
	scene.Active = scene.Registry[name]
	scene.Active = scene.Active.Open()
	hook.run("sceneOpen", name)

end

hook.add("think", "sceneTransitions", function()

	local t = timer.realtime()
	local s = scene.NextScene
	if s and t >= s.finish then
		closeActiveScene()
		setActiveScene(s.name)
		gui.fadeIn(s.transition)
		scene.NextScene = nil
	end

end)

function scene.Open(name, transition)

	if not scene.Registry[name] then
		error("Attempt to open nil scene \"" .. tostring(name) .. "\"")
	end

	if scene.Active then
		if transition then
			if not scene.NextScene then
				hook.run("sceneClosing", scene.ActiveName)
				scene.NextScene = {name = name, start = timer.realtime(), finish = timer.realtime() + transition, transition = transition}
				gui.fadeOut(transition)
			end
		else
			hook.run("sceneClosing", scene.ActiveName)
			closeActiveScene()
			setActiveScene(name)
		end
	else
		setActiveScene(name)
		if transition then
			gui.fadeIn(transition)
		end
	end

end

scene.Open(scene.Entry, 1)
