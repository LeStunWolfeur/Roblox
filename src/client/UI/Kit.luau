--[[
	Boîte à outils d'interface, style simulateur Roblox :
	- tuiles un peu anguleuses, gros contour sombre
	- dégradé en diagonale très saturé + reflets vitrés en biais + brillance en haut
	- texte blanc en Fredoka One avec un contour épais
	Les décorations d'une tuile ont ZIndex 0, le contenu ZIndex 1 et plus
	(ZIndexBehavior = Sibling), donc pas besoin de gérer les ZIndex à la main.
]]

local TweenService = game:GetService("TweenService")

local Sounds = require(script.Parent.Sounds)

local Kit = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

Kit.Colors = {
	Ink = rgb(18, 18, 26),
	Ink2 = rgb(34, 36, 48),
	White = Color3.new(1, 1, 1),
	Green = rgb(110, 235, 70),
	Money = rgb(90, 230, 70),
	Blue = rgb(80, 175, 255),
	Red = rgb(255, 70, 80),
	Yellow = rgb(255, 215, 50),
	Purple = rgb(185, 110, 255),
	Pink = rgb(255, 90, 170),
	Orange = rgb(255, 150, 40),
	Grey = rgb(160, 165, 180),
	Speed = rgb(110, 200, 255),
	Paper = rgb(250, 247, 240),
}

-- Palettes : couleurs du dégradé (haut gauche vers bas droite) + couleur du contour
Kit.Palettes = {
	Red = { rgb(255, 110, 120), rgb(245, 45, 75), rgb(200, 20, 60), Border = rgb(90, 10, 25) },
	Blue = { rgb(120, 210, 255), rgb(55, 145, 255), rgb(40, 95, 225), Border = rgb(15, 35, 100) },
	Green = { rgb(185, 255, 95), rgb(90, 220, 60), rgb(35, 165, 55), Border = rgb(15, 70, 20) },
	Lime = { rgb(110, 225, 70), rgb(190, 240, 60), rgb(255, 215, 50), Border = rgb(40, 80, 10) },
	Yellow = { rgb(255, 245, 120), rgb(255, 205, 40), rgb(255, 145, 20), Border = rgb(115, 60, 0) },
	Orange = { rgb(255, 205, 90), rgb(255, 140, 40), rgb(235, 80, 25), Border = rgb(110, 40, 0) },
	Purple = { rgb(240, 120, 255), rgb(175, 85, 255), rgb(115, 50, 225), Border = rgb(55, 15, 105) },
	Pink = { rgb(255, 150, 220), rgb(250, 75, 175), rgb(200, 40, 150), Border = rgb(95, 10, 65) },
	Cyan = { rgb(150, 250, 255), rgb(50, 210, 245), rgb(25, 150, 225), Border = rgb(5, 65, 100) },
	Grey = { rgb(215, 220, 230), rgb(160, 166, 182), rgb(115, 120, 138), Border = rgb(45, 48, 58) },
	Dark = { rgb(70, 74, 92), rgb(42, 45, 60), rgb(28, 30, 40), Border = rgb(8, 8, 12) },
	Rainbow = {
		rgb(100, 230, 90),
		rgb(255, 235, 70),
		rgb(255, 140, 60),
		rgb(255, 80, 170),
		rgb(150, 95, 255),
		Border = rgb(35, 15, 55),
	},
	Candy = { rgb(255, 95, 200), rgb(190, 90, 255), rgb(110, 120, 255), Border = rgb(45, 15, 90) },
	Gold = { rgb(255, 250, 170), rgb(255, 210, 60), rgb(230, 140, 20), Border = rgb(100, 55, 0) },
}

Kit.Font = Enum.Font.FredokaOne
Kit.Title = Kit.Font
Kit.Body = Kit.Font

function Kit.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	if props then
		local parent = props.Parent
		for k, v in props do
			if k ~= "Parent" then
				(inst :: any)[k] = v
			end
		end
		if children then
			for _, child in children do
				child.Parent = inst
			end
		end
		if parent then
			inst.Parent = parent
		end
	end
	return inst
end

function Kit.corner(radius: number?): UICorner
	return Kit.new("UICorner", { CornerRadius = UDim.new(0, radius or 6) })
end

function Kit.stroke(thickness: number?, color: Color3?, transparency: number?): UIStroke
	return Kit.new("UIStroke", {
		Thickness = thickness or 3,
		Color = color or Kit.Colors.Ink,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Kit.textStroke(thickness: number?, color: Color3?): UIStroke
	return Kit.new("UIStroke", {
		Thickness = thickness or 2.5,
		Color = color or Kit.Colors.Ink,
		LineJoinMode = Enum.LineJoinMode.Round,
	})
end

function Kit.padding(px: number): UIPadding
	local u = UDim.new(0, px)
	return Kit.new("UIPadding", { PaddingTop = u, PaddingBottom = u, PaddingLeft = u, PaddingRight = u })
end

function Kit.gradient(colors: { Color3 }, rotation: number?): UIGradient
	local keys = {}
	local n = #colors
	for i = 1, n do
		table.insert(keys, ColorSequenceKeypoint.new(n == 1 and 0 or (i - 1) / (n - 1), colors[i]))
	end
	if n == 1 then
		table.insert(keys, ColorSequenceKeypoint.new(1, colors[1]))
	end
	return Kit.new("UIGradient", { Color = ColorSequence.new(keys), Rotation = rotation or 0 })
end

-- Texte blanc à gros contour (le style de tous les simulateurs)
function Kit.text(props: { [string]: any }): TextLabel
	local p = {
		BackgroundTransparency = 1,
		Font = Kit.Font,
		TextColor3 = Kit.Colors.White,
		TextScaled = true,
		ZIndex = 2,
	}
	for k, v in props do
		if k ~= "Stroke" and k ~= "StrokeColor" then
			p[k] = v
		end
	end
	local label = Kit.new("TextLabel", p)
	if props.Stroke ~= false then
		Kit.textStroke(props.Stroke or 2.5, props.StrokeColor).Parent = label
	end
	return label
end
Kit.label = Kit.text

-- reflets vitrés en biais (bandes blanches transparentes)
local STREAKS = {
	{ 0, 1 },
	{ 0.2, 1 },
	{ 0.205, 0.74 },
	{ 0.32, 0.74 },
	{ 0.325, 1 },
	{ 0.38, 1 },
	{ 0.385, 0.84 },
	{ 0.44, 0.84 },
	{ 0.445, 1 },
	{ 0.7, 1 },
	{ 0.705, 0.86 },
	{ 0.76, 0.86 },
	{ 0.765, 1 },
	{ 1, 1 },
}

local function decorate(face: Frame, radius: number, opts: { [string]: any })
	-- brillance en haut
	local gloss = Kit.new("Frame", {
		Name = "Gloss",
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromScale(1, 0.55),
		ZIndex = 0,
		Parent = face,
	}, { Kit.corner(radius) })
	Kit.new("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) }),
		Rotation = 90,
		Parent = gloss,
	})
	-- ombre en bas
	local shade = Kit.new("Frame", {
		Name = "Shade",
		BackgroundColor3 = Color3.new(0, 0, 0),
		Size = UDim2.fromScale(1, 0.45),
		Position = UDim2.fromScale(0, 0.55),
		ZIndex = 0,
		Parent = face,
	}, { Kit.corner(radius) })
	Kit.new("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.72) }),
		Rotation = 90,
		Parent = shade,
	})
	if opts.Streaks ~= false then
		local streaks = Kit.new("Frame", {
			Name = "Streaks",
			BackgroundColor3 = Color3.new(1, 1, 1),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 0,
			Parent = face,
		}, { Kit.corner(radius) })
		local keys = {}
		for _, k in STREAKS do
			table.insert(keys, NumberSequenceKeypoint.new(k[1], k[2]))
		end
		Kit.new("UIGradient", { Transparency = NumberSequence.new(keys), Rotation = opts.StreakRotation or -60, Parent = streaks })
	end
	-- liseré clair à l'intérieur du contour (effet biseau)
	Kit.new("Frame", {
		Name = "Bevel",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -6, 1, -6),
		Position = UDim2.fromOffset(3, 3),
		ZIndex = 0,
		Parent = face,
	}, { Kit.corner(math.max(radius - 3, 2)), Kit.stroke(2, Color3.new(1, 1, 1), 0.55) })
end

-- Applique (ou change) la palette d'une tuile
function Kit.paint(face: Frame, palette: any)
	-- rien à faire si la tuile a déjà cette palette (évite de recréer le dégradé)
	if type(palette) == "string" then
		if face:GetAttribute("Pal") == palette then
			return
		end
		face:SetAttribute("Pal", palette)
	end
	local pal = typeof(palette) == "table" and palette or Kit.Palettes[palette]
	local grad = face:FindFirstChild("Paint")
	if grad then
		grad:Destroy()
	end
	local g = Kit.gradient(pal, face:GetAttribute("Rot") or 25)
	g.Name = "Paint"
	g.Parent = face
	local stroke = face:FindFirstChild("Border")
	if stroke then
		(stroke :: UIStroke).Color = pal.Border or Kit.Colors.Ink
	end
end

-- Tuile brillante.
-- props : Parent, Size, Position, AnchorPoint, LayoutOrder, ZIndex, Name, Visible,
--         Palette (nom ou table), Radius, Border, Streaks, Rot
function Kit.tile(props: { [string]: any }): Frame
	local radius = props.Radius or 6
	local face = Kit.new("Frame", {
		Name = props.Name or "Tile",
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Visible = props.Visible ~= false,
		Rotation = props.Rotation or 0,
		Parent = props.Parent,
	}, { Kit.corner(radius) })
	face:SetAttribute("Rot", props.Rot or 25)
	local border = Kit.stroke(props.Border or 3)
	border.Name = "Border"
	border.Parent = face
	decorate(face, radius, props)
	Kit.paint(face, props.Palette or "Blue")
	return face
end

-- Panneau sombre semi-transparent (corps des fenêtres, cases)
function Kit.well(props: { [string]: any }): Frame
	local f = Kit.new("Frame", {
		Name = props.Name or "Well",
		BackgroundColor3 = props.Color or Color3.fromRGB(16, 20, 30),
		BackgroundTransparency = props.Transparency or 0.25,
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	}, { Kit.corner(props.Radius or 6) })
	if props.Border ~= false then
		Kit.stroke(props.Border or 3, props.BorderColor or Kit.Colors.Ink).Parent = f
	end
	return f
end

-- Bouton = tuile + zone cliquable + texte optionnel. Petit rebond au clic.
function Kit.button(props: { [string]: any }, onClick: (() -> ())?): (Frame, TextButton, TextLabel?)
	local face = Kit.tile(props)
	local scale = Kit.new("UIScale", { Parent = face })
	local label
	if props.Text then
		label = Kit.text({
			Name = "Label",
			Parent = face,
			Text = props.Text,
			Size = props.TextSize or UDim2.new(1, -14, 1, -10),
			Position = props.TextPosition or UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Stroke = props.TextStroke or 2.5,
			ZIndex = 3,
		})
	end
	local hit = Kit.new("TextButton", {
		Name = "Hit",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 20,
		Parent = face,
	})
	local quick = TweenInfo.new(0.08)
	hit.MouseEnter:Connect(function()
		TweenService:Create(scale, quick, { Scale = 1.05 }):Play()
	end)
	hit.MouseLeave:Connect(function()
		TweenService:Create(scale, quick, { Scale = 1 }):Play()
	end)
	hit.MouseButton1Down:Connect(function()
		TweenService:Create(scale, quick, { Scale = 0.93 }):Play()
	end)
	hit.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end)
	hit.Activated:Connect(function()
		Sounds.play("Click")
	end)
	if onClick then
		hit.Activated:Connect(onClick)
	end
	return face, hit, label
end

-- Icône Robux (hexagone vert) en 2D
function Kit.robux(props: { [string]: any }): Frame
	local holder = Kit.new("Frame", {
		Name = "Robux",
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.fromOffset(22, 22),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 2,
		Parent = props.Parent,
	})
	Kit.new("UIAspectRatioConstraint", { Parent = holder })
	local function hex(scale: number, color: Color3)
		for i = 0, 2 do
			Kit.new("Frame", {
				BackgroundColor3 = color,
				Size = UDim2.fromScale(0.866 * scale, 0.5 * scale),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Rotation = 90 + i * 60,
				BorderSizePixel = 0,
				ZIndex = holder.ZIndex,
				Parent = holder,
			})
		end
	end
	hex(1.12, Kit.Colors.Ink)
	hex(0.95, props.Color or rgb(80, 220, 70))
	hex(0.56, rgb(235, 255, 225))
	hex(0.34, props.Color or rgb(80, 220, 70))
	return holder
end

-- Prix Robux : hexagone + nombre. Renvoie le label pour pouvoir changer le texte.
function Kit.price(props: { [string]: any }): (Frame, TextLabel)
	local row = Kit.new("Frame", {
		Name = "Price",
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.fromOffset(90, 26),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 2,
		Parent = props.Parent,
	})
	Kit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = props.Align or Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = row,
	})
	local h = props.IconSize or 22
	Kit.robux({ Parent = row, Size = UDim2.fromOffset(h, h), LayoutOrder = 1, ZIndex = row.ZIndex })
	local label = Kit.text({
		Parent = row,
		Text = props.Text or "...",
		Size = UDim2.new(0, props.TextWidth or 56, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = props.Color or Kit.Colors.Money,
		Stroke = props.Stroke or 2.5,
		LayoutOrder = 2,
		ZIndex = row.ZIndex,
	})
	return row, label
end

-- Barre de progression orange façon "XP"
function Kit.bar(props: { [string]: any }): (Frame, Frame, TextLabel, TextLabel)
	local back = Kit.well({
		Name = props.Name or "Bar",
		Parent = props.Parent,
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Color = rgb(235, 238, 245),
		Transparency = 0.05,
		Border = 3,
		Radius = 4,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
	})
	local fill = Kit.tile({
		Name = "Fill",
		Parent = back,
		Size = UDim2.fromScale(0.5, 1),
		Palette = props.Palette or "Orange",
		Border = 0,
		Radius = 4,
		ZIndex = 1,
	})
	local left = Kit.text({
		Parent = back,
		Size = UDim2.new(0.6, -12, 1, -6),
		Position = UDim2.fromOffset(10, 3),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		ZIndex = 3,
	})
	local right = Kit.text({
		Parent = back,
		Size = UDim2.new(0.5, -12, 1, -6),
		Position = UDim2.new(0.5, 0, 0, 3),
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
		ZIndex = 3,
	})
	return back, fill, left, right
end

-- Pastille rouge "!"
function Kit.badge(parent: Instance, position: UDim2?): Frame
	local b = Kit.new("Frame", {
		Name = "Badge",
		BackgroundColor3 = rgb(240, 40, 50),
		Size = UDim2.fromOffset(30, 30),
		Position = position or UDim2.new(1, -18, 0, -12),
		ZIndex = 30,
		Visible = false,
		Parent = parent,
	}, { Kit.corner(15), Kit.stroke(3, Color3.new(1, 1, 1)) })
	Kit.text({ Parent = b, Size = UDim2.fromScale(1, 0.9), Text = "!", ZIndex = 31, Stroke = 2 })
	return b
end

-- Petite étiquette inclinée ("VALUE!", "OP", "BEST")
function Kit.tag(props: { [string]: any }): TextLabel
	return Kit.text({
		Parent = props.Parent,
		Text = props.Text,
		Size = props.Size or UDim2.fromOffset(90, 30),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Rotation = props.Rotation or 12,
		TextColor3 = props.Color or Kit.Colors.Yellow,
		StrokeColor = props.StrokeColor or rgb(90, 20, 10),
		Stroke = props.Stroke or 3,
		ZIndex = props.ZIndex or 25,
	})
end

function Kit.pop(gui: GuiObject, scale: UIScale?)
	local s = scale or gui:FindFirstChildOfClass("UIScale") or Kit.new("UIScale", { Parent = gui })
	s.Scale = 0.6
	TweenService:Create(s, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

function Kit.clear(frame: Instance)
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

function Kit.formatNumber(n: number): string
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end
	return formatted
end

function Kit.formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then
		return ("%dh %02dm"):format(h, m)
	end
	return ("%dm %02ds"):format(m, s)
end

return Kit
