--[[
	Grandes cartes 3D posées sur les présentoirs (boutiques et bases).
	- Bordure lumineuse à la couleur de la rareté (sauf Common).
	- Aura de particules dont l'intensité monte avec la rareté, lumière dès Rare.
	- Effet propre à chaque mutation : paillettes d'or, éclats de diamant, arc-en-ciel,
	  fumée de matière noire, reflets holo, feux follets hantés, flocons gelés.
	- Étiquette nom / rareté / revenu au-dessus.
	Le client fait tourner et flotter doucement les cartes (tag "DisplayCard").

	CardDisplay.build(id, finish, grade, cf, scale, parent) -> Model, carte
	CardDisplay.decorate(part, id, finish, scale) : ajoute aura et effets à une carte
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cards = require(ReplicatedStorage.Shared.Cards)
local CardArt = require(ReplicatedStorage.Shared.CardArt)
local Nameplate = require(ReplicatedStorage.Shared.Nameplate)

local CardDisplay = {}

CardDisplay.WIDTH = 4.6
CardDisplay.HEIGHT = 6.44

local AURA_RATE = { Common = 0, Uncommon = 2, Rare = 5, Epic = 9, Legendary = 14, Mythic = 20, Secret = 26 }

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function emitter(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.LightEmission = 1
	e.Lifetime = NumberRange.new(1, 2)
	e.Speed = NumberRange.new(0.5, 1.5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new(0.35, 0)
	e.Transparency = NumberSequence.new(0, 1)
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

-- Effets de mutation
local MUTATION_FX = {
	Holo = function(p: BasePart, s: number)
		emitter(p, { Color = ColorSequence.new(rgb(150, 230, 255), rgb(230, 170, 255)), Rate = 6, Size = NumberSequence.new(0.3 * s, 0) })
	end,
	Gold = function(p: BasePart, s: number)
		emitter(p, { Color = ColorSequence.new(rgb(255, 225, 90)), Rate = 12, Size = NumberSequence.new(0.35 * s, 0), Speed = NumberRange.new(1, 2.5) })
	end,
	Diamond = function(p: BasePart, s: number)
		emitter(p, {
			Color = ColorSequence.new(rgb(230, 252, 255), rgb(150, 230, 255)),
			Rate = 10,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.55 * s), NumberSequenceKeypoint.new(1, 0) }),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-180, 180),
			Lifetime = NumberRange.new(0.6, 1.2),
		})
	end,
	Rainbow = function(p: BasePart, s: number)
		local keys = {}
		for i = 0, 6 do
			table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.75, 1)))
		end
		emitter(p, { Color = ColorSequence.new(keys), Rate = 16, Size = NumberSequence.new(0.45 * s, 0), Speed = NumberRange.new(1, 3) })
	end,
	DarkMatter = function(p: BasePart, s: number)
		emitter(p, {
			Color = ColorSequence.new(rgb(70, 0, 120), rgb(10, 0, 20)),
			LightEmission = 0.2,
			Rate = 10,
			Size = NumberSequence.new(1.4 * s, 2.4 * s),
			Transparency = NumberSequence.new(0.4, 1),
			Speed = NumberRange.new(0.2, 0.8),
			Lifetime = NumberRange.new(1.5, 2.5),
		})
		emitter(p, { Color = ColorSequence.new(rgb(190, 90, 255)), Rate = 6, Size = NumberSequence.new(0.3 * s, 0) })
	end,
	Haunted = function(p: BasePart, s: number)
		emitter(p, { Color = ColorSequence.new(rgb(255, 140, 30), rgb(120, 255, 90)), Rate = 8, Size = NumberSequence.new(0.6 * s, 0), Acceleration = Vector3.new(0, 2, 0) })
	end,
	Frozen = function(p: BasePart, s: number)
		emitter(p, { Color = ColorSequence.new(rgb(240, 250, 255)), LightEmission = 0.4, Rate = 10, Size = NumberSequence.new(0.3 * s, 0.2 * s), Acceleration = Vector3.new(0, -2, 0) })
	end,
}

function CardDisplay.decorate(part: BasePart, id: string, finish: string?, scale: number)
	local rarity = Cards.Rarities[Cards.ById[id].Rarity]
	local color = rarity.Name == "Secret" and rgb(255, 255, 255) or rarity.Color
	local rate = AURA_RATE[rarity.Name] or 0
	if rate > 0 then
		emitter(part, { Color = ColorSequence.new(color), Rate = rate, Size = NumberSequence.new(0.5 * scale, 0), Speed = NumberRange.new(0.6, 1.8) })
	end
	if rarity.Order >= 3 then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 10 * scale + 4
		light.Brightness = 0.6 + rarity.Order * 0.15
		light.Shadows = false
		light.Parent = part
	end
	local fx = finish and MUTATION_FX[finish]
	if fx then
		fx(part, scale)
	end
end

function CardDisplay.build(id: string, finish: string?, grade: number?, cf: CFrame, scale: number, parent: Instance): (Model, BasePart)
	local rarity = Cards.Rarities[Cards.ById[id].Rarity]
	local model = Instance.new("Model")
	model.Name = "Display"
	local w, h = CardDisplay.WIDTH * scale, CardDisplay.HEIGHT * scale
	local card = CardArt.part(id, finish, grade, true)
	card.Size = Vector3.new(w, h, 0.16 * scale + 0.05)
	card.CFrame = cf
	card.Parent = model
	model.PrimaryPart = card
	card:SetAttribute("BaseCFrame", cf)
	CollectionService:AddTag(card, "DisplayCard")

	-- bordure lumineuse (4 baguettes autour de la carte)
	if rarity.Order >= 2 then
		local color = rarity.Name == "Secret" and rgb(255, 255, 255) or rarity.Color
		local t = 0.18 * scale + 0.05
		for _, b in {
			{ Vector3.new(w + t * 2, t, card.Size.Z + 0.06), CFrame.new(0, h / 2 + t / 2, 0) },
			{ Vector3.new(w + t * 2, t, card.Size.Z + 0.06), CFrame.new(0, -h / 2 - t / 2, 0) },
			{ Vector3.new(t, h, card.Size.Z + 0.06), CFrame.new(w / 2 + t / 2, 0, 0) },
			{ Vector3.new(t, h, card.Size.Z + 0.06), CFrame.new(-w / 2 - t / 2, 0, 0) },
		} do
			local bar = Instance.new("Part")
			bar.Name = "Edge"
			bar.Anchored = false
			bar.Massless = true
			bar.CanCollide = false
			bar.CanQuery = false
			bar.CanTouch = false
			bar.Material = Enum.Material.Neon
			bar.Color = color
			bar.Size = b[1]
			bar.CFrame = cf * b[2]
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = card
			weld.Part1 = bar
			weld.Parent = bar
			bar.Parent = model
		end
	end
	CardDisplay.decorate(card, id, finish, scale)
	Nameplate.attach(card, id, finish, grade, Vector3.new(0, h / 2 + 2.2 * scale + 0.6, 0))
	model.Parent = parent
	return model, card
end

return CardDisplay
