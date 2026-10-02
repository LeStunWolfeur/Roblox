--[[
	Présentoir de carte dont le look dépend de la rareté :
	  Common    : socle gris
	  Uncommon  : liseré vert
	  Rare      : liseré bleu + lumière
	  Epic      : violet + lumière + rayon lumineux
	  Legendary : or + lumière + rayon + étincelles
	  Mythic    : rose + lumière + rayon + étincelles
	  Secret    : noir et blanc + tout le reste
	Utilisé dans les boutiques (cartes à voler) et dans les bases (cartes exposées).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cards = require(ReplicatedStorage.Shared.Cards)
local Props = require(script.Parent.Props)

local Showcase = {}

local part = Props.part
local EMPTY = Color3.fromRGB(150, 155, 175)
local BODY = Color3.fromRGB(225, 228, 238)

-- cf : centre du socle au sol. Renvoie un objet présentoir.
function Showcase.build(cf: CFrame, parent: Instance, name: string?)
	local folder = Instance.new("Folder")
	folder.Name = name or "Showcase"
	folder.Parent = parent

	local base = part({ Name = "Base", Size = Vector3.new(6, 1.2, 6), CFrame = cf * CFrame.new(0, 0.6, 0), Color = Color3.fromRGB(60, 62, 78), Studs = "top" }, folder)
	local body = part({ Name = "Body", Size = Vector3.new(4.6, 2.4, 4.6), CFrame = cf * CFrame.new(0, 2.4, 0), Color = BODY, Studs = "all" }, folder)
	local rim = part({ Name = "Rim", Size = Vector3.new(5.2, 0.5, 5.2), CFrame = cf * CFrame.new(0, 3.85, 0), Color = EMPTY, Material = Enum.Material.Neon }, folder)
	local top = part({ Name = "Top", Size = Vector3.new(4.8, 0.4, 4.8), CFrame = cf * CFrame.new(0, 4.3, 0), Color = Color3.fromRGB(235, 235, 245), Studs = "top" }, folder)
	-- 4 petites colonnes dorées aux coins
	for _, c in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
		part({ Name = "Corner", Size = Vector3.new(0.6, 2.6, 0.6), CFrame = cf * CFrame.new(c[1] * 2.6, 2.5, c[2] * 2.6), Color = Props.GOLD, Material = Enum.Material.Metal }, folder)
	end
	-- rayon lumineux (Epic et plus)
	local beam = part({
		Name = "Beam",
		Size = Vector3.new(16, 3.4, 3.4),
		Shape = Enum.PartType.Cylinder,
		CFrame = cf * CFrame.new(0, 12.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = EMPTY,
		Material = Enum.Material.Neon,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
	}, folder)
	local light = Instance.new("PointLight")
	light.Range = 14
	light.Brightness = 1.6
	light.Enabled = false
	light.Parent = rim
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Rate = 0
	sparkles.Lifetime = NumberRange.new(1, 1.8)
	sparkles.Speed = NumberRange.new(2, 4)
	sparkles.SpreadAngle = Vector2.new(30, 30)
	sparkles.Size = NumberSequence.new(0.5, 0)
	sparkles.LightEmission = 1
	sparkles.Parent = top

	return {
		Folder = folder,
		Base = base,
		Body = body,
		Rim = rim,
		Top = top,
		Beam = beam,
		Light = light,
		Sparkles = sparkles,
		-- où poser la carte (elle regarde vers -Z du cf, donc vers l'entrée si cf est bien orienté)
		CardCFrame = cf * CFrame.new(0, 7.6, 0) * CFrame.Angles(0, math.pi, 0),
	}
end

-- rarity = nil pour un présentoir vide
function Showcase.style(s, rarity: string?)
	local r = rarity and Cards.Rarities[rarity]
	if not r then
		s.Body.Color = BODY
		s.Rim.Color = EMPTY
		s.Beam.Transparency = 1
		s.Light.Enabled = false
		s.Sparkles.Rate = 0
		return
	end
	local order = r.Order
	local color = r.Color
	if rarity == "Secret" then
		color = Color3.fromRGB(240, 240, 255)
		s.Body.Color = Color3.fromRGB(15, 15, 20)
	else
		-- le corps prend une teinte claire de la rareté
		s.Body.Color = color:Lerp(Color3.new(1, 1, 1), 0.55)
	end
	s.Rim.Color = color
	s.Light.Color = color
	s.Light.Enabled = order >= 3
	s.Beam.Color = color
	s.Beam.Transparency = order >= 4 and 0.75 or 1
	s.Sparkles.Color = ColorSequence.new(color)
	s.Sparkles.Rate = order >= 5 and (order - 4) * 6 or 0
end

return Showcase
