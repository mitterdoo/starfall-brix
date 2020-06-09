--@client
--@include brix/client/gui.lua
--@include brix/br/arena_cl.lua
--@include brix/client/input.lua


require("brix/br/arena_cl.lua")
require("brix/client/gui.lua")
require("brix/client/input.lua")

local mat = brix.makeMatrix(10, 20)

local m = gui.Create("Control")
function m:Paint(w, h)
	render.setRGBA(255, 0, 255, 255)
	render.drawRect(0, 0, w, h)
end
m:SetPos(64, 64)
m:SetSize(48 * 10, 48*20)

local fieldCtrl = gui.Create("Field", m)
fieldCtrl:SetField(mat)
fieldCtrl:SetPos(0, -48)

mat:lock(brix.pieces[0], 1, 2, 0, false)


hook.add("postdrawhud", "", function()

	gui.Draw()

end)


