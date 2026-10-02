--[[
	Enseignes du monde, posées sur une face de pièce.
	Look : plaque sombre en relief, face en dégradé avec reflet en haut et
	ombre en bas, titre en Luckiest Guy (blanc, gros contour, ombre portée),
	sous-titre dans une pastille sombre.

	Signs.panel(part, face, opts) -> titre, sous-titre
	opts : Title, Sub, Colors = { clair, milieu, foncé, bord }, PixelsPerStud,
	       TitleColor, SubColor, Radius, Icon (texte court affiché à gauche, ex. "1")
	Signs.text(part, face, text, opts) -> texte seul (sans plaque), même style de lettres
]]

local Signs = {}

Signs.TitleFont = Enum.Font.LuckiestGuy
Signs.SubFont = Enum.Font.FredokaOne

Signs.Palettes = {
	Green = { Color3.fromRGB(170, 255, 110), Color3.fromRGB(70, 210, 70), Color3.fromRGB(25, 140, 60), Color3.fromRGB(10, 55, 25) },
	Gold = { Color3.fromRGB(255, 240, 140), Color3.fromRGB(255, 196, 40), Color3.fromRGB(225, 120, 15), Color3.fromRGB(90, 45, 0) },
	Blue = { Color3.fromRGB(110, 205, 255), Color3.fromRGB(45, 135, 255), Color3.fromRGB(30, 75, 210), Color3.fromRGB(12, 28, 90) },
	Red = { Color3.fromRGB(255, 120, 120), Color3.fromRGB(240, 50, 70), Color3.fromRGB(180, 15, 50), Color3.fromRGB(75, 5, 20) },
	Purple = { Color3.fromRGB(235, 140, 255), Color3.fromRGB(165, 80, 250), Color3.fromRGB(100, 40, 210), Color3.fromRGB(45, 12, 95) },
	Dark = { Color3.fromRGB(78, 82, 104), Color3.fromRGB(46, 50, 68), Color3.fromRGB(28, 30, 44), Color3.fromRGB(8, 8, 14) },
}

local INK = Color3.fromRGB(16, 14, 26)
local WHITE = Color3.new(1, 1, 1)

local function new(className: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(className)
	for k, v in props do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local function corner(parent: Instance, px: number)
	new("UICorner", { CornerRadius = UDim.new(0, px) }, parent)
end

-- Palette à partir d'une seule couleur (bases)
function Signs.paletteOf(color: Color3)
	return { color:Lerp(WHITE, 0.45), color, color:Lerp(INK, 0.3), color:Lerp(INK, 0.7) }
end

-- Lettres "affiche" : texte blanc légèrement doré, gros contour, ombre portée.
-- La copie d'ombre suit le texte quand on le change.
local function bigText(parent: Instance, value: string, size: UDim2, pos: UDim2, px: number, color: Color3?, font: Enum.Font?): TextLabel
	local stroke = math.max(2, math.floor(px * 0.075 + 0.5))
	local drop = math.max(2, math.floor(px * 0.07 + 0.5))
	local shadow = new("TextLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Size = size,
		Position = pos + UDim2.fromOffset(0, drop),
		AnchorPoint = Vector2.new(0.5, 0),
		Font = font or Signs.TitleFont,
		TextScaled = true,
		TextColor3 = INK,
		Text = value,
		ZIndex = 3,
	}, parent)
	new("UIStroke", { Thickness = stroke, Color = INK, LineJoinMode = Enum.LineJoinMode.Round }, shadow)
	local label = new("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Size = size,
		Position = pos,
		AnchorPoint = Vector2.new(0.5, 0),
		Font = font or Signs.TitleFont,
		TextScaled = true,
		TextColor3 = color or WHITE,
		Text = value,
		ZIndex = 4,
	}, parent)
	new("UIStroke", { Thickness = stroke, Color = INK, LineJoinMode = Enum.LineJoinMode.Round }, label)
	if not color then
		new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, WHITE),
				ColorSequenceKeypoint.new(0.55, WHITE),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 232, 170)),
			}),
		}, label)
	end
	label:GetPropertyChangedSignal("Text"):Connect(function()
		shadow.Text = label.Text
	end)
	label:GetPropertyChangedSignal("Visible"):Connect(function()
		shadow.Visible = label.Visible
	end)
	return label
end

local function surface(target: BasePart, face: Enum.NormalId, ppm: number): (SurfaceGui, Vector2)
	local gui = new("SurfaceGui", {
		Face = face,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = ppm,
		LightInfluence = 0,
		Brightness = 1.15,
		ClipsDescendants = true,
	}, target)
	local s = target.Size
	local w, h
	if face == Enum.NormalId.Front or face == Enum.NormalId.Back then
		w, h = s.X, s.Y
	elseif face == Enum.NormalId.Left or face == Enum.NormalId.Right then
		w, h = s.Z, s.Y
	else
		w, h = s.X, s.Z
	end
	return gui, Vector2.new(w * ppm, h * ppm)
end

-- plaque en relief : bord sombre + face en dégradé, reflet et ombre. Renvoie la face et sa taille en pixels.
local function plate(gui: SurfaceGui, px: Vector2, colors, radiusOpt: number?): (Frame, Vector2)
	local unit = math.min(px.X, px.Y)
	local radius = radiusOpt or math.floor(unit * 0.16)
	local border = math.max(4, math.floor(unit * 0.05))

	-- plaque (bord sombre)
	local back = new("Frame", {
		Name = "Plate",
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.fromOffset(2, 2),
		BackgroundColor3 = colors[4],
		BorderSizePixel = 0,
	}, gui)
	corner(back, radius)
	-- face colorée
	local faceFrame = new("Frame", {
		Name = "Face",
		Size = UDim2.new(1, -border * 2, 1, -border * 2),
		Position = UDim2.fromOffset(border, border),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,
	}, back)
	corner(faceFrame, math.max(2, radius - border))
	new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, colors[1]),
			ColorSequenceKeypoint.new(0.45, colors[2]),
			ColorSequenceKeypoint.new(1, colors[3]),
		}),
	}, faceFrame)
	-- reflet en haut et liseré clair
	local shine = new("Frame", {
		Name = "Shine",
		Size = UDim2.new(1, 0, 0.42, 0),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, faceFrame)
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) }),
	}, shine)
	new("Frame", {
		Name = "TopLine",
		Size = UDim2.new(1, -radius * 2, 0, math.max(2, math.floor(border * 0.5))),
		Position = UDim2.new(0, radius, 0, math.max(2, math.floor(border * 0.6))),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, faceFrame)
	-- ombre en bas
	local shade = new("Frame", {
		Name = "Shade",
		Size = UDim2.new(1, 0, 0.22, 0),
		Position = UDim2.fromScale(0, 0.78),
		BackgroundColor3 = INK,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, faceFrame)
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.6) }),
	}, shade)

	return faceFrame, Vector2.new(px.X - border * 2, px.Y - border * 2)
end
Signs.plate = plate

function Signs.panel(target: BasePart, face: Enum.NormalId, opts: { [string]: any }): (TextLabel, TextLabel?)
	local ppm = opts.PixelsPerStud or 40
	local gui, px = surface(target, face, ppm)
	local faceFrame, inner = plate(gui, px, opts.Colors or Signs.Palettes.Dark, opts.Radius)
	local title, sub
	if opts.Sub then
		local th = inner.Y * 0.56
		title = bigText(faceFrame, opts.Title or "", UDim2.new(0.9, 0, 0.56, 0), UDim2.new(0.5, 0, 0.05, 0), th, opts.TitleColor)
		local pill = new("Frame", {
			Name = "SubPill",
			Size = UDim2.new(0.82, 0, 0.27, 0),
			Position = UDim2.new(0.5, 0, 0.66, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = INK,
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, faceFrame)
		corner(pill, math.floor(inner.Y * 0.14))
		sub = new("TextLabel", {
			Name = "Sub",
			BackgroundTransparency = 1,
			Size = UDim2.new(0.92, 0, 0.78, 0),
			Position = UDim2.new(0.04, 0, 0.11, 0),
			Font = Signs.SubFont,
			TextScaled = true,
			TextColor3 = opts.SubColor or WHITE,
			Text = opts.Sub,
			ZIndex = 4,
		}, pill)
		new("UIStroke", { Thickness = math.max(1.5, inner.Y * 0.012), Color = INK }, sub)
		-- la pastille disparaît si le sous-titre est vide
		local function sync()
			pill.Visible = sub.Text ~= ""
		end
		sub:GetPropertyChangedSignal("Text"):Connect(sync)
		sync()
	else
		title = bigText(faceFrame, opts.Title or "", UDim2.new(0.9, 0, 0.74, 0), UDim2.new(0.5, 0, 0.12, 0), inner.Y * 0.74, opts.TitleColor)
	end
	return title, sub
end

Signs.bigText = bigText

-- Panneau de zone : pastille avec le numéro, nom de la boutique, et la vitesse conseillée en gros
function Signs.speedSign(target: BasePart, face: Enum.NormalId, opts: { [string]: any })
	local ppm = opts.PixelsPerStud or 30
	local gui, px = surface(target, face, ppm)
	local faceFrame, inner = plate(gui, px, opts.Colors or Signs.Palettes.Dark)
	-- pastille du numéro
	local badge = new("Frame", {
		Name = "Badge",
		Size = UDim2.fromScale(0.22, 0.22 * inner.X / inner.Y),
		Position = UDim2.fromScale(0.04, 0.07),
		BackgroundColor3 = INK,
		ZIndex = 3,
	}, faceFrame)
	new("UIAspectRatioConstraint", { AspectRatio = 1 }, badge)
	corner(badge, 9999)
	new("UIStroke", { Thickness = math.max(3, inner.Y * 0.025), Color = WHITE }, badge)
	bigText(badge, tostring(opts.Zone or ""), UDim2.fromScale(0.8, 0.62), UDim2.fromScale(0.5, 0.2), inner.Y * 0.2)
	new("TextLabel", {
		Name = "ShopWord",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.8, 0.2),
		Position = UDim2.fromScale(0.1, 0.02),
		Font = Signs.SubFont,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(200, 205, 220),
		Text = "SHOP",
		ZIndex = 4,
	}, badge)
	-- nom
	bigText(faceFrame, opts.Name or "", UDim2.fromScale(0.68, 0.3), UDim2.fromScale(0.62, 0.1), inner.Y * 0.3)
	-- bandeau vitesse
	local band = new("Frame", {
		Name = "SpeedBand",
		Size = UDim2.fromScale(0.92, 0.42),
		Position = UDim2.fromScale(0.04, 0.52),
		BackgroundColor3 = INK,
		BackgroundTransparency = 0.25,
		ZIndex = 3,
	}, faceFrame)
	corner(band, math.floor(inner.Y * 0.08))
	if opts.Speed then
		new("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.34, 0.5),
			Position = UDim2.fromScale(0.04, 0.25),
			Font = Signs.SubFont,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(215, 220, 235),
			Text = "SPEED\nNEEDED",
			ZIndex = 4,
		}, band)
		bigText(band, opts.Speed, UDim2.fromScale(0.58, 0.84), UDim2.fromScale(0.68, 0.06), inner.Y * 0.35, Color3.fromRGB(255, 215, 60))
	else
		bigText(band, "NO SPEED NEEDED", UDim2.fromScale(0.9, 0.6), UDim2.fromScale(0.5, 0.2), inner.Y * 0.25, Color3.fromRGB(120, 255, 140))
	end
end

-- Écran de la borne d'amélioration du tapis. Renvoie les éléments à mettre à jour.
function Signs.kioskScreen(target: BasePart, face: Enum.NormalId)
	local gui, px = surface(target, face, 60)
	gui.Brightness = 1.6
	local root = new("Frame", {
		Name = "Screen",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, gui)
	corner(root, math.floor(px.Y * 0.08))
	local grad = new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(40, 46, 70), Color3.fromRGB(14, 16, 28)),
	}, root)
	-- lignes de balayage discrètes
	for k = 1, 7 do
		new("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.fromScale(0, k / 8),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.94,
			BorderSizePixel = 0,
		}, root)
	end
	local function label(text: string, size: UDim2, pos: UDim2, color: Color3, font: Enum.Font?, align: Enum.TextXAlignment?): TextLabel
		local l = new("TextLabel", {
			BackgroundTransparency = 1,
			Size = size,
			Position = pos,
			Font = font or Signs.SubFont,
			TextScaled = true,
			TextColor3 = color,
			TextXAlignment = align or Enum.TextXAlignment.Center,
			Text = text,
			ZIndex = 3,
		}, root)
		new("UIStroke", { Thickness = 2.5, Color = INK }, l)
		return l
	end
	local header = label("TREADMILL UPGRADE", UDim2.fromScale(0.62, 0.13), UDim2.fromScale(0.05, 0.05), Color3.fromRGB(170, 180, 205), nil, Enum.TextXAlignment.Left)
	local levelPill = new("Frame", {
		Size = UDim2.fromScale(0.24, 0.15),
		Position = UDim2.fromScale(0.71, 0.04),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.85,
		ZIndex = 2,
	}, root)
	corner(levelPill, 999)
	local level = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.86, 0.8),
		Position = UDim2.fromScale(0.07, 0.1),
		Font = Signs.SubFont,
		TextScaled = true,
		TextColor3 = WHITE,
		Text = "LV 1",
		ZIndex = 3,
	}, levelPill)
	local tier = bigText(root, "UNCOMMON", UDim2.fromScale(0.9, 0.26), UDim2.fromScale(0.5, 0.2), px.Y * 0.26, Color3.fromRGB(90, 230, 120))
	local gain = label("+30 SPEED/S", UDim2.fromScale(0.9, 0.14), UDim2.fromScale(0.05, 0.48), WHITE)
	-- bouton de prix
	local priceBox = new("Frame", {
		Name = "PriceBox",
		Size = UDim2.fromScale(0.86, 0.27),
		Position = UDim2.fromScale(0.07, 0.67),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, root)
	corner(priceBox, math.floor(px.Y * 0.07))
	local priceStroke = new("UIStroke", { Thickness = 3, Color = Color3.fromRGB(10, 60, 20), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, priceBox)
	local priceGrad = new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(140, 255, 100), Color3.fromRGB(30, 170, 60)),
	}, priceBox)
	local price = bigText(priceBox, "$250", UDim2.fromScale(0.9, 0.8), UDim2.fromScale(0.5, 0.06), px.Y * 0.27 * 0.8)
	return {
		Root = root,
		Gradient = grad,
		Header = header,
		Level = level,
		Tier = tier,
		Gain = gain,
		PriceBox = priceBox,
		PriceStroke = priceStroke,
		PriceGradient = priceGrad,
		Price = price,
	}
end

-- Étiquette flottante (BillboardGui) avec les mêmes lettres
function Signs.billboard(parent: Instance, size: UDim2, offset: Vector3, value: string, color: Color3?, maxDistance: number?): (TextLabel, BillboardGui)
	local gui = new("BillboardGui", {
		Size = size,
		StudsOffset = offset,
		MaxDistance = maxDistance or 120,
		LightInfluence = 0,
	}, parent)
	local h = size.Y.Offset > 0 and size.Y.Offset or 40
	local label = bigText(gui, value, UDim2.fromScale(1, 0.86), UDim2.fromScale(0.5, 0), h * 0.86, color)
	return label, gui
end

-- Lettres seules (au sol, sur un mur...)
function Signs.text(target: BasePart, face: Enum.NormalId, value: string, opts: { [string]: any }?): TextLabel
	local o = opts or {}
	local ppm = o.PixelsPerStud or 30
	local gui, px = surface(target, face, ppm)
	return bigText(gui, value, UDim2.fromScale(0.96, 0.9), UDim2.fromScale(0.5, 0.04), px.Y * 0.9, o.Color, o.Font)
end

return Signs
