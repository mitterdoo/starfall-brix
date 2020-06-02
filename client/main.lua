--@clinet
--@include brix/client/loader.lua
--@include brix/client/brix_33.lua
--[[
	Runs the loader asynchronously, and then initializes the main game once everything has finished loading.
]]

require("brix/client/loader.lua")

hook.add("load", "", function()



	require("brix/client/brix_33.lua")


end)
