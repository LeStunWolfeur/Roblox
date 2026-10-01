--[[
	Types de stages. Chaque fonction reçoit un contexte et construit un stage
	qui part de ctx.start (centre du dessus du checkpoint précédent) vers +Z.
	Elle renvoie la position où poser le checkpoint suivant.

	ctx.d = difficulté entre 0 (stage 1) et 1 (dernier stage)
]]

local Build = require(script.Parent.Build)

local StageTypes = {}

local PAD_HALF = 6 -- moitié de la taille d'un checkpoint
local MAX_X = 14 -- on reste dans un couloir pour que la map ne dérive pas

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Plateforme dont le dessus est à yTop
local function plat(ctx, x: number, yTop: number, z: number, sx: number, sz: number, props: { [string]: any }?): BasePart
	local p = {
		Size = Vector3.new(sx, 1.2, sz),
		CFrame = CFrame.new(x, yTop - 0.6, z),
		Color = ctx.theme.Main,
		Material = ctx.theme.Material,
	}
	if props then
		for k, v in props do
			p[k] = v
		end
	end
	local part = Build.part(p, ctx.folder)
	ctx.track(part)
	return part
end

local function clampX(x: number): number
	return math.clamp(x, -MAX_X, MAX_X)
end

--------------------------------------------------------------------
-- 1. Sauts simples entre plateformes
--------------------------------------------------------------------
function StageTypes.Hops(ctx)
	local d, rng = ctx.d, ctx.rng
	local count = rng:NextInteger(5, 7) + math.floor(d * 3)
	local x, y, z = ctx.start.X, ctx.start.Y, ctx.start.Z + PAD_HALF
	for i = 1, count do
		local size = lerp(7, 3.5, d) + rng:NextNumber(-0.5, 0.5)
		-- un saut à plat fait environ 8,5 studs, on reste en dessous
		local gap = lerp(3.5, 6.5, d) + rng:NextNumber(0, 1)
		z += gap + size / 2
		x = clampX(x + rng:NextNumber(-4, 4))
		y += rng:NextNumber(-0.5, 1.5)
		local color = (i % 2 == 0) and ctx.theme.Alt or ctx.theme.Main
		plat(ctx, x, y, z, size, size, { Color = color })
		z += size / 2
	end
	return Vector3.new(x, y, z + lerp(4, 7, d) + PAD_HALF)
end

--------------------------------------------------------------------
-- 2. Sol en damier avec cases mortelles, un chemin sûr garanti
--------------------------------------------------------------------
function StageTypes.KillFloor(ctx)
	local d, rng = ctx.d, ctx.rng
	local cols = 4
	local rows = rng:NextInteger(6, 9) + math.floor(d * 4)
	local tile = 4.5
	local x0, y, z = ctx.start.X, ctx.start.Y, ctx.start.Z + PAD_HALF
	local safeCol = rng:NextInteger(1, cols)
	local killChance = lerp(0.35, 0.75, d)
	for r = 1, rows do
		-- le chemin sûr bouge d'au plus une colonne par rangée.
		-- quand il bouge, les deux colonnes restent sûres sur cette rangée
		-- pour qu'on n'ait jamais à passer en diagonale.
		local prevCol = safeCol
		safeCol = math.clamp(safeCol + rng:NextInteger(-1, 1), 1, cols)
		local rowZ = z + (r - 0.5) * tile
		for c = 1, cols do
			local cx = x0 + (c - (cols + 1) / 2) * tile
			local isKill = c ~= safeCol and c ~= prevCol and rng:NextNumber() < killChance
			if isKill then
				local k = Build.kill({
					Size = Vector3.new(tile, 1.2, tile),
					CFrame = CFrame.new(cx, y - 0.6, rowZ),
				}, ctx.folder)
				ctx.track(k)
			else
				plat(ctx, cx, y, rowZ, tile, tile, {
					Color = ((r + c) % 2 == 0) and ctx.theme.Main or ctx.theme.Alt,
				})
			end
		end
	end
	return Vector3.new(x0, y, z + rows * tile + PAD_HALF + 1)
end

--------------------------------------------------------------------
-- 3. Couloir avec barres mortelles qui tournent (il faut sauter)
--------------------------------------------------------------------
function StageTypes.Spinners(ctx)
	local d, rng = ctx.d, ctx.rng
	local count = rng:NextInteger(2, 3) + math.floor(d * 2)
	local width = lerp(14, 9, d)
	local spacing = 18
	local length = count * spacing + 6
	local x, y, z = ctx.start.X, ctx.start.Y, ctx.start.Z + PAD_HALF
	plat(ctx, x, y, z + length / 2, width, length)
	for i = 1, count do
		local cz = z + (i - 0.5) * spacing + 3
		Build.part({
			Size = Vector3.new(2, 2, 2),
			Shape = Enum.PartType.Cylinder,
			CFrame = CFrame.new(x, y + 1, cz) * CFrame.Angles(0, 0, math.rad(90)),
			Color = ctx.theme.Alt,
			Material = Enum.Material.Metal,
		}, ctx.folder)
		local bar = Build.kill({
			Size = Vector3.new(width + 10, 1, 1),
			CFrame = CFrame.new(x, y + 1.6, cz),
		}, ctx.folder)
		local speed = lerp(1.4, 3.2, d) * (rng:NextNumber() < 0.5 and -1 or 1)
		Build.spin(bar, speed, rng:NextNumber(0, math.pi))
	end
	return Vector3.new(x, y, z + length + PAD_HALF)
end

--------------------------------------------------------------------
-- 4. Poutre étroite avec blocs mortels qui balayent
--------------------------------------------------------------------
function StageTypes.Sweepers(ctx)
	local d, rng = ctx.d, ctx.rng
	local count = rng:NextInteger(3, 4) + math.floor(d * 2)
	local width = lerp(6, 3, d)
	local spacing = 12
	local length = count * spacing + 6
	local x, y, z = ctx.start.X, ctx.start.Y, ctx.start.Z + PAD_HALF
	plat(ctx, x, y, z + length / 2, width, length, { Color = ctx.theme.Alt })
	for i = 1, count do
		local cz = z + (i - 0.5) * spacing + 3
		local block = Build.kill({
			Size = Vector3.new(3, 5, 3),
			CFrame = CFrame.new(x, y + 2.5, cz),
		}, ctx.folder)
		Build.slide(block, Vector3.new(width / 2 + 5, 0, 0), lerp(1.2, 2.6, d), i * 1.3)
	end
	return Vector3.new(x, y, z + length + PAD_HALF)
end

--------------------------------------------------------------------
-- 5. Plateformes qui disparaissent quand on marche dessus
--------------------------------------------------------------------
function StageTypes.Vanish(ctx)
	local d, rng = ctx.d, ctx.rng
	local count = rng:NextInteger(5, 7) + math.floor(d * 3)
	local x, y, z = ctx.start.X, ctx.start.Y, ctx.start.Z + PAD_HALF
	for _ = 1, count do
		local size = lerp(6.5, 4, d)
		local gap = lerp(3.5, 6.5, d)
		z += gap + size / 2
		x = clampX(x + rng:NextNumber(-4, 4))
		local p = plat(ctx, x, y, z, size, size, {
			Color = ctx.theme.Alt,
			Material = Enum.Material.Glass,
			Transparency = 0.15,
		})
		Build.vanish(p)
		z += size / 2
	end
	return Vector3.new(x, y, z + 5 + PAD_HALF)
end

--------------------------------------------------------------------
-- 6. Tour à grimper (échelle) avec murs mortels
--------------------------------------------------------------------
function StageTypes.Climb(ctx)
	local d, rng = ctx.d, ctx.rng
	local height = math.floor(lerp(16, 30, d))
	local x, y, z = ctx.start.X, ctx.start.Y, ctx.start.Z + PAD_HALF
	-- petit pont jusqu'à la tour
	plat(ctx, x, y, z + 5, 6, 10)
	local towerZ = z + 12
	local truss = Build.part({
		ClassName = "TrussPart",
		Size = Vector3.new(2, height, 2),
		CFrame = CFrame.new(x, y + height / 2, towerZ),
		Color = ctx.theme.Alt,
		Material = Enum.Material.Metal,
	}, ctx.folder)
	ctx.track(truss)
	-- murs mortels qui tournent autour de l'échelle à partir d'un certain niveau
	if d > 0.2 then
		local hazards = 1 + math.floor(d * 2)
		for i = 1, hazards do
			local hy = y + height * (i / (hazards + 1))
			local bar = Build.kill({
				Size = Vector3.new(12, 0.8, 0.8),
				CFrame = CFrame.new(x, hy, towerZ),
			}, ctx.folder)
			Build.spin(bar, lerp(1, 2.2, d), rng:NextNumber(0, math.pi))
		end
	end
	-- la plateforme du haut commence juste derrière l'échelle
	local topY = y + height
	plat(ctx, x, topY, towerZ + 6, 8, 10)
	return Vector3.new(x, topY, towerZ + 11 + PAD_HALF)
end

--------------------------------------------------------------------
-- 7. Trampolines qui envoient en l'air
--------------------------------------------------------------------
function StageTypes.Bounce(ctx)
	local d, rng = ctx.d, ctx.rng
	local count = rng:NextInteger(2, 3) + math.floor(d * 2)
	local x, y, z = ctx.start.X, ctx.start.Y, ctx.start.Z + PAD_HALF
	for _ = 1, count do
		z += 6
		local pad = plat(ctx, x, y, z, 6, 6, {
			Color = Color3.fromRGB(80, 255, 140),
			Material = Enum.Material.Neon,
		})
		Build.jumpPad(pad, 85)
		-- plateforme d'arrivée, plus haute et plus loin
		-- (le trampoline donne ~18 studs de haut et ~12 studs de portée)
		y += rng:NextNumber(8, 11)
		z += lerp(9, 11, d)
		x = clampX(x + rng:NextNumber(-4, 4))
		local land = lerp(9, 6, d)
		plat(ctx, x, y, z, land, land)
		z += land / 2
	end
	return Vector3.new(x, y, z + 4 + PAD_HALF)
end

--------------------------------------------------------------------
-- 8. Poutres en zigzag au-dessus du vide
--------------------------------------------------------------------
function StageTypes.Beams(ctx)
	local d, rng = ctx.d, ctx.rng
	local count = rng:NextInteger(3, 4) + math.floor(d * 2)
	local width = lerp(2.6, 1.4, d)
	local x, y, z = ctx.start.X, ctx.start.Y, ctx.start.Z + PAD_HALF
	local side = rng:NextNumber() < 0.5 and -1 or 1
	for _ = 1, count do
		local len = rng:NextNumber(12, 16)
		local nx = clampX(x + side * rng:NextNumber(5, 8))
		side = -side
		local from = Vector3.new(x, y, z)
		local to = Vector3.new(nx, y, z + len)
		local mid = (from + to) / 2
		local dist = (to - from).Magnitude
		local beam = Build.part({
			Size = Vector3.new(width, 1, dist + width),
			CFrame = CFrame.lookAt(mid - Vector3.new(0, 0.5, 0), to - Vector3.new(0, 0.5, 0)),
			Color = ctx.theme.Alt,
			Material = Enum.Material.WoodPlanks,
		}, ctx.folder)
		ctx.track(beam)
		-- petit plot au bout de chaque poutre
		plat(ctx, nx, y, z + len, 3.5, 3.5)
		x, z = nx, z + len
	end
	return Vector3.new(x, y, z + 6 + PAD_HALF)
end

-- Ordre des types débloqués au fil de la progression
StageTypes.Unlock = {
	{ name = "Hops", from = 1 },
	{ name = "KillFloor", from = 2 },
	{ name = "Vanish", from = 4 },
	{ name = "Spinners", from = 5 },
	{ name = "Beams", from = 8 },
	{ name = "Bounce", from = 11 },
	{ name = "Sweepers", from = 13 },
	{ name = "Climb", from = 17 },
}

function StageTypes.Pick(stage: number, rng: Random, previous: string?): string
	local pool = {}
	for _, entry in StageTypes.Unlock do
		if stage >= entry.from and entry.name ~= previous then
			table.insert(pool, entry.name)
		end
	end
	-- le dernier type débloqué apparaît forcément au moment où il arrive
	for _, entry in StageTypes.Unlock do
		if entry.from == stage then
			return entry.name
		end
	end
	if #pool == 0 then
		return "Hops"
	end
	return pool[rng:NextInteger(1, #pool)]
end

return StageTypes
