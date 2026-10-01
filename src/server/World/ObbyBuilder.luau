-- Construit le lobby, tous les stages et les checkpoints au lancement du serveur.
-- La map est générée avec une graine fixe : elle est identique sur tous les serveurs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Build = require(script.Parent.Build)
local StageTypes = require(script.Parent.StageTypes)
local Config = require(ReplicatedStorage.Shared.Config)

local ObbyBuilder = {}

local LOBBY_Y = 50
local FONT = Enum.Font.FredokaOne

local function surfaceText(part: BasePart, face: Enum.NormalId, text: string, color: Color3, strokeColor: Color3?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = FONT
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.Parent = gui
	if strokeColor then
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 6
		stroke.Color = strokeColor
		stroke.Parent = label
	end
	return gui, label
end

local function makeCheckpoint(stage: number, pos: Vector3, theme, parent: Instance): BasePart
	local isFinish = stage == Config.TotalStages()
	local pad = Build.part({
		Name = "Checkpoint_" .. stage,
		Size = Vector3.new(12, 1.2, 12),
		CFrame = CFrame.new(pos.X, pos.Y - 0.6, pos.Z),
		Color = isFinish and Color3.fromRGB(255, 205, 50) or Color3.fromRGB(245, 245, 245),
		Material = Enum.Material.SmoothPlastic,
	}, parent)
	pad:SetAttribute("Stage", stage)

	-- bordure néon à la couleur du monde
	local rim = Build.part({
		Name = "Rim",
		Size = Vector3.new(12.6, 0.9, 12.6),
		CFrame = pad.CFrame * CFrame.new(0, -0.3, 0),
		Color = isFinish and Color3.fromRGB(255, 160, 0) or theme.Alt,
		Material = Enum.Material.Neon,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
	}, pad)
	rim.Name = "Rim"

	surfaceText(
		pad,
		Enum.NormalId.Top,
		isFinish and "FINISH" or tostring(stage),
		Color3.fromRGB(30, 30, 40),
		nil
	)
	return pad
end

local function makeWorldSign(worldIndex: number, theme, pos: Vector3, parent: Instance)
	local post = Build.part({
		Name = "WorldSign",
		Size = Vector3.new(16, 7, 1),
		CFrame = CFrame.new(pos.X, pos.Y + 12, pos.Z + 8) * CFrame.Angles(0, math.pi, 0),
		Color = theme.Main,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
	}, parent)
	surfaceText(post, Enum.NormalId.Back, ("WORLD %d\n%s"):format(worldIndex, theme.Name:upper()), Color3.new(1, 1, 1), theme.Alt)
end

local function makeKillZone(bounds, parent: Instance)
	local sizeX = (bounds.maxX - bounds.minX) + 80
	local sizeZ = (bounds.maxZ - bounds.minZ) + 40
	Build.kill({
		Name = "Void",
		Size = Vector3.new(sizeX, 4, sizeZ),
		CFrame = CFrame.new((bounds.minX + bounds.maxX) / 2, bounds.minY - 30, (bounds.minZ + bounds.maxZ) / 2),
		Transparency = 1,
		CanCollide = false,
	}, parent)
end

local function newBounds()
	return { minX = math.huge, maxX = -math.huge, minZ = math.huge, maxZ = -math.huge, minY = math.huge }
end

local function growBounds(bounds, part: BasePart)
	local half = part.Size / 2
	local radius = math.max(half.X, half.Z)
	local p = part.Position
	bounds.minX = math.min(bounds.minX, p.X - radius)
	bounds.maxX = math.max(bounds.maxX, p.X + radius)
	bounds.minZ = math.min(bounds.minZ, p.Z - radius)
	bounds.maxZ = math.max(bounds.maxZ, p.Z + radius)
	bounds.minY = math.min(bounds.minY, p.Y - half.Y)
end

--------------------------------------------------------------------
-- Lobby
--------------------------------------------------------------------
local function buildLobby(root: Instance)
	local lobby = Instance.new("Folder")
	lobby.Name = "Lobby"
	lobby.Parent = root

	local base = Build.part({
		Name = "LobbyFloor",
		Size = Vector3.new(90, 4, 80),
		CFrame = CFrame.new(0, LOBBY_Y - 2, -10),
		Color = Color3.fromRGB(235, 235, 240),
		Material = Enum.Material.Concrete,
	}, lobby)

	-- bandes de couleur au sol, une par monde
	for i, world in Config.Worlds do
		Build.part({
			Name = "Stripe",
			Size = Vector3.new(90 / #Config.Worlds, 0.2, 4),
			CFrame = CFrame.new(-45 + (i - 0.5) * 90 / #Config.Worlds, LOBBY_Y + 0.1, 26),
			Color = world.Alt,
			Material = Enum.Material.Neon,
			CanCollide = false,
		}, lobby)
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(0, LOBBY_Y + 0.5, -14)
	spawn.Color = Color3.fromRGB(40, 40, 55)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = lobby
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end

	-- titre géant
	local title = Build.part({
		Name = "Title",
		Size = Vector3.new(44, 14, 1),
		CFrame = CFrame.new(0, LOBBY_Y + 16, -48),
		Transparency = 1,
		CanCollide = false,
	}, lobby)
	surfaceText(title, Enum.NormalId.Back, Config.GameName, Color3.fromRGB(255, 255, 255), Color3.fromRGB(20, 20, 30))
	local sub = Build.part({
		Name = "Subtitle",
		Size = Vector3.new(20, 5, 1),
		CFrame = CFrame.new(0, LOBBY_Y + 7, -48),
		Transparency = 1,
		CanCollide = false,
	}, lobby)
	surfaceText(sub, Enum.NormalId.Back, Config.Subtitle, Color3.fromRGB(255, 70, 110), Color3.fromRGB(20, 20, 30))

	-- panneaux de classement (remplis par LeaderboardService)
	local boards = {}
	for i, info in { { "TopLevels", "TOP LEVELS", -32 }, { "TopDonors", "TOP DONORS", 32 } } do
		local board = Build.part({
			Name = info[1],
			Size = Vector3.new(18, 24, 1),
			CFrame = CFrame.new(info[3], LOBBY_Y + 12, -40) * CFrame.Angles(0, math.rad(i == 1 and 20 or -20), 0),
			Color = Color3.fromRGB(25, 25, 35),
			Material = Enum.Material.SmoothPlastic,
		}, lobby)
		boards[info[1]] = { part = board, title = info[2] }
	end

	-- panneau d'aide
	local help = Build.part({
		Name = "Help",
		Size = Vector3.new(16, 6, 0.6),
		CFrame = CFrame.new(0, LOBBY_Y + 3.5, 24),
		Transparency = 1,
		CanCollide = false,
	}, lobby)
	surfaceText(help, Enum.NormalId.Front, "START", Color3.fromRGB(255, 255, 255), Color3.fromRGB(20, 20, 30))

	-- sécurité sous le lobby
	makeKillZone({ minX = -45, maxX = 45, minZ = -50, maxZ = 30, minY = LOBBY_Y - 4 }, lobby)

	return base, boards
end

--------------------------------------------------------------------
-- Construction complète
--------------------------------------------------------------------
function ObbyBuilder.Build()
	local existing = workspace:FindFirstChild("Obby")
	if existing then
		existing:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = "Obby"
	root.Parent = workspace

	local _, boards = buildLobby(root)

	local checkpointsFolder = Instance.new("Folder")
	checkpointsFolder.Name = "Checkpoints"
	checkpointsFolder.Parent = root

	local stagesFolder = Instance.new("Folder")
	stagesFolder.Name = "Stages"
	stagesFolder.Parent = root

	local checkpoints: { [number]: BasePart } = {}
	local total = Config.TotalStages()

	-- checkpoint 0 = départ, collé au lobby
	local pos = Vector3.new(0, LOBBY_Y, 36)
	checkpoints[0] = makeCheckpoint(0, pos, Config.Worlds[1], checkpointsFolder)
	makeWorldSign(1, Config.Worlds[1], pos, root)

	local previousType: string? = nil
	for stage = 1, total do
		local theme, worldIndex = Config.WorldForStage(stage)
		local rng = Random.new(stage * 7919 + 13)
		local folder = Instance.new("Folder")
		folder.Name = ("Stage_%02d"):format(stage)
		folder.Parent = stagesFolder

		local bounds = newBounds()
		local ctx = {
			start = pos,
			d = (stage - 1) / math.max(total - 1, 1),
			theme = theme,
			folder = folder,
			rng = rng,
			track = function(part: BasePart)
				growBounds(bounds, part)
			end,
		}

		local typeName = StageTypes.Pick(stage, rng, previousType)
		previousType = typeName
		folder:SetAttribute("Type", typeName)
		local nextPos = StageTypes[typeName](ctx)

		if bounds.minY ~= math.huge then
			makeKillZone(bounds, folder)
		end

		checkpoints[stage] = makeCheckpoint(stage, nextPos, theme, checkpointsFolder)

		-- panneau au début de chaque nouveau monde
		if stage % Config.StagesPerWorld == 0 and stage < total then
			local nextWorld = Config.Worlds[worldIndex + 1]
			makeWorldSign(worldIndex + 1, nextWorld, nextPos, root)
		end

		pos = nextPos
	end

	-- petite arène de fin autour du dernier checkpoint
	local finish = checkpoints[total]
	Build.part({
		Name = "FinishFloor",
		Size = Vector3.new(40, 2, 40),
		CFrame = CFrame.new(finish.Position.X, finish.Position.Y - 0.6, finish.Position.Z + 20),
		Color = Color3.fromRGB(255, 220, 90),
		Material = Enum.Material.SmoothPlastic,
	}, root)

	return checkpoints, boards
end

return ObbyBuilder
