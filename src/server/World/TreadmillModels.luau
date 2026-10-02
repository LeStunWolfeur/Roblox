--[[
	Les 9 tapis de course (un look par niveau), modélisés en pièces lisses :
	châssis, rails latéraux, capot moteur, montants, console inclinée avec écran,
	guidons, bandes néon, flèches sur la bande. Puis des extras selon le niveau :
	  6 Mythic  : pointes rouges
	  7 Divine  : blanc et cyan, cristaux flottants
	  8 Ancient : bande galaxie, planètes en orbite, pointes
	  9 Supreme : or et blanc, ailes, auréole, nuages

	TreadmillModels.build(level, cf, parent) -> Model
	cf : origine au sol au centre du tapis, le coureur regarde vers -Z.
	Le dessus de la bande est à BELT_TOP au-dessus de cf.
]]

local CollectionService = game:GetService("CollectionService")

local TreadmillModels = {}

TreadmillModels.BELT_TOP = 1.65

local rad = math.rad
local V = Vector3.new
local CF = CFrame.new
local A = CFrame.Angles

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Palette de chaque niveau
-- Frame : châssis et capot, Rail : rails et montants, Accent : néons,
-- Cap : embouts, Glow : true si les accents sont en néon
local LOOKS = {
	{ Frame = rgb(48, 50, 58), Rail = rgb(190, 195, 205), Accent = rgb(150, 156, 168), Cap = rgb(120, 125, 135), Belt = rgb(28, 28, 32), Screen = rgb(70, 85, 110), Glow = false, Metal = true },
	{ Frame = rgb(30, 32, 36), Rail = rgb(62, 66, 74), Accent = rgb(80, 255, 60), Cap = rgb(90, 95, 105), Belt = rgb(24, 24, 28), Screen = rgb(60, 220, 60), Glow = true },
	{ Frame = rgb(26, 30, 40), Rail = rgb(52, 60, 78), Accent = rgb(40, 150, 255), Cap = rgb(60, 70, 95), Belt = rgb(22, 24, 30), Screen = rgb(40, 140, 255), Glow = true },
	{ Frame = rgb(36, 22, 56), Rail = rgb(70, 42, 110), Accent = rgb(175, 70, 255), Cap = rgb(90, 55, 140), Belt = rgb(24, 20, 32), Screen = rgb(160, 70, 255), Glow = true },
	{ Frame = rgb(42, 34, 22), Rail = rgb(235, 178, 45), Accent = rgb(255, 205, 70), Cap = rgb(255, 215, 90), Belt = rgb(26, 24, 22), Screen = rgb(255, 200, 60), Glow = true, Metal = true },
	{ Frame = rgb(26, 10, 12), Rail = rgb(58, 16, 20), Accent = rgb(255, 35, 45), Cap = rgb(90, 20, 26), Belt = rgb(22, 16, 18), Screen = rgb(255, 40, 50), Glow = true, Spikes = rgb(200, 25, 35) },
	{ Frame = rgb(205, 222, 232), Rail = rgb(240, 248, 252), Accent = rgb(60, 230, 255), Cap = rgb(190, 240, 255), Belt = rgb(22, 30, 38), Screen = rgb(60, 230, 255), Glow = true },
	{ Frame = rgb(32, 18, 58), Rail = rgb(78, 42, 135), Accent = rgb(200, 90, 255), Cap = rgb(120, 70, 200), Belt = rgb(18, 10, 40), Screen = rgb(190, 90, 255), Glow = true, Spikes = rgb(150, 60, 230) },
	{ Frame = rgb(250, 246, 235), Rail = rgb(240, 190, 60), Accent = rgb(255, 228, 120), Cap = rgb(255, 250, 240), Belt = rgb(30, 26, 20), Screen = rgb(255, 215, 90), Glow = true, Metal = true, Spikes = rgb(255, 210, 80) },
}
TreadmillModels.Looks = LOOKS

local function part(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: string?, collide: boolean?): BasePart
	local p
	if shape == "Wedge" then
		p = Instance.new("WedgePart")
	else
		p = Instance.new("Part")
		if shape == "Ball" then
			p.Shape = Enum.PartType.Ball
		elseif shape == "Cylinder" then
			p.Shape = Enum.PartType.Cylinder
		end
	end
	p.Name = name
	p.Anchored = true
	p.CanCollide = collide == true
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = material ~= Enum.Material.Neon
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

-- triangle plein (deux wedges) dans le plan YZ local, pointe vers +Y local
local function spike(model: Model, cf: CFrame, w: number, h: number, thick: number, color: Color3, material: Enum.Material?)
	part(model, "Spike", V(thick, h, w / 2), cf * CF(0, 0, -w / 4), color, material, "Wedge")
	part(model, "Spike", V(thick, h, w / 2), cf * CF(0, 0, w / 4) * A(0, math.pi, 0), color, material, "Wedge")
end

local function orbit(p: BasePart, center: Vector3, radius: number, height: number, speed: number, phase: number)
	p:SetAttribute("Center", center)
	p:SetAttribute("Radius", radius)
	p:SetAttribute("Height", height)
	p:SetAttribute("Speed", speed)
	p:SetAttribute("Phase", phase)
	CollectionService:AddTag(p, "Orbit")
end

function TreadmillModels.build(level: number, cf: CFrame, parent: Instance): Model
	level = math.clamp(level, 1, #LOOKS)
	local look = LOOKS[level]
	local model = Instance.new("Model")
	model.Name = "TreadmillModel"
	model:SetAttribute("Level", level)
	model:SetAttribute("Frame", cf)
	local function at(x: number, y: number, z: number): CFrame
		return cf * CF(x, y, z)
	end
	local railMat = look.Metal and Enum.Material.Metal or Enum.Material.SmoothPlastic
	local accentMat = look.Glow and Enum.Material.Neon or Enum.Material.SmoothPlastic
	local accent = look.Accent

	-- CHÂSSIS
	local deck = part(model, "Deck", V(8, 1.1, 15.4), at(0, 0.55, 1), look.Frame, nil, nil, true)
	model.PrimaryPart = deck
	part(model, "Belt", V(6, 0.2, 14.6), at(0, TreadmillModels.BELT_TOP - 0.1, 1), look.Belt, Enum.Material.Fabric)
	-- rouleau arrière arrondi
	part(model, "Roller", V(7.4, 1.3, 1.3), at(0, 0.8, 8.7), look.Frame, nil, "Cylinder")
	for _, s in { -1, 1 } do
		-- rails latéraux
		part(model, "Rail", V(1.25, 0.95, 15), at(s * 3.62, 1.52, 0.8), look.Rail, railMat, nil, true)
		part(model, "RailTop", V(0.18, 0.07, 14), at(s * 3.05, 2.02, 0.8), accent, accentMat)
		part(model, "RailStrip", V(0.12, 0.3, 13.6), at(s * 4.26, 1.45, 0.8), accent, accentMat)
		-- embouts avant et arrière
		part(model, "CapBack", V(1.5, 1.35, 1.5), at(s * 3.62, 0.85, 8.6), look.Cap, railMat)
		part(model, "CapBackStrip", V(0.1, 0.3, 1.3), at(s * 4.38, 0.9, 8.6), accent, accentMat)
		part(model, "CapFront", V(1.5, 1.6, 1.4), at(s * 3.62, 1.1, -6.6), look.Cap, railMat)
		-- pieds
		part(model, "Foot", V(1.2, 0.3, 1.2), at(s * 3.3, 0.15, 8.4), rgb(25, 25, 30))
		part(model, "Foot", V(1.2, 0.3, 1.2), at(s * 3.3, 0.15, -9.4), rgb(25, 25, 30))
	end

	-- CAPOT MOTEUR (avant)
	part(model, "Hood", V(8, 1.9, 3.6), at(0, 0.95, -8.6), look.Frame)
	part(model, "HoodSlope", V(8, 0.9, 3.6), at(0, 2.35, -8.6) * A(0, math.pi, 0), look.Rail, railMat, "Wedge")
	part(model, "HoodStrip", V(6.4, 0.22, 0.1), at(0, 1.35, -10.45), accent, accentMat)
	part(model, "HoodLogo", V(2.2, 0.5, 0.1), at(0, 0.7, -10.45), accent, accentMat)

	-- MONTANTS (légèrement inclinés vers le coureur)
	local tilt = rad(11)
	for _, s in { -1, 1 } do
		local up = at(s * 3.55, 5.3, -8.65) * A(tilt, 0, 0)
		part(model, "Upright", V(0.95, 6.6, 1.4), up, look.Rail, railMat)
		part(model, "UprightStrip", V(0.12, 5.6, 0.36), up * CF(-s * 0.5, 0, 0.3), accent, accentMat)
	end

	-- CONSOLE inclinée vers le coureur, avec écran
	local console = at(0, 8.85, -7.75) * A(rad(-35), 0, 0)
	part(model, "Console", V(7.6, 2.5, 1.2), console, look.Frame)
	part(model, "ConsoleRim", V(7.9, 2.8, 0.9), console * CF(0, 0, -0.25), look.Rail, railMat)
	local screen = part(model, "Screen", V(5.4, 1.7, 0.08), console * CF(0, 0.08, 0.62), look.Screen, Enum.Material.Neon)
	part(model, "ScreenFrame", V(5.9, 0.12, 0.1), console * CF(0, 1.0, 0.6), accent, accentMat)
	part(model, "ScreenFrame", V(5.9, 0.12, 0.1), console * CF(0, -0.84, 0.6), accent, accentMat)
	part(model, "Keypad", V(6.6, 0.5, 0.2), console * CF(0, -1.05, 0.55), rgb(25, 25, 30))
	for k = -2, 2 do
		part(model, "Key", V(0.7, 0.22, 0.12), console * CF(k * 1.2, -1.05, 0.68), (k == 0) and accent or rgb(70, 72, 80), (k == 0) and accentMat or nil)
	end
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = screen
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(20, 20, 28)
	label.Text = "LV " .. level
	label.Parent = gui

	-- GUIDONS
	for _, s in { -1, 1 } do
		part(model, "Handle", V(0.6, 0.6, 5), at(s * 3.75, 7.05, -5.6), look.Rail, railMat)
		part(model, "HandleStrip", V(0.2, 0.08, 4.4), at(s * 3.75, 7.39, -5.6), accent, accentMat)
		part(model, "Grip", V(0.75, 0.75, 1.3), at(s * 3.75, 7.05, -3.2), rgb(30, 30, 36))
		part(model, "HandleJoint", V(0.9, 1.4, 0.9), at(s * 3.7, 7.3, -8.1), look.Frame)
	end

	-- FLÈCHES SUR LA BANDE (animées côté client quand on court)
	for k, z0 in { -3.6, -0.6, 2.4, 5.4 } do
		for _, s in { -1, 1 } do
			local bar = part(model, "Chevron", V(1.7, 0.05, 0.38), at(s * 0.58, TreadmillModels.BELT_TOP + 0.03, z0 + 0.52) * A(0, rad(s * -42), 0), accent, accentMat)
			bar:SetAttribute("Z0", z0)
			bar:SetAttribute("Side", s)
			bar:SetAttribute("Order", k)
			CollectionService:AddTag(bar, "BeltChevron")
		end
	end

	-- lueur au sol
	if look.Glow then
		local glow = part(model, "UnderGlow", V(8.6, 0.06, 16.4), at(0, 0.04, 0.4), accent, Enum.Material.Neon)
		glow.Transparency = 0.35
	end
	local lamp = Instance.new("PointLight")
	lamp.Color = accent
	lamp.Range = 16
	lamp.Brightness = look.Glow and 1.4 or 0.6
	lamp.Shadows = false
	lamp.Parent = screen

	-- EXTRAS
	if look.Spikes then
		for _, s in { -1, 1 } do
			-- pointes à l'arrière et à l'avant, vers l'extérieur
			spike(model, at(s * 4.9, 1.0, 8.2) * A(0, 0, rad(-s * 90)) * A(rad(35), 0, 0), 2.0, 2.6, 0.6, look.Spikes, Enum.Material.SmoothPlastic)
			spike(model, at(s * 4.9, 1.3, -6.4) * A(0, 0, rad(-s * 90)) * A(rad(-35), 0, 0), 1.8, 2.4, 0.6, look.Spikes, Enum.Material.SmoothPlastic)
			spike(model, at(s * 4.4, 1.6, 2.5) * A(0, 0, rad(-s * 90)), 1.2, 1.4, 0.4, accent, accentMat)
			-- pointes au sommet de la console
			spike(model, at(s * 3.9, 10.4, -8.3) * A(0, 0, rad(-s * 28)), 1.2, 2.4, 0.5, look.Spikes, Enum.Material.SmoothPlastic)
			spike(model, at(s * 4.9, 7.05, -8.0) * A(0, 0, rad(-s * 90)), 1.0, 1.8, 0.45, accent, accentMat)
		end
	end

	if level == 7 then
		-- cristaux flottants autour de la console et des côtés
		local center = at(0, 0, -2).Position
		for k = 1, 6 do
			local ang = (k - 1) / 6 * math.pi * 2
			local crystal = part(model, "Crystal", V(0.9, 2.4, 0.9), CF(center) * CF(math.cos(ang) * 5.4, 6, math.sin(ang) * 5.4) * A(0, rad(45), rad(15)), rgb(150, 245, 255), Enum.Material.Glass)
			crystal.Transparency = 0.2
			local core = part(model, "CrystalCore", V(0.45, 1.8, 0.45), crystal.CFrame, accent, Enum.Material.Neon)
			orbit(crystal, center, 5.4, 6, 0.35, ang)
			orbit(core, center, 5.4, 6, 0.35, ang)
		end
		for _, s in { -1, 1 } do
			-- lames de cristal sur les côtés de la console
			spike(model, at(s * 4.4, 9.8, -8.0) * A(0, 0, rad(-s * 25)), 1.1, 2.6, 0.35, accent, Enum.Material.Neon)
			spike(model, at(s * 4.9, 8.6, -7.8) * A(0, 0, rad(-s * 60)), 0.9, 2.0, 0.35, rgb(190, 250, 255), Enum.Material.Glass)
		end
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Color = ColorSequence.new(accent)
		sparkles.LightEmission = 1
		sparkles.Size = NumberSequence.new(0.35, 0)
		sparkles.Lifetime = NumberRange.new(1, 2)
		sparkles.Rate = 8
		sparkles.Speed = NumberRange.new(1, 3)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Parent = deck
	elseif level == 8 then
		-- bande galaxie : spirale de petits néons sur la bande
		for k = 0, 23 do
			local t = k / 24
			local ang = t * math.pi * 4
			local r = 0.4 + t * 2.4
			local x = math.cos(ang) * r
			local z = 1 + math.sin(ang) * r * 2.2
			if math.abs(x) < 2.8 and z > -5.8 and z < 7.8 then
				part(model, "Galaxy", V(0.5, 0.04, 0.5), at(x, TreadmillModels.BELT_TOP + 0.02, z) * A(0, ang, 0), (k % 2 == 0) and rgb(255, 90, 220) or rgb(120, 140, 255), Enum.Material.Neon)
			end
		end
		part(model, "GalaxyCore", V(1.1, 0.05, 1.1), at(0, TreadmillModels.BELT_TOP + 0.03, 1) * A(0, rad(45), 0), rgb(255, 200, 255), Enum.Material.Neon)
		-- planètes en orbite
		local center = at(0, 0, -1).Position
		for k, info in { { 1.8, rgb(170, 70, 255), 6.5, 7.5 }, { 1.2, rgb(80, 150, 255), 5.5, 9.5 }, { 1.4, rgb(255, 90, 200), 7.2, 5.5 } } do
			local ang = k * 2.1
			local planet = part(model, "Planet", V(info[1], info[1], info[1]), CF(center + V(math.cos(ang) * info[3], info[4], math.sin(ang) * info[3])), info[2], Enum.Material.Neon, "Ball")
			orbit(planet, center, info[3], info[4], 0.25 + k * 0.08, ang)
			local ring = part(model, "PlanetRing", V(0.06, info[1] * 1.9, info[1] * 1.9), planet.CFrame * A(0, 0, rad(70)), rgb(230, 200, 255), Enum.Material.Glass, "Cylinder")
			ring.Transparency = 0.45
			orbit(ring, center, info[3], info[4], 0.25 + k * 0.08, ang)
		end
		local stars = Instance.new("ParticleEmitter")
		stars.Color = ColorSequence.new(rgb(220, 160, 255), rgb(120, 160, 255))
		stars.LightEmission = 1
		stars.Size = NumberSequence.new(0.25, 0)
		stars.Lifetime = NumberRange.new(1.5, 2.5)
		stars.Rate = 10
		stars.Speed = NumberRange.new(0.5, 1.5)
		stars.SpreadAngle = Vector2.new(180, 180)
		stars.Parent = deck
	elseif level == 9 then
		-- ailes dorées de chaque côté de la console
		for _, s in { -1, 1 } do
			for k = 0, 5 do
				local ang = rad(15 + k * 14)
				local len = 5.2 - k * 0.45
				local feather = at(s * 4.4, 9.2, -8.4) * A(0, 0, -s * ang) * CF(s * len / 2, 0, 0)
				part(model, "Feather", V(len, 0.75, 0.3), feather, (k % 2 == 0) and rgb(255, 252, 240) or rgb(255, 225, 120))
				part(model, "FeatherTip", V(1.0, 0.8, 0.32), feather * CF(s * len / 2, 0, 0), rgb(255, 205, 70), Enum.Material.Neon)
			end
		end
		-- auréole derrière la console
		for k = 0, 19 do
			local ang = k / 20 * math.pi * 2
			part(model, "Halo", V(1.0, 0.28, 0.28), at(math.cos(ang) * 3.1, 10.6 + math.sin(ang) * 3.1, -9.4) * A(0, 0, ang + math.pi / 2), rgb(255, 215, 90), Enum.Material.Neon)
		end
		-- nuages autour du tapis
		local rng = Random.new(9)
		-- petits nuages autour des embouts
		for _, corner in { { -1, 9.2 }, { 1, 9.2 }, { -1, -10 }, { 1, -10 } } do
			for k = 1, 4 do
				local size = rng:NextNumber(1.2, 2.2)
				part(model, "Cloud", V(size, size, size), at(corner[1] * rng:NextNumber(4.2, 5.6), rng:NextNumber(0.3, 1.0), corner[2] + rng:NextNumber(-1.6, 1.6)), rgb(255, 252, 245), nil, "Ball")
			end
		end
		local gold = Instance.new("ParticleEmitter")
		gold.Color = ColorSequence.new(rgb(255, 230, 120))
		gold.LightEmission = 1
		gold.Size = NumberSequence.new(0.4, 0)
		gold.Lifetime = NumberRange.new(1, 2)
		gold.Rate = 12
		gold.Speed = NumberRange.new(1, 3)
		gold.SpreadAngle = Vector2.new(180, 180)
		gold.Parent = deck
	end

	model.Parent = parent
	return model
end

return TreadmillModels
