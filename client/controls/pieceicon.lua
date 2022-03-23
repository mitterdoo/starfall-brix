--[[
BRIX: Stack to the Death, a multiplayer brick stacking game written for the Starfall addon in Garry's Mod.
Copyright (C) 2022  Connor Ashcroft

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see LICENSE.md).
If not, see <https://www.gnu.org/licenses/>.
]]
local PANEL = {}

local pieceO = brix.pieceIDs.o
function PANEL:Paint(w, h)

	local offset = brix.normalPiece(self.pieceID) == pieceO and self.brickSize or 0

	PANEL.super.Paint(self, w, h, offset, -offset)

end

gui.Register("PieceIcon", PANEL, "Piece")
