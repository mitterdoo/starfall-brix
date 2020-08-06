local PANEL = {}

local pieceO = brix.pieceIDs.o
function PANEL:Paint(w, h)

	local offset = brix.normalPiece(self.pieceID) == pieceO and self.brickSize or 0

	PANEL.super.Paint(self, w, h, offset, -offset)

end

gui.Register("PieceIcon", PANEL, "Piece")
