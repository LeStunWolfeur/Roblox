--[[
	Construit toute la map, en style briques (picots).

	ZONE SÛRE (z < 0) : la rue des bases. 8 bases de joueurs (4 de chaque côté),
	  chacune avec son tapis de course, ses supports à cartes et ses étages (rebirth).
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
local Stands = require(script.Parent.Stands)
local Signs = require(script.Parent.Signs)

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
	return Signs.text(target, face, text, { PixelsPerStud = ppm, Color = color ~= PAPER and color or nil, Font = font })
end
MapBuilder.surfaceText = surfaceText

local function billboard(parent: Instance, size: UDim2, offset: Vector3, text: string, color: Color3?, maxDistance: number?)
	return Signs.billboard(parent, size, offset, text, color ~= PAPER and color or nil, maxDistance)
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

-- Panneau de zone sur deux pieds. cf = centre du panneau ; la face Front (-Z local) regarde les joueurs.
local function speedBoard(cf: CFrame, w: number, h: number, zoneIndex: number, zone, parent: Instance)
	local postHeight = cf.Position.Y + h / 2
	for _, side in { -1, 1 } do
		local p = (cf * CFrame.new(side * (w / 2 - 1.5), 0, 0.2)).Position
		part({ Name = "Post", Size = Vector3.new(1.2, postHeight, 1.2), CFrame = CFrame.new(p.X, postHeight / 2, p.Z), Color = Color3.fromRGB(60, 64, 80) }, parent)
		part({ Name = "PostCap", Size = Vector3.new(1.6, 0.6, 1.6), CFrame = CFrame.new(p.X, postHeight + 0.3, p.Z), Color = zone.Accent, Material = Enum.Material.Neon }, parent)
	end
	local board = part({ Name = "Board", Size = Vector3.new(w, h, 0.6), CFrame = cf, Color = INK }, parent)
	local colors = { zone.Accent:Lerp(Color3.new(1, 1, 1), 0.35), zone.Main, zone.Main:Lerp(INK, 0.45), INK }
	Signs.speedSign(board, Enum.NormalId.Front, {
		Zone = zoneIndex,
		Name = zone.Name:upper(),
		Speed = zone.Speed > 0 and Format.short(zone.Speed) or nil,
		Colors = colors,
		PixelsPerStud = 30,
	})
	Signs.panel(board, Enum.NormalId.Back, { Title = "BACK TO YOUR BASE", Colors = Signs.Palettes.Green, PixelsPerStud = 24 })
	return board
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
-- Milieu : 8 supports. Fond : mezzanines des étages 2 et 3 (débloquées par rebirth).
--------------------------------------------------------------------
local BASE_W = 60
local BASE_D = 64
local CASE_COLS = { -21, -7, 7, 21 }
-- rangées de supports par étage (profondeur) et hauteur du sol de chaque étage
local FLOOR_ROWS = { { 24, 36 }, { 50, 58 }, { 50, 58 } }
local FLOOR_Y = { 1.7, 13.7, 25.7 }
local MEZZ_FROM = 44 -- les étages 2 et 3 couvrent le fond de la base

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

	local white = Color3.fromRGB(246, 247, 250)
	local slate = Color3.fromRGB(46, 50, 64)
	local deep = color:Lerp(Props.INK, 0.45)

	-- socle sombre, bordé d'un liseré lumineux
	part({ Name = "Platform", Size = Vector3.new(BASE_W, 1.5, BASE_D), CFrame = at(0, 0.75, BASE_D / 2), Color = slate }, folder)
	for _, side in { -1, 1 } do
		part({ Name = "Underglow", Size = Vector3.new(0.3, 0.35, BASE_D), CFrame = at(side * (BASE_W / 2 + 0.1), 0.4, BASE_D / 2), Color = color, Material = Enum.Material.Neon, CanCollide = false }, folder)
	end
	part({ Name = "Underglow", Size = Vector3.new(BASE_W, 0.35, 0.3), CFrame = at(0, 0.4, BASE_D + 0.1), Color = color, Material = Enum.Material.Neon, CanCollide = false }, folder)
	-- sol en damier (la disposition des cartes ne change pas)
	local tile = 10
	for i = 0, BASE_W / tile - 1 do
		for j = 0, math.floor(BASE_D / tile) - 1 do
			part({
				Name = "Tile",
				Size = Vector3.new(tile, 0.2, tile),
				CFrame = at(-BASE_W / 2 + (i + 0.5) * tile, 1.6, 2 + (j + 0.5) * tile),
				Color = ((i + j) % 2 == 0) and light or PAPER,
			}, folder)
		end
	end
	part({ Name = "Edge", Size = Vector3.new(BASE_W + 0.6, 0.5, 0.6), CFrame = at(0, 1.5, -0.3), Color = color, Material = Enum.Material.Neon }, folder)
	-- tapis d'entrée jusqu'aux vitrines
	part({ Name = "Carpet", Size = Vector3.new(7, 0.1, 17), CFrame = at(0, 1.75, 10), Color = deep, Material = Enum.Material.Fabric }, folder)
	for _, side in { -1, 1 } do
		part({ Name = "CarpetEdge", Size = Vector3.new(0.4, 0.12, 17), CFrame = at(side * 3.6, 1.76, 10), Color = Props.GOLD, Material = Enum.Material.Metal }, folder)
	end

	-- murs vitrés façon galerie : muret, vitre, rambarde lumineuse, poteaux
	local function glassWall(len: number, c: CFrame, alongX: boolean)
		local function sz(thick: number, h: number): Vector3
			return alongX and Vector3.new(len, h, thick) or Vector3.new(thick, h, len)
		end
		part({ Name = "WallBase", Size = sz(1.3, 2.4), CFrame = c * CFrame.new(0, 1.2, 0), Color = color }, folder)
		local glass = part({ Name = "Glass", Size = sz(0.35, 5.2), CFrame = c * CFrame.new(0, 5, 0), Color = Color3.fromRGB(190, 225, 255), Material = Enum.Material.Glass, Transparency = 0.55 }, folder)
		glass.CastShadow = false
		part({ Name = "Rail", Size = sz(1.4, 0.55), CFrame = c * CFrame.new(0, 7.85, 0), Color = white }, folder)
		part({ Name = "RailGlow", Size = sz(0.25, 0.2), CFrame = c * CFrame.new(0, 8.2, 0), Color = color, Material = Enum.Material.Neon, CanCollide = false }, folder)
	end
	local y0 = 1.5
	glassWall(BASE_D - 4, at(-BASE_W / 2 + 0.7, y0, BASE_D / 2 + 1), false)
	glassWall(BASE_D - 4, at(BASE_W / 2 - 0.7, y0, BASE_D / 2 + 1), false)
	for _, x in { -BASE_W / 2 + 0.7, BASE_W / 2 - 0.7 } do
		for k = 1, 5 do
			local d = 4 + k * (BASE_D - 6) / 6
			part({ Name = "Post", Size = Vector3.new(1.6, 8.6, 1.6), CFrame = at(x, y0 + 4.3, d), Color = white }, folder)
			part({ Name = "PostCap", Size = Vector3.new(1.9, 0.5, 1.9), CFrame = at(x, y0 + 8.85, d), Color = color, Material = Enum.Material.Neon }, folder)
		end
	end
	-- mur du fond, plus haut, avec l'enseigne côté intérieur
	part({ Name = "BackWall", Size = Vector3.new(BASE_W, 15, 1.6), CFrame = at(0, y0 + 7.5, BASE_D - 0.8), Color = color }, folder)
	for _, h in { 3, 14.6 } do
		part({ Name = "BackBand", Size = Vector3.new(BASE_W + 0.2, 0.8, 1.8), CFrame = at(0, y0 + h, BASE_D - 0.8), Color = white }, folder)
	end
	for k = -2, 2 do
		part({ Name = "BackStripe", Size = Vector3.new(0.5, 10.8, 1.75), CFrame = at(k * 12, y0 + 8.8, BASE_D - 0.8), Color = deep }, folder)
	end
	local backSign = part({ Name = "BackSign", Size = Vector3.new(26, 6.5, 0.4), CFrame = at(0, y0 + 7.4, BASE_D - 1.8), Color = deep }, folder)

	-- tours d'angle à l'avant
	for _, side in { -1, 1 } do
		local x = side * (BASE_W / 2 - 1.8)
		part({ Name = "Tower", Size = Vector3.new(3.6, 13, 3.6), CFrame = at(x, y0 + 6.5, 1.8), Color = white }, folder)
		part({ Name = "TowerStripe", Size = Vector3.new(3.75, 9, 1.2), CFrame = at(x, y0 + 6.5, 1.8), Color = color }, folder)
		part({ Name = "TowerStripe", Size = Vector3.new(1.2, 9, 3.75), CFrame = at(x, y0 + 6.5, 1.8), Color = color }, folder)
		local lamp = part({ Name = "TowerLamp", Size = Vector3.new(3, 1.2, 3), CFrame = at(x, y0 + 13.6, 1.8), Color = color:Lerp(Color3.new(1, 1, 1), 0.3), Material = Enum.Material.Neon }, folder)
		Props.light(lamp, color, 26, 1.3)
		part({ Name = "TowerCap", Size = Vector3.new(4.2, 0.6, 4.2), CFrame = at(x, y0 + 14.5, 1.8), Color = white }, folder)
		-- façade basse entre la tour et l'entrée
		local segW = BASE_W / 2 - 3.6 - 12.5
		local segX = side * (12.5 + segW / 2)
		part({ Name = "FrontBase", Size = Vector3.new(segW, 2.4, 1.3), CFrame = at(segX, y0 + 1.2, 0.8), Color = color }, folder)
		part({ Name = "FrontRail", Size = Vector3.new(segW, 0.5, 1.4), CFrame = at(segX, y0 + 2.65, 0.8), Color = white }, folder)
		part({ Name = "FrontGlow", Size = Vector3.new(segW, 0.2, 0.25), CFrame = at(segX, y0 + 2.95, 0.8), Color = color, Material = Enum.Material.Neon, CanCollide = false }, folder)
	end

	-- entrée : deux pylônes, une grande enseigne et un auvent éclairé
	for _, side in { -1, 1 } do
		local x = side * 10
		part({ Name = "Pylon", Size = Vector3.new(3, 16, 3), CFrame = at(x, y0 + 8, 1.2), Color = color }, folder)
		for _, h in { 2.5, 6.5, 10.5 } do
			part({ Name = "PylonBand", Size = Vector3.new(3.25, 0.5, 3.25), CFrame = at(x, y0 + h, 1.2), Color = white }, folder)
		end
		part({ Name = "PylonGlow", Size = Vector3.new(0.3, 15, 0.3), CFrame = at(x - side * 1.6, y0 + 8, -0.4), Color = color:Lerp(Color3.new(1, 1, 1), 0.4), Material = Enum.Material.Neon, CanCollide = false }, folder)
	end
	local header = part({ Name = "Header", Size = Vector3.new(26, 6, 2.6), CFrame = at(0, y0 + 18.2, 1.2), Color = white }, folder)
	part({ Name = "HeaderGlow", Size = Vector3.new(26.2, 0.3, 2.8), CFrame = at(0, y0 + 15.1, 1.2), Color = color, Material = Enum.Material.Neon, CanCollide = false }, folder)
	local _ = header
	local signFront = part({ Name = "Banner", Size = Vector3.new(25, 5.2, 0.3), CFrame = at(0, y0 + 18.2, -0.25), Color = color }, folder)
	local signBack = part({ Name = "BannerBack", Size = Vector3.new(25, 5.2, 0.3), CFrame = at(0, y0 + 18.2, 2.65), Color = color }, folder)
	part({ Name = "Canopy", Size = Vector3.new(21, 0.6, 7), CFrame = at(0, y0 + 14.3, -1.8), Color = color }, folder)
	part({ Name = "CanopyEdge", Size = Vector3.new(21.2, 0.3, 0.3), CFrame = at(0, y0 + 14.0, -5.3), Color = white, Material = Enum.Material.Neon }, folder)
	for _, x in { -6, 0, 6 } do
		local spot = part({ Name = "Downlight", Size = Vector3.new(1.2, 0.2, 1.2), CFrame = at(x, y0 + 13.95, -1.8), Color = Color3.fromRGB(255, 245, 220), Material = Enum.Material.Neon, CanCollide = false }, folder)
		local sl = Instance.new("SpotLight")
		sl.Face = Enum.NormalId.Bottom
		sl.Range = 18
		sl.Brightness = 1.4
		sl.Angle = 70
		sl.Parent = spot
	end
	-- enseignes : nom du propriétaire et revenu de la base en direct
	local palette = Signs.paletteOf(color)
	local t1, s1 = Signs.panel(signFront, Enum.NormalId.Front, { Title = "FREE BASE", Sub = "", Colors = palette, PixelsPerStud = 36 })
	local t2, s2 = Signs.panel(signBack, Enum.NormalId.Back, { Title = "FREE BASE", Sub = "", Colors = palette, PixelsPerStud = 36 })
	local t3, s3 = Signs.panel(backSign, Enum.NormalId.Front, { Title = "FREE BASE", Sub = "", Colors = palette, PixelsPerStud = 30 })
	local signTitles = { t1, t2, t3 }
	local signSubs = { s1, s2, s3 }

	-- ÉTAGES 2 et 3 (mezzanines au fond), visibles seulement après les rebirths
	local floors = {}
	local pads = {}
	for f = 2, 3 do
		local ff = Instance.new("Folder")
		ff.Name = "Floor" .. f
		ff.Parent = folder
		floors[f] = ff
		local y = FLOOR_Y[f]
		local depth = BASE_D - MEZZ_FROM
		local midD = MEZZ_FROM + depth / 2
		part({ Name = "Slab", Size = Vector3.new(BASE_W - 2, 1.2, depth), CFrame = at(0, y - 0.6, midD), Color = slate }, ff)
		for i = 0, BASE_W / 10 - 1 do
			for j = 0, 1 do
				part({
					Name = "Tile",
					Size = Vector3.new(10, 0.2, depth / 2),
					CFrame = at(-BASE_W / 2 + (i + 0.5) * 10, y + 0.1, MEZZ_FROM + (j + 0.5) * depth / 2),
					Color = ((i + j + f) % 2 == 0) and light or PAPER,
				}, ff)
			end
		end
		part({ Name = "SlabGlow", Size = Vector3.new(BASE_W - 2, 0.3, 0.3), CFrame = at(0, y - 1.25, MEZZ_FROM), Color = color, Material = Enum.Material.Neon, CanCollide = false }, ff)
		-- garde-corps vitré à l'avant de la mezzanine
		part({ Name = "RailGlass", Size = Vector3.new(BASE_W - 2, 3, 0.3), CFrame = at(0, y + 1.6, MEZZ_FROM + 0.3), Color = Color3.fromRGB(190, 225, 255), Material = Enum.Material.Glass, Transparency = 0.55 }, ff)
		part({ Name = "RailTop", Size = Vector3.new(BASE_W - 2, 0.4, 0.6), CFrame = at(0, y + 3.2, MEZZ_FROM + 0.3), Color = white }, ff)
		for _, x in { -BASE_W / 2 + 1.2, BASE_W / 2 - 1.2 } do
			part({ Name = "SideGlass", Size = Vector3.new(0.3, 3, depth), CFrame = at(x, y + 1.6, midD), Color = Color3.fromRGB(190, 225, 255), Material = Enum.Material.Glass, Transparency = 0.55 }, ff)
			part({ Name = "SideRail", Size = Vector3.new(0.6, 0.4, depth), CFrame = at(x, y + 3.2, midD), Color = white }, ff)
		end
		-- poteaux sous la mezzanine
		for _, x in { -27, -10, 10, 27 } do
			part({ Name = "Column", Size = Vector3.new(1.6, 12, 1.6), CFrame = at(x, y - 7.2, MEZZ_FROM + 0.8), Color = white }, ff)
		end
		-- mur du fond qui monte avec les étages
		part({ Name = "BackWallUp", Size = Vector3.new(BASE_W, 12, 1.6), CFrame = at(0, y + 4.4, BASE_D - 0.8), Color = color }, ff)
		part({ Name = "BackBandUp", Size = Vector3.new(BASE_W + 0.2, 0.8, 1.8), CFrame = at(0, y + 10, BASE_D - 0.8), Color = white }, ff)
		local floorSign = part({ Name = "FloorSign", Size = Vector3.new(12, 3.2, 0.3), CFrame = at(0, y + 6.6, BASE_D - 1.8), Color = slate }, ff)
		Signs.panel(floorSign, Enum.NormalId.Front, { Title = "FLOOR " .. f, Colors = { color:Lerp(Color3.new(1, 1, 1), 0.45), color, color:Lerp(Props.INK, 0.3), color:Lerp(Props.INK, 0.65) }, PixelsPerStud = 30 })
		-- plateformes pour monter / descendre
		local function pad(x: number, d: number, py: number, target: CFrame, text: string, padColor: Color3)
			local p = part({ Name = "Pad", Size = Vector3.new(0.4, 5, 5), Shape = Enum.PartType.Cylinder, CFrame = at(x, py + 0.2, d) * CFrame.Angles(0, 0, math.rad(90)), Color = padColor, Material = Enum.Material.Neon, CanCollide = false }, ff)
			part({ Name = "PadRing", Size = Vector3.new(0.3, 5.8, 5.8), Shape = Enum.PartType.Cylinder, CFrame = at(x, py + 0.1, d) * CFrame.Angles(0, 0, math.rad(90)), Color = white }, ff)
			local label = billboard(p, UDim2.fromOffset(150, 40), Vector3.new(0, 3, 0), text, padColor, 40)
			label.Parent.LightInfluence = 0
			table.insert(pads, { Part = p, Target = target, Floor = f })
		end
		local up = Color3.fromRGB(90, 255, 140)
		local down = Color3.fromRGB(255, 200, 70)
		if f == 2 then
			pad(0, MEZZ_FROM - 3.5, FLOOR_Y[1], at(0, FLOOR_Y[2] + 3, 54), "UP TO FLOOR 2", up)
			pad(-14, MEZZ_FROM + 3, y, at(0, FLOOR_Y[1] + 3, 30), "DOWN", down)
		else
			pad(14, MEZZ_FROM + 3, FLOOR_Y[2], at(0, FLOOR_Y[3] + 3, 54), "UP TO FLOOR 3", up)
			pad(-14, MEZZ_FROM + 3, y, at(0, FLOOR_Y[2] + 3, 54), "DOWN", down)
		end
	end

	-- supports : 8 par étage
	local cases = {}
	local n = 0
	for f = 1, 3 do
		for _, depth in FLOOR_ROWS[f] do
			for _, x in CASE_COLS do
				n += 1
				-- le présentoir regarde vers l'entrée (+Z local)
				local show = Showcase.build(at(x, FLOOR_Y[f], depth), f == 1 and folder or floors[f], "Case" .. n, 0.62)
				cases[n] = {
					Index = n,
					Floor = f,
					Show = show,
					Plinth = show.Base,
					CardCFrame = show.CardCFrame,
				}
			end
		end
	end

	-- dalle de collecte (devant à gauche)
	local collect = part({ Name = "Collect", Size = Vector3.new(10, 0.4, 7), CFrame = at(-17, 1.9, 9), Color = Color3.fromRGB(80, 230, 140), Material = Enum.Material.Neon }, folder)
	part({ Name = "CollectRim", Size = Vector3.new(11, 0.3, 8), CFrame = at(-17, 1.75, 9), Color = Props.GOLD }, folder)
	local collectLabel = billboard(collect, UDim2.fromOffset(240, 56), Vector3.new(0, 4.4, 0), "", Color3.fromRGB(110, 255, 110), 70)
	local hint = billboard(collect, UDim2.fromOffset(170, 24), Vector3.new(0, 2.3, 0), "STEP HERE TO COLLECT", PAPER, 35)
	hint.Parent.MaxDistance = 35

	-- tapis de course (devant à droite). On court vers l'entrée.
	-- Le modèle 3D (9 looks) est construit par TrainingService selon le niveau du propriétaire.
	local tmFolder = Instance.new("Folder")
	tmFolder.Name = "Treadmill"
	tmFolder.Parent = folder
	local tx, td = 16, 12
	local modelCF = at(tx, 1.7, td) * CFrame.Angles(0, math.pi, 0)
	-- repères invisibles : la bande (position) et la console (prompts côté client)
	local belt = part({ Name = "Belt", Size = Vector3.new(6, 0.3, 14), CFrame = at(tx, 3.2, td), Transparency = 1, CanCollide = false, CanQuery = false }, tmFolder)
	local console = part({ Name = "Console", Size = Vector3.new(6, 4, 1), CFrame = at(tx, 6, td - 8), Transparency = 1, CanCollide = false, CanQuery = false }, tmFolder)
	-- le joueur se place ici et regarde vers la console (l'entrée)
	local spotPos = at(tx, 5, td + 2).Position
	local consolePos = at(tx, 5, td - 10).Position
	local spot = CFrame.lookAt(spotPos, Vector3.new(consolePos.X, spotPos.Y, consolePos.Z))
	console:SetAttribute("BaseIndex", index)
	console:SetAttribute("Spot", spot)
	console:SetAttribute("BeltTop", 1.7 + 1.65)
	game:GetService("CollectionService"):AddTag(console, "Treadmill")

	-- BORNE D'AMÉLIORATION, à gauche du tapis : un écran incliné (prochain niveau,
	-- gain de Speed, prix) et un gros bouton rond sur un socle, devant l'écran.
	local kiosk = Instance.new("Model")
	kiosk.Name = "UpgradeKiosk"
	kiosk.Parent = tmFolder
	local kx, kd = 8.4, 8
	local kpos = at(kx, 0, kd).Position
	local facing = (at(kx + 0.3, 0, kd - 1).Position - kpos).Unit -- vers l'entrée, un peu tourné vers le tapis
	local kcf = CFrame.lookAt(kpos, kpos + facing)
	local slate2 = Color3.fromRGB(40, 44, 58)
	part({ Name = "KioskFoot", Size = Vector3.new(4.6, 0.6, 3.4), CFrame = kcf * CFrame.new(0, 1.95, 0.4), Color = slate2 }, kiosk)
	part({ Name = "KioskFootGlow", Size = Vector3.new(4.8, 0.2, 3.6), CFrame = kcf * CFrame.new(0, 1.75, 0.4), Color = color, Material = Enum.Material.Neon, CanCollide = false }, kiosk)
	part({ Name = "KioskBody", Size = Vector3.new(3.2, 4.4, 1.6), CFrame = kcf * CFrame.new(0, 4.4, 0.9), Color = white }, kiosk)
	part({ Name = "KioskStripe", Size = Vector3.new(3.3, 0.5, 1.7), CFrame = kcf * CFrame.new(0, 3.2, 0.9), Color = color }, kiosk)
	local screenCF = kcf * CFrame.new(0, 7.6, 0.6) * CFrame.Angles(math.rad(22), 0, 0)
	part({ Name = "Bezel", Size = Vector3.new(6.2, 4.2, 0.5), CFrame = screenCF * CFrame.new(0, 0, 0.2), Color = slate2 }, kiosk)
	part({ Name = "BezelGlow", Size = Vector3.new(6.4, 4.4, 0.2), CFrame = screenCF * CFrame.new(0, 0, 0.42), Color = color, Material = Enum.Material.Neon, CanCollide = false }, kiosk)
	local screen = part({ Name = "Screen", Size = Vector3.new(5.8, 3.8, 0.1), CFrame = screenCF * CFrame.new(0, 0, -0.08), Color = Props.INK }, kiosk)
	-- gros bouton rond sur son petit socle, devant l'écran
	local bcf = kcf * CFrame.new(0, 0, -2.6)
	part({ Name = "ButtonBase", Size = Vector3.new(0.5, 4.6, 4.6), Shape = Enum.PartType.Cylinder, CFrame = bcf * CFrame.new(0, 1.95, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = slate2 }, kiosk)
	part({ Name = "ButtonPost", Size = Vector3.new(2.2, 2.6, 2.6), Shape = Enum.PartType.Cylinder, CFrame = bcf * CFrame.new(0, 3.2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = white }, kiosk)
	local ring = part({ Name = "Ring", Size = Vector3.new(0.4, 3.3, 3.3), CFrame = bcf * CFrame.new(0, 4.45, 0) * CFrame.Angles(0, 0, math.rad(90)), Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(80, 255, 120), Material = Enum.Material.Neon, CanCollide = false }, kiosk)
	part({ Name = "Collar", Size = Vector3.new(0.5, 3, 3), Shape = Enum.PartType.Cylinder, CFrame = bcf * CFrame.new(0, 4.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Props.GOLD, Material = Enum.Material.Metal }, kiosk)
	local push = part({ Name = "Button", Size = Vector3.new(0.8, 2.3, 2.3), Shape = Enum.PartType.Cylinder, CFrame = bcf * CFrame.new(0, 5.0, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(80, 255, 120), Material = Enum.Material.Neon }, kiosk)
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 40
	click.Parent = push
	push:SetAttribute("BaseIndex", index)
	game:GetService("CollectionService"):AddTag(push, "UpgradeButton")
	-- on peut aussi cliquer sur l'écran
	local screenClick = Instance.new("ClickDetector")
	screenClick.MaxActivationDistance = 40
	screenClick.Parent = screen
	screen:SetAttribute("BaseIndex", index)
	game:GetService("CollectionService"):AddTag(screen, "UpgradeButton")
	local ui = Signs.kioskScreen(screen, Enum.NormalId.Front)

	-- coin salon au fond du rez-de-chaussée (sous la mezzanine)
	for _, x in { -18, 18 } do
		part({ Name = "Sofa", Size = Vector3.new(8, 1.6, 3), CFrame = at(x, 2.5, 60), Color = color:Lerp(Props.INK, 0.25) }, folder)
		part({ Name = "SofaBack", Size = Vector3.new(8, 2.4, 1), CFrame = at(x, 3.6, 61.6), Color = color:Lerp(Props.INK, 0.35) }, folder)
		Props.plantPot(at(x + (x > 0 and -6 or 6), 1.7, 60).Position, folder)
	end
	part({ Name = "Rug", Size = Vector3.new(26, 0.08, 10), CFrame = at(0, 1.75, 55), Color = deep, Material = Enum.Material.Fabric }, folder)

	-- décor de façade : jardinières de chaque côté de l'entrée
	for _, side in { -1, 1 } do
		part({ Name = "Planter", Size = Vector3.new(4, 1.4, 2.4), CFrame = at(side * 20.5, 0.7, -2.2), Color = white }, folder)
		Props.bush(at(side * 20.5, 1.4, -2.2).Position, Color3.fromRGB(70, 170, 70), folder)
	end

	return {
		Index = index,
		Color = color,
		Folder = folder,
		CFrame = cf,
		Cases = cases,
		SignTitles = signTitles,
		SignSubs = signSubs,
		Collect = collect,
		CollectLabel = collectLabel,
		Spawn = at(0, 5, 16) * CFrame.Angles(0, math.pi, 0),
		Treadmill = {
			Folder = tmFolder,
			ModelCFrame = modelCF,
			Belt = belt,
			Console = console,
			Spot = spot,
			Button = push,
			ButtonRing = ring,
			Screen = ui,
			ScreenPart = screen,
		},
		Floors = floors,
		Pads = pads,
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
	Signs.panel(arch, Enum.NormalId.Front, {
		Title = zone.Name:upper(),
		Sub = zone.Speed > 0 and ("SHOP %d  ·  SPEED %s"):format(i, Format.short(zone.Speed)) or ("SHOP %d  ·  NO SPEED NEEDED"):format(i),
		Colors = { zone.Accent:Lerp(Color3.new(1, 1, 1), 0.4), zone.Main, zone.Main:Lerp(INK, 0.4), INK },
		PixelsPerStud = 20,
	})
	Signs.panel(arch, Enum.NormalId.Back, { Title = "BACK TO YOUR BASE", Colors = Signs.Palettes.Green, PixelsPerStud = 20 })

	-- PANNEAU VITESSE CONSEILLÉE, juste avant l'arche, à droite de la route
	speedBoard(CFrame.new(road + 13, 9, gateZ - 8) * CFrame.Angles(0, math.rad(25), 0), 16, 9, i, zone, folder)

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
	Signs.panel(shopSign, Enum.NormalId.Back, {
		Title = zone.Name:upper(),
		Sub = "Guarded by " .. zone.Guardian,
		Colors = { zone.Accent:Lerp(Color3.new(1, 1, 1), 0.4), zone.Main, zone.Main:Lerp(INK, 0.4), INK },
		PixelsPerStud = 22,
	})
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
	Signs.panel(exitArch, Enum.NormalId.Front, { Title = "TO THE SHOPS", Colors = Signs.Palettes.Red, PixelsPerStud = 20 })
	Signs.panel(exitArch, Enum.NormalId.Back, { Title = "SAFE ZONE", Colors = Signs.Palettes.Green, PixelsPerStud = 20 })
	-- grand écran : minuteur du refresh des boutiques
	local screen = part({ Name = "RefreshScreen", Size = Vector3.new(26, 5, 0.8), CFrame = CFrame.new(0, 19.5, MapBuilder.HubEdgeZ + 2), Color = Props.INK }, root)
	for _, side in { -1, 1 } do
		part({ Name = "ScreenCable", Size = Vector3.new(0.3, 4, 0.3), CFrame = CFrame.new(side * 11, 23.5, MapBuilder.HubEdgeZ + 2), Color = Props.INK }, root)
	end
	local refreshLabels = {}
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local label = Signs.panel(screen, face, { Title = "SHOPS REFRESH IN 10:00", Colors = Signs.Palettes.Dark, PixelsPerStud = 24, TitleColor = Color3.fromRGB(255, 220, 80) })
		table.insert(refreshLabels, label)
	end
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
	for _, info in { { "TopIncome", "TOP CASH/S", -50 }, { "TopSpeed", "TOP SPEED", 50 } } do
		local board = part({ Name = info[1], Size = Vector3.new(18, 24, 1), CFrame = CFrame.new(info[3], 14, backZ + 6) * CFrame.Angles(0, math.pi, 0), Color = INK }, root)
		part({ Name = "BoardFrame", Size = Vector3.new(19.5, 25.5, 0.8), CFrame = board.CFrame * CFrame.new(0, 0, 0.3), Color = GOLD, Material = Enum.Material.Metal }, root)
		part({ Name = "BoardBase", Size = Vector3.new(20, 2, 4), CFrame = CFrame.new(info[3], 1, backZ + 6), Color = INK, Studs = "top" }, root)
		boards[info[1]] = { part = board, title = info[2] }
	end

	-- les deux stands au bout de la rue : améliorations (gauche) et vente (droite)
	local stands = {
		upgrades = Stands.build("upgrades", CFrame.lookAt(Vector3.new(-22, 0, backZ + 9), Vector3.new(-22, 0, backZ + 20)), root),
		grading = Stands.build("grading", CFrame.lookAt(Vector3.new(0, 0, backZ + 9), Vector3.new(0, 0, backZ + 20)), root),
		packs = Stands.build("packs", CFrame.lookAt(Vector3.new(22, 0, backZ + 9), Vector3.new(22, 0, backZ + 20)), root),
	}

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
		Stands = stands,
		RefreshLabels = refreshLabels,
	}
end

return MapBuilder
