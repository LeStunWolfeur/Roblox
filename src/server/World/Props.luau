--[[
	Bibliothèque de décors. Style "briques" (picots façon Lego) comme dans
	les jeux du genre : chaque pièce peut recevoir des picots sur ses faces.
	Toutes les fonctions prennent un CFrame (ou une position) et un parent.
]]

local Props = {}

Props.INK = Color3.fromRGB(28, 28, 38)
Props.GOLD = Color3.fromRGB(255, 200, 40)
Props.WHITE = Color3.fromRGB(248, 246, 240)

local STUDS = Enum.SurfaceType.Studs
local INLET = Enum.SurfaceType.Inlet
local SMOOTH = Enum.SurfaceType.Smooth

-- props.Studs = "top" (dessus seulement) | "all" (toutes les faces) | nil (lisse)
function Props.part(props: { [string]: any }, parent: Instance?): BasePart
	local p = Instance.new(props.ClassName or "Part") :: BasePart
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = SMOOTH
	p.BottomSurface = SMOOTH
	local studs = props.Studs
	for k, v in props do
		if k ~= "ClassName" and k ~= "Studs" then
			(p :: any)[k] = v
		end
	end
	if studs == "top" or studs == "all" then
		p.TopSurface = STUDS
		p.BottomSurface = INLET
	end
	if studs == "all" then
		p.FrontSurface = STUDS
		p.BackSurface = STUDS
		p.LeftSurface = STUDS
		p.RightSurface = STUDS
	end
	p.Parent = parent
	return p
end
local part = Props.part

local function light(parent: Instance, color: Color3, range: number, brightness: number?)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness or 1
	l.Shadows = false
	l.Parent = parent
	return l
end
Props.light = light

local function folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

--------------------------------------------------------------------
-- Végétation
--------------------------------------------------------------------
function Props.tree(position: Vector3, scale: number, leaf: Color3, parent: Instance)
	local f = folder("Tree", parent)
	local s = scale
	part({ Name = "Trunk", Size = Vector3.new(2, 8, 2) * s, CFrame = CFrame.new(position + Vector3.new(0, 4 * s, 0)), Color = Color3.fromRGB(120, 80, 50), Studs = "top" }, f)
	part({ Name = "Leaves1", Size = Vector3.new(10, 4, 10) * s, CFrame = CFrame.new(position + Vector3.new(0, 9 * s, 0)), Color = leaf, Studs = "all" }, f)
	part({ Name = "Leaves2", Size = Vector3.new(7, 3, 7) * s, CFrame = CFrame.new(position + Vector3.new(0, 12.5 * s, 0)), Color = leaf:Lerp(Color3.new(1, 1, 1), 0.12), Studs = "all" }, f)
	part({ Name = "Leaves3", Size = Vector3.new(4, 2, 4) * s, CFrame = CFrame.new(position + Vector3.new(0, 15 * s, 0)), Color = leaf:Lerp(Color3.new(1, 1, 1), 0.22), Studs = "all" }, f)
	return f
end

function Props.bush(position: Vector3, color: Color3, parent: Instance)
	local f = folder("Bush", parent)
	part({ Name = "Bush", Size = Vector3.new(6, 3, 4), CFrame = CFrame.new(position + Vector3.new(0, 1.5, 0)), Color = color, Studs = "all" }, f)
	part({ Name = "Bush", Size = Vector3.new(4, 2, 3), CFrame = CFrame.new(position + Vector3.new(0.5, 3.5, 0)), Color = color:Lerp(Color3.new(1, 1, 1), 0.15), Studs = "all" }, f)
	return f
end

function Props.flowers(position: Vector3, parent: Instance)
	local colors = { Color3.fromRGB(255, 90, 120), Color3.fromRGB(255, 220, 60), Color3.fromRGB(150, 110, 255), Color3.fromRGB(255, 255, 255) }
	for i = 0, 3 do
		local offset = Vector3.new((i % 2) * 2 - 1, 0, math.floor(i / 2) * 2 - 1)
		part({ Name = "Stem", Size = Vector3.new(0.3, 1.4, 0.3), CFrame = CFrame.new(position + offset + Vector3.new(0, 0.7, 0)), Color = Color3.fromRGB(60, 160, 60), CanCollide = false }, parent)
		part({ Name = "Petal", Size = Vector3.new(1, 0.6, 1), CFrame = CFrame.new(position + offset + Vector3.new(0, 1.6, 0)), Color = colors[i + 1], CanCollide = false, Studs = "top" }, parent)
	end
end

function Props.plantPot(position: Vector3, parent: Instance)
	local f = folder("Plant", parent)
	part({ Name = "Pot", Size = Vector3.new(2.4, 2, 2.4), CFrame = CFrame.new(position + Vector3.new(0, 1, 0)), Color = Color3.fromRGB(200, 110, 70), Studs = "top" }, f)
	part({ Name = "Leaves", Size = Vector3.new(3, 2.4, 3), CFrame = CFrame.new(position + Vector3.new(0, 3.2, 0)), Color = Color3.fromRGB(70, 180, 80), Studs = "all" }, f)
	part({ Name = "Leaves", Size = Vector3.new(1.8, 1.4, 1.8), CFrame = CFrame.new(position + Vector3.new(0, 5, 0)), Color = Color3.fromRGB(90, 200, 100), Studs = "all" }, f)
	return f
end

--------------------------------------------------------------------
-- Mobilier urbain
--------------------------------------------------------------------
function Props.lampPost(position: Vector3, color: Color3, parent: Instance, facing: Vector3?)
	local f = folder("LampPost", parent)
	local dir = facing or Vector3.new(1, 0, 0)
	part({ Name = "Base", Size = Vector3.new(2, 1, 2), CFrame = CFrame.new(position + Vector3.new(0, 0.5, 0)), Color = Props.INK, Studs = "top" }, f)
	part({ Name = "Pole", Size = Vector3.new(0.8, 14, 0.8), CFrame = CFrame.new(position + Vector3.new(0, 7.5, 0)), Color = Props.INK }, f)
	local armPos = position + Vector3.new(0, 14.5, 0) + dir * 1.5
	part({ Name = "Arm", Size = Vector3.new(0.6, 0.6, 3.6), CFrame = CFrame.lookAt(armPos, armPos + dir), Color = Props.INK }, f)
	local bulb = part({
		Name = "Lamp",
		Size = Vector3.new(1.8, 1, 1.8),
		CFrame = CFrame.new(position + Vector3.new(0, 13.9, 0) + dir * 3),
		Color = color,
		Material = Enum.Material.Neon,
	}, f)
	light(bulb, color, 22, 1.4)
	return f
end

function Props.bench(cf: CFrame, color: Color3, parent: Instance)
	local f = folder("Bench", parent)
	part({ Name = "Seat", Size = Vector3.new(6, 0.5, 2), CFrame = cf * CFrame.new(0, 1.6, 0), Color = color, Studs = "top" }, f)
	part({ Name = "Back", Size = Vector3.new(6, 1.6, 0.4), CFrame = cf * CFrame.new(0, 2.8, 0.9), Color = color }, f)
	for _, x in { -2.5, 2.5 } do
		part({ Name = "Leg", Size = Vector3.new(0.5, 1.4, 1.8), CFrame = cf * CFrame.new(x, 0.7, 0), Color = Props.INK }, f)
	end
	return f
end

-- Poteaux dorés reliés par une corde rouge (barrière de musée)
function Props.stanchions(a: Vector3, b: Vector3, parent: Instance)
	local f = folder("Stanchions", parent)
	local dist = (b - a).Magnitude
	local count = math.max(1, math.floor(dist / 6))
	local prev
	for i = 0, count do
		local p = a:Lerp(b, i / count)
		part({ Name = "Base", Size = Vector3.new(1.4, 0.3, 1.4), CFrame = CFrame.new(p + Vector3.new(0, 0.15, 0)), Color = Props.GOLD }, f)
		part({ Name = "Post", Size = Vector3.new(0.5, 3, 0.5), CFrame = CFrame.new(p + Vector3.new(0, 1.6, 0)), Color = Props.GOLD, Material = Enum.Material.Metal }, f)
		part({ Name = "Knob", Size = Vector3.new(0.8, 0.8, 0.8), Shape = Enum.PartType.Ball, CFrame = CFrame.new(p + Vector3.new(0, 3.2, 0)), Color = Props.GOLD, Material = Enum.Material.Metal }, f)
		if prev then
			local mid = (prev + p) / 2 + Vector3.new(0, 2.6, 0)
			local len = (p - prev).Magnitude
			part({
				Name = "Rope",
				Size = Vector3.new(0.3, 0.3, len),
				CFrame = CFrame.lookAt(mid, p + Vector3.new(0, 2.6, 0)),
				Color = Color3.fromRGB(200, 30, 50),
				Material = Enum.Material.Fabric,
				CanCollide = false,
			}, f)
		end
		prev = p
	end
	return f
end

-- Applique murale. cf : sur le mur, -Z local pointe vers la pièce
function Props.wallLamp(cf: CFrame, parent: Instance)
	local f = folder("WallLamp", parent)
	part({ Name = "Plate", Size = Vector3.new(1.4, 2, 0.3), CFrame = cf, Color = Props.GOLD }, f)
	part({ Name = "Arm", Size = Vector3.new(0.3, 0.3, 1), CFrame = cf * CFrame.new(0, 0.3, -0.6), Color = Props.GOLD }, f)
	local shade = part({
		Name = "Shade",
		Size = Vector3.new(1.6, 1.2, 1.4),
		CFrame = cf * CFrame.new(0, 0.6, -1.4),
		Color = Color3.fromRGB(255, 235, 150),
		Material = Enum.Material.Neon,
	}, f)
	light(shade, Color3.fromRGB(255, 225, 160), 14, 0.9)
	return f
end

-- Cadre avec une toile. cf : sur le mur, -Z local vers la pièce
function Props.frame(cf: CFrame, w: number, h: number, canvas: Color3, parent: Instance)
	local f = folder("Frame", parent)
	part({ Name = "Frame", Size = Vector3.new(w + 0.8, h + 0.8, 0.3), CFrame = cf, Color = Props.GOLD, Material = Enum.Material.Metal }, f)
	part({ Name = "Canvas", Size = Vector3.new(w, h, 0.2), CFrame = cf * CFrame.new(0, 0, -0.15), Color = canvas }, f)
	part({ Name = "Shape", Size = Vector3.new(w * 0.4, w * 0.4, 0.1), CFrame = cf * CFrame.new(0, 0, -0.3) * CFrame.Angles(0, 0, math.rad(45)), Color = canvas:Lerp(Color3.new(1, 1, 1), 0.5) }, f)
	return f
end

function Props.column(position: Vector3, height: number, color: Color3, parent: Instance)
	local f = folder("Column", parent)
	part({ Name = "Base", Size = Vector3.new(4, 1, 4), CFrame = CFrame.new(position + Vector3.new(0, 0.5, 0)), Color = color, Studs = "top" }, f)
	part({ Name = "Shaft", Size = Vector3.new(height - 2, 2.6, 2.6), Shape = Enum.PartType.Cylinder, CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = color }, f)
	part({ Name = "Top", Size = Vector3.new(4, 1, 4), CFrame = CFrame.new(position + Vector3.new(0, height - 0.5, 0)), Color = color }, f)
	return f
end

function Props.statue(position: Vector3, color: Color3, parent: Instance)
	local f = folder("Statue", parent)
	part({ Name = "Plinth", Size = Vector3.new(4, 3, 4), CFrame = CFrame.new(position + Vector3.new(0, 1.5, 0)), Color = Props.WHITE, Studs = "top" }, f)
	part({ Name = "Legs", Size = Vector3.new(2, 2.4, 1), CFrame = CFrame.new(position + Vector3.new(0, 4.2, 0)), Color = color }, f)
	part({ Name = "Body", Size = Vector3.new(2.6, 2.4, 1.2), CFrame = CFrame.new(position + Vector3.new(0, 6.6, 0)), Color = color }, f)
	part({ Name = "Head", Size = Vector3.new(1.6, 1.6, 1.6), CFrame = CFrame.new(position + Vector3.new(0, 8.6, 0)), Color = color }, f)
	part({ Name = "Arm", Size = Vector3.new(0.8, 2.6, 0.8), CFrame = CFrame.new(position + Vector3.new(1.8, 7.4, 0)) * CFrame.Angles(0, 0, math.rad(-35)), Color = color }, f)
	return f
end

function Props.arcadeCabinet(cf: CFrame, color: Color3, parent: Instance)
	local f = folder("Arcade", parent)
	part({ Name = "Body", Size = Vector3.new(3.4, 7, 3), CFrame = cf * CFrame.new(0, 3.5, 0), Color = color, Studs = "all" }, f)
	part({ Name = "Screen", Size = Vector3.new(2.6, 2.2, 0.2), CFrame = cf * CFrame.new(0, 5, -1.5), Color = Color3.fromRGB(0, 230, 255), Material = Enum.Material.Neon }, f)
	part({ Name = "Panel", Size = Vector3.new(3.2, 0.4, 1.2), CFrame = cf * CFrame.new(0, 3.4, -1.9) * CFrame.Angles(math.rad(20), 0, 0), Color = Props.INK }, f)
	part({ Name = "Marquee", Size = Vector3.new(3.4, 1, 0.3), CFrame = cf * CFrame.new(0, 6.8, -1.55), Color = Color3.fromRGB(255, 60, 200), Material = Enum.Material.Neon }, f)
	return f
end

function Props.vaultDoor(cf: CFrame, parent: Instance)
	local f = folder("VaultDoor", parent)
	part({ Name = "Door", Size = Vector3.new(1.2, 14, 14), Shape = Enum.PartType.Cylinder, CFrame = cf * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(150, 155, 165), Material = Enum.Material.DiamondPlate }, f)
	part({ Name = "Hub", Size = Vector3.new(1.6, 3, 3), Shape = Enum.PartType.Cylinder, CFrame = cf * CFrame.new(0, 0, -0.6) * CFrame.Angles(0, math.rad(90), 0), Color = Props.GOLD, Material = Enum.Material.Metal }, f)
	for i = 0, 2 do
		part({ Name = "Spoke", Size = Vector3.new(9, 0.5, 0.5), CFrame = cf * CFrame.new(0, 0, -1.2) * CFrame.Angles(0, 0, math.rad(i * 60)), Color = Props.GOLD, Material = Enum.Material.Metal }, f)
	end
	return f
end

function Props.cloud(position: Vector3, parent: Instance)
	local f = folder("Cloud", parent)
	for i, o in { Vector3.new(0, 0, 0), Vector3.new(4, -0.5, 1), Vector3.new(-4, -0.6, -1), Vector3.new(1, 1.5, 0) } do
		part({ Name = "Puff", Size = Vector3.new(7, 7, 7) * (i == 4 and 0.8 or 1), Shape = Enum.PartType.Ball, CFrame = CFrame.new(position + o), Color = Color3.new(1, 1, 1), CanCollide = false, Material = Enum.Material.SmoothPlastic }, f)
	end
	return f
end

function Props.planet(position: Vector3, size: number, color: Color3, parent: Instance)
	local f = folder("Planet", parent)
	part({ Name = "Planet", Size = Vector3.new(size, size, size), Shape = Enum.PartType.Ball, CFrame = CFrame.new(position), Color = color, CanCollide = false }, f)
	part({
		Name = "Ring",
		Size = Vector3.new(0.4, size * 1.7, size * 1.7),
		Shape = Enum.PartType.Cylinder,
		CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(75)) * CFrame.Angles(math.rad(20), 0, 0),
		Color = color:Lerp(Color3.new(1, 1, 1), 0.5),
		Transparency = 0.3,
		CanCollide = false,
	}, f)
	return f
end

-- Auvent rayé. cf : au-dessus de l'entrée, -Z local vers l'extérieur
function Props.awning(cf: CFrame, width: number, a: Color3, b: Color3, parent: Instance)
	local f = folder("Awning", parent)
	local stripes = math.max(2, math.floor(width / 3))
	local w = width / stripes
	for i = 0, stripes - 1 do
		part({
			Name = "Stripe",
			Size = Vector3.new(w, 0.4, 6),
			CFrame = cf * CFrame.new(-width / 2 + w * (i + 0.5), 0, -3) * CFrame.Angles(math.rad(-18), 0, 0),
			Color = (i % 2 == 0) and a or b,
		}, f)
	end
	return f
end

-- Grille de plafonniers (comme un musée / centre commercial)
function Props.ceilingLights(cf: CFrame, width: number, depth: number, parent: Instance)
	local f = folder("CeilingLights", parent)
	local nx = math.max(1, math.floor(width / 12))
	local nz = math.max(1, math.floor(depth / 12))
	for i = 0, nx - 1 do
		for j = 0, nz - 1 do
			local x = -width / 2 + (i + 0.5) * width / nx
			local z = -(j + 0.5) * depth / nz
			local panel = part({
				Name = "Panel",
				Size = Vector3.new(6, 0.3, 6),
				CFrame = cf * CFrame.new(x, 0, z),
				Color = Color3.fromRGB(255, 250, 230),
				Material = Enum.Material.Neon,
				CanCollide = false,
			}, f)
			-- une lumière sur trois panneaux : joli et léger pour les mobiles
			if (i + j) % 3 == 0 then
				light(panel, Color3.fromRGB(255, 245, 225), 26, 0.9)
			end
		end
	end
	return f
end

-- Caisse enregistreuse sur comptoir. cf : -Z local vers les clients
function Props.counter(cf: CFrame, width: number, color: Color3, parent: Instance)
	local f = folder("Counter", parent)
	part({ Name = "Counter", Size = Vector3.new(width, 3.6, 3), CFrame = cf * CFrame.new(0, 1.8, 0), Color = color, Studs = "all" }, f)
	part({ Name = "Top", Size = Vector3.new(width + 0.4, 0.4, 3.4), CFrame = cf * CFrame.new(0, 3.8, 0), Color = Props.INK }, f)
	part({ Name = "Register", Size = Vector3.new(2.4, 1.4, 2), CFrame = cf * CFrame.new(width / 2 - 2, 4.7, 0.2), Color = Color3.fromRGB(60, 60, 75) }, f)
	part({ Name = "Display", Size = Vector3.new(2, 0.8, 0.2), CFrame = cf * CFrame.new(width / 2 - 2, 5.8, 0.6) * CFrame.Angles(math.rad(-15), 0, 0), Color = Color3.fromRGB(80, 255, 140), Material = Enum.Material.Neon }, f)
	return f
end

-- Pile de boîtes de cartes (booster boxes)
function Props.cardBoxes(position: Vector3, colors: { Color3 }, parent: Instance)
	local f = folder("CardBoxes", parent)
	local layout = { Vector3.new(0, 0, 0), Vector3.new(2.6, 0, 0.2), Vector3.new(1.2, 1.6, 0.1) }
	for i, o in layout do
		local c = colors[(i - 1) % #colors + 1]
		part({ Name = "Box", Size = Vector3.new(2.4, 1.6, 1.8), CFrame = CFrame.new(position + o + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, math.rad(i * 9), 0), Color = c, Studs = "top" }, f)
	end
	return f
end

function Props.fountain(position: Vector3, parent: Instance)
	local f = folder("Fountain", parent)
	part({ Name = "Basin", Size = Vector3.new(2, 14, 14), Shape = Enum.PartType.Cylinder, CFrame = CFrame.new(position + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Props.WHITE }, f)
	part({ Name = "Water", Size = Vector3.new(0.4, 12.6, 12.6), Shape = Enum.PartType.Cylinder, CFrame = CFrame.new(position + Vector3.new(0, 1.9, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(80, 180, 255), Material = Enum.Material.Glass, Transparency = 0.3, CanCollide = false }, f)
	part({ Name = "Spout", Size = Vector3.new(5, 2, 2), Shape = Enum.PartType.Cylinder, CFrame = CFrame.new(position + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Props.WHITE }, f)
	part({ Name = "Jet", Size = Vector3.new(1, 4, 1), CFrame = CFrame.new(position + Vector3.new(0, 7.5, 0)), Color = Color3.fromRGB(150, 220, 255), Material = Enum.Material.Glass, Transparency = 0.4, CanCollide = false }, f)
	return f
end

function Props.bookshelf(cf: CFrame, parent: Instance)
	local f = folder("Bookshelf", parent)
	part({ Name = "Frame", Size = Vector3.new(8, 10, 2), CFrame = cf * CFrame.new(0, 5, 0), Color = Color3.fromRGB(110, 70, 40) }, f)
	local colors = { Color3.fromRGB(200, 60, 60), Color3.fromRGB(60, 120, 200), Color3.fromRGB(230, 190, 70), Color3.fromRGB(70, 160, 90) }
	for row = 0, 2 do
		for i = 0, 6 do
			part({
				Name = "Book",
				Size = Vector3.new(0.9, 2.2, 1.4),
				CFrame = cf * CFrame.new(-3.2 + i * 1.05, 1.8 + row * 3.1, -0.4),
				Color = colors[(i + row) % #colors + 1],
			}, f)
		end
	end
	return f
end

return Props
