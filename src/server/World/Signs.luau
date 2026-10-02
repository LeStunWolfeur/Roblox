--[[
	Enseignes propres (style interface du jeu) posées sur une face de pièce :
	fond en dégradé, bord épais, texte blanc à gros contour.
	Signs.panel(part, face, opts) -> titre, sous-titre
	opts : Title, Sub, Colors = { haut, milieu, bas, bord }, PixelsPerStud, Radius
]]

local Signs = {}

Signs.Palettes = {
	Green = { Color3.fromRGB(185, 255, 95), Color3.fromRGB(90, 220, 60), Color3.fromRGB(35, 165, 55), Color3.fromRGB(15, 70, 20) },
	Gold = { Color3.fromRGB(255, 250, 170), Color3.fromRGB(255, 205, 50), Color3.fromRGB(235, 140, 20), Color3.fromRGB(100, 55, 0) },
	Blue = { Color3.fromRGB(120, 210, 255), Color3.fromRGB(55, 145, 255), Color3.fromRGB(40, 95, 225), Color3.fromRGB(15, 35, 100) },
	Dark = { Color3.fromRGB(70, 74, 92), Color3.fromRGB(42, 45, 60), Color3.fromRGB(28, 30, 40), Color3.fromRGB(8, 8, 12) },
}

local INK = Color3.fromRGB(18, 18, 26)

local function text(parent: Instance, value: string, size: UDim2, pos: UDim2, stroke: number, color: Color3?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos
	l.AnchorPoint = Vector2.new(0.5, 0)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Text = value
	l.Parent = parent
	local s = Instance.new("UIStroke")
	s.Thickness = stroke
	s.Color = INK
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = l
	return l
end

function Signs.panel(target: BasePart, face: Enum.NormalId, opts: { [string]: any }): (TextLabel, TextLabel?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = opts.PixelsPerStud or 40
	gui.LightInfluence = 0
	gui.Brightness = 1.2
	gui.Parent = target
	local colors = opts.Colors or Signs.Palettes.Dark
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -16, 1, -16)
	frame.Position = UDim2.fromOffset(8, 8)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, opts.Radius or 18)
	corner.Parent = frame
	local border = Instance.new("UIStroke")
	border.Thickness = 8
	border.Color = colors[4]
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = frame
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colors[1]),
		ColorSequenceKeypoint.new(0.5, colors[2]),
		ColorSequenceKeypoint.new(1, colors[3]),
	})
	grad.Rotation = 25
	grad.Parent = frame
	-- reflet en haut
	local gloss = Instance.new("Frame")
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.Size = UDim2.fromScale(1, 0.5)
	gloss.ZIndex = 0
	gloss.Parent = frame
	local gc = Instance.new("UICorner")
	gc.CornerRadius = UDim.new(0, opts.Radius or 18)
	gc.Parent = gloss
	local gg = Instance.new("UIGradient")
	gg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
	gg.Rotation = 90
	gg.Parent = gloss
	local title, sub
	if opts.Sub then
		title = text(frame, opts.Title or "", UDim2.new(0.92, 0, 0.58, 0), UDim2.new(0.5, 0, 0.06, 0), opts.Stroke or 7, opts.TitleColor)
		sub = text(frame, opts.Sub, UDim2.new(0.86, 0, 0.26, 0), UDim2.new(0.5, 0, 0.66, 0), 4, opts.SubColor)
	else
		title = text(frame, opts.Title or "", UDim2.new(0.92, 0, 0.8, 0), UDim2.new(0.5, 0, 0.1, 0), opts.Stroke or 7, opts.TitleColor)
	end
	return title, sub
end

return Signs
