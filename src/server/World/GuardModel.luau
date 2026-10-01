--[[
	Gardien de boutique : un personnage en pièces (casquette, moustache, ventre,
	uniforme, matraque) animé par le code. Pas de physique : il est déplacé
	image par image, donc il ne peut ni tomber ni se coincer.
]]

local GuardModel = {}

local INK = Color3.fromRGB(28, 28, 38)
local SKIN = Color3.fromRGB(240, 180, 120)

type Piece = { part: BasePart, offset: CFrame, swing: string? }

-- Construit le modèle. Renvoie un objet avec :Place(cf, runPhase, speedRatio, frozen)
function GuardModel.new(name: string, uniform: Color3, accent: Color3, parent: Instance)
	local model = Instance.new("Model")
	model.Name = name
	local pieces: { Piece } = {}

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

	-- l'origine est au niveau du sol, -Z = devant
	local root = add("Root", Vector3.new(4, 9, 3), CFrame.new(0, 4.5, 0), uniform)
	root.Transparency = 1
	model.PrimaryPart = root

	-- jambes (pivot à la hanche, y = 3.4)
	add("LegL", Vector3.new(1.5, 3.2, 1.6), CFrame.new(-0.85, 1.8, 0), Color3.fromRGB(60, 45, 35), "legL")
	add("LegR", Vector3.new(1.5, 3.2, 1.6), CFrame.new(0.85, 1.8, 0), Color3.fromRGB(60, 45, 35), "legR")
	add("ShoeL", Vector3.new(1.6, 0.6, 2.2), CFrame.new(-0.85, 0.3, -0.25), INK, "legL")
	add("ShoeR", Vector3.new(1.6, 0.6, 2.2), CFrame.new(0.85, 0.3, -0.25), INK, "legR")

	-- corps : gros ventre, ceinture, badge, cravate
	add("Body", Vector3.new(4.2, 3.6, 2.6), CFrame.new(0, 5.2, 0), uniform)
	add("Belly", Vector3.new(3.4, 2.4, 1), CFrame.new(0, 4.6, -1.5), uniform)
	add("Belt", Vector3.new(4.3, 0.5, 2.8), CFrame.new(0, 3.6, 0), INK)
	add("Buckle", Vector3.new(0.8, 0.5, 0.2), CFrame.new(0, 3.6, -1.45), Color3.fromRGB(255, 200, 40), nil, nil, Enum.Material.Metal)
	add("Badge", Vector3.new(0.7, 0.8, 0.15), CFrame.new(1.1, 6.2, -1.35), Color3.fromRGB(255, 200, 40), nil, nil, Enum.Material.Metal)
	add("Tie", Vector3.new(0.5, 1.6, 0.15), CFrame.new(0, 6, -1.35), accent)

	-- bras (pivot à l'épaule, y = 6.8)
	add("ArmL", Vector3.new(1.2, 3.2, 1.2), CFrame.new(-2.75, 5.3, 0), uniform, "armL")
	add("ArmR", Vector3.new(1.2, 3.2, 1.2), CFrame.new(2.75, 5.3, 0), uniform, "armR")
	add("HandL", Vector3.new(1, 0.9, 1), CFrame.new(-2.75, 3.4, 0), SKIN, "armL")
	add("HandR", Vector3.new(1, 0.9, 1), CFrame.new(2.75, 3.4, 0), SKIN, "armR")
	-- matraque dans la main droite
	add("Baton", Vector3.new(0.4, 0.4, 3.2), CFrame.new(2.75, 3.4, -1.4), INK, "armR")

	-- tête
	add("Head", Vector3.new(2.6, 2.4, 2.4), CFrame.new(0, 8.2, 0), SKIN)
	add("Nose", Vector3.new(0.6, 0.6, 0.5), CFrame.new(0, 8.1, -1.35), Color3.fromRGB(230, 150, 100))
	add("Mustache", Vector3.new(1.8, 0.4, 0.3), CFrame.new(0, 7.6, -1.3), Color3.fromRGB(60, 40, 30))
	add("EyeL", Vector3.new(0.35, 0.45, 0.1), CFrame.new(-0.55, 8.6, -1.22), INK)
	add("EyeR", Vector3.new(0.35, 0.45, 0.1), CFrame.new(0.55, 8.6, -1.22), INK)
	add("BrowL", Vector3.new(0.8, 0.2, 0.1), CFrame.new(-0.55, 9.05, -1.23) * CFrame.Angles(0, 0, math.rad(-15)), Color3.fromRGB(60, 40, 30))
	add("BrowR", Vector3.new(0.8, 0.2, 0.1), CFrame.new(0.55, 9.05, -1.23) * CFrame.Angles(0, 0, math.rad(15)), Color3.fromRGB(60, 40, 30))
	-- casquette
	add("Cap", Vector3.new(2.9, 0.9, 2.7), CFrame.new(0, 9.75, 0), uniform)
	add("CapBand", Vector3.new(2.95, 0.3, 2.75), CFrame.new(0, 9.4, 0), INK)
	add("Visor", Vector3.new(2.6, 0.2, 1.2), CFrame.new(0, 9.35, -1.8), INK)
	add("CapBadge", Vector3.new(0.6, 0.5, 0.1), CFrame.new(0, 9.8, -1.38), accent, nil, nil, Enum.Material.Neon)

	-- glace (visible seulement quand il est gelé)
	local ice = add("Ice", Vector3.new(5.5, 11, 4.5), CFrame.new(0, 5.2, 0), Color3.fromRGB(170, 230, 255), nil, nil, Enum.Material.Ice)
	ice.Transparency = 1

	model.Parent = parent

	local guard = { Model = model, Head = model:FindFirstChild("Head") :: BasePart }

	-- runPhase avance pendant la course ; speedRatio règle l'amplitude
	function guard:Place(cf: CFrame, runPhase: number, moving: boolean, frozen: boolean)
		local swing = moving and not frozen and math.sin(runPhase) * 0.9 or 0
		local bob = moving and not frozen and math.abs(math.sin(runPhase)) * 0.35 or 0
		local base = cf * CFrame.new(0, bob, 0)
		local parts, cframes = {}, {}
		for _, piece in pieces do
			local off = piece.offset
			if piece.swing == "legL" or piece.swing == "legR" then
				local a = piece.swing == "legL" and swing or -swing
				-- rotation autour de la hanche
				off = CFrame.new(0, 3.4, 0) * CFrame.Angles(a, 0, 0) * CFrame.new(0, -3.4, 0) * off
			elseif piece.swing == "armL" or piece.swing == "armR" then
				local a = piece.swing == "armL" and -swing or swing
				off = CFrame.new(0, 6.8, 0) * CFrame.Angles(a * 0.8, 0, 0) * CFrame.new(0, -6.8, 0) * off
			end
			table.insert(parts, piece.part)
			table.insert(cframes, base * off)
		end
		-- déplacement groupé : beaucoup plus léger que de changer chaque pièce une par une
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
		ice.Transparency = frozen and 0.35 or 1
	end

	return guard
end

return GuardModel
