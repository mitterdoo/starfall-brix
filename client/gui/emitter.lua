local PANEL = {}

--[[

	Particles rewrite

	Paint:
		Calculate position of each particle
		Create list of particle positions and sizes
		For each position entry, run their callbacks with (x, y, w, h, frac, isGlow)


]]

gui.Register("Emitter", PANEL, "Control")
