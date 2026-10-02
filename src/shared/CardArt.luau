--[[
	Face d'une carte, dessinée avec des objets d'interface.
	Utilisée sur les cartes 3D (SurfaceGui) et dans l'interface (labo, vente, révélation).

	Mise en page, façon carte à collectionner :
	  cadre métallisé (couleur de la rareté, ou de la finition : or, arc-en-ciel...)
	  en haut : nom + revenu
	  fenêtre d'illustration : halo + portrait de la créature de la carte
	  ruban de rareté avec des étoiles
	  encart : finition et note
	  bas : numéro de la carte et nom du set
	  étiquette de note (façon carte gradée) en haut à droite quand la carte est notée
]]

local CollectionService = game:GetService("CollectionService")

local Cards = require(script.Parent.Cards)
local Entity = require(script.Parent.Entity)
local Format = require(script.Parent.Format)

local CardArt = {}

local INK = Color3.fromRGB(18, 18, 26)
local WHITE = Color3.new(1, 1, 1)
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local NUMBER = {}
for i, c in Cards.List do
	NUMBER[c.Id] = i
end

local function make(className: string, props: { [string]: any }, parent: Instance?)
	local inst = Instance.new(className)
	for k, v in props do
		(inst :: any)[k] = v
	end
	inst.Parent = parent
	return inst
end

local function corner(parent: Instance, scale: number)
	make("UICorner", { CornerRadius = UDim.new(scale, 0) }, parent)
end

local function text(parent: Instance, props: { [string]: any }, stroke: number?): TextLabel
	local p = {
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		TextColor3 = WHITE,
	}
	for k, v in props do
		p[k] = v
	end
	local l = make("TextLabel", p, parent)
	if stroke then
		make("UIStroke", { Thickness = stroke, Color = INK, LineJoinMode = Enum.LineJoinMode.Round }, l)
	end
	return l
end

local function gradient(parent: Instance, colors: { Color3 }, rotation: number)
	local keys = {}
	for i, c in colors do
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / math.max(#colors - 1, 1), c))
	end
	if #colors == 1 then
		table.insert(keys, ColorSequenceKeypoint.new(1, colors[1]))
	end
	return make("UIGradient", { Color = ColorSequence.new(keys), Rotation = rotation }, parent)
end

-- couleurs du cadre selon la finition (sinon la rareté)
local function frameColors(rarity, finish: string?): { Color3 }
	if finish == "Gold" then
		return { rgb(255, 245, 170), rgb(255, 200, 50), rgb(190, 120, 20), rgb(255, 230, 120) }
	elseif finish == "Rainbow" then
		return { rgb(255, 90, 90), rgb(255, 200, 60), rgb(90, 230, 110), rgb(70, 160, 255), rgb(190, 90, 255) }
	elseif finish == "DarkMatter" then
		return { rgb(150, 70, 255), rgb(30, 10, 50), rgb(110, 40, 200), rgb(20, 5, 35) }
	elseif finish == "Holo" then
		return { rgb(200, 250, 255), rgb(150, 200, 255), rgb(230, 170, 255), rgb(160, 240, 230) }
	elseif finish == "Haunted" then
		return { rgb(255, 160, 60), rgb(60, 30, 60), rgb(255, 120, 20) }
	elseif finish == "Frozen" then
		return { rgb(240, 252, 255), rgb(150, 220, 255), rgb(90, 160, 230) }
	end
	local c = rarity.Color
	if rarity.Name == "Secret" then
		return { rgb(90, 90, 100), rgb(20, 20, 26), rgb(160, 160, 175), rgb(10, 10, 14) }
	end
	return { c:Lerp(WHITE, 0.55), c, c:Lerp(INK, 0.35), c:Lerp(WHITE, 0.25) }
end

local function circle(parent: Instance, x: number, y: number, w: number, h: number, color: Color3, z: number, transparency: number?): Frame
	local f = make("Frame", {
		Size = UDim2.fromScale(w, h),
		Position = UDim2.fromScale(x, y),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color,
		BackgroundTransparency = transparency or 0,
		BorderSizePixel = 0,
		ZIndex = z,
	}, parent)
	corner(f, 0.5)
	return f
end

local function box(parent: Instance, x: number, y: number, w: number, h: number, color: Color3, z: number, radius: number?, rotation: number?): Frame
	local f = make("Frame", {
		Size = UDim2.fromScale(w, h),
		Position = UDim2.fromScale(x, y),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Rotation = rotation or 0,
		ZIndex = z,
	}, parent)
	if radius then
		corner(f, radius)
	end
	return f
end

-- Portrait 2D de la créature (mêmes formes et couleurs que le modèle 3D)
local function portrait(parent: Frame, id: string, finish: string?, z: number)
	local t = Entity.traits(id, finish)
	-- le portrait est dessiné dans un carré centré en bas de la fenêtre
	local holder = make("Frame", {
		Size = UDim2.fromScale(0.86, 0.86),
		Position = UDim2.fromScale(0.5, 0.56),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = z,
	}, parent)
	make("UIAspectRatioConstraint", { AspectRatio = 1 }, holder)
	local body, belly = t.Body, t.Belly
	local dark = body:Lerp(INK, 0.35)
	local outline = INK
	local function shape(x, y, w, h, color, zz, radius)
		local f = box(holder, x, y, w, h, color, zz, radius)
		make("UIStroke", { Thickness = 2, Color = outline, Transparency = 0.2 }, f)
		return f
	end
	-- jambes
	shape(0.38, 0.92, 0.13, 0.14, dark, z + 1, 0.3)
	shape(0.62, 0.92, 0.13, 0.14, dark, z + 1, 0.3)
	local headY, headR
	if t.Shape == 1 then
		shape(0.5, 0.58, 0.7, 0.7, body, z + 2, 0.5)
		headY, headR = 0.52, 0.3
	elseif t.Shape == 2 then
		shape(0.5, 0.58, 0.66, 0.62, body, z + 2, 0.16)
		headY, headR = 0.5, 0.28
	elseif t.Shape == 3 then
		shape(0.5, 0.52, 0.5, 0.8, body, z + 2, 0.22)
		headY, headR = 0.36, 0.22
	else
		shape(0.5, 0.68, 0.66, 0.5, body, z + 2, 0.5)
		shape(0.5, 0.34, 0.52, 0.48, body, z + 3, 0.5)
		headY, headR = 0.34, 0.24
	end
	-- bras
	shape(0.5 - headR - 0.12, headY + 0.24, 0.1, 0.22, body:Lerp(INK, 0.15), z + 1, 0.4)
	shape(0.5 + headR + 0.12, headY + 0.24, 0.1, 0.22, body:Lerp(INK, 0.15), z + 1, 0.4)
	-- ventre
	if t.Shape ~= 4 then
		box(holder, 0.5, headY + 0.27, headR * 1.1, headR * 0.8, belly, z + 3, 0.45)
	else
		box(holder, 0.5, 0.72, 0.36, 0.26, belly, z + 4, 0.45)
	end
	-- yeux
	local secret = t.Rarity == "Secret"
	local es = 0.15 * t.EyeSize
	for _, side in { -1, 1 } do
		local ex = 0.5 + side * headR * 0.45
		local eye = circle(holder, ex, headY - 0.02, es, es, secret and rgb(255, 60, 60) or WHITE, z + 5)
		make("UIStroke", { Thickness = 2, Color = outline }, eye)
		if not secret then
			circle(holder, ex + side * 0.01, headY, es * 0.5, es * 0.5, INK, z + 6)
			circle(holder, ex - 0.01, headY - 0.035, es * 0.18, es * 0.18, WHITE, z + 7)
		end
		if t.EyeStyle == 2 then
			box(holder, ex, headY - 0.02 - es * 0.25, es * 1.08, es * 0.5, body:Lerp(INK, 0.2), z + 7, 0.3)
		elseif t.EyeStyle == 3 then
			box(holder, ex, headY - es * 0.8, es * 1.1, 0.025, INK, z + 7, nil, side * -18)
		end
	end
	-- bouche
	box(holder, 0.5, headY + 0.11, headR * 0.5, 0.05, INK, z + 5, 0.5)
	-- accessoires selon la rareté
	local r = t.Rarity
	local top = headY - headR - 0.04
	if t.Shape == 3 then
		top = 0.14
	elseif t.Shape == 4 then
		top = 0.12
	elseif t.Shape == 2 then
		top = 0.28
	else
		top = 0.24
	end
	if r == "Uncommon" then
		box(holder, 0.5, top - 0.04, 0.26, 0.08, rgb(60, 60, 70), z + 6, 0.2)
		box(holder, 0.5, top - 0.1, 0.16, 0.1, rgb(60, 60, 70), z + 6, 0.2)
	elseif r == "Rare" then
		box(holder, 0.32, top - 0.02, 0.07, 0.16, rgb(250, 245, 230), z + 1, 0.4, -20)
		box(holder, 0.68, top - 0.02, 0.07, 0.16, rgb(250, 245, 230), z + 1, 0.4, 20)
	elseif r == "Epic" then
		box(holder, 0.14, 0.5, 0.2, 0.32, rgb(230, 220, 255), z + 1, 0.5, -25)
		box(holder, 0.86, 0.5, 0.2, 0.32, rgb(230, 220, 255), z + 1, 0.5, 25)
	elseif r == "Legendary" then
		local crown = box(holder, 0.5, top - 0.03, 0.3, 0.09, rgb(255, 200, 40), z + 6, 0.15)
		make("UIStroke", { Thickness = 2, Color = outline }, crown)
		for k = -1, 1 do
			box(holder, 0.5 + k * 0.1, top - 0.09, 0.07, 0.07, rgb(255, 200, 40), z + 5, 0.15, 45)
		end
		box(holder, 0.5, top - 0.03, 0.05, 0.05, rgb(230, 40, 70), z + 7, 0.5)
	elseif r == "Mythic" then
		local halo = circle(holder, 0.5, top - 0.08, 0.34, 0.08, rgb(255, 240, 150), z + 1, 1)
		make("UIStroke", { Thickness = 3, Color = rgb(255, 225, 100) }, halo)
		box(holder, 0.12, 0.48, 0.2, 0.36, rgb(255, 150, 210), z + 1, 0.5, -25)
		box(holder, 0.88, 0.48, 0.2, 0.36, rgb(255, 150, 210), z + 1, 0.5, 25)
	elseif r == "Secret" then
		for k = 0, 2 do
			circle(holder, 0.16 + k * 0.34, 0.14 + (k % 2) * 0.06, 0.07, 0.07, rgb(255, 60, 60), z + 1)
		end
	end
	return holder
end

-- options.hidden = carte pas encore découverte (silhouette)
-- options.grade = note à afficher
-- options.strokeThickness = épaisseur du contour extérieur
function CardArt.build(parent: Instance, id: string, finish: string?, options: { [string]: any }?): Frame
	local opts = options or {}
	local card = Cards.ById[id]
	local rarity = Cards.Rarities[card.Rarity]
	local f = Cards.Finishes[finish or "Normal"] or Cards.Finishes.Normal
	local hidden = opts.hidden == true
	local z0 = opts.zIndex or 1

	-- cadre métallisé
	local root = make("Frame", {
		Name = "CardFace",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = z0,
	}, parent)
	corner(root, 0.05)
	make("UIStroke", { Thickness = opts.strokeThickness or 4, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, root)
	gradient(root, hidden and { rgb(70, 72, 84), rgb(40, 42, 52) } or frameColors(rarity, finish), 45)

	-- carte intérieure
	local inner = make("Frame", {
		Name = "Inner",
		Size = UDim2.fromScale(0.9, 0.93),
		Position = UDim2.fromScale(0.05, 0.035),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = z0 + 1,
	}, root)
	corner(inner, 0.04)
	local base = hidden and rgb(30, 31, 40) or rarity.Color:Lerp(INK, 0.72)
	gradient(inner, { base:Lerp(WHITE, 0.12), base, base:Lerp(INK, 0.4) }, 90)
	local z = z0 + 2

	-- en-tête : nom + revenu
	text(inner, {
		Size = UDim2.fromScale(0.58, 0.08),
		Position = UDim2.fromScale(0.04, 0.02),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = hidden and "???" or card.Name,
		ZIndex = z,
	}, 1.5)
	text(inner, {
		Size = UDim2.fromScale(0.34, 0.06),
		Position = UDim2.fromScale(0.63, 0.03),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = rgb(110, 255, 110),
		Text = hidden and "" or (Format.cash(Cards.IncomeOf(id, finish, opts.grade)) .. "/s"),
		ZIndex = z,
	}, 1.5)

	-- fenêtre d'illustration
	local art = make("Frame", {
		Name = "Art",
		Size = UDim2.fromScale(0.92, 0.5),
		Position = UDim2.fromScale(0.04, 0.115),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = z,
	}, inner)
	corner(art, 0.05)
	make("UIStroke", { Thickness = 2, Color = hidden and rgb(80, 82, 95) or rarity.Color:Lerp(WHITE, 0.4) }, art)
	if hidden then
		gradient(art, { rgb(45, 46, 58), rgb(25, 26, 34) }, 90)
		text(art, { Size = UDim2.fromScale(0.6, 0.7), Position = UDim2.fromScale(0.2, 0.15), Text = "?", TextColor3 = rgb(80, 82, 98), ZIndex = z + 1 })
	else
		gradient(art, { card.A:Lerp(WHITE, 0.35), card.A, card.B }, 125)
		-- halo derrière la créature
		for k, s in { 1.25, 0.95, 0.68 } do
			local ring = circle(art, 0.5, 0.58, s, s * 1.0, WHITE, z + 1, 0.82 - k * 0.04)
			make("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, ring)
		end
		if card.Image ~= "" then
			make("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = card.Image, ScaleType = Enum.ScaleType.Crop, ZIndex = z + 2 }, art)
		else
			portrait(art, id, finish, z + 2)
		end
	end

	-- ruban de rareté avec étoiles
	local ribbon = make("Frame", {
		Name = "Ribbon",
		Size = UDim2.fromScale(1.02, 0.075),
		Position = UDim2.fromScale(-0.01, 0.63),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = z,
	}, inner)
	gradient(ribbon, hidden and { rgb(80, 80, 92), rgb(50, 50, 60) } or { rarity.Color:Lerp(WHITE, 0.35), rarity.Color, rarity.Color:Lerp(INK, 0.3) }, 0)
	make("UIStroke", { Thickness = 1.5, Color = INK }, ribbon)
	text(ribbon, {
		Size = UDim2.fromScale(0.5, 0.8),
		Position = UDim2.fromScale(0.05, 0.1),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = hidden and "UNKNOWN" or rarity.Name:upper(),
		ZIndex = z + 1,
	}, 1.5)
	if not hidden then
		for k = 1, rarity.Order do
			local star = box(ribbon, 0.95 - (k - 1) * 0.055, 0.5, 0.035, 0.45, rgb(255, 245, 200), z + 1, 0.15, 45)
			make("UIAspectRatioConstraint", { AspectRatio = 1 }, star)
			make("UIStroke", { Thickness = 1, Color = INK }, star)
		end
	end

	-- encart : finition + note
	local info = make("Frame", {
		Name = "Info",
		Size = UDim2.fromScale(0.92, 0.17),
		Position = UDim2.fromScale(0.04, 0.725),
		BackgroundColor3 = rgb(0, 0, 0),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ZIndex = z,
	}, inner)
	corner(info, 0.12)
	local finishLine
	if hidden then
		finishLine = "Find it in the shops"
	elseif f.Name ~= "" then
		finishLine = ("%s finish  x%s"):format(f.Name, tostring(f.Mult))
	else
		finishLine = "Standard finish"
	end
	text(info, {
		Size = UDim2.fromScale(0.92, 0.4),
		Position = UDim2.fromScale(0.04, 0.08),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = (f.Name ~= "" and not hidden) and (f.Color or WHITE) or rgb(220, 222, 235),
		Text = finishLine,
		ZIndex = z + 1,
	}, 1)
	local gradeLine = "Not graded yet"
	if opts.grade and not hidden then
		gradeLine = ("Grade %d  ·  %s  x%s"):format(opts.grade, Cards.GradeNames[opts.grade], tostring(Cards.GradeMult[opts.grade]))
	elseif hidden then
		gradeLine = ""
	end
	text(info, {
		Size = UDim2.fromScale(0.92, 0.36),
		Position = UDim2.fromScale(0.04, 0.54),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = rgb(200, 205, 220),
		Text = gradeLine,
		ZIndex = z + 1,
	}, 1)

	-- bas : numéro et set
	text(inner, {
		Size = UDim2.fromScale(0.4, 0.045),
		Position = UDim2.fromScale(0.05, 0.925),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = rgb(200, 205, 220),
		Text = ("#%03d/%03d"):format(NUMBER[id] or 0, #Cards.List),
		ZIndex = z,
	})
	text(inner, {
		Size = UDim2.fromScale(0.5, 0.045),
		Position = UDim2.fromScale(0.45, 0.925),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = rgb(200, 205, 220),
		Text = card.Season and Cards.Seasons[card.Season].Name:upper() or "BASE SET",
		ZIndex = z,
	})

	-- étiquette de note (façon carte gradée)
	if opts.grade and not hidden then
		local gem = opts.grade >= 10
		local slab = make("Frame", {
			Name = "GradeSlab",
			Size = UDim2.fromScale(0.3, 0.13),
			Position = UDim2.fromScale(0.97, 0.13),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			ZIndex = z0 + 8,
		}, root)
		corner(slab, 0.15)
		make("UIStroke", { Thickness = 2, Color = gem and rgb(220, 30, 60) or INK }, slab)
		local band = make("Frame", { Size = UDim2.fromScale(1, 0.32), BackgroundColor3 = gem and rgb(220, 30, 60) or rgb(40, 40, 52), BorderSizePixel = 0, ZIndex = z0 + 9 }, slab)
		corner(band, 0.2)
		text(band, { Size = UDim2.fromScale(0.9, 0.9), Position = UDim2.fromScale(0.05, 0.05), Text = "GRADE", ZIndex = z0 + 10 })
		text(slab, {
			Size = UDim2.fromScale(0.9, 0.62),
			Position = UDim2.fromScale(0.05, 0.34),
			Text = tostring(opts.grade),
			TextColor3 = gem and rgb(220, 30, 60) or INK,
			ZIndex = z0 + 10,
		})
	end

	-- reflet animé pour les finitions (animé côté client grâce au tag)
	if f.Name ~= "" and not hidden then
		local shine = make("Frame", {
			Name = "Shine",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = f.Color or WHITE,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			ZIndex = z0 + 7,
		}, root)
		local grad = make("UIGradient", {
			Rotation = 25,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.4, 1),
				NumberSequenceKeypoint.new(0.5, finish == "DarkMatter" and 0.3 or 0.5),
				NumberSequenceKeypoint.new(0.6, 1),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Offset = Vector2.new(-1, 0),
		}, shine)
		if finish == "Rainbow" then
			local keys = {}
			for i = 0, 6 do
				table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.7, 1)))
			end
			grad.Color = ColorSequence.new(keys)
			shine.BackgroundColor3 = WHITE
		end
		CollectionService:AddTag(grad, "CardShine")
	end

	return root
end

-- Carte 3D : une plaque fine avec la face des deux côtés (ou seulement devant)
function CardArt.part(id: string, finish: string?, grade: number?, twoSided: boolean?): BasePart
	local part = Instance.new("Part")
	part.Name = "Card_" .. id
	part.Size = Vector3.new(4, 5.6, 0.2)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Cards.Rarities[Cards.ById[id].Rarity].Color
	part:SetAttribute("CardId", id)
	part:SetAttribute("Finish", finish or "Normal")
	local faces = twoSided and { Enum.NormalId.Front, Enum.NormalId.Back } or { Enum.NormalId.Front }
	for _, face in faces do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 50
		gui.LightInfluence = 0.15
		gui.Parent = part
		CardArt.build(gui, id, finish, { grade = grade, strokeThickness = 5 })
	end
	return part
end

return CardArt
