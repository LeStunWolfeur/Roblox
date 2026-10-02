--[[
	Les deux stands au bout de la rue des bases :
	  "upgrades" : améliorations (tapis, vitrines, labo)
	  "sell"     : vendre ses cartes, une par une ou toutes d'un coup
	Un stand = estrade en bois, comptoir, étagères, auvent rayé, grande enseigne,
	un vendeur (une créature du jeu) et des accessoires.

	Stands.build(kind, cf, parent) -> { Prompt = ProximityPrompt }
	cf : au sol, au milieu de l'avant du comptoir, -Z = vers les clients.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Entity = require(ReplicatedStorage.Shared.Entity)
local Signs = require(script.Parent.Signs)

local Stands = {}

local rad = math.rad
local V = Vector3.new
local CF = CFrame.new
local A = CFrame.Angles

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local LOOK = {
	upgrades = {
		Main = rgb(60, 200, 80),
		Dark = rgb(30, 90, 45),
		Light = rgb(150, 245, 120),
		Title = "UPGRADES",
		Sub = "Treadmill · Cases · Lab",
		Colors = Signs.Palettes.Green,
		Vendor = "roboraccoon",
		Prompt = "StandUpgrades",
		Object = "Upgrades",
	},
	sell = {
		Main = rgb(245, 185, 40),
		Dark = rgb(120, 70, 10),
		Light = rgb(255, 230, 130),
		Title = "SELL CARDS",
		Sub = "One by one or all at once",
		Colors = Signs.Palettes.Gold,
		Vendor = "goldengoose",
		Prompt = "StandSell",
		Object = "Sell Cards",
	},
}

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: string?, collide: boolean?): BasePart
	local p = Instance.new("Part")
	if shape == "Ball" then
		p.Shape = Enum.PartType.Ball
	elseif shape == "Cylinder" then
		p.Shape = Enum.PartType.Cylinder
	end
	p.Name = name
	p.Anchored = true
	p.CanCollide = collide ~= false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function Stands.build(kind: string, cf: CFrame, parent: Instance)
	local look = LOOK[kind]
	local model = Instance.new("Model")
	model.Name = "Stand_" .. kind
	model.Parent = parent
	local function at(x: number, y: number, z: number): CFrame
		return cf * CF(x, y, z)
	end
	local white = rgb(248, 247, 242)
	local wood = rgb(176, 120, 74)
	local woodDark = rgb(130, 84, 50)

	-- ESTRADE en planches
	part(model, "Deck", V(19, 0.6, 13), at(0, 0.3, 3), woodDark, Enum.Material.Wood)
	for k = 0, 5 do
		part(model, "Plank", V(18.6, 0.12, 1.9), at(0, 0.62, -2.7 + k * 2.1), (k % 2 == 0) and wood or woodDark:Lerp(wood, 0.5), Enum.Material.Wood, nil, false)
	end
	part(model, "Step", V(14, 0.3, 1.6), at(0, 0.15, -4.4), woodDark, Enum.Material.Wood)

	-- COMPTOIR
	part(model, "Counter", V(15, 3.4, 2.6), at(0, 2.3, -1.6), look.Main)
	part(model, "CounterPanel", V(13.8, 2.3, 0.15), at(0, 2.2, -2.95), look.Light)
	for _, x in { -4.6, 0, 4.6 } do
		part(model, "PanelLine", V(0.25, 2.3, 0.2), at(x, 2.2, -3.0), look.Dark, nil, nil, false)
	end
	part(model, "CounterTop", V(15.8, 0.45, 3.2), at(0, 4.2, -1.6), white, Enum.Material.Marble)
	part(model, "CounterTrim", V(15.9, 0.22, 0.12), at(0, 3.9, -3.25), look.Main:Lerp(Color3.new(1, 1, 1), 0.3), Enum.Material.Neon, nil, false)

	-- MUR DU FOND + ÉTAGÈRES
	part(model, "BackWall", V(18, 10.5, 0.8), at(0, 5.85, 9.1), look.Dark)
	part(model, "BackPanel", V(16.6, 8.6, 0.2), at(0, 5.6, 8.6), look.Dark:Lerp(Color3.new(0, 0, 0), 0.25))
	for _, y in { 3.6, 6.2, 8.8 } do
		part(model, "Shelf", V(16, 0.35, 1.6), at(0, y, 7.8), wood, Enum.Material.Wood)
	end
	local rng = Random.new(kind == "sell" and 4 or 7)
	for _, y in { 3.6, 6.2, 8.8 } do
		for k = -6, 6, 2 do
			if kind == "sell" then
				-- paquets de cartes et piles de pièces
				if (k + math.floor(y)) % 4 == 0 then
					for c = 0, rng:NextInteger(2, 4) do
						part(model, "Coin", V(0.25, 0.9, 0.9), at(k + 0.3, y + 0.3 + c * 0.26, 7.8) * A(0, 0, rad(90)), rgb(255, 205, 50), Enum.Material.Metal, "Cylinder", false)
					end
				else
					local c = ({ rgb(70, 150, 255), rgb(170, 90, 255), rgb(255, 180, 30), rgb(255, 60, 110) })[rng:NextInteger(1, 4)]
					part(model, "Pack", V(1.1, 1.6, 0.25), at(k, y + 0.98, 7.9) * A(rad(-8), 0, rad(rng:NextNumber(-6, 6))), c, nil, nil, false)
				end
			else
				-- boissons de vitesse et caisses d'outils
				if (k + math.floor(y)) % 4 == 0 then
					part(model, "Crate", V(1.5, 1.1, 1.1), at(k, y + 0.73, 7.8), rgb(200, 60, 50), nil, nil, false)
					part(model, "CrateHandle", V(0.8, 0.15, 0.2), at(k, y + 1.35, 7.8), rgb(40, 40, 46), nil, nil, false)
				else
					local c = ({ rgb(80, 255, 120), rgb(60, 200, 255), rgb(255, 220, 60), rgb(200, 90, 255) })[rng:NextInteger(1, 4)]
					part(model, "Bottle", V(1.1, 0.6, 0.6), at(k, y + 0.73, 7.8) * A(0, 0, rad(90)), c, Enum.Material.Neon, "Cylinder", false)
					part(model, "Cap", V(0.25, 0.4, 0.4), at(k, y + 1.4, 7.8) * A(0, 0, rad(90)), white, nil, "Cylinder", false)
				end
			end
		end
	end

	-- POTEAUX ET AUVENT RAYÉ
	for _, x in { -8.8, 8.8 } do
		for _, z in { -3.4, 8.6 } do
			part(model, "Post", V(0.9, 10.2, 0.9), at(x, 5.7, z), white)
			part(model, "PostCap", V(1.3, 0.5, 1.3), at(x, 10.9, z), look.Main)
		end
	end
	local stripes = 8
	for k = 0, stripes - 1 do
		local x = -9.5 + (k + 0.5) * (19 / stripes)
		part(model, "Awning", V(19 / stripes + 0.02, 0.35, 13.2), at(x, 11.9, 2.6) * A(rad(-12), 0, 0), (k % 2 == 0) and look.Main or white, Enum.Material.Fabric, nil, false)
		part(model, "Scallop", V(0.3, 2.2, 2.2), at(x, 10.55, -4.0) * A(0, rad(90), 0), (k % 2 == 0) and look.Main or white, Enum.Material.Fabric, "Cylinder", false)
	end
	-- ampoules sous l'auvent
	for _, x in { -5, 0, 5 } do
		part(model, "Wire", V(0.08, 1.2, 0.08), at(x, 10.4, -1.2), rgb(30, 30, 30), nil, nil, false)
		local bulb = part(model, "Bulb", V(0.8, 0.8, 0.8), at(x, 9.6, -1.2), rgb(255, 240, 200), Enum.Material.Neon, "Ball", false)
		local l = Instance.new("PointLight")
		l.Color = rgb(255, 230, 180)
		l.Range = 14
		l.Brightness = 1.2
		l.Parent = bulb
	end

	-- GRANDE ENSEIGNE au-dessus de l'auvent
	for _, x in { -5.5, 5.5 } do
		part(model, "SignPost", V(0.5, 3, 0.5), at(x, 14.3, 5.5), rgb(40, 40, 48))
	end
	local board = part(model, "Sign", V(16, 5, 0.6), at(0, 17.5, 5.5), look.Dark)
	Signs.panel(board, Enum.NormalId.Front, { Title = look.Title, Sub = look.Sub, Colors = look.Colors, PixelsPerStud = 40 })
	Signs.panel(board, Enum.NormalId.Back, { Title = look.Title, Colors = look.Colors, PixelsPerStud = 30 })

	-- LE VENDEUR derrière le comptoir
	local vendor = Entity.build(look.Vendor, "Normal")
	vendor.Parent = model
	Entity.place(vendor, at(0, 0.6, 3.6), 1.7)

	-- ACCESSOIRES SUR LE COMPTOIR
	if kind == "sell" then
		-- caisse enregistreuse
		part(model, "Register", V(3, 1.4, 2), at(4.5, 5.1, -1.4), rgb(40, 42, 50))
		local screen = part(model, "RegisterScreen", V(2, 0.9, 0.15), at(4.5, 6.2, -1.9) * A(rad(-20), 0, 0), rgb(80, 255, 140), Enum.Material.Neon)
		Signs.panel(screen, Enum.NormalId.Front, { Title = "$$$", Colors = Signs.Palettes.Dark, PixelsPerStud = 60, Stroke = 3, TitleColor = rgb(120, 255, 140) })
		part(model, "Drawer", V(3.1, 0.4, 2.1), at(4.5, 4.55, -1.5), rgb(200, 205, 215))
		for c = 0, 4 do
			part(model, "Coin", V(0.25, 1, 1), at(-4.5, 4.55 + c * 0.26, -1.6) * A(0, 0, rad(90)), rgb(255, 205, 50), Enum.Material.Metal, "Cylinder", false)
		end
		for c = 0, 2 do
			part(model, "Coin", V(0.25, 1, 1), at(-3.3, 4.55 + c * 0.26, -1.1) * A(0, 0, rad(90)), rgb(255, 205, 50), Enum.Material.Metal, "Cylinder", false)
		end
		part(model, "CardPile", V(1.6, 0.3, 2.2), at(-0.5, 4.55, -1.6) * A(0, rad(12), 0), rgb(240, 240, 250), nil, nil, false)
		part(model, "CardTop", V(1.4, 0.05, 2.0), at(-0.5, 4.72, -1.6) * A(0, rad(12), 0), rgb(255, 180, 30), nil, nil, false)
	else
		-- caisse à outils et flèche de vitesse
		part(model, "Toolbox", V(3, 1.2, 1.6), at(-4.5, 5.0, -1.4), rgb(220, 50, 50))
		part(model, "ToolboxLid", V(3.1, 0.3, 1.7), at(-4.5, 5.7, -1.4), rgb(180, 30, 35))
		part(model, "ToolboxHandle", V(1.6, 0.25, 0.3), at(-4.5, 6.05, -1.4), rgb(40, 40, 46))
		part(model, "Wrench", V(2.4, 0.2, 0.45), at(-4.2, 6.0, -2.2) * A(0, rad(25), 0), rgb(200, 205, 215), Enum.Material.Metal, nil, false)
		for k = 0, 2 do
			part(model, "Arrow", V(1.6, 0.4, 0.5), at(4.2 - 0.5, 5.2 + k * 0.9, -1.5) * A(0, 0, rad(40)), rgb(80, 255, 120), Enum.Material.Neon, nil, false)
			part(model, "Arrow", V(1.6, 0.4, 0.5), at(4.2 + 0.5, 5.2 + k * 0.9, -1.5) * A(0, 0, rad(-40)), rgb(80, 255, 120), Enum.Material.Neon, nil, false)
		end
	end

	-- tapis d'accueil devant
	part(model, "Mat", V(10, 0.1, 3.4), at(0, 0.05, -6.6), look.Dark)
	part(model, "MatEdge", V(10.4, 0.06, 3.8), at(0, 0.02, -6.6), look.Main, Enum.Material.Neon, nil, false)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = look.Prompt
	prompt.ActionText = "Open"
	prompt.ObjectText = look.Object
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = model:FindFirstChild("Counter")
	return { Model = model, Prompt = prompt }
end

return Stands
