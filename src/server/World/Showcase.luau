--[[
	Présentoir rond (boutiques et bases). La grande carte flotte au-dessus.
	Look selon la rareté de la carte posée :
	  anneau lumineux et plateau à la couleur de la rareté,
	  lumière dès Rare, rayon lumineux dès Epic, étincelles dès Legendary.
	Verrouillé : gris, avec un cadenas.

	Showcase.build(cf, parent, name, scale) -> présentoir
	  cf : centre du socle au sol. La carte regarde vers -Z du cf.
	Showcase.style(s, rarity, locked)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cards = require(ReplicatedStorage.Shared.Cards)

local Showcase = {}

local EMPTY = Color3.fromRGB(150, 156, 175)
local SLATE = Color3.fromRGB(40, 44, 58)
local WHITE = Color3.fromRGB(245, 246, 250)
local LOCKED = Color3.fromRGB(95, 98, 112)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: string?): BasePart
	local p = Instance.new("Part")
	if shape == "Cylinder" then
		p.Shape = Enum.PartType.Cylinder
	elseif shape == "Ball" then
		p.Shape = Enum.PartType.Ball
	end
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local UP = CFrame.Angles(0, 0, math.rad(90)) -- un cylindre debout

function Showcase.build(cf: CFrame, parent: Instance, name: string?, scale: number?)
	local folder = Instance.new("Folder")
	folder.Name = name or "Showcase"
	folder.Parent = parent
	local k = scale or 1

	local base = part(folder, "Base", Vector3.new(0.8, 6.4, 6.4), cf * CFrame.new(0, 0.4, 0) * UP, SLATE, nil, "Cylinder")
	local rim = part(folder, "Rim", Vector3.new(0.3, 6.9, 6.9), cf * CFrame.new(0, 0.95, 0) * UP, EMPTY, Enum.Material.Neon, "Cylinder")
	rim.CanCollide = false
	local body = part(folder, "Body", Vector3.new(2.6, 4.2, 4.2), cf * CFrame.new(0, 2.4, 0) * UP, WHITE, nil, "Cylinder")
	part(folder, "Band", Vector3.new(0.4, 4.35, 4.35), cf * CFrame.new(0, 2.1, 0) * UP, SLATE, nil, "Cylinder")
	local top = part(folder, "Top", Vector3.new(0.6, 5.4, 5.4), cf * CFrame.new(0, 4.0, 0) * UP, WHITE, nil, "Cylinder")
	local glow = part(folder, "TopGlow", Vector3.new(0.12, 4.6, 4.6), cf * CFrame.new(0, 4.33, 0) * UP, EMPTY, Enum.Material.Neon, "Cylinder")
	glow.CanCollide = false

	-- rayon lumineux (Epic et plus)
	local beam = part(folder, "Beam", Vector3.new(14, 3.6, 3.6), cf * CFrame.new(0, 11.4, 0) * UP, EMPTY, Enum.Material.Neon, "Cylinder")
	beam.Transparency = 1
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.CastShadow = false

	-- cadenas (supports verrouillés)
	local lock = Instance.new("Folder")
	lock.Name = "Lock"
	lock.Parent = folder
	local lockBody = part(lock, "LockBody", Vector3.new(2, 1.6, 0.9), cf * CFrame.new(0, 5.3, 0), Color3.fromRGB(255, 200, 50), Enum.Material.Metal)
	for i = 0, 5 do
		local a = math.rad(i * 36)
		part(lock, "Shackle", Vector3.new(0.36, 0.36, 0.5), cf * CFrame.new(math.cos(a) * 0.65, 6.1 + math.sin(a) * 0.65, 0), Color3.fromRGB(200, 205, 215), Enum.Material.Metal)
	end
	part(lock, "Keyhole", Vector3.new(0.3, 0.5, 0.95), cf * CFrame.new(0, 5.2, 0), Color3.fromRGB(40, 30, 10))
	for _, p in lock:GetChildren() do
		(p :: BasePart).CanCollide = false
	end

	local light = Instance.new("PointLight")
	light.Range = 14
	light.Brightness = 1.4
	light.Enabled = false
	light.Parent = glow
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Rate = 0
	sparkles.Lifetime = NumberRange.new(1, 1.8)
	sparkles.Speed = NumberRange.new(2, 4)
	sparkles.SpreadAngle = Vector2.new(30, 30)
	sparkles.Size = NumberSequence.new(0.45, 0)
	sparkles.LightEmission = 1
	sparkles.Parent = glow

	local cardHalf = 3.22 * k
	return {
		Folder = folder,
		Base = base,
		Body = body,
		Rim = rim,
		Top = top,
		Glow = glow,
		Beam = beam,
		Lock = lock,
		LockBody = lockBody,
		Light = light,
		Sparkles = sparkles,
		-- centre de la carte (elle regarde vers -Z du cf)
		CardCFrame = cf * CFrame.new(0, 4.5 + cardHalf + 0.9, 0) * CFrame.Angles(0, math.pi, 0),
	}
end

local function setLock(s, visible: boolean)
	for _, p in s.Lock:GetChildren() do
		(p :: BasePart).Transparency = visible and 0 or 1
	end
end

-- rarity = nil pour un présentoir vide ; locked = support pas encore acheté
function Showcase.style(s, rarity: string?, locked: boolean?)
	local r = rarity and Cards.Rarities[rarity]
	setLock(s, locked == true)
	if not r then
		s.Body.Color = locked and LOCKED or Color3.fromRGB(245, 246, 250)
		s.Top.Color = locked and LOCKED or Color3.fromRGB(235, 237, 245)
		s.Rim.Color = locked and Color3.fromRGB(70, 72, 82) or EMPTY
		s.Glow.Color = locked and Color3.fromRGB(70, 72, 82) or EMPTY
		s.Beam.Transparency = 1
		s.Light.Enabled = false
		s.Sparkles.Rate = 0
		return
	end
	local order = r.Order
	local color = rarity == "Secret" and Color3.fromRGB(240, 240, 255) or r.Color
	s.Body.Color = rarity == "Secret" and Color3.fromRGB(20, 20, 26) or Color3.fromRGB(245, 246, 250)
	s.Top.Color = color:Lerp(Color3.new(1, 1, 1), 0.5)
	s.Rim.Color = color
	s.Glow.Color = color
	s.Light.Color = color
	s.Light.Enabled = order >= 3
	s.Beam.Color = color
	s.Beam.Transparency = order >= 4 and 0.8 or 1
	s.Sparkles.Color = ColorSequence.new(color)
	s.Sparkles.Rate = order >= 5 and (order - 4) * 6 or 0
end

return Showcase
