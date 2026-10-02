--[[
	Gardien de boutique (et vendeurs des stands) : personnage en pièces, animé par le code.
	Casquette de police avec visière et insigne, tête arrondie avec visage (yeux, sourcils,
	nez, moustache), chemise d'uniforme avec col, épaulettes, insigne étoile, poches,
	radio à l'épaule, ceinture avec étui, membres arrondis, chaussures, matraque.
	Les gardiens des boutiques chères portent des lunettes de soleil.
	Pas de physique : il est déplacé image par image (BulkMoveTo), il ne peut ni tomber
	ni se coincer.

	GuardModel.new(name, uniform, accent, parent, opts) -> objet avec :Place(cf, phase, moving, frozen)
	opts : Shades (lunettes), Vendor (tablier au lieu de la matraque), Skin
]]

local GuardModel = {}

local INK = Color3.fromRGB(28, 28, 38)
local SKINS = { Color3.fromRGB(240, 190, 140), Color3.fromRGB(198, 140, 95), Color3.fromRGB(130, 85, 55), Color3.fromRGB(255, 214, 170) }
local GOLD = Color3.fromRGB(255, 200, 50)
local WHITE = Color3.fromRGB(245, 245, 250)

type Piece = { part: BasePart, offset: CFrame, swing: string? }

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- cylindre debout
local FACING = CFrame.Angles(0, math.rad(90), 0) -- cylindre tourné vers l'avant

function GuardModel.new(name: string, uniform: Color3, accent: Color3, parent: Instance, opts: { [string]: any }?)
	local o = opts or {}
	local model = Instance.new("Model")
	model.Name = name
	local pieces: { Piece } = {}
	local skin = o.Skin or SKINS[(#name % #SKINS) + 1]
	local pants = uniform:Lerp(INK, 0.55)
	local shirt = o.Vendor and Color3.fromRGB(250, 248, 240) or uniform

	local function add(partName: string, size: Vector3, offset: CFrame, color: Color3, swing: string?, shape: Enum.PartType?, material: Enum.Material?)
		local p = Instance.new("Part")
		p.Name = partName
		p.Size = size
		p.Color = color
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = true
		p.Material = material or Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then
			p.Shape = shape
		end
		p.Parent = model
		table.insert(pieces, { part = p, offset = offset, swing = swing })
		return p
	end
	local BALL, CYL = Enum.PartType.Ball, Enum.PartType.Cylinder

	-- l'origine est au niveau du sol, -Z = devant
	local root = add("Root", Vector3.new(4, 9, 3), CFrame.new(0, 4.5, 0), uniform)
	root.Transparency = 1
	model.PrimaryPart = root

	-- JAMBES (pivot à la hanche, y = 3.4)
	for _, s in { -1, 1 } do
		local side = s < 0 and "legL" or "legR"
		add("Leg", Vector3.new(3.1, 1.5, 1.5), CFrame.new(s * 0.82, 1.95, 0) * UPRIGHT, pants, side, CYL)
		add("Shoe", Vector3.new(1.55, 0.7, 2.0), CFrame.new(s * 0.82, 0.35, -0.15), INK, side)
		add("Toe", Vector3.new(1.4, 1.4, 1.4), CFrame.new(s * 0.82, 0.5, -1.0), INK, side, BALL)
		add("Stripe", Vector3.new(2.6, 0.2, 0.2), CFrame.new(s * 1.58, 2.0, 0) * UPRIGHT, accent, side, CYL)
	end

	-- CORPS
	add("Torso", Vector3.new(4.1, 3.7, 2.3), CFrame.new(0, 5.3, 0), shirt)
	add("Belly", Vector3.new(1.0, 3.2, 3.2), CFrame.new(0, 4.6, -1.0) * FACING, shirt, nil, CYL)
	add("Belt", Vector3.new(4.2, 0.55, 2.5), CFrame.new(0, 3.55, 0), INK)
	add("Belt2", Vector3.new(3.3, 0.55, 0.4), CFrame.new(0, 3.55, -1.55), INK)
	add("Buckle", Vector3.new(0.9, 0.5, 0.2), CFrame.new(0, 3.55, -1.8), GOLD, nil, nil, Enum.Material.Metal)
	add("Holster", Vector3.new(0.8, 1.2, 0.9), CFrame.new(2.0, 3.2, 0), INK)
	add("Collar", Vector3.new(1.4, 0.5, 0.3), CFrame.new(-0.55, 6.95, -1.12) * CFrame.Angles(0, 0, math.rad(-20)), shirt:Lerp(WHITE, 0.4))
	add("Collar", Vector3.new(1.4, 0.5, 0.3), CFrame.new(0.55, 6.95, -1.12) * CFrame.Angles(0, 0, math.rad(20)), shirt:Lerp(WHITE, 0.4))
	add("Tie", Vector3.new(0.45, 1.8, 0.15), CFrame.new(0, 5.9, -1.22), accent)
	add("TieKnot", Vector3.new(0.6, 0.4, 0.2), CFrame.new(0, 6.85, -1.22), accent)
	if o.Vendor then
		-- tablier de vendeur
		add("Apron", Vector3.new(3.2, 4.2, 0.2), CFrame.new(0, 4.4, -1.62), accent)
		add("ApronPocket", Vector3.new(1.8, 0.9, 0.22), CFrame.new(0, 3.6, -1.7), accent:Lerp(INK, 0.25))
	else
		for _, s in { -1, 1 } do
			add("Pocket", Vector3.new(1.1, 0.9, 0.15), CFrame.new(s * 1.2, 5.9, -1.2), shirt:Lerp(INK, 0.15))
			add("PocketFlap", Vector3.new(1.2, 0.25, 0.2), CFrame.new(s * 1.2, 6.3, -1.22), shirt:Lerp(INK, 0.3))
		end
		-- insigne étoile (deux carrés tournés)
		add("Badge", Vector3.new(0.7, 0.7, 0.12), CFrame.new(1.2, 6.15, -1.32), GOLD, nil, nil, Enum.Material.Metal)
		add("Badge", Vector3.new(0.7, 0.7, 0.12), CFrame.new(1.2, 6.15, -1.32) * CFrame.Angles(0, 0, math.rad(45)), GOLD, nil, nil, Enum.Material.Metal)
		-- radio à l'épaule
		add("Radio", Vector3.new(0.6, 0.9, 0.4), CFrame.new(-1.4, 6.6, -1.25), INK)
		add("Antenna", Vector3.new(0.12, 0.7, 0.12), CFrame.new(-1.55, 7.35, -1.25), INK)
	end
	-- épaulettes
	for _, s in { -1, 1 } do
		add("Epaulette", Vector3.new(1.3, 0.3, 1.6), CFrame.new(s * 1.95, 7.2, 0), o.Vendor and accent or GOLD, nil, nil, o.Vendor and nil or Enum.Material.Metal)
	end

	-- BRAS (pivot à l'épaule, y = 6.8)
	for _, s in { -1, 1 } do
		local side = s < 0 and "armL" or "armR"
		add("Sleeve", Vector3.new(1.8, 1.35, 1.35), CFrame.new(s * 2.7, 6.3, 0) * UPRIGHT, shirt, side, CYL)
		add("Arm", Vector3.new(1.6, 1.15, 1.15), CFrame.new(s * 2.7, 4.75, 0) * UPRIGHT, skin, side, CYL)
		add("Hand", Vector3.new(1.15, 1.15, 1.15), CFrame.new(s * 2.7, 3.75, 0), skin, side, BALL)
	end
	if not o.Vendor then
		add("Baton", Vector3.new(3.2, 0.42, 0.42), CFrame.new(2.7, 3.75, -1.5) * FACING, INK, "armR", CYL)
		add("BatonGrip", Vector3.new(0.5, 0.5, 0.5), CFrame.new(2.7, 3.75, 0.1) * FACING, Color3.fromRGB(90, 90, 100), "armR", CYL)
	end

	-- TÊTE (forme arrondie)
	add("Neck", Vector3.new(0.6, 1.1, 1.1), CFrame.new(0, 7.35, 0) * UPRIGHT, skin, nil, CYL)
	local head = add("Head", Vector3.new(2.7, 2.6, 2.5), CFrame.new(0, 8.6, 0), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	mesh.Parent = head
	for _, s in { -1, 1 } do
		add("Ear", Vector3.new(0.6, 0.6, 0.6), CFrame.new(s * 1.62, 8.6, 0.1), skin, nil, BALL)
		if o.Shades then
			add("Lens", Vector3.new(0.85, 0.55, 0.15), CFrame.new(s * 0.55, 8.85, -1.42), INK, nil, nil, Enum.Material.Glass)
		else
			add("EyeWhite", Vector3.new(0.55, 0.55, 0.55), CFrame.new(s * 0.55, 8.85, -1.25), WHITE, nil, BALL)
			add("Pupil", Vector3.new(0.3, 0.3, 0.3), CFrame.new(s * 0.52, 8.83, -1.5), INK, nil, BALL)
		end
		add("Brow", Vector3.new(0.8, 0.2, 0.15), CFrame.new(s * 0.55, 9.35, -1.38) * CFrame.Angles(0, 0, math.rad(s * 15)), Color3.fromRGB(60, 40, 30))
		add("Stache", Vector3.new(0.85, 0.35, 0.3), CFrame.new(s * 0.42, 8.05, -1.42) * CFrame.Angles(0, 0, math.rad(s * -12)), Color3.fromRGB(70, 45, 30))
	end
	if o.Shades then
		add("Bridge", Vector3.new(0.4, 0.12, 0.12), CFrame.new(0, 8.95, -1.45), INK)
	end
	add("Nose", Vector3.new(0.6, 0.6, 0.6), CFrame.new(0, 8.45, -1.4), skin:Lerp(Color3.fromRGB(220, 120, 90), 0.3), nil, BALL)
	add("Mouth", Vector3.new(0.7, 0.15, 0.1), CFrame.new(0, 7.75, -1.3), Color3.fromRGB(120, 50, 50))

	-- CASQUETTE de police
	add("CapCrown", Vector3.new(1.2, 3.1, 3.1), CFrame.new(0, 10.15, 0) * UPRIGHT, uniform:Lerp(INK, 0.35), nil, CYL)
	add("CapBand", Vector3.new(0.5, 2.85, 2.85), CFrame.new(0, 9.65, 0) * UPRIGHT, INK, nil, CYL)
	add("CapStripe", Vector3.new(0.18, 2.9, 2.9), CFrame.new(0, 9.75, 0) * UPRIGHT, o.Vendor and accent or GOLD, nil, CYL)
	add("Visor", Vector3.new(2.5, 0.22, 1.3), CFrame.new(0, 9.4, -1.6) * CFrame.Angles(math.rad(12), 0, 0), INK)
	add("CapBadge", Vector3.new(0.6, 0.6, 0.12), CFrame.new(0, 10.15, -1.58), GOLD, nil, nil, Enum.Material.Neon)

	-- glace (visible seulement quand il est gelé)
	local ice = add("Ice", Vector3.new(6.2, 11.6, 5), CFrame.new(0, 5.5, 0), Color3.fromRGB(170, 230, 255), nil, nil, Enum.Material.Ice)
	ice.Transparency = 1

	model.Parent = parent

	local guard = { Model = model, Head = head }

	function guard:Place(cf: CFrame, runPhase: number, moving: boolean, frozen: boolean)
		local swing = moving and not frozen and math.sin(runPhase) * 0.9 or 0
		local bob = moving and not frozen and math.abs(math.sin(runPhase)) * 0.35 or 0
		-- penché en avant quand il court
		local lean = moving and not frozen and CFrame.Angles(math.rad(-8), 0, 0) or CFrame.new()
		local base = cf * CFrame.new(0, bob, 0) * lean
		local parts, cframes = {}, {}
		for _, piece in pieces do
			local off = piece.offset
			if piece.swing == "legL" or piece.swing == "legR" then
				local a = piece.swing == "legL" and swing or -swing
				off = CFrame.new(0, 3.4, 0) * CFrame.Angles(a, 0, 0) * CFrame.new(0, -3.4, 0) * off
			elseif piece.swing == "armL" or piece.swing == "armR" then
				local a = piece.swing == "armL" and -swing or swing
				off = CFrame.new(0, 6.8, 0) * CFrame.Angles(a * 0.8, 0, 0) * CFrame.new(0, -6.8, 0) * off
			end
			table.insert(parts, piece.part)
			table.insert(cframes, base * off)
		end
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
		ice.Transparency = frozen and 0.35 or 1
	end

	return guard
end

return GuardModel
