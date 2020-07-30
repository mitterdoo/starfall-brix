

hook.add("brConnect", "death", function(game, arena)
	local dieRT = "brixDeath"
	local Field = game.controls.fieldCtrl
	local FieldPos = game.controls.Field_UnderMatrix
	local field_w, field_h = 0, 0
	local function fx_Death(x, y, w, h, frac, glow)

		render.setRGBA(255, 255, 255, 255*(1-frac)^2)
		render.setRenderTargetTexture(dieRT)
		render.drawTexturedRectUV(x, y, w, h, 0, 0, field_w/1024, field_h/1024)

	end
	local function fx_Win(x, y, w, h, frac, glow)

		render.setRGBA(100, 255, 100, 255*(1-frac)^2)
		render.setRenderTargetTexture(dieRT)
		render.drawTexturedRectUV(x, y, w, h, 0, 0, field_w/1024, field_h/1024)

	end

	local function clearMatrixEffect(fxFunc)
		if not render.renderTargetExists(dieRT) then
			render.createRenderTarget(dieRT)
		end

		hook.add("postdrawhud", "death", function()
			hook.remove("postdrawhud", "death")
			gui.pushRT(dieRT)
			render.clear(Color(0, 0, 0, 0), true)
			
			render.resetStencil()
			render.setStencilEnable(true)
			render.setStencilReferenceValue(1)
			render.setStencilPassOperation(STENCIL_REPLACE)
			Field:Paint()

			render.setStencilCompareFunction(STENCIL_EQUAL)
			render.setRGBA(255, 255, 255, 255)
			render.drawRectFast(0, 0, 1024, 1024)
			render.setStencilEnable(false)

			gui.popRT()

			local brickSize = Field.brickSize
			field_w, field_h = brickSize*10, brickSize*21

			local fieldPos, scale = FieldPos:AbsolutePos(Vector(field_w/2, field_h/-2, 0))
			local pos = fieldPos
			gfx.EmitParticle(
				{pos, pos},
				{Vector(field_w, field_h, 0)*scale, Vector(field_w, field_h, 0)*Vector(2, 1, 0) * scale},
				0, 0.3,
				fxFunc,
				true, true
			)

			Field:SetVisible(false)
			Field.invalid = true
			game.controls.RT.invalid = true
			game.controls.fieldDanger:Remove()
			sound.fadeLooped("se_game_danger", 0.2)


		end)
	end

	arena.hook("die", function(killerID)
		clearMatrixEffect(fx_Death)
	end)

	arena.hook("win", function()
		clearMatrixEffect(fx_Win)
	end)

end)
