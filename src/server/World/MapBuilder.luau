--[[
	Construit toute la map.

	HUB (zone sûre, z < 100) :
	  - 8 galeries de joueurs (4 à gauche, 4 à droite)
	  - le Grading Lab (gauche du centre) et la Training Track (droite du centre)
	  - le spawn et les classements au fond
	ROUTE (z > 100) : une ligne droite avec 10 boutiques, une par zone.
	  Chaque zone commence par un portail avec la vitesse minimum.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Cards = require(ReplicatedStorage.Shared.Cards)
local CardArt = require(ReplicatedStorage.Shared.CardArt)

local MapBuilder = {}

local INK = Color3.fromRGB(20, 20, 30)
local PAPER = Color3.fromRGB(250, 247, 240)
local CONCRETE = Color3.fromRGB(72, 74, 90)

MapBuilder.HubEdgeZ = 100 -- au-delà, on est sur la route
MapBuilder.ZoneLength = 200
MapBuilder.RoadHalfWidth = 20
MapBuilder.ZoneHalfWidth = 100

function MapBuilder.ZoneGateZ(i: number): number
	return 120 + (i - 1) * MapBuilder.ZoneLength
end

-- Zone dans laquelle se trouve une position (0 = hub)
function MapBuilder.ZoneAt(z: number): number
	if z < MapBuilder.ZoneGateZ(1) then
		return 0
	end
	return math.clamp(math.floor((z - MapBuilder.ZoneGateZ(1)) / MapBuilder.ZoneLength) + 1, 1, #Config.Zones)
end

function MapBuilder.InHub(position: Vector3): boolean
	return position.Z < MapBuilder.HubEdgeZ
end

--------------------------------------------------------------------
-- Aides
--------------------------------------------------------------------
local function part(props: { [string]: any }, parent: Instance?): BasePart
	local p = Instance.new(props.ClassName or "Part") :: BasePart
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		if k ~= "ClassName" then
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end
MapBuilder.part = part

local function surfaceText(target: BasePart, face: Enum.NormalId, text: string, color: Color3, ppm: number?, font: Enum.Font?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = ppm or 30
	gui.LightInfluence = 0
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = font or Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = INK
	stroke.Parent = label
	return label
end
MapBuilder.surfaceText = surfaceText

local function billboard(parent: Instance, size: UDim2, offset: Vector3, text: string, color: Color3?, maxDistance: number?)
	local gui = Instance.new("BillboardGui")
	gui.Size = size
	gui.StudsOffset = offset
	gui.MaxDistance = maxDistance or 120
	gui.LightInfluence = 0
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = INK
	stroke.Parent = label
	return label, gui
end
MapBuilder.billboard = billboard

local function prompt(parent: Instance, action: string, object: string, hold: number?, distance: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold or 0
	p.MaxActivationDistance = distance or 10
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end
MapBuilder.prompt = prompt

-- Un bâtiment ouvert sur une face : sol, 3 murs, façade avec ouverture, toit
-- cf : -Z local = vers l'intérieur, origine au milieu de l'entrée, au sol
local function building(cf: CFrame, width: number, depth: number, height: number, door: number, wall: Color3, trim: Color3, floor: Color3, parent: Instance)
	local function at(x, y, d)
		return cf * CFrame.new(x, y, -d)
	end
	part({ Name = "Floor", Size = Vector3.new(width, 1, depth), CFrame = at(0, 0.5, depth / 2), Color = floor }, parent)
	part({ Name = "Back", Size = Vector3.new(width, height, 2), CFrame = at(0, height / 2 + 1, depth - 1), Color = wall }, parent)
	part({ Name = "Left", Size = Vector3.new(2, height, depth), CFrame = at(-width / 2 + 1, height / 2 + 1, depth / 2), Color = wall }, parent)
	part({ Name = "Right", Size = Vector3.new(2, height, depth), CFrame = at(width / 2 - 1, height / 2 + 1, depth / 2), Color = wall }, parent)
	local seg = (width - door) / 2
	part({ Name = "FrontL", Size = Vector3.new(seg, height, 2), CFrame = at(-(door / 2 + seg / 2), height / 2 + 1, 1), Color = wall }, parent)
	part({ Name = "FrontR", Size = Vector3.new(seg, height, 2), CFrame = at(door / 2 + seg / 2, height / 2 + 1, 1), Color = wall }, parent)
	part({ Name = "Lintel", Size = Vector3.new(door, 4, 2), CFrame = at(0, height - 1, 1), Color = wall }, parent)
	part({ Name = "Roof", Size = Vector3.new(width + 2, 1.5, depth + 2), CFrame = at(0, height + 1.75, depth / 2), Color = trim }, parent)
	part({
		Name = "TrimStrip",
		Size = Vector3.new(width + 2.2, 1, 0.4),
		CFrame = at(0, height + 0.5, -0.2),
		Color = trim,
		Material = Enum.Material.Neon,
	}, parent)
	return at
end

--------------------------------------------------------------------
-- GALERIES DES JOUEURS
--------------------------------------------------------------------
local GALLERY_W = 50 -- largeur (le long de l'entrée)
local GALLERY_D = 44 -- profondeur
local CASE_COLS = { -18, -6, 6, 18 }
local CASE_ROWS = { 13, 22, 31, 40 }

local GALLERY_COLORS = {
	Color3.fromRGB(255, 70, 110),
	Color3.fromRGB(70, 160, 255),
	Color3.fromRGB(80, 230, 140),
	Color3.fromRGB(255, 200, 40),
	Color3.fromRGB(170, 100, 255),
	Color3.fromRGB(255, 130, 50),
	Color3.fromRGB(0, 220, 220),
	Color3.fromRGB(255, 120, 220),
}

local function buildGallery(index: number, entrance: Vector3, inward: Vector3, parent: Instance)
	local color = GALLERY_COLORS[index]
	local cf = CFrame.lookAt(entrance, entrance + inward)
	local folder = Instance.new("Folder")
	folder.Name = "Gallery" .. index
	folder.Parent = parent

	local at = building(cf, GALLERY_W, GALLERY_D, 16, 14, PAPER, color, Color3.fromRGB(34, 34, 46), folder)

	-- tapis rouge jusqu'aux vitrines
	part({
		Name = "Carpet",
		Size = Vector3.new(8, 0.1, GALLERY_D - 4),
		CFrame = at(0, 1.05, GALLERY_D / 2),
		Color = color:Lerp(INK, 0.35),
		CanCollide = false,
	}, folder)

	-- enseigne au-dessus de l'entrée (face extérieure)
	local sign = part({
		Name = "Sign",
		Size = Vector3.new(26, 5, 0.6),
		CFrame = at(0, 21, -0.6),
		Color = INK,
	}, folder)
	local signLabel = surfaceText(sign, Enum.NormalId.Back, "FREE GALLERY", color, 25)

	local cases = {}
	local n = 0
	for _, depth in CASE_ROWS do
		for _, x in CASE_COLS do
			n += 1
			local plinth = part({
				Name = "Plinth" .. n,
				Size = Vector3.new(6, 3, 3.4),
				CFrame = at(x, 2.5, depth),
				Color = INK,
			}, folder)
			local strip = part({
				Name = "Strip",
				Size = Vector3.new(6.2, 0.4, 3.6),
				CFrame = plinth.CFrame * CFrame.new(0, 1.3, 0),
				Color = color,
				Material = Enum.Material.Neon,
				CanCollide = false,
			}, folder)
			local glass = part({
				Name = "Glass",
				Size = Vector3.new(5.4, 6.6, 2.8),
				CFrame = plinth.CFrame * CFrame.new(0, 4.8, 0),
				Color = Color3.fromRGB(200, 230, 255),
				Material = Enum.Material.Glass,
				Transparency = 0.75,
				CanCollide = true,
			}, folder)
			local cap = part({
				Name = "Cap",
				Size = Vector3.new(5.8, 0.4, 3.2),
				CFrame = glass.CFrame * CFrame.new(0, 3.5, 0),
				Color = INK,
			}, folder)
			local label = billboard(plinth, UDim2.fromOffset(160, 40), Vector3.new(0, -0.2, 0), "", Color3.new(1, 1, 1), 40)
			cases[n] = {
				Index = n,
				Plinth = plinth,
				Strip = strip,
				Glass = glass,
				Cap = cap,
				Label = label,
				CardCFrame = plinth.CFrame * CFrame.new(0, 4.6, 0) * CFrame.Angles(0, math.pi, 0),
			}
		end
	end

	local collect = part({
		Name = "Collect",
		Size = Vector3.new(10, 0.4, 5),
		CFrame = at(0, 1.2, 5),
		Color = Color3.fromRGB(80, 230, 140),
		Material = Enum.Material.Neon,
	}, folder)
	local collectLabel = billboard(collect, UDim2.fromOffset(220, 56), Vector3.new(0, 4, 0), "", Color3.fromRGB(80, 230, 140), 80)

	return {
		Index = index,
		Color = color,
		Folder = folder,
		CFrame = cf,
		Cases = cases,
		SignLabel = signLabel,
		Collect = collect,
		CollectLabel = collectLabel,
		Spawn = at(0, 4, 8) * CFrame.Angles(0, math.pi, 0),
	}
end

--------------------------------------------------------------------
-- GRADING LAB
--------------------------------------------------------------------
local function buildLab(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "GradingLab"
	folder.Parent = parent
	local entrance = Vector3.new(-22, 0, -40)
	local cf = CFrame.lookAt(entrance, entrance + Vector3.new(-1, 0, 0))
	local at = building(cf, 40, 34, 18, 16, Color3.fromRGB(235, 240, 250), Color3.fromRGB(70, 160, 255), Color3.fromRGB(220, 228, 240), folder)

	local sign = part({ Name = "Sign", Size = Vector3.new(30, 6, 0.6), CFrame = at(0, 24, -0.6), Color = Color3.fromRGB(70, 160, 255) }, folder)
	surfaceText(sign, Enum.NormalId.Back, "GRADING LAB", Color3.new(1, 1, 1), 25)

	-- comptoir
	local counter = part({
		Name = "Counter",
		Size = Vector3.new(24, 4, 3),
		CFrame = at(0, 3, 14),
		Color = INK,
	}, folder)
	part({
		Name = "CounterTop",
		Size = Vector3.new(24.4, 0.4, 3.4),
		CFrame = counter.CFrame * CFrame.new(0, 2.2, 0),
		Color = Color3.fromRGB(70, 160, 255),
		Material = Enum.Material.Neon,
	}, folder)
	-- machines de gradation (déco)
	for i, x in { -12, 0, 12 } do
		local machine = part({
			Name = "Grader" .. i,
			Size = Vector3.new(8, 10, 6),
			CFrame = at(x, 6, 28),
			Color = Color3.fromRGB(45, 50, 70),
		}, folder)
		part({
			Name = "Slot",
			Size = Vector3.new(5, 0.6, 0.4),
			CFrame = machine.CFrame * CFrame.new(0, 1, 3.1),
			Color = Color3.fromRGB(0, 255, 200),
			Material = Enum.Material.Neon,
		}, folder)
		part({
			Name = "Screen",
			Size = Vector3.new(6, 3, 0.2),
			CFrame = machine.CFrame * CFrame.new(0, 3.2, 3.05),
			Color = Color3.fromRGB(0, 120, 255),
			Material = Enum.Material.Neon,
		}, folder)
	end
	local p = prompt(counter, "Open Lab", "Grading Lab", 0, 14)
	p.Name = "LabPrompt"
	return { Folder = folder, Prompt = p, Spawn = at(0, 4, 6) }
end

--------------------------------------------------------------------
-- TRAINING TRACK (tapis de course)
--------------------------------------------------------------------
local function buildTraining(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "TrainingTrack"
	folder.Parent = parent
	local originX, originZ = 30, -85
	part({
		Name = "Floor",
		Size = Vector3.new(50, 0.6, 100),
		CFrame = CFrame.new(originX + 25, 0.3, originZ + 50),
		Color = Color3.fromRGB(230, 90, 60),
		Material = Enum.Material.Slate,
	}, folder)
	local sign = part({
		Name = "Sign",
		Size = Vector3.new(30, 6, 0.6),
		CFrame = CFrame.new(originX + 2, 12, originZ + 50) * CFrame.Angles(0, math.rad(90), 0),
		Color = Color3.fromRGB(255, 130, 60),
	}, folder)
	surfaceText(sign, Enum.NormalId.Front, "TRAINING TRACK", Color3.new(1, 1, 1), 25)
	part({ Name = "SignPost", Size = Vector3.new(1, 9, 1), CFrame = CFrame.new(originX + 2, 4.5, originZ + 50), Color = INK }, folder)

	local treadmills = {}
	for i, t in Config.Treadmills do
		local z = originZ + 8 + (i - 1) * 12
		local x = originX + 30
		local base = part({
			Name = "Treadmill" .. i,
			Size = Vector3.new(16, 1, 8),
			CFrame = CFrame.new(x, 1.1, z),
			Color = INK,
		}, folder)
		-- la bande : on court vers -X (vers le centre du hub), elle ramène vers +X
		local belt = part({
			Name = "Belt",
			Size = Vector3.new(14, 0.3, 6),
			CFrame = CFrame.new(x, 1.75, z),
			Color = Color3.fromRGB(40, 40, 52),
			Material = Enum.Material.Fabric,
		}, folder)
		belt.AssemblyLinearVelocity = Vector3.new(14, 0, 0)
		-- console et barres de maintien
		local console = part({
			Name = "Console",
			Size = Vector3.new(1, 4, 6),
			CFrame = CFrame.new(x - 8, 3.6, z),
			Color = t.Color,
		}, folder)
		part({ Name = "Back", Size = Vector3.new(1, 3, 8), CFrame = CFrame.new(x + 8.5, 2.5, z), Color = INK, Transparency = 0.5 }, folder)
		local label = billboard(console, UDim2.fromOffset(220, 60), Vector3.new(0, 4.5, 0), "", t.Color, 60)
		console:SetAttribute("TreadmillIndex", i)
		treadmills[i] = { Index = i, Belt = belt, Base = base, Console = console, Label = label }
	end
	return { Folder = folder, Treadmills = treadmills }
end

--------------------------------------------------------------------
-- LA ROUTE ET LES BOUTIQUES
--------------------------------------------------------------------
local function buildZone(i: number, zone, parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = ("Zone%02d"):format(i)
	folder.Parent = parent
	local gateZ = MapBuilder.ZoneGateZ(i)
	local midZ = gateZ + MapBuilder.ZoneLength / 2
	local half = MapBuilder.ZoneHalfWidth

	-- sol de la zone et route
	part({
		Name = "Ground",
		Size = Vector3.new(half * 2, 1, MapBuilder.ZoneLength),
		CFrame = CFrame.new(0, -0.5, midZ),
		Color = zone.Main:Lerp(CONCRETE, 0.55),
	}, folder)
	part({
		Name = "Road",
		Size = Vector3.new(MapBuilder.RoadHalfWidth * 2, 0.2, MapBuilder.ZoneLength),
		CFrame = CFrame.new(0, 0.1, midZ),
		Color = Color3.fromRGB(45, 45, 58),
	}, folder)
	for k = 0, 7 do
		part({
			Name = "Dash",
			Size = Vector3.new(1, 0.05, 10),
			CFrame = CFrame.new(0, 0.22, gateZ + 12 + k * 25),
			Color = zone.Accent,
			CanCollide = false,
		}, folder)
	end

	-- clôtures sur les côtés
	for _, side in { -1, 1 } do
		part({
			Name = "Fence",
			Size = Vector3.new(2, 14, MapBuilder.ZoneLength),
			CFrame = CFrame.new(side * (half + 1), 7, midZ),
			Color = zone.Main:Lerp(INK, 0.4),
		}, folder)
	end

	-- portail avec la vitesse minimum
	local gateWall = Color3.fromRGB(30, 30, 42)
	for _, side in { -1, 1 } do
		local w = half - MapBuilder.RoadHalfWidth
		part({
			Name = "GateWall",
			Size = Vector3.new(w, 14, 2),
			CFrame = CFrame.new(side * (MapBuilder.RoadHalfWidth + w / 2), 7, gateZ),
			Color = gateWall,
		}, folder)
		part({
			Name = "Pillar",
			Size = Vector3.new(4, 22, 4),
			CFrame = CFrame.new(side * (MapBuilder.RoadHalfWidth + 2), 11, gateZ),
			Color = zone.Accent,
			Material = Enum.Material.Neon,
		}, folder)
	end
	local arch = part({
		Name = "Arch",
		Size = Vector3.new(MapBuilder.RoadHalfWidth * 2 + 8, 6, 2),
		CFrame = CFrame.new(0, 25, gateZ),
		Color = INK,
	}, folder)
	local speedText = zone.Speed > 0 and ("SPEED " .. Format.short(zone.Speed)) or "FREE"
	surfaceText(arch, Enum.NormalId.Front, zone.Name:upper() .. "  ·  " .. speedText, zone.Accent, 20)
	surfaceText(arch, Enum.NormalId.Back, "BACK TO HUB", Color3.new(1, 1, 1), 20)
	-- barrière : bloque côté client ceux qui n'ont pas la vitesse (voir client)
	local barrier = part({
		Name = "SpeedGate",
		Size = Vector3.new(MapBuilder.RoadHalfWidth * 2, 22, 1),
		CFrame = CFrame.new(0, 11, gateZ),
		Color = zone.Accent,
		Material = Enum.Material.ForceField,
		Transparency = zone.Speed > 0 and 0.4 or 1,
		CanCollide = false,
	}, folder)
	barrier:SetAttribute("Zone", i)
	barrier:SetAttribute("Speed", zone.Speed)

	-- la boutique (à droite de la route, ouverte vers la route)
	local shopEntrance = Vector3.new(MapBuilder.RoadHalfWidth + 6, 0, gateZ + 100)
	local shopCF = CFrame.lookAt(shopEntrance, shopEntrance + Vector3.new(1, 0, 0))
	local at = building(shopCF, 70, 56, 20, 22, zone.Main, zone.Accent, zone.Main:Lerp(PAPER, 0.6), folder)
	local shopSign = part({
		Name = "ShopSign",
		Size = Vector3.new(40, 7, 0.8),
		CFrame = at(0, 26, -0.8),
		Color = INK,
	}, folder)
	surfaceText(shopSign, Enum.NormalId.Back, zone.Name:upper(), zone.Accent, 25)

	-- présentoirs
	local pedestals = {}
	-- une allée centrale reste libre pour le gardien
	local positions = { { -24, 14 }, { 24, 14 }, { -12, 22 }, { 12, 22 }, { -24, 30 }, { 24, 30 } }
	for k = 1, Config.PedestalsPerZone do
		local pos = positions[k]
		local stand = part({
			Name = "Stand" .. k,
			Size = Vector3.new(6, 3, 6),
			CFrame = at(pos[1], 2.5, pos[2]),
			Color = INK,
		}, folder)
		part({
			Name = "StandTop",
			Size = Vector3.new(6.4, 0.4, 6.4),
			CFrame = stand.CFrame * CFrame.new(0, 1.7, 0),
			Color = zone.Accent,
			Material = Enum.Material.Neon,
		}, folder)
		pedestals[k] = {
			Index = k,
			Stand = stand,
			-- la carte regarde vers l'entrée de la boutique
			CardCFrame = stand.CFrame * CFrame.new(0, 4.9, 0) * CFrame.Angles(0, math.pi, 0),
		}
	end

	-- déco côté gauche : lampadaires
	for k = 0, 3 do
		local z = gateZ + 25 + k * 50
		part({ Name = "LampPost", Size = Vector3.new(1, 16, 1), CFrame = CFrame.new(-MapBuilder.RoadHalfWidth - 4, 8, z), Color = INK }, folder)
		local bulb = part({
			Name = "Lamp",
			Size = Vector3.new(3, 1.5, 3),
			CFrame = CFrame.new(-MapBuilder.RoadHalfWidth - 4, 16.5, z),
			Color = zone.Accent,
			Material = Enum.Material.Neon,
		}, folder)
		local light = Instance.new("PointLight")
		light.Color = zone.Accent
		light.Range = 24
		light.Brightness = 1.2
		light.Parent = bulb
	end

	-- cartes géantes côté gauche : les plus belles cartes de la boutique
	local best = 0
	for rarity in zone.Rarity do
		best = math.max(best, Cards.Rarities[rarity].Order)
	end
	local showcase = {}
	for _, c in Cards.List do
		if not c.Season and Cards.Rarities[c.Rarity].Order == best then
			table.insert(showcase, c.Id)
		end
	end
	for k, z in { gateZ + 45, gateZ + 155 } do
		local id = showcase[((i + k) % #showcase) + 1]
		if id then
			part({
				Name = "ShowcaseBase",
				Size = Vector3.new(8, 2, 20),
				CFrame = CFrame.new(-58, 1, z),
				Color = INK,
			}, folder)
			local giant = CardArt.part(id, "Holo", nil, false)
			giant.Name = "Showcase"
			giant.Size = Vector3.new(16, 22.4, 1)
			giant.CFrame = CFrame.new(-58, 13.3, z) * CFrame.Angles(0, math.rad(-90), 0)
			giant.CanCollide = true
			giant.Parent = folder
		end
	end

	-- gros panneau du nom de zone côté gauche
	local billboardPart = part({
		Name = "ZoneBoard",
		Size = Vector3.new(1, 18, 44),
		CFrame = CFrame.new(-half + 20, 14, gateZ + 100),
		Color = zone.Main,
	}, folder)
	surfaceText(
		billboardPart,
		Enum.NormalId.Right,
		("ZONE %d\n%s\nGuardian: %s"):format(i, zone.Name:upper(), zone.Guardian),
		Color3.new(1, 1, 1),
		14
	)

	return {
		Index = i,
		Folder = folder,
		GateZ = gateZ,
		ShopCFrame = shopCF,
		ShopAt = at,
		Pedestals = pedestals,
		GuardianHome = at(0, 0, 50),
		Barrier = barrier,
	}
end

--------------------------------------------------------------------
-- MAP COMPLÈTE
--------------------------------------------------------------------
function MapBuilder.Build()
	local root = Instance.new("Folder")
	root.Name = "Map"
	root.Parent = workspace

	-- sol du hub
	part({
		Name = "HubGround",
		Size = Vector3.new(320, 2, 280),
		CFrame = CFrame.new(0, -1, -40),
		Color = Color3.fromRGB(205, 210, 220),
		Material = Enum.Material.Concrete,
	}, root)
	part({
		Name = "HubPath",
		Size = Vector3.new(30, 0.2, 280),
		CFrame = CFrame.new(0, 0.1, -40),
		Color = Color3.fromRGB(250, 247, 240),
	}, root)
	-- murs du hub
	part({ Name = "HubWallBack", Size = Vector3.new(320, 20, 2), CFrame = CFrame.new(0, 10, -181), Color = CONCRETE }, root)
	for _, side in { -1, 1 } do
		part({ Name = "HubWallSide", Size = Vector3.new(2, 20, 280), CFrame = CFrame.new(side * 161, 10, -40), Color = CONCRETE }, root)
		part({
			Name = "HubWallFront",
			Size = Vector3.new(160 - MapBuilder.RoadHalfWidth, 20, 2),
			CFrame = CFrame.new(side * (MapBuilder.RoadHalfWidth + (160 - MapBuilder.RoadHalfWidth) / 2), 10, MapBuilder.HubEdgeZ + 1),
			Color = CONCRETE,
		}, root)
	end
	-- arche de sortie vers la route
	local exitArch = part({
		Name = "ExitArch",
		Size = Vector3.new(MapBuilder.RoadHalfWidth * 2 + 8, 7, 2),
		CFrame = CFrame.new(0, 24, MapBuilder.HubEdgeZ + 1),
		Color = Color3.fromRGB(255, 70, 110),
	}, root)
	surfaceText(exitArch, Enum.NormalId.Back, "TO THE SHOPS  >", Color3.new(1, 1, 1), 20)
	surfaceText(exitArch, Enum.NormalId.Front, "SAFE ZONE", Color3.fromRGB(80, 230, 140), 20)
	part({
		Name = "Approach",
		Size = Vector3.new(MapBuilder.RoadHalfWidth * 2, 0.2, 20),
		CFrame = CFrame.new(0, 0.1, MapBuilder.HubEdgeZ + 10),
		Color = Color3.fromRGB(45, 45, 58),
	}, root)
	part({
		Name = "ApproachGround",
		Size = Vector3.new(MapBuilder.ZoneHalfWidth * 2, 1, 20),
		CFrame = CFrame.new(0, -0.5, MapBuilder.HubEdgeZ + 10),
		Color = CONCRETE,
	}, root)
	for _, side in { -1, 1 } do
		part({
			Name = "ApproachFence",
			Size = Vector3.new(2, 14, 20),
			CFrame = CFrame.new(side * (MapBuilder.ZoneHalfWidth + 1), 7, MapBuilder.HubEdgeZ + 10),
			Color = CONCRETE,
		}, root)
	end

	-- spawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 0.6, -150)
	spawn.Color = INK
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = root
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end

	local title = part({
		Name = "Title",
		Size = Vector3.new(60, 16, 1),
		CFrame = CFrame.new(0, 18, -178),
		Transparency = 1,
		CanCollide = false,
	}, root)
	surfaceText(title, Enum.NormalId.Back, Config.GameName, Color3.new(1, 1, 1), 20)

	-- classements
	local boards = {}
	for _, info in { { "TopIncome", "TOP CASH/S", -45 }, { "TopSpeed", "TOP SPEED", 45 } } do
		local board = part({
			Name = info[1],
			Size = Vector3.new(18, 24, 1),
			CFrame = CFrame.new(info[3], 12, -170) * CFrame.Angles(0, math.pi, 0),
			Color = INK,
		}, root)
		boards[info[1]] = { part = board, title = info[2] }
	end

	-- galeries : 4 à gauche (entrée vers +X), 4 à droite (entrée vers -X)
	local galleriesFolder = Instance.new("Folder")
	galleriesFolder.Name = "Galleries"
	galleriesFolder.Parent = root
	local galleries = {}
	local zs = { -140, -85, -30, 25 }
	for k, z in zs do
		galleries[k] = buildGallery(k, Vector3.new(-92, 0, z), Vector3.new(-1, 0, 0), galleriesFolder)
		galleries[k + 4] = buildGallery(k + 4, Vector3.new(92, 0, z), Vector3.new(1, 0, 0), galleriesFolder)
	end

	local lab = buildLab(root)
	local training = buildTraining(root)

	-- la route
	local zonesFolder = Instance.new("Folder")
	zonesFolder.Name = "Zones"
	zonesFolder.Parent = root
	local zones = {}
	for i, zone in Config.Zones do
		zones[i] = buildZone(i, zone, zonesFolder)
	end
	-- mur de fin
	local lastZ = MapBuilder.ZoneGateZ(#Config.Zones) + MapBuilder.ZoneLength
	part({ Name = "EndWall", Size = Vector3.new(MapBuilder.ZoneHalfWidth * 2 + 4, 30, 2), CFrame = CFrame.new(0, 15, lastZ + 1), Color = INK }, root)

	return {
		Galleries = galleries,
		Lab = lab,
		Training = training,
		Zones = zones,
		Boards = boards,
	}
end

return MapBuilder
