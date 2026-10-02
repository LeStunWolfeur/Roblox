--[[
	Icônes 3D construites avec des parts et affichées dans un ViewportFrame.
	Ça donne le rendu "objet 3D brillant" des simulateurs Roblox sans avoir
	besoin d'images uploadées.

	Icons3D.view(kind, props) -> ViewportFrame
	Icons3D.entity(cardId, finish, props) -> ViewportFrame avec la créature de la carte
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Entity = require(ReplicatedStorage.Shared.Entity)

local Icons3D = {}

local rad = math.rad
local V = Vector3.new
local CF = CFrame.new
local A = CFrame.Angles

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function P(model: Instance, size: Vector3, cf: CFrame, color: Color3, shape: string?, material: Enum.Material?)
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
	p.Anchored = true
	p.CanCollide = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

-- disque dont la face regarde la caméra (+Z)
local function disc(m, d: number, thick: number, cf: CFrame, color: Color3, material: Enum.Material?)
	return P(m, V(thick, d, d), cf * A(0, rad(90), 0), color, "Cylinder", material)
end

-- arc de cercle dans le plan XY fait de petits blocs
local function arc(m, center: CFrame, radius: number, a0: number, a1: number, n: number, thick: number, depth: number, color: Color3)
	for i = 0, n - 1 do
		local t0 = a0 + (a1 - a0) * i / n
		local t1 = a0 + (a1 - a0) * (i + 1) / n
		local mid = (t0 + t1) / 2
		local len = 2 * radius * math.sin(math.abs(t1 - t0) / 2) + thick * 0.35
		P(m, V(len, thick, depth), center * CF(math.cos(mid) * radius, math.sin(mid) * radius, 0) * A(0, 0, mid + math.pi / 2), color)
	end
end

-- triangle plein dans le plan XY qui pointe vers le +Y de cf (deux wedges dos à dos)
local function arrowHead(m, cf: CFrame, w: number, h: number, depth: number, color: Color3)
	local base = cf * A(0, -math.pi / 2, 0)
	P(m, V(depth, h, w / 2), base * CF(0, 0, -w / 4), color, "Wedge")
	P(m, V(depth, h, w / 2), base * CF(0, 0, w / 4) * A(0, math.pi, 0), color, "Wedge")
end

local builders: { [string]: (Model, any?) -> () } = {}

builders.basket = function(m)
	local red, dark = rgb(235, 45, 60), rgb(170, 20, 40)
	P(m, V(3.2, 1.9, 2.2), CF(0, -0.3, 0), red)
	P(m, V(3.5, 0.4, 2.5), CF(0, 0.75, 0), dark)
	P(m, V(2.6, 0.3, 1.6), CF(0, -1.3, 0), dark)
	for _, x in { -1, 0, 1 } do
		P(m, V(0.22, 1.4, 0.1), CF(x * 0.95, -0.3, 1.12), dark)
	end
	P(m, V(3.0, 0.2, 0.1), CF(0, -0.3, 1.12), dark)
	arc(m, CF(0, 0.85, 0), 1.35, 0, math.pi, 9, 0.32, 0.32, rgb(215, 220, 230))
end

builders.ticket = function(m)
	local gold = rgb(255, 196, 40)
	local root = CF() * A(0, 0, rad(18))
	P(m, V(3.8, 2.1, 0.4), root, rgb(235, 150, 20))
	P(m, V(3.5, 1.8, 0.5), root, gold)
	P(m, V(2.4, 1.1, 0.55), root * CF(0.25, 0, 0), rgb(255, 225, 110))
	for _, y in { -0.6, -0.2, 0.2, 0.6 } do
		P(m, V(0.12, 0.22, 0.58), root * CF(-1.15, y, 0), rgb(235, 150, 20))
	end
	disc(m, 0.7, 0.62, root * CF(-1.9, 0, 0), rgb(235, 150, 20))
	disc(m, 0.7, 0.62, root * CF(1.9, 0, 0), rgb(235, 150, 20))
end

builders.rebirth = function(m)
	local red, white = rgb(235, 50, 60), rgb(240, 244, 250)
	local c = CF()
	arc(m, c, 1.55, rad(20), rad(170), 8, 0.62, 0.6, red)
	arc(m, c, 1.55, rad(200), rad(350), 8, 0.62, 0.6, white)
	arrowHead(m, c * CF(math.cos(rad(170)) * 1.55, math.sin(rad(170)) * 1.55, 0) * A(0, 0, rad(170)), 1.4, 0.9, 0.6, red)
	arrowHead(m, c * CF(math.cos(rad(350)) * 1.55, math.sin(rad(350)) * 1.55, 0) * A(0, 0, rad(350)), 1.4, 0.9, 0.6, white)
end

builders.book = function(m)
	local blue, dark = rgb(50, 120, 240), rgb(25, 70, 170)
	local root = CF() * A(0, 0, rad(-10))
	P(m, V(2.5, 3.1, 0.14), root * CF(0, 0, 0.42), blue)
	P(m, V(2.5, 3.1, 0.14), root * CF(0, 0, -0.42), dark)
	P(m, V(2.3, 2.95, 0.72), root * CF(0.08, 0, 0), rgb(250, 248, 240))
	P(m, V(0.28, 3.12, 0.98), root * CF(-1.2, 0, 0), dark)
	P(m, V(1.5, 0.45, 0.05), root * CF(0.15, 0.7, 0.5), rgb(130, 190, 255))
	P(m, V(1.1, 0.18, 0.05), root * CF(0.15, 0.15, 0.5), rgb(130, 190, 255))
	P(m, V(0.3, 1.0, 0.06), root * CF(0.7, -1.75, 0.3), rgb(230, 40, 60))
end

builders.gift = function(m)
	local purple, light, gold = rgb(140, 60, 235), rgb(175, 105, 255), rgb(255, 200, 40)
	P(m, V(2.5, 1.9, 2.5), CF(0, -0.35, 0), purple)
	P(m, V(2.8, 0.55, 2.8), CF(0, 0.85, 0), light)
	P(m, V(0.5, 2.5, 2.84), CF(0, 0.05, 0), gold)
	P(m, V(2.84, 2.5, 0.5), CF(0, 0.05, 0), gold)
	P(m, V(0.4, 1.2, 1.2), CF(-0.6, 1.55, 0) * A(0, 0, rad(-35)), gold, "Cylinder")
	P(m, V(0.4, 1.2, 1.2), CF(0.6, 1.55, 0) * A(0, 0, rad(35)), gold, "Cylinder")
	P(m, V(0.6, 0.6, 0.6), CF(0, 1.3, 0), rgb(255, 170, 30), "Ball")
end

builders.crate = function(m, color)
	local c = color or rgb(245, 160, 70)
	P(m, V(2.6, 2.6, 2.6), CF(), c)
	P(m, V(0.7, 2.64, 2.64), CF(), c:Lerp(Color3.new(1, 1, 1), 0.35))
	P(m, V(2.64, 0.08, 2.64), CF(0, 0.5, 0), c:Lerp(Color3.new(0, 0, 0), 0.15))
end

builders.cardpack = function(m, color)
	local c = color or rgb(170, 90, 255)
	local root = CF() * A(0, 0, rad(-8))
	P(m, V(2.2, 3.1, 0.35), root, c)
	P(m, V(2.24, 0.35, 0.4), root * CF(0, 1.45, 0), c:Lerp(Color3.new(1, 1, 1), 0.45))
	P(m, V(2.24, 0.35, 0.4), root * CF(0, -1.45, 0), c:Lerp(Color3.new(1, 1, 1), 0.45))
	disc(m, 1.2, 0.42, root * CF(0, 0.05, 0), Color3.new(1, 1, 1))
	disc(m, 0.7, 0.46, root * CF(0, 0.05, 0), c:Lerp(Color3.new(0, 0, 0), 0.2))
end

builders.cash = function(m)
	local g, d = rgb(90, 205, 90), rgb(50, 150, 60)
	for i = 0, 2 do
		local cf = CF(0, -0.5 + i * 0.42, 0) * A(0, rad(i * 9 - 9), 0)
		P(m, V(3.4, 0.38, 1.8), cf, i % 2 == 0 and g or d:Lerp(g, 0.5))
	end
	P(m, V(0.7, 1.45, 1.84), CF(0, -0.08, 0) * A(0, rad(0), 0), rgb(255, 225, 120))
	disc(m, 0.8, 0.1, CF(1.05, 0.38, 0.95) * A(rad(-90), 0, 0), d)
end

builders.cashpile = function(m)
	local g, d = rgb(90, 205, 90), rgb(50, 150, 60)
	for i = 0, 3 do
		P(m, V(3.2, 0.36, 1.7), CF(-0.7, -0.9 + i * 0.4, 0) * A(0, rad(i * 7), 0), i % 2 == 0 and g or d)
	end
	for i = 0, 2 do
		P(m, V(3.2, 0.36, 1.7), CF(0.9, -0.9 + i * 0.4, 0.5) * A(0, rad(-20 + i * 6), 0), i % 2 == 0 and d or g)
	end
	P(m, V(1.2, 1.2, 1.2), CF(0.2, 0.8, 0.6), rgb(255, 205, 40), "Ball")
end

builders.clover = function(m)
	local g, d = rgb(70, 210, 80), rgb(40, 150, 55)
	for i = 0, 3 do
		local a = rad(45 + i * 90)
		local base = CF(math.cos(a) * 0.75, math.sin(a) * 0.75 + 0.3, 0) * A(0, 0, a)
		disc(m, 1.15, 0.35, base * CF(0, 0.32, 0), g)
		disc(m, 1.15, 0.35, base * CF(0, -0.32, 0), g)
		P(m, V(0.9, 0.12, 0.4), base * CF(-0.1, 0, 0.05), d)
	end
	P(m, V(0.28, 1.6, 0.3), CF(0.35, -1.2, 0) * A(0, 0, rad(-20)), d)
end

builders.bolt = function(m, color)
	local y = color or rgb(255, 210, 40)
	local o = y:Lerp(rgb(255, 130, 0), 0.5)
	P(m, V(1.0, 1.9, 0.6), CF(0.45, 0.85, 0) * A(0, 0, rad(-22)), y)
	P(m, V(1.9, 0.6, 0.6), CF(0.05, 0.05, 0) * A(0, 0, rad(-22)), y)
	arrowHead(m, CF(-0.25, -0.35, 0) * A(0, 0, rad(158)), 1.5, 2.2, 0.6, o)
end

builders.house = function(m)
	P(m, V(2.6, 1.9, 2.2), CF(0, -0.6, 0), rgb(250, 240, 220))
	P(m, V(1.95, 0.35, 2.6), CF(-0.7, 0.75, 0) * A(0, 0, rad(38)), rgb(60, 140, 255))
	P(m, V(1.95, 0.35, 2.6), CF(0.7, 0.75, 0) * A(0, 0, rad(-38)), rgb(40, 110, 230))
	P(m, V(0.7, 1.2, 0.1), CF(0, -0.95, 1.12), rgb(150, 90, 50))
	P(m, V(0.6, 0.6, 0.1), CF(0.85, -0.4, 1.12), rgb(150, 220, 255))
	P(m, V(0.6, 0.6, 0.1), CF(-0.85, -0.4, 1.12), rgb(150, 220, 255))
end

builders.arrowup = function(m, color)
	local g = color or rgb(90, 220, 70)
	P(m, V(1.1, 1.8, 0.7), CF(0, -0.8, 0), g)
	arrowHead(m, CF(0, 0.85, 0), 2.8, 1.5, 0.7, g:Lerp(Color3.new(1, 1, 1), 0.2))
end

builders.snowflake = function(m)
	local c = rgb(150, 220, 255)
	for i = 0, 2 do
		P(m, V(3.6, 0.42, 0.42), CF() * A(0, 0, rad(i * 60)), c)
		for _, s in { -1, 1 } do
			local tip = CF() * A(0, 0, rad(i * 60)) * CF(s * 1.25, 0, 0)
			P(m, V(0.9, 0.25, 0.3), tip * A(0, 0, rad(45)), rgb(220, 245, 255))
			P(m, V(0.9, 0.25, 0.3), tip * A(0, 0, rad(-45)), rgb(220, 245, 255))
		end
	end
	P(m, V(0.8, 0.8, 0.8), CF(), rgb(220, 245, 255), "Ball")
end

builders.flask = function(m)
	P(m, V(2.4, 2.4, 2.4), CF(0, -0.5, 0), rgb(80, 220, 255), "Ball")
	P(m, V(1.0, 0.7, 0.7), CF(0, 1.0, 0) * A(0, 0, rad(90)), rgb(235, 245, 255), "Cylinder")
	P(m, V(0.3, 1.0, 1.0), CF(0, 1.45, 0) * A(0, 0, rad(90)), rgb(200, 120, 60), "Cylinder")
	P(m, V(0.4, 0.4, 0.4), CF(-0.5, -0.1, 1.0), rgb(220, 250, 255), "Ball")
end

builders.calendar = function(m)
	local root = CF() * A(0, 0, rad(-8))
	P(m, V(2.8, 2.7, 0.45), root * CF(0, -0.2, 0), rgb(250, 250, 255))
	P(m, V(2.8, 0.85, 0.5), root * CF(0, 1.0, 0), rgb(235, 50, 60))
	for _, x in { -0.8, 0.8 } do
		P(m, V(0.45, 0.25, 0.25), root * CF(x, 1.55, 0) * A(0, 0, rad(90)), rgb(60, 60, 70), "Cylinder")
	end
	for r = 0, 2 do
		for c = 0, 3 do
			P(m, V(0.45, 0.4, 0.05), root * CF(-0.9 + c * 0.6, 0.15 - r * 0.6, 0.23), (r == 2 and c == 2) and rgb(235, 50, 60) or rgb(190, 195, 210))
		end
	end
end

builders.people = function(m)
	for i, c in { rgb(60, 150, 255), rgb(90, 210, 90) } do
		local x = i == 1 and -0.8 or 0.8
		local z = i == 1 and -0.3 or 0.3
		P(m, V(1.1, 1.1, 1.1), CF(x, 0.75, z), rgb(255, 214, 160), "Ball")
		P(m, V(1.5, 1.6, 0.9), CF(x, -0.75, z), c)
	end
end

builders.crown = function(m)
	local gold = rgb(255, 200, 40)
	P(m, V(3.2, 0.9, 1.3), CF(0, -0.6, 0), gold)
	for i = -2, 2 do
		local s = i == 0 and 1.25 or 0.95
		P(m, V(s, s, 0.9), CF(i * 0.62, -0.15, 0) * A(0, 0, rad(45)), gold)
		P(m, V(0.4, 0.4, 0.4), CF(i * 0.62, -0.15 + s * 0.72, 0), rgb(255, 245, 210), "Ball")
	end
	P(m, V(0.5, 0.5, 0.2), CF(0, -0.6, 0.66), rgb(230, 40, 70))
	P(m, V(0.38, 0.38, 0.2), CF(-1.0, -0.6, 0.66), rgb(60, 150, 255))
	P(m, V(0.38, 0.38, 0.2), CF(1.0, -0.6, 0.66), rgb(60, 200, 90))
end

builders.clock = function(m)
	disc(m, 3.0, 0.5, CF(), rgb(255, 200, 40))
	disc(m, 2.5, 0.56, CF(), rgb(250, 250, 255))
	P(m, V(0.18, 0.9, 0.1), CF(0, 0.4, 0.32), rgb(40, 40, 50))
	P(m, V(0.7, 0.18, 0.1), CF(0.3, 0, 0.32), rgb(40, 40, 50))
	P(m, V(0.3, 0.3, 0.3), CF(0, 0, 0.32), rgb(230, 50, 60), "Ball")
end

builders.magnet = function(m)
	local red = rgb(235, 50, 60)
	P(m, V(0.8, 1.8, 0.8), CF(-0.9, 0.1, 0), red)
	P(m, V(0.8, 1.8, 0.8), CF(0.9, 0.1, 0), red)
	arc(m, CF(0, -0.8, 0), 0.9, math.pi, 2 * math.pi, 6, 0.8, 0.8, red)
	P(m, V(0.82, 0.6, 0.82), CF(-0.9, 1.25, 0), rgb(220, 225, 235))
	P(m, V(0.82, 0.6, 0.82), CF(0.9, 1.25, 0), rgb(220, 225, 235))
end

builders.cards = function(m)
	for i, c in { rgb(70, 150, 255), rgb(170, 90, 255), rgb(255, 180, 30) } do
		local cf = CF(-0.5 + (i - 1) * 0.5, 0, (i - 1) * 0.2) * A(0, 0, rad(18 - (i - 1) * 18))
		P(m, V(1.7, 2.4, 0.12), cf, Color3.new(1, 1, 1))
		P(m, V(1.45, 2.1, 0.14), cf, c)
	end
	P(m, V(1.2, 0.36, 0.36), CF(1.1, -1.0, 0.7), rgb(90, 220, 70))
	P(m, V(0.36, 1.2, 0.36), CF(1.1, -1.0, 0.7), rgb(90, 220, 70))
end

builders.treadmill = function(m)
	P(m, V(3.2, 0.35, 1.5), CF(0, -0.9, 0) * A(rad(0), 0, rad(8)), rgb(45, 45, 55))
	P(m, V(3.0, 0.1, 1.2), CF(0, -0.7, 0) * A(rad(0), 0, rad(8)), rgb(80, 220, 120), nil, Enum.Material.Neon)
	P(m, V(0.25, 1.9, 0.25), CF(1.3, 0.2, 0.55), rgb(200, 205, 215))
	P(m, V(0.25, 1.9, 0.25), CF(1.3, 0.2, -0.55), rgb(200, 205, 215))
	P(m, V(0.7, 0.5, 1.5), CF(1.35, 1.1, 0) * A(0, 0, rad(25)), rgb(60, 150, 255))
end

builders.cases = function(m)
	P(m, V(2.4, 1.2, 2.4), CF(0, -1.0, 0), rgb(220, 225, 240))
	P(m, V(2.6, 0.3, 2.6), CF(0, -0.3, 0), rgb(255, 200, 40), nil, Enum.Material.Neon)
	P(m, V(1.3, 1.8, 0.12), CF(0, 0.9, 0) * A(0, rad(20), 0), rgb(255, 255, 255))
	P(m, V(1.1, 1.55, 0.14), CF(0, 0.9, 0) * A(0, rad(20), 0), rgb(255, 120, 60))
end

builders.plus = function(m, color)
	local c = color or rgb(90, 220, 70)
	P(m, V(2.6, 0.9, 0.8), CF(), c)
	P(m, V(0.9, 2.6, 0.8), CF(), c)
end

builders.trophy = function(m)
	local gold = rgb(255, 200, 40)
	P(m, V(1.8, 1.5, 1.5), CF(0, 0.6, 0) * A(0, 0, rad(90)), gold, "Cylinder")
	P(m, V(0.4, 1.0, 0.4), CF(0, -0.5, 0), gold)
	P(m, V(1.6, 0.4, 1.0), CF(0, -1.1, 0), rgb(150, 90, 50))
	arc(m, CF(-0.9, 0.7, 0), 0.45, math.pi / 2, 3 * math.pi / 2, 4, 0.25, 0.25, gold)
	arc(m, CF(0.9, 0.7, 0), 0.45, -math.pi / 2, math.pi / 2, 4, 0.25, 0.25, gold)
end

-- cadre la caméra pour que tout le modèle tienne dans la vue
local function frame(vp: ViewportFrame, model: Model, dir: Vector3, fov: number, fill: number)
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then
			local h = p.Size / 2
			for _, c in { V(1, 1, 1), V(1, 1, -1), V(1, -1, 1), V(1, -1, -1), V(-1, 1, 1), V(-1, 1, -1), V(-1, -1, 1), V(-1, -1, -1) } do
				local w = p.CFrame * (h * c)
				minV = V(math.min(minV.X, w.X), math.min(minV.Y, w.Y), math.min(minV.Z, w.Z))
				maxV = V(math.max(maxV.X, w.X), math.max(maxV.Y, w.Y), math.max(maxV.Z, w.Z))
			end
		end
	end
	local center = (minV + maxV) / 2
	local radius = (maxV - minV).Magnitude / 2
	local dist = radius / math.tan(math.rad(fov / 2)) * fill
	local cam = Instance.new("Camera")
	cam.FieldOfView = fov
	cam.CFrame = CFrame.lookAt(center + dir.Unit * dist, center)
	cam.Parent = vp
	vp.CurrentCamera = cam
end

local function newViewport(props: { [string]: any }): ViewportFrame
	local vp = Instance.new("ViewportFrame")
	vp.Name = props.Name or "Icon"
	vp.BackgroundTransparency = 1
	vp.Size = props.Size or UDim2.fromScale(1, 1)
	vp.Position = props.Position or UDim2.new()
	vp.AnchorPoint = props.AnchorPoint or Vector2.zero
	vp.Rotation = props.Rotation or 0
	vp.ZIndex = props.ZIndex or 1
	vp.LayoutOrder = props.LayoutOrder or 0
	vp.Ambient = Color3.fromRGB(180, 180, 190)
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.LightDirection = Vector3.new(-0.6, -1, -0.8)
	vp.Parent = props.Parent
	return vp
end

-- props : Parent, Size, Position, AnchorPoint, Rotation, ZIndex, Color, Dir, Fill, Outline
-- Renvoie un cadre qui contient l'icône et, derrière, sa silhouette sombre un peu plus
-- grande : ça fait le contour "autocollant" des icônes des simulateurs.
function Icons3D.view(kind: string, props: { [string]: any }): Frame
	local holder = Instance.new("Frame")
	holder.Name = props.Name or "Icon"
	holder.BackgroundTransparency = 1
	holder.Size = props.Size or UDim2.fromScale(1, 1)
	holder.Position = props.Position or UDim2.new()
	holder.AnchorPoint = props.AnchorPoint or Vector2.zero
	holder.Rotation = props.Rotation or 0
	holder.ZIndex = props.ZIndex or 1
	holder.LayoutOrder = props.LayoutOrder or 0
	local build = builders[kind] or builders.crate
	local dir = props.Dir or V(0.55, 0.45, 1)
	local fill = props.Fill or 1.12
	local function layer(scale: number, z: number): ViewportFrame
		local vp = newViewport({ Parent = holder, Size = UDim2.fromScale(scale, scale), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = z })
		local model = Instance.new("Model")
		model.Name = kind
		build(model, props.Color)
		model.Parent = vp
		frame(vp, model, dir, 30, fill)
		return vp
	end
	if props.Outline ~= false then
		local outline = layer(1.1, holder.ZIndex)
		outline.Name = "Outline"
		outline.ImageColor3 = Color3.fromRGB(22, 18, 34)
		outline.Position = UDim2.new(0.5, 0, 0.5, 2)
	end
	local main = layer(1, holder.ZIndex + 1)
	main.Name = "Main"
	holder.Parent = props.Parent
	return holder
end

-- créature d'une carte (silhouette noire si pas encore découverte)
function Icons3D.entity(cardId: string, finish: string?, props: { [string]: any }): ViewportFrame
	local vp = newViewport(props)
	local model = Entity.build(cardId, finish or "Normal")
	model.Parent = vp
	if props.Hidden then
		vp.ImageColor3 = Color3.new(0, 0, 0)
		vp.ImageTransparency = 0.15
	end
	frame(vp, model, props.Dir or V(0.35, 0.25, -1), 30, props.Fill or 1.0)
	return vp
end

function Icons3D.has(kind: string): boolean
	return builders[kind] ~= nil
end

return Icons3D
