--[[
	Construit toute la map, en style briques (picots).

	ZONE SÛRE (z < 0) : la rue des bases. 8 bases de joueurs (4 de chaque côté),
	  chacune avec son tapis de course, ses présentoirs et sa machine de gradation.
	ROUTE (z > 0) : la suite de la même rue, avec 10 boutiques thématiques.
	  Avant chaque zone : un panneau avec la vitesse conseillée.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Cards = require(ReplicatedStorage.Shared.Cards)
local CardArt = require(ReplicatedStorage.Shared.CardArt)
local Props = require(script.Parent.Props)
local Showcase = require(script.Parent.Showcase)

local MapBuilder = {}

local INK = Props.INK
local PAPER = Props.WHITE
local GOLD = Props.GOLD
local GRASS = Color3.fromRGB(110, 205, 80)
local part = Props.part

MapBuilder.HubEdgeZ = 0 -- au-delà, on quitte la zone sûre des bases
MapBuilder.ZoneLength = 200
MapBuilder.RoadHalfWidth = 20
MapBuilder.ZoneHalfWidth = 100

function MapBuilder.ZoneGateZ(i: number): number
	return 20 + (i - 1) * MapBuilder.ZoneLength
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
-- BASES DES JOUEURS
-- Repère local : origine au milieu de l'entrée, -Z = vers l'intérieur.
-- Devant : tapis de course (droite) et dalle de collecte (gauche).
-- Milieu : 16 présentoirs. Fond : machine de gradation.
--------------------------------------------------------------------
local BASE_W = 60
local BASE_D = 64
local CASE_COLS = { -21, -7, 7, 21 }
local CASE_ROWS = { 22, 31, 40, 49 }

local BASE_COLORS = {
	Color3.fromRGB(255, 70, 110),
	Color3.fromRGB(70, 160, 255),
	Color3.fromRGB(80, 220, 120),
	Color3.fromRGB(255, 190, 40),
	Color3.fromRGB(170, 100, 255),
	Color3.fromRGB(255, 130, 50),
	Color3.fromRGB(0, 210, 210),
	Color3.fromRGB(255, 120, 220),
}

local function buildBase(index: number, entrance: Vector3, inward: Vector3, parent: Instance)
	local color = BASE_COLORS[index]
	local light = color:Lerp(PAPER, 0.55)
	local cf = CFrame.lookAt(entrance, entrance + inward)
	local function at(x, y, d)
		return cf * CFrame.new(x, y, -d)
	end
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. index
	folder.Parent = parent

	-- plateforme surélevée en damier
	part({ Name = "Platform", Size = Vector3.new(BASE_W, 1.5, BASE_D), CFrame = at(0, 0.75, BASE_D / 2), Color = Props.INK }, folder)
	local tile = 10
	for i = 0, BASE_W / tile - 1 do
		for j = 0, math.floor(BASE_D / tile) - 1 do
			part({
				Name = "Tile",
				Size = Vector3.new(tile, 0.2, tile),
				CFrame = at(-BASE_W / 2 + (i + 0.5) * tile, 1.6, 2 + (j + 0.5) * tile),
				Color = ((i + j) % 2 == 0) and light or PAPER,
				Studs = "top",
			}, folder)
		end
	end
	-- bordure lumineuse
	part({ Name = "Edge", Size = Vector3.new(BASE_W + 0.6, 0.6, 0.6), CFrame = at(0, 1.5, -0.3), Color = color, Material = Enum.Material.Neon }, folder)

	-- murets + piliers avec lampes (côtés et fond)
	local wallH = 4
	local function wall(size: Vector3, c: CFrame)
		part({ Name = "Wall", Size = size, CFrame = c, Color = color, Studs = "all" }, folder)
		part({ Name = "WallCap", Size = Vector3.new(size.X + 0.4, 0.6, size.Z + 0.4), CFrame = c * CFrame.new(0, size.Y / 2 + 0.3, 0), Color = PAPER, Studs = "top" }, folder)
	end
	wall(Vector3.new(2, wallH, BASE_D), at(-BASE_W / 2 + 1, 1.5 + wallH / 2, BASE_D / 2))
	wall(Vector3.new(2, wallH, BASE_D), at(BASE_W / 2 - 1, 1.5 + wallH / 2, BASE_D / 2))
	wall(Vector3.new(BASE_W, wallH, 2), at(0, 1.5 + wallH / 2, BASE_D - 1))
	for _, x in { -BASE_W / 2 + 1, BASE_W / 2 - 1 } do
		for _, d in { 2, BASE_D / 2, BASE_D - 1 } do
			part({ Name = "Pillar", Size = Vector3.new(3, 8, 3), CFrame = at(x, 5.5, d), Color = PAPER, Studs = "all" }, folder)
			local lamp = part({ Name = "PillarLamp", Size = Vector3.new(2.4, 1.6, 2.4), CFrame = at(x, 10.3, d), Color = color, Material = Enum.Material.Neon }, folder)
			if d == BASE_D / 2 then
				Props.light(lamp, color, 24, 1.2)
			end
		end
	end

	-- arche d'entrée avec le nom du propriétaire
	for _, side in { -1, 1 } do
		part({ Name = "GatePillar", Size = Vector3.new(3, 16, 3), CFrame = at(side * 9.5, 9.5, 1.5), Color = color, Studs = "all" }, folder)
		local orb = part({ Name = "GateOrb", Size = Vector3.new(3.4, 3.4, 3.4), Shape = Enum.PartType.Ball, CFrame = at(side * 9.5, 19.2, 1.5), Color = PAPER, Material = Enum.Material.Neon }, folder)
		Props.light(orb, color, 18, 1)
	end
	local banner = part({ Name = "Banner", Size = Vector3.new(24, 5, 1.2), CFrame = at(0, 15.5, 1.5), Color = Props.INK, Studs = "top" }, folder)
	part({ Name = "BannerTrim", Size = Vector3.new(25, 6, 0.8), CFrame = at(0, 15.5, 1.8), Color = color, Material = Enum.Material.Neon }, folder)
	local signLabel = surfaceText(banner, Enum.NormalId.Back, "FREE BASE", PAPER, 25)
	surfaceText(banner, Enum.NormalId.Front, "FREE BASE", PAPER, 25)

	-- présentoirs
	local cases = {}
	local n = 0
	for _, depth in CASE_ROWS do
		for _, x in CASE_COLS do
			n += 1
			-- le présentoir regarde vers l'entrée (+Z local)
			local show = Showcase.build(at(x, 1.7, depth), folder, "Case" .. n)
			local label = billboard(show.Top, UDim2.fromOffset(170, 34), Vector3.new(0, -2.4, 0), "", PAPER, 45)
			cases[n] = {
				Index = n,
				Show = show,
				Plinth = show.Base,
				Label = label,
				CardCFrame = show.CardCFrame,
			}
		end
	end

	-- dalle de collecte (devant à gauche)
	local collect = part({ Name = "Collect", Size = Vector3.new(10, 0.4, 7), CFrame = at(-17, 1.9, 9), Color = Color3.fromRGB(80, 230, 140), Material = Enum.Material.Neon }, folder)
	part({ Name = "CollectRim", Size = Vector3.new(11, 0.3, 8), CFrame = at(-17, 1.75, 9), Color = Props.GOLD }, folder)
	local collectLabel = billboard(collect, UDim2.fromOffset(220, 50), Vector3.new(0, 4, 0), "", Color3.fromRGB(80, 230, 140), 70)
	billboard(collect, UDim2.fromOffset(160, 22), Vector3.new(0, 2.2, 0), "STEP TO COLLECT", PAPER, 35)

	-- tapis de course (devant à droite). On court vers l'entrée.
	local tmFolder = Instance.new("Folder")
	tmFolder.Name = "Treadmill"
	tmFolder.Parent = folder
	local tx, td = 17, 11
	local tmBase = part({ Name = "TreadmillBase", Size = Vector3.new(9, 1.4, 16), CFrame = at(tx, 2.4, td), Color = Props.INK, Studs = "top" }, tmFolder)
	local belt = part({ Name = "Belt", Size = Vector3.new(6.5, 0.3, 14), CFrame = at(tx, 3.2, td), Color = Color3.fromRGB(35, 35, 45), Material = Enum.Material.Fabric }, tmFolder)
	-- 6 habillages (un par palier de niveaux), un seul visible à la fois
	local tiers = { {}, {}, {}, {}, {}, {} }
	local function deco(n: number, props: { [string]: any })
		props.CanCollide = false
		props.CanQuery = false
		local baseT = props.Transparency or 0
		props.Transparency = 1
		local p = part(props, tmFolder)
		p:SetAttribute("BaseT", baseT)
		table.insert(tiers[n], p)
		return p
	end
	local function T(x, y, d)
		return at(tx + x, y, td + d)
	end
	local grey = Color3.fromRGB(170, 175, 190)
	local metal = Color3.fromRGB(205, 210, 220)
	-- 1. BASIC : rambardes grises
	for _, side in { -1, 1 } do
		deco(1, { Name = "Side", Size = Vector3.new(1, 1.6, 16), CFrame = T(side * 4, 3.2, 0), Color = grey, Studs = "top" })
		deco(1, { Name = "Rail", Size = Vector3.new(0.6, 0.6, 7), CFrame = T(side * 4, 6.4, -3.5), Color = metal, Material = Enum.Material.Metal })
		deco(1, { Name = "Post", Size = Vector3.new(0.6, 3.4, 0.6), CFrame = T(side * 4, 4.6, -6.7), Color = metal, Material = Enum.Material.Metal })
	end
	-- 2. SPORT : panneaux verts à bande blanche, gourde, barre à serviette
	local green = Color3.fromRGB(80, 220, 120)
	for _, side in { -1, 1 } do
		deco(2, { Name = "Side", Size = Vector3.new(1.2, 2, 16), CFrame = T(side * 4.1, 3.4, 0), Color = green, Studs = "all" })
		deco(2, { Name = "Stripe", Size = Vector3.new(1.3, 0.4, 16.1), CFrame = T(side * 4.1, 3.6, 0), Color = Color3.new(1, 1, 1) })
		deco(2, { Name = "Rail", Size = Vector3.new(0.7, 0.7, 7), CFrame = T(side * 4.1, 6.6, -3.5), Color = green, Material = Enum.Material.Metal })
		deco(2, { Name = "Post", Size = Vector3.new(0.7, 3.6, 0.7), CFrame = T(side * 4.1, 4.8, -6.7), Color = metal, Material = Enum.Material.Metal })
	end
	deco(2, { Name = "Bottle", Size = Vector3.new(1.4, 0.8, 0.8), Shape = Enum.PartType.Cylinder, CFrame = T(2.6, 8.1, -7.6) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(60, 170, 255), Material = Enum.Material.Glass, Transparency = 0.2 })
	deco(2, { Name = "Towel", Size = Vector3.new(6, 0.5, 0.5), CFrame = T(0, 6.6, -7), Color = Color3.new(1, 1, 1), Material = Enum.Material.Fabric })
	-- 3. PRO : bleu, liserés lumineux, enceintes, arche
	local blue = Color3.fromRGB(60, 150, 255)
	for _, side in { -1, 1 } do
		deco(3, { Name = "Side", Size = Vector3.new(1.4, 2.2, 16.4), CFrame = T(side * 4.2, 3.5, 0), Color = blue, Studs = "all" })
		deco(3, { Name = "Edge", Size = Vector3.new(0.3, 0.2, 14), CFrame = T(side * 3.35, 3.45, 0), Color = Color3.fromRGB(120, 220, 255), Material = Enum.Material.Neon })
		deco(3, { Name = "Rail", Size = Vector3.new(0.7, 0.7, 7), CFrame = T(side * 4.2, 6.6, -3.5), Color = metal, Material = Enum.Material.Metal })
		deco(3, { Name = "Post", Size = Vector3.new(0.7, 3.6, 0.7), CFrame = T(side * 4.2, 4.8, -6.7), Color = metal, Material = Enum.Material.Metal })
		deco(3, { Name = "Speaker", Size = Vector3.new(2.2, 6, 2.2), CFrame = T(side * 6.4, 4.6, 6), Color = Color3.fromRGB(30, 34, 52), Studs = "all" })
		deco(3, { Name = "Cone", Size = Vector3.new(0.3, 1.6, 1.6), Shape = Enum.PartType.Cylinder, CFrame = T(side * 6.4, 5.6, 4.85) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(120, 220, 255), Material = Enum.Material.Neon })
		deco(3, { Name = "ArchPost", Size = Vector3.new(1, 9, 1), CFrame = T(side * 4.6, 7.5, 7.6), Color = blue, Studs = "all" })
	end
	deco(3, { Name = "Arch", Size = Vector3.new(10.2, 1.2, 1.2), CFrame = T(0, 12.4, 7.6), Color = Color3.fromRGB(120, 220, 255), Material = Enum.Material.Neon })
	-- 4. TURBO : violet, éventails, ailerons, lumière sous le tapis
	local purple = Color3.fromRGB(170, 90, 255)
	for _, side in { -1, 1 } do
		deco(4, { Name = "Side", Size = Vector3.new(1.6, 2.4, 16.6), CFrame = T(side * 4.3, 3.6, 0), Color = purple, Studs = "all" })
		deco(4, { Name = "Under", Size = Vector3.new(0.4, 0.3, 16), CFrame = T(side * 4.3, 2.2, 0), Color = Color3.fromRGB(220, 140, 255), Material = Enum.Material.Neon })
		deco(4, { Name = "Rail", Size = Vector3.new(0.7, 0.7, 7), CFrame = T(side * 4.3, 6.6, -3.5), Color = Color3.fromRGB(220, 140, 255), Material = Enum.Material.Neon })
		deco(4, { Name = "Post", Size = Vector3.new(0.7, 3.6, 0.7), CFrame = T(side * 4.3, 4.8, -6.7), Color = metal, Material = Enum.Material.Metal })
		deco(4, { Name = "FanBox", Size = Vector3.new(1.4, 6, 6), Shape = Enum.PartType.Cylinder, CFrame = T(side * 6.6, 5.6, 5) * CFrame.Angles(0, 0, 0), Color = Color3.fromRGB(40, 30, 60) })
		for k = 0, 2 do
			deco(4, { Name = "Blade", Size = Vector3.new(0.2, 5, 1), CFrame = T(side * 7.4, 5.6, 5) * CFrame.Angles(math.rad(k * 60), 0, 0), Color = Color3.fromRGB(220, 140, 255), Material = Enum.Material.Neon })
		end
		for k = 0, 2 do
			deco(4, { Name = "Fin", Size = Vector3.new(0.4, 2.6, 1.4), CFrame = T(side * 5.1, 4.8, -3 + k * 3) * CFrame.Angles(0, 0, math.rad(side * -30)), Color = purple, Material = Enum.Material.Neon })
		end
	end
	-- 5. HYPER : cadre doré, arche à orbes, cristaux jaunes
	local gold = Color3.fromRGB(255, 200, 40)
	for _, side in { -1, 1 } do
		deco(5, { Name = "Side", Size = Vector3.new(1.6, 2.6, 16.8), CFrame = T(side * 4.3, 3.7, 0), Color = gold, Material = Enum.Material.Metal, Studs = "top" })
		deco(5, { Name = "Rail", Size = Vector3.new(0.8, 0.8, 7), CFrame = T(side * 4.3, 6.8, -3.5), Color = gold, Material = Enum.Material.Metal })
		deco(5, { Name = "Post", Size = Vector3.new(0.8, 3.8, 0.8), CFrame = T(side * 4.3, 4.9, -6.7), Color = gold, Material = Enum.Material.Metal })
		deco(5, { Name = "ArchPost", Size = Vector3.new(1.4, 11, 1.4), CFrame = T(side * 5, 8.5, 7.8), Color = gold, Material = Enum.Material.Metal })
		deco(5, { Name = "Orb", Size = Vector3.new(2.4, 2.4, 2.4), Shape = Enum.PartType.Ball, CFrame = T(side * 5, 15, 7.8), Color = Color3.fromRGB(255, 240, 150), Material = Enum.Material.Neon })
		for k, d in { -4, 1, 6 } do
			deco(5, { Name = "Crystal", Size = Vector3.new(1.2, 3 + k, 1.2), CFrame = T(side * 6.2, 3.4 + k * 0.5, d) * CFrame.Angles(math.rad(10 * k), 0, math.rad(side * 20)), Color = Color3.fromRGB(255, 220, 60), Material = Enum.Material.Neon })
		end
	end
	deco(5, { Name = "Arch", Size = Vector3.new(11.4, 1.4, 1.4), CFrame = T(0, 14, 7.8), Color = gold, Material = Enum.Material.Metal })
	-- 6. QUANTUM : gros cristaux roses et cyan, anneaux flottants
	local pink = Color3.fromRGB(255, 60, 140)
	local cyan = Color3.fromRGB(80, 230, 255)
	for _, side in { -1, 1 } do
		deco(6, { Name = "Side", Size = Vector3.new(1.8, 2.8, 17), CFrame = T(side * 4.4, 3.8, 0), Color = Color3.fromRGB(40, 20, 50), Studs = "all" })
		deco(6, { Name = "Edge", Size = Vector3.new(0.4, 0.3, 16), CFrame = T(side * 3.4, 3.5, 0), Color = pink, Material = Enum.Material.Neon })
		deco(6, { Name = "Rail", Size = Vector3.new(0.8, 0.8, 7), CFrame = T(side * 4.4, 6.9, -3.5), Color = cyan, Material = Enum.Material.Neon })
		deco(6, { Name = "Post", Size = Vector3.new(0.8, 3.8, 0.8), CFrame = T(side * 4.4, 5, -6.7), Color = Color3.fromRGB(40, 20, 50) })
		for k, d in { -6, -1, 4, 8 } do
			local c = (k % 2 == 0) and pink or cyan
			deco(6, { Name = "Crystal", Size = Vector3.new(1.8, 5 + (k % 3) * 2, 1.8), CFrame = T(side * (6 + (k % 2)), 4.5 + (k % 3), d) * CFrame.Angles(math.rad(8 * k), math.rad(30 * k), math.rad(side * 22)), Color = c, Material = Enum.Material.Glass, Transparency = 0.15 })
			deco(6, { Name = "CrystalCore", Size = Vector3.new(0.8, 3 + (k % 3), 0.8), CFrame = T(side * (6 + (k % 2)), 4.5 + (k % 3), d) * CFrame.Angles(math.rad(8 * k), math.rad(30 * k), math.rad(side * 22)), Color = c, Material = Enum.Material.Neon })
		end
	end
	-- deux anneaux lumineux autour du coureur (faits de segments pour rester creux)
	for k, y in { 9.5, 12 } do
		local radius = 5 - k * 0.8
		for i = 0, 15 do
			local ang = i / 16 * math.pi * 2
			deco(6, {
				Name = "Ring",
				Size = Vector3.new(radius * 0.42, 0.35, 0.35),
				CFrame = T(math.cos(ang) * radius, y, math.sin(ang) * radius) * CFrame.Angles(0, -ang + math.pi / 2, 0),
				Color = (k == 1) and pink or cyan,
				Material = Enum.Material.Neon,
			})
		end
	end
	local console = part({ Name = "Console", Size = Vector3.new(7, 5, 1.4), CFrame = at(tx, 5, td - 7.6), Color = Color3.fromRGB(170, 175, 190), Studs = "all" }, tmFolder)
	local screen = part({ Name = "Screen", Size = Vector3.new(5, 2.2, 0.2), CFrame = at(tx, 5.8, td - 6.85), Color = Color3.fromRGB(80, 255, 140), Material = Enum.Material.Neon }, tmFolder)
	local glow = part({ Name = "Glow", Size = Vector3.new(7, 0.2, 15), CFrame = at(tx, 1.85, td), Color = color, Material = Enum.Material.Neon, CanCollide = false }, tmFolder)
	-- le joueur se place ici et regarde vers la console (l'entrée)
	local spotPos = at(tx, 5, td + 2).Position
	local consolePos = at(tx, 5, td - 10).Position
	local spot = CFrame.lookAt(spotPos, Vector3.new(consolePos.X, spotPos.Y, consolePos.Z))
	console:SetAttribute("BaseIndex", index)
	console:SetAttribute("Spot", spot)
	console:SetAttribute("BeltTop", 3.35)
	game:GetService("CollectionService"):AddTag(console, "Treadmill")

	-- panneau d'amélioration au-dessus de la console (lisible depuis le tapis et depuis la rue)
	local signCF = at(tx, 10.6, td - 8.2)
	part({ Name = "SignPost", Size = Vector3.new(0.8, 3, 0.8), CFrame = at(tx, 8.2, td - 8.2), Color = Props.INK }, tmFolder)
	local upgradeSign = part({ Name = "UpgradeSign", Size = Vector3.new(9, 4.6, 0.8), CFrame = signCF, Color = Color3.fromRGB(30, 34, 52), Studs = "top" }, tmFolder)
	part({ Name = "UpgradeTrim", Size = Vector3.new(9.6, 5.2, 0.5), CFrame = signCF, Color = color, Material = Enum.Material.Neon }, tmFolder)
	local upgradeLabel = surfaceText(upgradeSign, Enum.NormalId.Front, "", PAPER, 30)
	local upgradeLabelBack = surfaceText(upgradeSign, Enum.NormalId.Back, "", PAPER, 30)
	upgradeSign:SetAttribute("BaseIndex", index)
	game:GetService("CollectionService"):AddTag(upgradeSign, "TreadmillSign")

	-- machine de gradation (fond)
	local machine = part({ Name = "GradingMachine", Size = Vector3.new(20, 9, 5), CFrame = at(0, 6.2, 58), Color = Color3.fromRGB(45, 50, 72), Studs = "all" }, folder)
	part({ Name = "MachineTop", Size = Vector3.new(21, 1, 6), CFrame = at(0, 11.2, 58), Color = color, Studs = "top" }, folder)
	local machineScreen = part({ Name = "MachineScreen", Size = Vector3.new(16, 4.6, 0.3), CFrame = at(0, 7.2, 55.4), Color = Color3.fromRGB(15, 25, 50), Material = Enum.Material.SmoothPlastic }, folder)
	local machineLabel = surfaceText(machineScreen, Enum.NormalId.Back, "GRADING LAB", Color3.fromRGB(0, 230, 255), 25)
	for k = -2, 2 do
		part({ Name = "MachineSlot", Size = Vector3.new(2.4, 0.5, 0.4), CFrame = at(k * 3.2, 3.6, 55.4), Color = Color3.fromRGB(0, 255, 200), Material = Enum.Material.Neon }, folder)
	end
	for _, side in { -1, 1 } do
		part({ Name = "Tube", Size = Vector3.new(9, 1.6, 1.6), Shape = Enum.PartType.Cylinder, CFrame = at(side * 11.5, 6, 58) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(150, 255, 230), Material = Enum.Material.Glass, Transparency = 0.3 }, folder)
	end
	local labPrompt = prompt(machine, "Open", "Grading Lab", 0, 16)
	labPrompt.Name = "LabPrompt"
	local machineTag = billboard(machine, UDim2.fromOffset(220, 40), Vector3.new(0, 8.5, 0), "", Color3.fromRGB(255, 220, 80), 80)

	-- décor de façade
	for _, side in { -1, 1 } do
		Props.bush(at(side * 25, 1.5, -3).Position, Color3.fromRGB(70, 170, 70), folder)
	end

	return {
		Index = index,
		Color = color,
		Folder = folder,
		CFrame = cf,
		Cases = cases,
		SignLabel = signLabel,
		Collect = collect,
		CollectLabel = collectLabel,
		Spawn = at(0, 5, 16) * CFrame.Angles(0, math.pi, 0),
		Treadmill = {
			Belt = belt,
			Base = tmBase,
			Console = console,
			Screen = screen,
			Glow = glow,
			Tiers = tiers,
			Spot = spot,
			Sign = upgradeSign,
			SignLabels = { upgradeLabel, upgradeLabelBack },
		},
		Machine = machine,
		MachineLabel = machineLabel,
		MachineTag = machineTag,
	}
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
	part({ Name = "Ground", Size = Vector3.new(half * 2, 1, MapBuilder.ZoneLength), CFrame = CFrame.new(0, -0.5, midZ), Color = zone.Main:Lerp(PAPER, 0.45), Studs = "top" }, folder)
	part({ Name = "Road", Size = Vector3.new(road * 2, 0.2, MapBuilder.ZoneLength), CFrame = CFrame.new(0, 0.1, midZ), Color = Color3.fromRGB(52, 54, 68) }, folder)
	for _, side in { -1, 1 } do
		part({ Name = "Sidewalk", Size = Vector3.new(6, 0.5, MapBuilder.ZoneLength), CFrame = CFrame.new(side * (road + 3), 0.25, midZ), Color = Color3.fromRGB(205, 205, 215), Studs = "top" }, folder)
		part({ Name = "Curb", Size = Vector3.new(0.6, 0.6, MapBuilder.ZoneLength), CFrame = CFrame.new(side * (road + 0.3), 0.3, midZ), Color = zone.Accent }, folder)
	end
	for k = 0, 7 do
		part({ Name = "Dash", Size = Vector3.new(1, 0.05, 10), CFrame = CFrame.new(0, 0.22, gateZ + 12 + k * 25), Color = Color3.fromRGB(255, 220, 80), CanCollide = false }, folder)
	end
	-- murs d'enceinte en briques
	for _, side in { -1, 1 } do
		part({ Name = "Fence", Size = Vector3.new(2, 24, MapBuilder.ZoneLength), CFrame = CFrame.new(side * (half + 1), 12, midZ), Color = zone.Main:Lerp(Color3.fromRGB(150, 110, 70), 0.3), Studs = "all" }, folder)
		part({ Name = "FenceTop", Size = Vector3.new(3, 1.4, MapBuilder.ZoneLength), CFrame = CFrame.new(side * (half + 1), 24.7, midZ), Color = zone.Accent, Studs = "top" }, folder)
	end

	-- arche d'entrée de zone (décorative, on peut toujours passer)
	for _, side in { -1, 1 } do
		part({ Name = "Pillar", Size = Vector3.new(5, 30, 5), CFrame = CFrame.new(side * (road + 2.5), 15, gateZ), Color = zone.Accent, Studs = "all" }, folder)
		local cap = part({ Name = "PillarLight", Size = Vector3.new(4, 2, 4), CFrame = CFrame.new(side * (road + 2.5), 31, gateZ), Color = zone.Accent, Material = Enum.Material.Neon }, folder)
		Props.light(cap, zone.Accent, 30, 1.5)
	end
	local arch = part({ Name = "Arch", Size = Vector3.new(road * 2 + 10, 7, 3), CFrame = CFrame.new(0, 26.5, gateZ), Color = INK, Studs = "top" }, folder)
	surfaceText(arch, Enum.NormalId.Front, ("%d · %s"):format(i, zone.Name:upper()), zone.Accent, 20)
	surfaceText(arch, Enum.NormalId.Back, "BACK TO YOUR BASE", Color3.fromRGB(80, 230, 140), 20)

	-- PANNEAU VITESSE CONSEILLÉE, juste avant l'arche, à droite de la route
	local rec = zone.Speed > 0 and ("RECOMMENDED SPEED\n" .. Format.short(zone.Speed)) or "NO SPEED NEEDED"
	signBoard(
		CFrame.new(road + 13, 9, gateZ - 8) * CFrame.Angles(0, math.rad(25), 0),
		16,
		9,
		INK,
		("ZONE %d · %s\n%s"):format(i, zone.Name:upper(), rec),
		zone.Speed > 0 and Color3.fromRGB(255, 220, 80) or Color3.fromRGB(80, 230, 140),
		"BACK TO YOUR BASE",
		folder
	)

	-- lampadaires
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
	local wall = zone.Main
	local at = building(shopCF, 70, 56, 22, 22, wall, zone.Accent, PAPER, folder)

	-- sol en damier aux couleurs de la boutique
	for a = 0, 6 do
		for b = 0, 4 do
			part({
				Name = "FloorTile",
				Size = Vector3.new(10, 0.2, 10.8),
				CFrame = at(-30 + a * 10, 1.1, 2.4 + b * 10.8),
				Color = ((a + b) % 2 == 0) and zone.Accent:Lerp(PAPER, 0.55) or PAPER,
				Studs = "top",
			}, folder)
		end
	end

	-- façade : pilastres, corniche, enseigne lumineuse, vitrines avec affiches de cartes, auvent
	for _, x in { -34, -16, 16, 34 } do
		part({ Name = "Pilaster", Size = Vector3.new(3, 22, 1.4), CFrame = at(x, 12, -0.6), Color = zone.Accent:Lerp(INK, 0.15), Studs = "all" }, folder)
	end
	part({ Name = "Cornice", Size = Vector3.new(72, 2, 3), CFrame = at(0, 22.5, -0.8), Color = zone.Accent, Studs = "top" }, folder)
	local shopSign = part({ Name = "ShopSign", Size = Vector3.new(44, 7, 0.8), CFrame = at(0, 28.5, -0.8), Color = INK }, folder)
	part({ Name = "ShopSignTrim", Size = Vector3.new(45.5, 8.5, 0.5), CFrame = at(0, 28.5, -0.4), Color = zone.Accent, Material = Enum.Material.Neon }, folder)
	surfaceText(shopSign, Enum.NormalId.Back, zone.Name:upper(), zone.Accent, 25)
	local signLight = Instance.new("SurfaceLight")
	signLight.Face = Enum.NormalId.Back
	signLight.Color = zone.Accent
	signLight.Range = 18
	signLight.Brightness = 2
	signLight.Parent = shopSign

	-- cartes affichées en vitrine (les meilleures de la boutique)
	local best = 0
	for rarity in zone.Rarity do
		best = math.max(best, Cards.Rarities[rarity].Order)
	end
	local showcase = {}
	for _, c in Cards.List do
		if not c.Season and Cards.Rarities[c.Rarity].Order >= best - 1 then
			table.insert(showcase, c.Id)
		end
	end
	for k, side in { -1, 1 } do
		part({ Name = "WindowFrame", Size = Vector3.new(15, 11, 0.3), CFrame = at(side * 25, 9, -0.05), Color = Props.GOLD }, folder)
		local id = showcase[((i + k) % math.max(#showcase, 1)) + 1]
		if id then
			local poster = CardArt.part(id, "Holo", nil, false)
			poster.Size = Vector3.new(6, 8.4, 0.3)
			poster.CFrame = at(side * 25, 9, -0.35) * CFrame.Angles(0, math.pi, 0)
			poster.Parent = folder
		end
		part({ Name = "Window", Size = Vector3.new(14, 10, 0.3), CFrame = at(side * 25, 9, -0.7), Color = Color3.fromRGB(190, 225, 255), Material = Enum.Material.Glass, Transparency = 0.6 }, folder)
	end
	Props.awning(at(0, 17.5, -1.2) * CFrame.Angles(0, math.pi, 0), 26, zone.Accent, PAPER, folder)
	-- parapet lumineux sur le toit
	part({ Name = "Parapet", Size = Vector3.new(72, 1.6, 1), CFrame = at(0, 25, 0), Color = zone.Accent, Material = Enum.Material.Neon }, folder)

	-- intérieur : plafonniers, étagères de boîtes, affiches, plantes, comptoir
	Props.ceilingLights(at(0, 22.6, 2), 64, 52, folder)
	for _, side in { -1, 1 } do
		local inwardDir = shopCF.RightVector * -side
		for _, d in { 14, 40 } do
			local p = at(side * 32.5, 0, d).Position
			local shelfCF = CFrame.lookAt(p, p + inwardDir)
			part({ Name = "Shelf", Size = Vector3.new(10, 9, 2), CFrame = shelfCF * CFrame.new(0, 5.5, 0), Color = Color3.fromRGB(120, 80, 50), Studs = "all" }, folder)
			for row = 0, 2 do
				for b = 0, 3 do
					part({
						Name = "Booster",
						Size = Vector3.new(1.8, 2, 1.2),
						CFrame = shelfCF * CFrame.new(-3.6 + b * 2.4, 2.6 + row * 2.9, -1.4),
						Color = ((b + row) % 3 == 0) and zone.Accent or (((b + row) % 3 == 1) and zone.Main or Props.GOLD),
						Studs = "top",
					}, folder)
				end
			end
		end
		-- affiche de carte au mur
		local wp = at(side * 32.8, 11, 27).Position
		local id = showcase[((i + side + 3) % math.max(#showcase, 1)) + 1]
		if id then
			local poster = CardArt.part(id, "Normal", nil, false)
			poster.Size = Vector3.new(7, 9.8, 0.3)
			poster.CFrame = CFrame.lookAt(wp, wp + inwardDir) * CFrame.Angles(0, math.pi, 0)
			poster.Parent = folder
		end
		Props.wallLamp(CFrame.lookAt(at(side * 32.8, 16, 14).Position, at(side * 32.8, 16, 14).Position + inwardDir), folder)
		Props.wallLamp(CFrame.lookAt(at(side * 32.8, 16, 40).Position, at(side * 32.8, 16, 40).Position + inwardDir), folder)
		Props.plantPot(at(side * 29, 1, 4).Position, folder)
		Props.plantPot(at(side * 29, 1, 52).Position, folder)
	end
	Props.counter(at(0, 1, 54) * CFrame.Angles(0, math.pi, 0), 16, zone.Accent, folder)
	Props.cardBoxes(at(10, 1, 53).Position, { zone.Accent, zone.Main, Props.GOLD }, folder)

	-- présentoirs (design selon la rareté de la carte posée dessus)
	local pedestals = {}
	local positions = { { -24, 14 }, { 24, 14 }, { -12, 24 }, { 12, 24 }, { -24, 34 }, { 24, 34 } }
	for k = 1, Config.PedestalsPerZone do
		local pos = positions[k]
		local show = Showcase.build(at(pos[1], 1.2, pos[2]), folder, "Stand" .. k)
		pedestals[k] = {
			Index = k,
			Show = show,
			Stand = show.Base,
			CardCFrame = show.CardCFrame,
		}
	end

	-- cartes géantes côté gauche de la rue
	for k, z in { gateZ + 45, gateZ + 155 } do
		local id = showcase[((i + k) % math.max(#showcase, 1)) + 1]
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
	}
end

--------------------------------------------------------------------
-- MAP COMPLÈTE
--------------------------------------------------------------------
function MapBuilder.Build()
	local root = Instance.new("Folder")
	root.Name = "Map"
	root.Parent = workspace

	local road = MapBuilder.RoadHalfWidth
	local half = MapBuilder.ZoneHalfWidth
	local backZ = -290
	local hubLen = MapBuilder.HubEdgeZ - backZ
	local hubMid = (MapBuilder.HubEdgeZ + backZ) / 2

	-- quartier des bases : pelouse, rue, trottoirs
	part({ Name = "HubGround", Size = Vector3.new(half * 2, 2, hubLen), CFrame = CFrame.new(0, -1, hubMid), Color = GRASS, Studs = "top" }, root)
	part({ Name = "HubRoad", Size = Vector3.new(road * 2, 0.2, hubLen), CFrame = CFrame.new(0, 0.1, hubMid), Color = Color3.fromRGB(240, 225, 190), Studs = "top" }, root)
	for _, side in { -1, 1 } do
		part({ Name = "HubSidewalk", Size = Vector3.new(6, 0.5, hubLen), CFrame = CFrame.new(side * (road + 3), 0.25, hubMid), Color = Color3.fromRGB(205, 205, 215), Studs = "top" }, root)
		part({ Name = "HubWall", Size = Vector3.new(4, 28, hubLen), CFrame = CFrame.new(side * (half + 2), 14, hubMid), Color = Color3.fromRGB(210, 150, 95), Studs = "all" }, root)
		part({ Name = "HubWallTop", Size = Vector3.new(6, 2, hubLen), CFrame = CFrame.new(side * (half + 2), 29, hubMid), Color = GRASS, Studs = "top" }, root)
	end
	part({ Name = "HubWallBack", Size = Vector3.new(half * 2 + 8, 28, 4), CFrame = CFrame.new(0, 14, backZ - 2), Color = Color3.fromRGB(210, 150, 95), Studs = "all" }, root)
	part({ Name = "HubWallBackTop", Size = Vector3.new(half * 2 + 10, 2, 6), CFrame = CFrame.new(0, 29, backZ - 2), Color = GRASS, Studs = "top" }, root)
	local title = part({ Name = "Title", Size = Vector3.new(80, 18, 1), CFrame = CFrame.new(0, 40, backZ + 1), Transparency = 1, CanCollide = false }, root)
	surfaceText(title, Enum.NormalId.Back, Config.GameName, PAPER, 20)

	-- ligne SAFE ZONE et arche de sortie
	part({ Name = "SafeLine", Size = Vector3.new(road * 2, 0.1, 1.2), CFrame = CFrame.new(0, 0.3, MapBuilder.HubEdgeZ - 1), Color = Color3.fromRGB(255, 50, 70), Material = Enum.Material.Neon, CanCollide = false }, root)
	local safeText = part({ Name = "SafeText", Size = Vector3.new(30, 0.1, 6), CFrame = CFrame.new(0, 0.3, MapBuilder.HubEdgeZ - 6), Transparency = 1, CanCollide = false }, root)
	surfaceText(safeText, Enum.NormalId.Top, "SAFE ZONE", PAPER, 20)
	for _, side in { -1, 1 } do
		part({ Name = "ExitPillar", Size = Vector3.new(5, 30, 5), CFrame = CFrame.new(side * (road + 2.5), 15, MapBuilder.HubEdgeZ + 2), Color = Color3.fromRGB(255, 70, 110), Studs = "all" }, root)
	end
	local exitArch = part({ Name = "ExitArch", Size = Vector3.new(road * 2 + 10, 7, 3), CFrame = CFrame.new(0, 26.5, MapBuilder.HubEdgeZ + 2), Color = Color3.fromRGB(255, 70, 110), Studs = "top" }, root)
	surfaceText(exitArch, Enum.NormalId.Front, "TO THE SHOPS", PAPER, 20)
	surfaceText(exitArch, Enum.NormalId.Back, "SAFE ZONE", Color3.fromRGB(80, 230, 140), 20)
	part({ Name = "Approach", Size = Vector3.new(road * 2, 0.2, MapBuilder.ZoneGateZ(1) - MapBuilder.HubEdgeZ), CFrame = CFrame.new(0, 0.1, (MapBuilder.HubEdgeZ + MapBuilder.ZoneGateZ(1)) / 2), Color = Color3.fromRGB(52, 54, 68) }, root)
	part({ Name = "ApproachGround", Size = Vector3.new(half * 2, 1, MapBuilder.ZoneGateZ(1) - MapBuilder.HubEdgeZ), CFrame = CFrame.new(0, -0.5, (MapBuilder.HubEdgeZ + MapBuilder.ZoneGateZ(1)) / 2), Color = GRASS, Studs = "top" }, root)
	for _, side in { -1, 1 } do
		part({ Name = "ApproachWall", Size = Vector3.new(2, 24, MapBuilder.ZoneGateZ(1) - MapBuilder.HubEdgeZ), CFrame = CFrame.new(side * (half + 1), 12, (MapBuilder.HubEdgeZ + MapBuilder.ZoneGateZ(1)) / 2), Color = Color3.fromRGB(210, 150, 95), Studs = "all" }, root)
	end

	-- spawn neutre, fontaine, classements
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 0.7, backZ + 22)
	spawn.Color = INK
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Studs
	spawn.Parent = root
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	local boards = {}
	for _, info in { { "TopIncome", "TOP CASH/S", -40 }, { "TopSpeed", "TOP SPEED", 40 } } do
		local board = part({ Name = info[1], Size = Vector3.new(18, 24, 1), CFrame = CFrame.new(info[3], 14, backZ + 6) * CFrame.Angles(0, math.pi, 0), Color = INK }, root)
		part({ Name = "BoardFrame", Size = Vector3.new(19.5, 25.5, 0.8), CFrame = board.CFrame * CFrame.new(0, 0, 0.3), Color = GOLD, Material = Enum.Material.Metal }, root)
		part({ Name = "BoardBase", Size = Vector3.new(20, 2, 4), CFrame = CFrame.new(info[3], 1, backZ + 6), Color = INK, Studs = "top" }, root)
		boards[info[1]] = { part = board, title = info[2] }
	end

	-- bases : 4 de chaque côté de la rue, entrée face à la rue
	local basesFolder = Instance.new("Folder")
	basesFolder.Name = "Bases"
	basesFolder.Parent = root
	local bases = {}
	for k, z in { -245, -175, -105, -35 } do
		bases[k] = buildBase(k, Vector3.new(-(road + 6), 0, z), Vector3.new(-1, 0, 0), basesFolder)
		bases[k + 4] = buildBase(k + 4, Vector3.new(road + 6, 0, z), Vector3.new(1, 0, 0), basesFolder)
	end

	-- déco entre les bases et le long de la rue
	-- dans les allées entre les bases : buissons, fleurs, lampadaires
	for _, z in { -210, -140, -70 } do
		for _, side in { -1, 1 } do
			Props.bush(Vector3.new(side * 40, 0, z), Color3.fromRGB(80, 180, 70), root)
			Props.flowers(Vector3.new(side * 60, 0, z), root)
			Props.lampPost(Vector3.new(side * (road + 3), 0.5, z), Color3.fromRGB(255, 230, 150), root, Vector3.new(-side, 0, 0))
		end
	end
	for _, side in { -1, 1 } do
		Props.tree(Vector3.new(side * 60, 0, backZ + 8), 1.1, Color3.fromRGB(80, 180, 70), root)
		Props.lampPost(Vector3.new(side * (road + 3), 0.5, -2), Color3.fromRGB(255, 230, 150), root, Vector3.new(-side, 0, 0))
	end

	-- la rue des boutiques
	local zonesFolder = Instance.new("Folder")
	zonesFolder.Name = "Zones"
	zonesFolder.Parent = root
	local zones = {}
	for i, zone in Config.Zones do
		zones[i] = buildZone(i, zone, zonesFolder)
	end
	local lastZ = MapBuilder.ZoneGateZ(#Config.Zones) + MapBuilder.ZoneLength
	part({ Name = "EndWall", Size = Vector3.new(half * 2 + 4, 30, 3), CFrame = CFrame.new(0, 15, lastZ + 1.5), Color = INK, Studs = "all" }, root)

	return {
		Bases = bases,
		Zones = zones,
		Boards = boards,
	}
end

return MapBuilder
