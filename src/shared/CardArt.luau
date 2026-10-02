-- Dessine la face d'une carte avec des objets d'interface.
-- Utilisé sur les cartes 3D (SurfaceGui) et dans l'interface (révélation, index).

local CollectionService = game:GetService("CollectionService")

local Cards = require(script.Parent.Cards)
local Format = require(script.Parent.Format)

local CardArt = {}

local function initials(name: string): string
	local out = ""
	for word in name:gmatch("[%w]+") do
		if word ~= "The" then
			out ..= word:sub(1, 1):upper()
		end
		if #out >= 2 then
			break
		end
	end
	return out
end

local function make(className: string, props: { [string]: any }, parent: Instance?)
	local inst = Instance.new(className)
	for k, v in props do
		(inst :: any)[k] = v
	end
	inst.Parent = parent
	return inst
end

-- options.hidden = carte pas encore découverte (silhouette)
-- options.grade = note à afficher
function CardArt.build(parent: Instance, id: string, finish: string?, options: { [string]: any }?): Frame
	local opts = options or {}
	local card = Cards.ById[id]
	local rarity = Cards.Rarities[card.Rarity]
	local f = Cards.Finishes[finish or "Normal"] or Cards.Finishes.Normal
	local hidden = opts.hidden == true

	local root = make("Frame", {
		Name = "CardFace",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = hidden and Color3.fromRGB(40, 40, 50) or card.A,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = opts.zIndex or 1,
	}, parent)
	local z = root.ZIndex
	make("UICorner", { CornerRadius = UDim.new(0.06, 0) }, root)
	make("UIStroke", {
		Thickness = opts.strokeThickness or 4,
		Color = rarity.Color,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, root)
	if not hidden then
		make("UIGradient", {
			Color = ColorSequence.new(card.A, card.B),
			Rotation = 125,
		}, root)
	end

	-- bandeau du nom
	local nameBar = make("Frame", {
		Size = UDim2.new(0.9, 0, 0.12, 0),
		Position = UDim2.fromScale(0.05, 0.04),
		BackgroundColor3 = Color3.fromRGB(20, 20, 30),
		BackgroundTransparency = 0.15,
		ZIndex = z + 1,
	}, root)
	make("UICorner", { CornerRadius = UDim.new(0.3, 0) }, nameBar)
	make("TextLabel", {
		Size = UDim2.fromScale(0.92, 0.8),
		Position = UDim2.fromScale(0.04, 0.1),
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		Text = hidden and "???" or card.Name,
		ZIndex = z + 2,
	}, nameBar)

	-- illustration
	local art = make("Frame", {
		Size = UDim2.fromScale(0.84, 0.56),
		Position = UDim2.fromScale(0.08, 0.19),
		BackgroundColor3 = hidden and Color3.fromRGB(25, 25, 32) or card.B,
		ZIndex = z + 1,
	}, root)
	make("UICorner", { CornerRadius = UDim.new(0.06, 0) }, art)
	make("UIStroke", { Thickness = 2, Color = Color3.fromRGB(20, 20, 30) }, art)
	if hidden then
		make("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			TextScaled = true,
			TextColor3 = Color3.fromRGB(70, 70, 85),
			Text = "?",
			ZIndex = z + 2,
		}, art)
	elseif card.Image ~= "" then
		make("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = card.Image,
			ScaleType = Enum.ScaleType.Crop,
			ZIndex = z + 2,
		}, art)
	else
		make("UIGradient", {
			Color = ColorSequence.new(card.B, card.A),
			Rotation = -60,
		}, art)
		-- motif : grand disque + losange + monogramme
		local disc = make("Frame", {
			Size = UDim2.fromScale(0.78, 0.78),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = card.A,
			ZIndex = z + 2,
		}, art)
		make("UIAspectRatioConstraint", { AspectRatio = 1 }, disc)
		make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, disc)
		make("UIStroke", { Thickness = 3, Color = Color3.fromRGB(20, 20, 30), Transparency = 0.3 }, disc)
		local diamond = make("Frame", {
			Size = UDim2.fromScale(0.62, 0.62),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = 45,
			BackgroundColor3 = card.B,
			BackgroundTransparency = 0.2,
			ZIndex = z + 3,
		}, disc)
		make("UICorner", { CornerRadius = UDim.new(0.12, 0) }, diamond)
		local mono = make("TextLabel", {
			Size = UDim2.fromScale(0.8, 0.8),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			TextScaled = true,
			TextColor3 = Color3.new(1, 1, 1),
			Text = initials(card.Name),
			ZIndex = z + 4,
		}, disc)
		make("UIStroke", { Thickness = 3, Color = Color3.fromRGB(20, 20, 30) }, mono)
	end

	-- bas de carte : rareté + revenu
	local footer = make("Frame", {
		Size = UDim2.new(0.9, 0, 0.17, 0),
		Position = UDim2.fromScale(0.05, 0.79),
		BackgroundColor3 = rarity.Color,
		ZIndex = z + 1,
	}, root)
	make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, footer)
	make("UIStroke", { Thickness = 2, Color = Color3.fromRGB(20, 20, 30) }, footer)
	local rarityText = rarity.Name:upper()
	if f.Name ~= "" and not hidden then
		rarityText = f.Name:upper() .. "  ·  " .. rarityText
	end
	local rl = make("TextLabel", {
		Size = UDim2.fromScale(0.94, 0.5),
		Position = UDim2.fromScale(0.03, 0.05),
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		Text = rarityText,
		ZIndex = z + 2,
	}, footer)
	make("UIStroke", { Thickness = 1.5, Color = Color3.fromRGB(20, 20, 30) }, rl)
	make("TextLabel", {
		Size = UDim2.fromScale(0.94, 0.4),
		Position = UDim2.fromScale(0.03, 0.55),
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(20, 20, 30),
		Text = hidden and "" or (Format.cash(Cards.IncomeOf(id, finish, opts.grade)) .. "/s"),
		ZIndex = z + 2,
	}, footer)

	-- note de condition (en haut à droite, façon étiquette de carte gradée)
	if opts.grade and not hidden then
		local slab = make("Frame", {
			Size = UDim2.fromScale(0.26, 0.13),
			Position = UDim2.fromScale(0.72, 0.17),
			BackgroundColor3 = opts.grade == 10 and Color3.fromRGB(255, 70, 110) or Color3.fromRGB(250, 247, 240),
			Rotation = 8,
			ZIndex = z + 6,
		}, root)
		make("UICorner", { CornerRadius = UDim.new(0.2, 0) }, slab)
		make("UIStroke", { Thickness = 2, Color = Color3.fromRGB(20, 20, 30) }, slab)
		make("TextLabel", {
			Size = UDim2.fromScale(0.9, 0.9),
			Position = UDim2.fromScale(0.05, 0.05),
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			TextScaled = true,
			TextColor3 = opts.grade == 10 and Color3.new(1, 1, 1) or Color3.fromRGB(20, 20, 30),
			Text = "G" .. opts.grade,
			ZIndex = z + 7,
		}, slab)
	end

	-- reflet animé pour les finitions (animé côté client grâce au tag)
	if f.Name ~= "" and not hidden then
		local shine = make("Frame", {
			Name = "Shine",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = f.Color or Color3.new(1, 1, 1),
			BackgroundTransparency = 0,
			ZIndex = z + 5,
		}, root)
		local grad = make("UIGradient", {
			Rotation = 25,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.4, 1),
				NumberSequenceKeypoint.new(0.5, finish == "DarkMatter" and 0.25 or 0.45),
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
			shine.BackgroundColor3 = Color3.new(1, 1, 1)
		end
		CollectionService:AddTag(grad, "CardShine")
	end

	return root
end

-- Crée une carte 3D (une plaque fine avec la face des deux côtés)
-- twoSided = face visible des deux côtés (tapis), sinon seulement la face avant
function CardArt.part(id: string, finish: string?, grade: number?, twoSided: boolean?): BasePart
	local part = Instance.new("Part")
	part.Name = "Card_" .. id
	part.Size = Vector3.new(4, 5.6, 0.25)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Cards.ById[id].A
	part:SetAttribute("CardId", id)
	part:SetAttribute("Finish", finish or "Normal")
	local faces = twoSided and { Enum.NormalId.Front, Enum.NormalId.Back } or { Enum.NormalId.Front }
	for _, face in faces do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 45
		gui.LightInfluence = 0.2
		gui.Parent = part
		CardArt.build(gui, id, finish, { grade = grade, strokeThickness = 6 })
	end
	return part
end

return CardArt
