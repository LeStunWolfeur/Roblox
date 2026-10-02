--[[
	Créature (entité) de chaque carte, construite en pièces à partir de l'ID de la carte.
	Toujours la même pour une carte donnée. Accessoires selon la rareté :
	  Common : rien / feuille     Uncommon : petit chapeau    Rare : cornes ou oreilles
	  Epic : ailes                Legendary : couronne + cape Mythic : auréole + ailes lumineuses
	  Secret : corps sombre, yeux lumineux, orbes et aura
	La finition change la matière (Gold doré, Frozen glace, Haunted fantôme, Dark Matter...).
	Utilisé sur les présentoirs (serveur) et dans l'index / la révélation (ViewportFrame côté client).
]]

local Cards = require(script.Parent.Cards)

local Entity = {}

local INK = Color3.fromRGB(25, 25, 32)
local WHITE = Color3.fromRGB(250, 250, 250)

local function hash(s: string): number
	local h = 5381
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 2147483647
	end
	return h
end

-- Construit le modèle. L'origine (pivot) est aux pieds, -Z = face avant.
function Entity.build(id: string, finish: string?): Model
	local card = Cards.ById[id]
	local rarity = Cards.Rarities[card.Rarity]
	local order = rarity.Order
	local rng = Random.new(hash(id))
	local model = Instance.new("Model")
	model.Name = "Entity_" .. id

	local bodyColor = card.A
	local bellyColor = card.B
	local material = Enum.Material.SmoothPlastic
	local bodyTransparency = 0
	if finish == "Gold" then
		bodyColor, material = Color3.fromRGB(255, 200, 50), Enum.Material.Metal
	elseif finish == "Frozen" then
		bodyColor, material = Color3.fromRGB(170, 230, 255), Enum.Material.Ice
	elseif finish == "Haunted" then
		bodyTransparency = 0.35
	elseif finish == "DarkMatter" then
		bodyColor, bellyColor = Color3.fromRGB(30, 10, 50), Color3.fromRGB(160, 60, 255)
	elseif finish == "Rainbow" then
		bellyColor = Color3.fromHSV(rng:NextNumber(), 0.6, 1)
	end
	if card.Rarity == "Secret" then
		bodyColor = Color3.fromRGB(20, 18, 28)
	end

	local function p(name: string, size: Vector3, cf: CFrame, color: Color3, props: { [string]: any }?)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = cf
		part.Color = color
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Material = Enum.Material.SmoothPlastic
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		if props then
			for k, v in props do
				(part :: any)[k] = v
			end
		end
		part.Parent = model
		return part
	end

	local root = p("Root", Vector3.new(1, 1, 1), CFrame.new(0, 0.5, 0), WHITE, { Transparency = 1 })
	model.PrimaryPart = root

	-- corps : 4 silhouettes possibles
	local shape = rng:NextInteger(1, 4)
	local headY, headR, bodyTop
	local bodyProps = { Material = material, Transparency = bodyTransparency }
	-- jambes
	for _, x in { -0.75, 0.75 } do
		p("Leg", Vector3.new(0.8, 1, 0.9), CFrame.new(x, 0.5, 0), bodyColor:Lerp(INK, 0.35), bodyProps)
	end
	if shape == 1 then -- boule
		p("Body", Vector3.new(3.6, 3.6, 3.6), CFrame.new(0, 2.7, 0), bodyColor, { Shape = Enum.PartType.Ball, Material = material, Transparency = bodyTransparency })
		headY, headR, bodyTop = 2.9, 1.8, 4.5
	elseif shape == 2 then -- bloc
		p("Body", Vector3.new(3.4, 3.4, 3), CFrame.new(0, 2.7, 0), bodyColor, { Material = material, Transparency = bodyTransparency, TopSurface = Enum.SurfaceType.Studs })
		headY, headR, bodyTop = 3, 1.5, 4.4
	elseif shape == 3 then -- grand
		p("Body", Vector3.new(2.6, 4.4, 2.6), CFrame.new(0, 3.2, 0), bodyColor, { Material = material, Transparency = bodyTransparency, TopSurface = Enum.SurfaceType.Studs })
		headY, headR, bodyTop = 4, 1.3, 5.4
	else -- poire : corps + tête
		p("Body", Vector3.new(3.6, 3.2, 3.6), CFrame.new(0, 2.4, 0), bodyColor, { Shape = Enum.PartType.Ball, Material = material, Transparency = bodyTransparency })
		p("Head", Vector3.new(2.8, 2.8, 2.8), CFrame.new(0, 4.6, 0), bodyColor, { Shape = Enum.PartType.Ball, Material = material, Transparency = bodyTransparency })
		headY, headR, bodyTop = 4.6, 1.4, 6
	end

	-- ventre
	p("Belly", Vector3.new(headR * 1.2, headR * 1.1, 0.3), CFrame.new(0, headY - headR * 0.9, -headR - 0.05), bellyColor, { Material = material })

	-- bras
	for _, side in { -1, 1 } do
		p("Arm", Vector3.new(0.7, 1.6, 0.7), CFrame.new(side * (headR + 0.4), headY - 0.8, 0) * CFrame.Angles(0, 0, math.rad(side * 25)), bodyColor:Lerp(INK, 0.15), bodyProps)
	end

	-- yeux
	local eyeStyle = rng:NextInteger(1, 3)
	local eyeSize = rng:NextNumber(0.8, 1.15)
	local eyeColor = card.Rarity == "Secret" and Color3.fromRGB(255, 60, 60) or WHITE
	for _, side in { -1, 1 } do
		local ex = side * headR * 0.42
		local front = -headR - 0.1
		p("Eye", Vector3.new(eyeSize, eyeSize, eyeSize), CFrame.new(ex, headY + 0.35, front + 0.3), eyeColor, {
			Shape = Enum.PartType.Ball,
			Material = card.Rarity == "Secret" and Enum.Material.Neon or Enum.Material.SmoothPlastic,
		})
		if card.Rarity ~= "Secret" then
			p("Pupil", Vector3.new(eyeSize * 0.5, eyeSize * 0.5, eyeSize * 0.5), CFrame.new(ex + side * 0.05, headY + 0.3, front - 0.05), INK, { Shape = Enum.PartType.Ball })
		end
		if eyeStyle == 2 then -- paupières endormies
			p("Lid", Vector3.new(eyeSize * 1.05, eyeSize * 0.45, 0.3), CFrame.new(ex, headY + 0.35 + eyeSize * 0.3, front - 0.15), bodyColor:Lerp(INK, 0.2))
		elseif eyeStyle == 3 then -- sourcils fâchés
			p("Brow", Vector3.new(eyeSize, 0.2, 0.2), CFrame.new(ex, headY + 0.35 + eyeSize * 0.65, front - 0.1) * CFrame.Angles(0, 0, math.rad(side * -20)), INK)
		end
	end

	-- bouche
	local mouth = rng:NextInteger(1, 3)
	local my = headY - 0.55
	local mz = -headR - 0.1
	if mouth == 1 then
		p("Mouth", Vector3.new(0.9, 0.2, 0.2), CFrame.new(0, my, mz), INK)
	elseif mouth == 2 then
		p("Smile", Vector3.new(0.5, 0.2, 0.2), CFrame.new(-0.25, my, mz) * CFrame.Angles(0, 0, math.rad(-20)), INK)
		p("Smile", Vector3.new(0.5, 0.2, 0.2), CFrame.new(0.25, my, mz) * CFrame.Angles(0, 0, math.rad(20)), INK)
	else
		p("Mouth", Vector3.new(1, 0.5, 0.2), CFrame.new(0, my, mz), INK)
		p("Tooth", Vector3.new(0.3, 0.25, 0.1), CFrame.new(-0.2, my + 0.1, mz - 0.1), WHITE)
		p("Tooth", Vector3.new(0.3, 0.25, 0.1), CFrame.new(0.2, my + 0.1, mz - 0.1), WHITE)
	end

	-- accessoires selon la rareté
	local top = bodyTop
	local gold = Color3.fromRGB(255, 200, 40)
	if order == 1 and rng:NextNumber() < 0.6 then
		p("Leaf", Vector3.new(0.3, 1.2, 0.8), CFrame.new(0, top + 0.5, 0) * CFrame.Angles(0, 0, math.rad(20)), Color3.fromRGB(80, 190, 80))
	elseif order == 2 then
		p("HatBrim", Vector3.new(0.3, 2.4, 2.4), CFrame.new(0, top + 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), bellyColor, { Shape = Enum.PartType.Cylinder })
		p("Hat", Vector3.new(1.2, 1.5, 1.5), CFrame.new(0, top + 0.7, 0) * CFrame.Angles(0, 0, math.rad(90)), bellyColor, { Shape = Enum.PartType.Cylinder })
	elseif order == 3 then
		for _, side in { -1, 1 } do
			p("Horn", Vector3.new(0.6, 1.6, 0.6), CFrame.new(side * headR * 0.55, top + 0.4, 0) * CFrame.Angles(0, 0, math.rad(side * -25)), bellyColor:Lerp(WHITE, 0.3))
			p("HornTip", Vector3.new(0.4, 0.6, 0.4), CFrame.new(side * (headR * 0.55 + 0.35), top + 1.25, 0) * CFrame.Angles(0, 0, math.rad(side * -35)), WHITE)
		end
	end
	if order == 4 or order == 6 then
		for _, side in { -1, 1 } do
			p("Wing", Vector3.new(0.3, 2.6, 2), CFrame.new(side * (headR + 0.9), headY + 0.4, 0.8) * CFrame.Angles(0, math.rad(side * 30), math.rad(side * -35)), order == 6 and Color3.fromRGB(255, 240, 255) or bellyColor, {
				Material = order == 6 and Enum.Material.Neon or Enum.Material.SmoothPlastic,
			})
		end
	end
	if order == 5 then
		for k = 0, 4 do
			local a = math.rad(k * 72)
			p("Crown", Vector3.new(0.45, 0.9, 0.45), CFrame.new(math.cos(a) * 0.8, top + 0.45, math.sin(a) * 0.8), gold, { Material = Enum.Material.Metal })
		end
		p("CrownBand", Vector3.new(0.4, 2, 2), CFrame.new(0, top + 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), gold, { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal })
		p("Cape", Vector3.new(headR * 2, headY + 0.5, 0.2), CFrame.new(0, (headY + 0.5) / 2 + 0.3, headR + 0.2) * CFrame.Angles(math.rad(8), 0, 0), Color3.fromRGB(200, 30, 50), { Material = Enum.Material.Fabric })
	end
	if order == 6 then
		p("Halo", Vector3.new(0.25, 2.2, 2.2), CFrame.new(0, top + 1.1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 240, 150), { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon })
	end
	if order == 7 then
		for k = 0, 2 do
			local a = math.rad(k * 120)
			p("Orb", Vector3.new(0.8, 0.8, 0.8), CFrame.new(math.cos(a) * (headR + 1.5), headY + 1 + k * 0.4, math.sin(a) * (headR + 1.5)), Color3.fromRGB(255, 60, 60), { Shape = Enum.PartType.Ball, Material = Enum.Material.Neon })
		end
		p("Aura", Vector3.new(headR * 3.4, headR * 3.4, headR * 3.4), CFrame.new(0, headY, 0), Color3.fromRGB(255, 40, 80), { Shape = Enum.PartType.Ball, Material = Enum.Material.ForceField, Transparency = 0.2 })
	end

	-- petit détail de saison
	if card.Season == "Halloween" then
		p("WitchBrim", Vector3.new(0.25, 3, 3), CFrame.new(0, top + 0.15, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(40, 20, 60), { Shape = Enum.PartType.Cylinder })
		p("WitchHat1", Vector3.new(1.4, 1.2, 1.4), CFrame.new(0, top + 0.8, 0), Color3.fromRGB(40, 20, 60))
		p("WitchHat2", Vector3.new(0.8, 1, 0.8), CFrame.new(0.2, top + 1.8, 0) * CFrame.Angles(0, 0, math.rad(-15)), Color3.fromRGB(40, 20, 60))
		p("HatBand", Vector3.new(1.45, 0.3, 1.45), CFrame.new(0, top + 0.4, 0), Color3.fromRGB(255, 130, 20))
	elseif card.Season == "Winter" then
		p("Scarf", Vector3.new(headR * 2.1, 0.5, headR * 2.1), CFrame.new(0, headY - headR * 0.75, 0), Color3.fromRGB(220, 40, 60), { Material = Enum.Material.Fabric })
	elseif card.Season == "Spring" then
		p("Flower", Vector3.new(0.9, 0.9, 0.9), CFrame.new(headR * 0.6, top + 0.3, 0), Color3.fromRGB(255, 120, 180), { Shape = Enum.PartType.Ball })
	elseif card.Season == "Summer" then
		p("Shades", Vector3.new(headR * 1.6, 0.45, 0.2), CFrame.new(0, headY + 0.4, -headR - 0.35), INK)
	end

	return model
end

-- Place le modèle (pivot aux pieds) et applique une échelle
function Entity.place(model: Model, cf: CFrame, scale: number?)
	local s = scale or 1
	if s ~= 1 then
		local origin = model.PrimaryPart.CFrame
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				local rel = origin:ToObjectSpace(part.CFrame)
				part.Size *= s
				part.CFrame = origin * (rel - rel.Position + rel.Position * s)
			end
		end
	end
	local pivotOffset = model.PrimaryPart.CFrame * CFrame.new(0, -0.5 * s, 0)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CFrame = cf * pivotOffset:ToObjectSpace(part.CFrame)
		end
	end
end

return Entity
