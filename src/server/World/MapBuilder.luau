--[[
	Construit toute la map, en style briques (picots).

	HUB (zone sûre, z < 100) :
	  - 8 galeries de joueurs façon musée (4 à gauche, 4 à droite)
	  - le Grading Lab et la Training Track au centre
	  - spawn, fontaine, classements, arbres, bancs, lampadaires
	ROUTE (z > 100) : une rue droite avec 10 boutiques thématiques.
	  Avant chaque zone : un grand panneau avec la vitesse minimum, puis un portail.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Cards = require(ReplicatedStorage.Shared.Cards)
local CardArt = require(ReplicatedStorage.Shared.CardArt)
local Props = require(script.Parent.Props)

local MapBuilder = {}

local INK = Props.INK
local PAPER = Props.WHITE
local GOLD = Props.GOLD
local GRASS = Color3.fromRGB(110, 205, 80)
local part = Props.part

MapBuilder.HubEdgeZ = 100 -- au-delà, on est sur la route
MapBuilder.ZoneLength = 200
MapBuilder.RoadHalfWidth = 20
MapBuilder.ZoneHalfWidth = 100

function MapBuilder.ZoneGateZ(i: number): number
	return 120 + (i - 1) * MapBuilder.ZoneLength
end

function MapBuilder.ZoneAt(z: number): number
	if z < MapBuilder.ZoneGateZ(1) then
		return 0
	end
	return math.clamp(math.floor((z - MapBuilder.ZoneGateZ(1)) / MapBuilder.ZoneLength) + 1, 1, #Config.Zones)
end

function MapBuilder.InHub(position: Vector3): boolean
	return position.Z < MapBuilder.HubEdgeZ
end

MapBuilder.part = part

--------------------------------------------------------------------
-- Textes
--------------------------------------------------------------------
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

-- Panneau sur deux pieds. cf = centre du panneau ; la face Front (-Z local) est le texte principal.
local function signBoard(cf: CFrame, w: number, h: number, color: Color3, text: string, textColor: Color3, backText: string?, parent: Instance)
	local postHeight = cf.Position.Y + h / 2
	for _, side in { -1, 1 } do
		local p = (cf * CFrame.new(side * (w / 2 - 1), 0, 0)).Position
		part({ Name = "Post", Size = Vector3.new(1, postHeight, 1), CFrame = CFrame.new(p.X, postHeight / 2, p.Z), Color = INK }, parent)
	end
	local board = part({ Name = "Board", Size = Vector3.new(w, h, 1), CFrame = cf, Color = color, Studs = "top" }, parent)
	part({ Name = "Trim", Size = Vector3.new(w + 1, 0.6, 1.4), CFrame = cf * CFrame.new(0, h / 2 + 0.3, 0), Color = GOLD, Material = Enum.Material.Neon }, parent)
	local label = surfaceText(board, Enum.NormalId.Front, text, textColor, 18)
	surfaceText(board, Enum.NormalId.Back, backText or text, textColor, 18)
	return board, label
end

-- Bâtiment ouvert sur une face. cf : -Z local = vers l'intérieur, origine au milieu de l'entrée, au sol
local function building(cf: CFrame, width: number, depth: number, height: number, door: number, wall: Color3, trim: Color3, floor: Color3, parent: Instance)
	local function at(x, y, d)
		return cf * CFrame.new(x, y, -d)
	end
	part({ Name = "Floor", Size = Vector3.new(width, 1, depth), CFrame = at(0, 0.5, depth / 2), Color = floor, Studs = "top" }, parent)
	part({ Name = "Back", Size = Vector3.new(width, height, 2), CFrame = at(0, height / 2 + 1, depth - 1), Color = wall, Studs = "all" }, parent)
	part({ Name = "Left", Size = Vector3.new(2, height, depth), CFrame = at(-width / 2 + 1, height / 2 + 1, depth / 2), Color = wall, Studs = "all" }, parent)
	part({ Name = "Right", Size = Vector3.new(2, height, depth), CFrame = at(width / 2 - 1, height / 2 + 1, depth / 2), Color = wall, Studs = "all" }, parent)
	local seg = (width - door) / 2
	part({ Name = "FrontL", Size = Vector3.new(seg, height, 2), CFrame = at(-(door / 2 + seg / 2), height / 2 + 1, 1), Color = wall, Studs = "all" }, parent)
	part({ Name = "FrontR", Size = Vector3.new(seg, height, 2), CFrame = at(door / 2 + seg / 2, height / 2 + 1, 1), Color = wall, Studs = "all" }, parent)
	part({ Name = "Lintel", Size = Vector3.new(door, 4, 2), CFrame = at(0, height - 1, 1), Color = wall, Studs = "all" }, parent)
	part({ Name = "Roof", Size = Vector3.new(width + 2, 1.5, depth + 2), CFrame = at(0, height + 1.75, depth / 2), Color = trim, Studs = "top" }, parent)
	part({ Name = "RoofEdge", Size = Vector3.new(width + 2.4, 1, 0.6), CFrame = at(0, height + 0.5, -0.3), Color = trim, Material = Enum.Material.Neon }, parent)
	for _, side in { -1, 1 } do
		part({ Name = "DoorPillar", Size = Vector3.new(1.4, height - 2, 2.6), CFrame = at(side * (door / 2 + 0.7), (height - 2) / 2 + 1, 1), Color = GOLD, Studs = "all" }, parent)
	end
	return at
end

--------------------------------------------------------------------
-- GALERIES DES JOUEURS (façon musée)
--------------------------------------------------------------------
local GALLERY_W = 50
local GALLERY_D = 44
local CASE_COLS = { -18, -6, 6, 18 }
local CASE_ROWS = { 14, 23, 32, 41 }

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

	local at = building(cf, GALLERY_W, GALLERY_D, 18, 14, color:Lerp(PAPER, 0.72), color, Color3.fromRGB(46, 46, 60), folder)

	-- tapis rouge bordé d'or, barrières de musée
	part({ Name = "CarpetEdge", Size = Vector3.new(9, 0.1, GALLERY_D - 3), CFrame = at(0, 1.04, GALLERY_D / 2), Color = GOLD, CanCollide = false }, folder)
	part({ Name = "Carpet", Size = Vector3.new(8, 0.12, GALLERY_D - 4), CFrame = at(0, 1.06, GALLERY_D / 2), Color = Color3.fromRGB(200, 30, 50), Material = Enum.Material.Fabric, CanCollide = false }, folder)
	Props.stanchions(at(-5, 1, 9).Position, at(-5, 1, GALLERY_D - 5).Position, folder)
	Props.stanchions(at(5, 1, 9).Position, at(5, 1, GALLERY_D - 5).Position, folder)

	-- plafonniers, appliques, cadres, plantes
	Props.ceilingLights(at(0, 18.6, 2), GALLERY_W - 6, GALLERY_D - 4, folder)
	for _, side in { -1, 1 } do
		local inwardDir = cf.RightVector * -side
		for _, d in { 10, 22, 34 } do
			local p = at(side * (GALLERY_W / 2 - 2.2), 10, d).Position
			Props.wallLamp(CFrame.lookAt(p, p + inwardDir), folder)
		end
		for k, d in { 16, 28 } do
			local p = at(side * (GALLERY_W / 2 - 2.2), 9, d).Position
			Props.frame(CFrame.lookAt(p, p + inwardDir), 5, 4, GALLERY_COLORS[(index + k + side) % #GALLERY_COLORS + 1], folder)
		end
		Props.plantPot(at(side * (GALLERY_W / 2 - 4), 1, GALLERY_D - 4).Position, folder)
		Props.plantPot(at(side * (GALLERY_W / 2 - 4), 1, 4).Position, folder)
	end
	local backP = at(0, 12, GALLERY_D - 2.2).Position
	Props.frame(CFrame.lookAt(backP, backP - cf.LookVector), 12, 6, color, folder)

	-- façade : auvent, enseigne lumineuse, buissons
	Props.awning(at(0, 15.5, -1.2) * CFrame.Angles(0, math.pi, 0), 18, color, PAPER, folder)
	local sign = part({ Name = "Sign", Size = Vector3.new(28, 5, 0.8), CFrame = at(0, 23, -0.8), Color = INK }, folder)
	part({ Name = "SignTrim", Size = Vector3.new(29, 6, 0.6), CFrame = at(0, 23, -0.5), Color = color, Material = Enum.Material.Neon }, folder)
	local signLabel = surfaceText(sign, Enum.NormalId.Back, "FREE GALLERY", PAPER, 25)
	for _, side in { -1, 1 } do
		Props.bush(at(side * 13, 0, -4).Position, Color3.fromRGB(70, 170, 70), folder)
	end

	local cases = {}
	local n = 0
	for _, depth in CASE_ROWS do
		for _, x in CASE_COLS do
			n += 1
			local plinth = part({ Name = "Plinth" .. n, Size = Vector3.new(5.6, 3, 3.4), CFrame = at(x, 2.5, depth), Color = INK, Studs = "top" }, folder)
			local strip = part({
				Name = "Strip",
				Size = Vector3.new(5.8, 0.4, 3.6),
				CFrame = plinth.CFrame * CFrame.new(0, 1.3, 0),
				Color = color,
				Material = Enum.Material.Neon,
				CanCollide = false,
			}, folder)
			part({ Name = "Trim", Size = Vector3.new(5.8, 0.3, 3.6), CFrame = plinth.CFrame * CFrame.new(0, -1.35, 0), Color = GOLD }, folder)
			local glass = part({
				Name = "Glass",
				Size = Vector3.new(5, 6.6, 2.8),
				CFrame = plinth.CFrame * CFrame.new(0, 4.8, 0),
				Color = Color3.fromRGB(200, 230, 255),
				Material = Enum.Material.Glass,
				Transparency = 0.75,
			}, folder)
			local cap = part({ Name = "Cap", Size = Vector3.new(5.4, 0.4, 3.2), CFrame = glass.CFrame * CFrame.new(0, 3.5, 0), Color = GOLD, Material = Enum.Material.Metal }, folder)
			local label = billboard(plinth, UDim2.fromOffset(170, 38), Vector3.new(0, -0.4, 0), "", Color3.new(1, 1, 1), 40)
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
	local collectLabel = billboard(collect, UDim2.fromOffset(220, 56), Vector3.new(0, 4.2, 0), "", Color3.fromRGB(80, 230, 140), 80)
	billboard(collect, UDim2.fromOffset(170, 24), Vector3.new(0, 2.4, 0), "STEP TO COLLECT", PAPER, 40)

	return {
		Index = index,
		Color = color,
		Folder = folder,
		CFrame = cf,
		Cases = cases,
		SignLabel = signLabel,
		Collect = collect,
		CollectLabel = collectLabel,
		Spawn = at(0, 4, 9) * CFrame.Angles(0, math.pi, 0),
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
	local blue = Color3.fromRGB(70, 160, 255)
	local at = building(cf, 40, 34, 18, 16, Color3.fromRGB(235, 242, 252), blue, Color3.fromRGB(220, 228, 240), folder)

	local sign = part({ Name = "Sign", Size = Vector3.new(30, 6, 0.6), CFrame = at(0, 24, -0.6), Color = blue }, folder)
	surfaceText(sign, Enum.NormalId.Back, "GRADING LAB", Color3.new(1, 1, 1), 25)
	Props.awning(at(0, 15.5, -1.2) * CFrame.Angles(0, math.pi, 0), 20, blue, PAPER, folder)
	Props.ceilingLights(at(0, 18.6, 2), 34, 30, folder)

	local counter = part({ Name = "Counter", Size = Vector3.new(24, 4, 3), CFrame = at(0, 3, 14), Color = INK, Studs = "all" }, folder)
	part({ Name = "CounterTop", Size = Vector3.new(24.4, 0.4, 3.4), CFrame = counter.CFrame * CFrame.new(0, 2.2, 0), Color = blue, Material = Enum.Material.Neon }, folder)
	for i, x in { -12, 0, 12 } do
		local machine = part({ Name = "Grader" .. i, Size = Vector3.new(8, 10, 6), CFrame = at(x, 6, 28), Color = Color3.fromRGB(45, 50, 70), Studs = "all" }, folder)
		part({ Name = "Slot", Size = Vector3.new(5, 0.6, 0.4), CFrame = machine.CFrame * CFrame.new(0, -1, 3.1), Color = Color3.fromRGB(0, 255, 200), Material = Enum.Material.Neon }, folder)
		local screen = part({ Name = "Screen", Size = Vector3.new(6, 3, 0.2), CFrame = machine.CFrame * CFrame.new(0, 2.6, 3.05), Color = Color3.fromRGB(0, 120, 255), Material = Enum.Material.Neon }, folder)
		Props.light(screen, Color3.fromRGB(0, 160, 255), 14, 1)
		part({ Name = "Tube", Size = Vector3.new(6, 1.2, 1.2), Shape = Enum.PartType.Cylinder, CFrame = machine.CFrame * CFrame.new(0, 8, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(150, 255, 230), Material = Enum.Material.Glass, Transparency = 0.3 }, folder)
	end
	for _, x in { -8, 8 } do
		part({ Name = "Monitor", Size = Vector3.new(3, 2, 0.3), CFrame = at(x, 6.4, 14.4) * CFrame.Angles(0, math.pi, 0), Color = Color3.fromRGB(80, 255, 140), Material = Enum.Material.Neon }, folder)
	end
	Props.plantPot(at(-16, 1, 4).Position, folder)
	Props.plantPot(at(16, 1, 4).Position, folder)
	local p = prompt(counter, "Open Lab", "Grading Lab", 0, 16)
	p.Name = "LabPrompt"
	billboard(counter, UDim2.fromOffset(260, 40), Vector3.new(0, 5, 0), "GRADING LAB  (E)", PAPER, 60)
	return { Folder = folder, Prompt = p, Spawn = at(0, 4, 7) }
end

--------------------------------------------------------------------
-- TRAINING TRACK
--------------------------------------------------------------------
local function buildTraining(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "TrainingTrack"
	folder.Parent = parent
	local originX, originZ = 30, -90
	part({ Name = "Floor", Size = Vector3.new(54, 0.6, 108), CFrame = CFrame.new(originX + 27, 0.3, originZ + 52), Color = Color3.fromRGB(235, 100, 60), Material = Enum.Material.Slate, Studs = "top" }, folder)
	for k = 0, 3 do
		part({ Name = "Lane", Size = Vector3.new(0.6, 0.1, 104), CFrame = CFrame.new(originX + 6 + k * 3, 0.65, originZ + 52), Color = PAPER, CanCollide = false }, folder)
	end
	for _, z in { originZ + 30, originZ + 74 } do
		part({ Name = "ArchPost", Size = Vector3.new(3, 18, 3), CFrame = CFrame.new(originX + 2, 9, z), Color = Color3.fromRGB(255, 130, 60), Studs = "all" }, folder)
	end
	local arch = part({ Name = "Arch", Size = Vector3.new(4, 6, 47), CFrame = CFrame.new(originX + 2, 19, originZ + 52), Color = INK }, folder)
	surfaceText(arch, Enum.NormalId.Left, "TRAINING TRACK", Color3.fromRGB(255, 160, 80), 20)
	surfaceText(arch, Enum.NormalId.Right, "TRAINING TRACK", Color3.fromRGB(255, 160, 80), 20)

	local treadmills = {}
	for i, t in Config.Treadmills do
		local z = originZ + 9 + (i - 1) * 12.5
		local x = originX + 32
		local base = part({ Name = "Treadmill" .. i, Size = Vector3.new(16, 1.2, 8), CFrame = CFrame.new(x, 1.2, z), Color = INK, Studs = "top" }, folder)
		local belt = part({ Name = "Belt", Size = Vector3.new(14, 0.3, 6), CFrame = CFrame.new(x, 1.95, z), Color = Color3.fromRGB(38, 38, 50), Material = Enum.Material.Fabric }, folder)
		for _, side in { -1, 1 } do
			part({ Name = "RailPost", Size = Vector3.new(0.6, 4, 0.6), CFrame = CFrame.new(x - 6, 4, z + side * 3.6), Color = Color3.fromRGB(200, 205, 215), Material = Enum.Material.Metal }, folder)
			part({ Name = "Rail", Size = Vector3.new(8, 0.5, 0.5), CFrame = CFrame.new(x - 2.5, 5.6, z + side * 3.6), Color = Color3.fromRGB(200, 205, 215), Material = Enum.Material.Metal }, folder)
		end
		local console = part({ Name = "Console", Size = Vector3.new(1.4, 6, 7), CFrame = CFrame.new(x - 8.2, 4.2, z), Color = t.Color, Studs = "all" }, folder)
		part({ Name = "Screen", Size = Vector3.new(0.2, 2, 4), CFrame = CFrame.new(x - 7.45, 6, z), Color = Color3.fromRGB(80, 255, 140), Material = Enum.Material.Neon }, folder)
		part({ Name = "Stop", Size = Vector3.new(1, 3, 8), CFrame = CFrame.new(x + 8.5, 3, z), Color = INK, Transparency = 0.6 }, folder)
		local label = billboard(console, UDim2.fromOffset(230, 56), Vector3.new(0, 5, 0), "", t.Color, 70)
		local spot = CFrame.lookAt(Vector3.new(x - 1, 5, z), Vector3.new(x - 10, 5, z))
		console:SetAttribute("TreadmillIndex", i)
		console:SetAttribute("Spot", spot)
		console:SetAttribute("BeltTop", 2.1)
		game:GetService("CollectionService"):AddTag(console, "Treadmill")
		treadmills[i] = {
			Index = i,
			Belt = belt,
			Base = base,
			Console = console,
			Label = label,
			-- où se place le joueur pour s'entraîner (il regarde la console)
			Spot = spot,
		}
	end
	-- gradins et cônes
	for k = 0, 3 do
		part({
			Name = "Bleacher",
			Size = Vector3.new(2.5, 1 + k * 1.2, 90),
			CFrame = CFrame.new(originX + 44 + k * 2.5, 0.5 + k * 0.6, originZ + 52),
			Color = (k % 2 == 0) and Color3.fromRGB(70, 160, 255) or PAPER,
			Studs = "top",
		}, folder)
	end
	for k = 0, 5 do
		part({ Name = "Cone", Size = Vector3.new(1.2, 1.6, 1.2), CFrame = CFrame.new(originX + 10, 1.4, originZ + 6 + k * 18), Color = Color3.fromRGB(255, 140, 30), Studs = "top" }, folder)
	end
	return { Folder = folder, Treadmills = treadmills }
end

--------------------------------------------------------------------
-- DÉCOR À THÈME PAR ZONE (côté gauche de la rue)
--------------------------------------------------------------------
local function themeDecor(i: number, zone, gateZ: number, folder: Folder)
	if i == 1 then
		for k = 0, 3 do
			Props.tree(Vector3.new(-85 + (k % 2) * 20, 0, gateZ + 30 + k * 45), 1, Color3.fromRGB(90, 175, 70), folder)
		end
		Props.bench(CFrame.new(-30, 0, gateZ + 80) * CFrame.Angles(0, math.rad(-90), 0), Color3.fromRGB(200, 120, 60), folder)
		Props.flowers(Vector3.new(-40, 0, gateZ + 120), folder)
	elseif i == 2 then
		for k, w in { "POW!", "BAM!", "ZAP!" } do
			local p = part({ Name = "ComicPanel", Size = Vector3.new(1, 12, 16), CFrame = CFrame.new(-80, 7, gateZ + 20 + k * 40) * CFrame.Angles(0, 0, math.rad(k * 3 - 6)), Color = (k % 2 == 0) and zone.Main or zone.Accent, Studs = "all" }, folder)
			surfaceText(p, Enum.NormalId.Right, w, PAPER, 14)
		end
		Props.cardBoxes(Vector3.new(-40, 0, gateZ + 170), { zone.Main, zone.Accent, PAPER }, folder)
	elseif i == 3 then
		for k = 0, 5 do
			Props.arcadeCabinet(CFrame.new(-34, 0, gateZ + 40 + k * 22) * CFrame.Angles(0, math.rad(-90), 0), (k % 2 == 0) and zone.Accent or Color3.fromRGB(255, 60, 200), folder)
		end
	elseif i == 4 then
		Props.fountain(Vector3.new(-55, 0, gateZ + 100), folder)
		for k = 0, 3 do
			Props.plantPot(Vector3.new(-35, 0, gateZ + 40 + k * 40), folder)
			Props.bench(CFrame.new(-35, 0, gateZ + 60 + k * 40) * CFrame.Angles(0, math.rad(-90), 0), zone.Accent, folder)
		end
	elseif i == 5 then
		for k = 0, 2 do
			Props.bookshelf(CFrame.new(-90, 0, gateZ + 40 + k * 60) * CFrame.Angles(0, math.rad(-90), 0), folder)
			Props.cardBoxes(Vector3.new(-40, 0, gateZ + 60 + k * 50), { zone.Accent, zone.Main, GOLD }, folder)
		end
	elseif i == 6 then
		for k = 0, 4 do
			Props.column(Vector3.new(-35, 0, gateZ + 30 + k * 35), 16, zone.Accent, folder)
		end
		local podium = part({ Name = "Podium", Size = Vector3.new(6, 5, 4), CFrame = CFrame.new(-55, 2.5, gateZ + 100), Color = zone.Main, Studs = "all" }, folder)
		surfaceText(podium, Enum.NormalId.Right, "SOLD!", GOLD, 14)
	elseif i == 7 then
		Props.vaultDoor(CFrame.new(-85, 10, gateZ + 100) * CFrame.Angles(0, math.rad(-90), 0), folder)
		for k = 0, 5 do
			part({ Name = "GoldBar", Size = Vector3.new(3, 1, 1.5), CFrame = CFrame.new(-40, 0.5 + (k % 3), gateZ + 60 + math.floor(k / 3) * 4), Color = GOLD, Material = Enum.Material.Metal, Studs = "top" }, folder)
		end
	elseif i == 8 then
		for k = 0, 4 do
			Props.column(Vector3.new(-32, 0, gateZ + 30 + k * 35), 18, PAPER, folder)
		end
		Props.statue(Vector3.new(-60, 0, gateZ + 75), Color3.fromRGB(200, 200, 205), folder)
		Props.statue(Vector3.new(-60, 0, gateZ + 125), Color3.fromRGB(205, 170, 90), folder)
	elseif i == 9 then
		for k = 0, 5 do
			Props.cloud(Vector3.new(-80 + (k % 3) * 25, 22 + (k % 2) * 6, gateZ + 25 + k * 30), folder)
		end
	elseif i == 10 then
		Props.planet(Vector3.new(-70, 40, gateZ + 60), 18, Color3.fromRGB(255, 80, 230), folder)
		Props.planet(Vector3.new(-50, 55, gateZ + 150), 12, Color3.fromRGB(80, 200, 255), folder)
		for k = 0, 8 do
			part({ Name = "Star", Size = Vector3.new(0.8, 0.8, 0.8), Shape = Enum.PartType.Ball, CFrame = CFrame.new(-90 + k * 8, 30 + (k * 7) % 25, gateZ + 20 + k * 20), Color = PAPER, Material = Enum.Material.Neon, CanCollide = false }, folder)
		end
	end
end

--------------------------------------------------------------------
-- UNE ZONE (boutique)
--------------------------------------------------------------------
local function buildZone(i: number, zone, parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = ("Zone%02d"):format(i)
	folder.Parent = parent
	local gateZ = MapBuilder.ZoneGateZ(i)
	local midZ = gateZ + MapBuilder.ZoneLength / 2
	local half = MapBuilder.ZoneHalfWidth
	local road = MapBuilder.RoadHalfWidth

	-- sol, trottoirs, route
	part({ Name = "Ground", Size = Vector3.new(half * 2, 1, MapBuilder.ZoneLength), CFrame = CFrame.new(0, -0.5, midZ), Color = zone.Main:Lerp(PAPER, 0.35), Studs = "top" }, folder)
	part({ Name = "Road", Size = Vector3.new(road * 2, 0.2, MapBuilder.ZoneLength), CFrame = CFrame.new(0, 0.1, midZ), Color = Color3.fromRGB(52, 54, 68) }, folder)
	for _, side in { -1, 1 } do
		part({ Name = "Sidewalk", Size = Vector3.new(6, 0.5, MapBuilder.ZoneLength), CFrame = CFrame.new(side * (road + 3), 0.25, midZ), Color = Color3.fromRGB(200, 200, 210), Studs = "top" }, folder)
		part({ Name = "Curb", Size = Vector3.new(0.6, 0.6, MapBuilder.ZoneLength), CFrame = CFrame.new(side * (road + 0.3), 0.3, midZ), Color = zone.Accent }, folder)
	end
	for k = 0, 7 do
		part({ Name = "Dash", Size = Vector3.new(1, 0.05, 10), CFrame = CFrame.new(0, 0.22, gateZ + 12 + k * 25), Color = Color3.fromRGB(255, 220, 80), CanCollide = false }, folder)
	end

	-- murs d'enceinte
	for _, side in { -1, 1 } do
		part({ Name = "Fence", Size = Vector3.new(2, 24, MapBuilder.ZoneLength), CFrame = CFrame.new(side * (half + 1), 12, midZ), Color = zone.Main:Lerp(Color3.fromRGB(150, 110, 70), 0.35), Studs = "all" }, folder)
		part({ Name = "FenceTop", Size = Vector3.new(3, 1.4, MapBuilder.ZoneLength), CFrame = CFrame.new(side * (half + 1), 24.7, midZ), Color = zone.Accent, Studs = "top" }, folder)
	end

	-- PANNEAU DE VITESSE REQUISE, juste avant le portail, à droite de la route
	local need = zone.Speed > 0 and ("REQUIRES " .. Format.short(zone.Speed) .. " SPEED") or "NO SPEED NEEDED"
	signBoard(
		CFrame.new(road + 13, 9, gateZ - 8) * CFrame.Angles(0, math.rad(25), 0),
		16,
		9,
		INK,
		("ZONE %d\n%s\n%s"):format(i, zone.Name:upper(), need),
		zone.Speed > 0 and Color3.fromRGB(255, 220, 80) or Color3.fromRGB(80, 230, 140),
		"BACK TO SAFE ZONE",
		folder
	)

	-- portail
	for _, side in { -1, 1 } do
		local w = half - road
		part({ Name = "GateWall", Size = Vector3.new(w, 24, 2), CFrame = CFrame.new(side * (road + w / 2), 12, gateZ), Color = zone.Main:Lerp(INK, 0.3), Studs = "all" }, folder)
		part({ Name = "Pillar", Size = Vector3.new(5, 30, 5), CFrame = CFrame.new(side * (road + 2.5), 15, gateZ), Color = zone.Accent, Studs = "all" }, folder)
		local cap = part({ Name = "PillarLight", Size = Vector3.new(4, 2, 4), CFrame = CFrame.new(side * (road + 2.5), 31, gateZ), Color = zone.Accent, Material = Enum.Material.Neon }, folder)
		Props.light(cap, zone.Accent, 30, 1.5)
	end
	local arch = part({ Name = "Arch", Size = Vector3.new(road * 2 + 10, 7, 3), CFrame = CFrame.new(0, 26.5, gateZ), Color = INK, Studs = "top" }, folder)
	surfaceText(arch, Enum.NormalId.Front, zone.Name:upper() .. "  ·  " .. (zone.Speed > 0 and Format.short(zone.Speed) .. " SPEED" or "FREE"), zone.Accent, 20)
	surfaceText(arch, Enum.NormalId.Back, "BACK TO SAFE ZONE", Color3.fromRGB(80, 230, 140), 20)
	local barrier = part({
		Name = "SpeedGate",
		Size = Vector3.new(road * 2, 23, 1),
		CFrame = CFrame.new(0, 11.5, gateZ),
		Color = zone.Accent,
		Material = Enum.Material.ForceField,
		Transparency = zone.Speed > 0 and 0.4 or 1,
		CanCollide = false,
	}, folder)
	barrier:SetAttribute("Zone", i)
	barrier:SetAttribute("Speed", zone.Speed)
	game:GetService("CollectionService"):AddTag(barrier, "SpeedGate")

	-- lampadaires des deux côtés
	for k = 0, 3 do
		local z = gateZ + 25 + k * 50
		Props.lampPost(Vector3.new(-road - 4, 0.5, z), zone.Accent, folder, Vector3.new(1, 0, 0))
		if k ~= 2 then
			Props.lampPost(Vector3.new(road + 4, 0.5, z - 12), zone.Accent, folder, Vector3.new(-1, 0, 0))
		end
	end

	-- LA BOUTIQUE (à droite, ouverte vers la route)
	local shopEntrance = Vector3.new(road + 6, 0, gateZ + 100)
	local shopCF = CFrame.lookAt(shopEntrance, shopEntrance + Vector3.new(1, 0, 0))
	local at = building(shopCF, 70, 56, 22, 22, zone.Main:Lerp(PAPER, 0.25), zone.Accent, zone.Main:Lerp(PAPER, 0.7), folder)

	local shopSign = part({ Name = "ShopSign", Size = Vector3.new(44, 7, 0.8), CFrame = at(0, 28.5, -0.8), Color = INK }, folder)
	part({ Name = "ShopSignTrim", Size = Vector3.new(45.5, 8.5, 0.5), CFrame = at(0, 28.5, -0.4), Color = zone.Accent, Material = Enum.Material.Neon }, folder)
	surfaceText(shopSign, Enum.NormalId.Back, zone.Name:upper(), zone.Accent, 25)
	for _, side in { -1, 1 } do
		part({ Name = "WindowFrame", Size = Vector3.new(15, 10, 0.3), CFrame = at(side * 21, 9, -0.05), Color = GOLD }, folder)
		part({ Name = "Window", Size = Vector3.new(14, 9, 0.4), CFrame = at(side * 21, 9, -0.25), Color = Color3.fromRGB(180, 220, 255), Material = Enum.Material.Glass, Transparency = 0.35 }, folder)
	end
	Props.awning(at(0, 17.5, -1.2) * CFrame.Angles(0, math.pi, 0), 26, zone.Accent, PAPER, folder)

	-- intérieur
	Props.ceilingLights(at(0, 22.6, 2), 64, 52, folder)
	for _, side in { -1, 1 } do
		local inwardDir = shopCF.RightVector * -side
		for _, d in { 12, 28, 44 } do
			local p = at(side * 33, 12, d).Position
			Props.wallLamp(CFrame.lookAt(p, p + inwardDir), folder)
		end
		for k, d in { 20, 36 } do
			local p = at(side * 33, 9, d).Position
			Props.frame(CFrame.lookAt(p, p + inwardDir), 6, 5, (k % 2 == 0) and zone.Accent or zone.Main, folder)
		end
		Props.plantPot(at(side * 30, 1, 4).Position, folder)
		Props.plantPot(at(side * 30, 1, 52).Position, folder)
	end
	Props.counter(at(0, 1, 54) * CFrame.Angles(0, math.pi, 0), 16, zone.Accent, folder)

	-- présentoirs : l'allée centrale reste libre pour le gardien
	local pedestals = {}
	local positions = { { -24, 14 }, { 24, 14 }, { -12, 22 }, { 12, 22 }, { -24, 30 }, { 24, 30 } }
	for k = 1, Config.PedestalsPerZone do
		local pos = positions[k]
		local stand = part({ Name = "Stand" .. k, Size = Vector3.new(6, 3, 6), CFrame = at(pos[1], 2.5, pos[2]), Color = INK, Studs = "top" }, folder)
		part({ Name = "StandTop", Size = Vector3.new(6.4, 0.4, 6.4), CFrame = stand.CFrame * CFrame.new(0, 1.7, 0), Color = zone.Accent, Material = Enum.Material.Neon }, folder)
		part({ Name = "StandTrim", Size = Vector3.new(6.4, 0.4, 6.4), CFrame = stand.CFrame * CFrame.new(0, -1.3, 0), Color = GOLD }, folder)
		Props.stanchions((stand.CFrame * CFrame.new(-4.5, -1.5, -4)).Position, (stand.CFrame * CFrame.new(-4.5, -1.5, 4)).Position, folder)
		Props.stanchions((stand.CFrame * CFrame.new(4.5, -1.5, -4)).Position, (stand.CFrame * CFrame.new(4.5, -1.5, 4)).Position, folder)
		pedestals[k] = {
			Index = k,
			Stand = stand,
			CardCFrame = stand.CFrame * CFrame.new(0, 4.9, 0) * CFrame.Angles(0, math.pi, 0),
		}
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
			part({ Name = "ShowcaseBase", Size = Vector3.new(8, 2, 20), CFrame = CFrame.new(-58, 1, z), Color = INK, Studs = "top" }, folder)
			local giant = CardArt.part(id, "Holo", nil, false)
			giant.Name = "Showcase"
			giant.Size = Vector3.new(16, 22.4, 1)
			giant.CFrame = CFrame.new(-58, 13.3, z) * CFrame.Angles(0, math.rad(-90), 0)
			giant.CanCollide = true
			giant.Parent = folder
		end
	end

	themeDecor(i, zone, gateZ, folder)

	return {
		Index = i,
		Folder = folder,
		GateZ = gateZ,
		ShopCFrame = shopCF,
		ShopAt = at,
		Pedestals = pedestals,
		GuardianHome = at(0, 0, 49),
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

	-- hub : pelouse, allée, murs
	part({ Name = "HubGround", Size = Vector3.new(320, 2, 280), CFrame = CFrame.new(0, -1, -40), Color = GRASS, Studs = "top" }, root)
	part({ Name = "HubPath", Size = Vector3.new(30, 0.3, 280), CFrame = CFrame.new(0, 0.15, -40), Color = Color3.fromRGB(240, 225, 190), Studs = "top" }, root)
	for _, side in { -1, 1 } do
		part({ Name = "PathEdge", Size = Vector3.new(1, 0.4, 280), CFrame = CFrame.new(side * 15.5, 0.2, -40), Color = Color3.fromRGB(200, 170, 120) }, root)
	end
	local wallColor = Color3.fromRGB(210, 150, 95)
	part({ Name = "HubWallBack", Size = Vector3.new(320, 28, 4), CFrame = CFrame.new(0, 14, -182), Color = wallColor, Studs = "all" }, root)
	part({ Name = "HubWallBackTop", Size = Vector3.new(322, 2, 6), CFrame = CFrame.new(0, 29, -182), Color = GRASS, Studs = "top" }, root)
	for _, side in { -1, 1 } do
		part({ Name = "HubWallSide", Size = Vector3.new(4, 28, 284), CFrame = CFrame.new(side * 162, 14, -40), Color = wallColor, Studs = "all" }, root)
		part({ Name = "HubWallSideTop", Size = Vector3.new(6, 2, 286), CFrame = CFrame.new(side * 162, 29, -40), Color = GRASS, Studs = "top" }, root)
		part({
			Name = "HubWallFront",
			Size = Vector3.new(160 - MapBuilder.RoadHalfWidth, 28, 4),
			CFrame = CFrame.new(side * (MapBuilder.RoadHalfWidth + (160 - MapBuilder.RoadHalfWidth) / 2), 14, MapBuilder.HubEdgeZ + 2),
			Color = wallColor,
			Studs = "all",
		}, root)
	end

	-- ligne SAFE ZONE au sol + arche de sortie
	part({ Name = "SafeLine", Size = Vector3.new(MapBuilder.RoadHalfWidth * 2, 0.1, 1.2), CFrame = CFrame.new(0, 0.35, MapBuilder.HubEdgeZ - 1), Color = Color3.fromRGB(255, 50, 70), Material = Enum.Material.Neon, CanCollide = false }, root)
	local safeText = part({ Name = "SafeText", Size = Vector3.new(30, 0.1, 6), CFrame = CFrame.new(0, 0.32, MapBuilder.HubEdgeZ - 6), Transparency = 1, CanCollide = false }, root)
	surfaceText(safeText, Enum.NormalId.Top, "SAFE ZONE", PAPER, 20)
	local exitArch = part({ Name = "ExitArch", Size = Vector3.new(MapBuilder.RoadHalfWidth * 2 + 10, 7, 3), CFrame = CFrame.new(0, 26, MapBuilder.HubEdgeZ + 2), Color = Color3.fromRGB(255, 70, 110), Studs = "top" }, root)
	surfaceText(exitArch, Enum.NormalId.Front, "TO THE SHOPS", PAPER, 20)
	surfaceText(exitArch, Enum.NormalId.Back, "SAFE ZONE", Color3.fromRGB(80, 230, 140), 20)
	part({ Name = "Approach", Size = Vector3.new(MapBuilder.RoadHalfWidth * 2, 0.2, 22), CFrame = CFrame.new(0, 0.1, MapBuilder.HubEdgeZ + 11), Color = Color3.fromRGB(52, 54, 68) }, root)
	part({ Name = "ApproachGround", Size = Vector3.new(MapBuilder.ZoneHalfWidth * 2, 1, 22), CFrame = CFrame.new(0, -0.5, MapBuilder.HubEdgeZ + 11), Color = GRASS, Studs = "top" }, root)
	for _, side in { -1, 1 } do
		part({ Name = "ApproachFence", Size = Vector3.new(2, 24, 22), CFrame = CFrame.new(side * (MapBuilder.ZoneHalfWidth + 1), 12, MapBuilder.HubEdgeZ + 11), Color = wallColor, Studs = "all" }, root)
	end

	-- spawn, fontaine, titre
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 0.8, -155)
	spawn.Color = INK
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Studs
	spawn.Parent = root
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	Props.fountain(Vector3.new(0, 0.3, -125), root)
	local title = part({ Name = "Title", Size = Vector3.new(70, 18, 1), CFrame = CFrame.new(0, 34, -179), Transparency = 1, CanCollide = false }, root)
	surfaceText(title, Enum.NormalId.Back, Config.GameName, PAPER, 20)

	-- panneau d'orientation (vu depuis le spawn : la droite de l'écran est vers -X)
	-- (sur le bord gauche de l'allée, tourné vers ceux qui arrivent du spawn)
	signBoard(
		CFrame.new(-24, 6, -112) * CFrame.Angles(0, math.rad(-35), 0),
		16,
		6,
		Color3.fromRGB(255, 70, 110),
		"< TRAINING    LAB >\nSHOPS STRAIGHT AHEAD",
		PAPER,
		"BACK TO SPAWN",
		root
	)

	-- végétation et mobilier du hub
	for _, z in { -160, -10, 70 } do
		for _, x in { -150, 150 } do
			Props.tree(Vector3.new(x, 0, z), 1.2, Color3.fromRGB(70, 170, 70), root)
		end
	end
	for _, p in { Vector3.new(-62, 0, 5), Vector3.new(-60, 0, 50), Vector3.new(60, 0, 50), Vector3.new(-60, 0, -110), Vector3.new(-45, 0, 85), Vector3.new(45, 0, 85) } do
		Props.tree(p, 1, Color3.fromRGB(90, 185, 75), root)
	end
	for k = 0, 5 do
		local z = -130 + k * 40
		Props.lampPost(Vector3.new(-17.5, 0, z), Color3.fromRGB(255, 230, 150), root, Vector3.new(1, 0, 0))
		Props.lampPost(Vector3.new(17.5, 0, z + 20), Color3.fromRGB(255, 230, 150), root, Vector3.new(-1, 0, 0))
	end
	for _, z in { -100, -60, 40, 80 } do
		Props.bench(CFrame.new(-19, 0, z) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(200, 120, 60), root)
		Props.bench(CFrame.new(19, 0, z) * CFrame.Angles(0, math.rad(-90), 0), Color3.fromRGB(200, 120, 60), root)
	end
	for _, p in { Vector3.new(-40, 0, 60), Vector3.new(40, 0, 60), Vector3.new(-40, 0, -150), Vector3.new(40, 0, -150), Vector3.new(-60, 0, 20) } do
		Props.flowers(p, root)
		Props.bush(p + Vector3.new(6, 0, 0), Color3.fromRGB(80, 180, 70), root)
	end

	-- classements
	local boards = {}
	for _, info in { { "TopIncome", "TOP CASH/S", -45 }, { "TopSpeed", "TOP SPEED", 45 } } do
		local board = part({ Name = info[1], Size = Vector3.new(18, 24, 1), CFrame = CFrame.new(info[3], 14, -172) * CFrame.Angles(0, math.pi, 0), Color = INK }, root)
		part({ Name = "BoardFrame", Size = Vector3.new(19.5, 25.5, 0.8), CFrame = board.CFrame * CFrame.new(0, 0, 0.3), Color = GOLD, Material = Enum.Material.Metal }, root)
		part({ Name = "BoardBase", Size = Vector3.new(20, 2, 4), CFrame = CFrame.new(info[3], 1, -172), Color = INK, Studs = "top" }, root)
		boards[info[1]] = { part = board, title = info[2] }
	end

	-- galeries
	local galleriesFolder = Instance.new("Folder")
	galleriesFolder.Name = "Galleries"
	galleriesFolder.Parent = root
	local galleries = {}
	for k, z in { -140, -85, -30, 25 } do
		galleries[k] = buildGallery(k, Vector3.new(-92, 0, z), Vector3.new(-1, 0, 0), galleriesFolder)
		galleries[k + 4] = buildGallery(k + 4, Vector3.new(92, 0, z), Vector3.new(1, 0, 0), galleriesFolder)
	end

	local lab = buildLab(root)
	local training = buildTraining(root)

	-- la rue
	local zonesFolder = Instance.new("Folder")
	zonesFolder.Name = "Zones"
	zonesFolder.Parent = root
	local zones = {}
	for i, zone in Config.Zones do
		zones[i] = buildZone(i, zone, zonesFolder)
	end
	local lastZ = MapBuilder.ZoneGateZ(#Config.Zones) + MapBuilder.ZoneLength
	part({ Name = "EndWall", Size = Vector3.new(MapBuilder.ZoneHalfWidth * 2 + 4, 30, 3), CFrame = CFrame.new(0, 15, lastZ + 1.5), Color = INK, Studs = "all" }, root)

	return {
		Galleries = galleries,
		Lab = lab,
		Training = training,
		Zones = zones,
		Boards = boards,
	}
end

return MapBuilder
