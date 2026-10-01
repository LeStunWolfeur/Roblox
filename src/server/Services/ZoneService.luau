--[[
	Les boutiques de la route.
	- Chaque boutique a des présentoirs avec des cartes à voler (maintenir E).
	- Le gardien de la boutique poursuit le voleur jusqu'au portail de la zone.
	- Attrapé ou frappé par un joueur : la carte tombe au sol, n'importe qui peut la ramasser.
	- De retour dans le hub (zone sûre), la carte part au Grading Lab.
	- Un joueur sans la vitesse minimum ne peut pas entrer dans une zone.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Cards = require(ReplicatedStorage.Shared.Cards)
local CardArt = require(ReplicatedStorage.Shared.CardArt)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local MapBuilder = require(script.Parent.Parent.World.MapBuilder)
local Hub = require(script.Parent.Parent.Hub)

local ZoneService = {}

type Carry = { Id: string, F: string, Zone: number, visual: BasePart? }

local zones = {}
local carrying: { [Player]: Carry } = {}
local guardians = {}
local gateWarning: { [Player]: number } = {}

local INK = Color3.fromRGB(20, 20, 30)

function ZoneService.IsCarrying(player: Player): boolean
	return carrying[player] ~= nil
end

--------------------------------------------------------------------
-- Visuel de la carte portée
--------------------------------------------------------------------
local function clearCarryVisual(player: Player, c: Carry)
	if c.visual then
		c.visual:Destroy()
		c.visual = nil
	end
	local head = player.Character and player.Character:FindFirstChild("Head")
	local tag = head and head:FindFirstChild("CarryTag")
	if tag then
		tag:Destroy()
	end
end

local function attachCarryVisual(player: Player, c: Carry)
	local head = player.Character and player.Character:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local part = CardArt.part(c.Id, c.F, nil, true)
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Size = Vector3.new(2.4, 3.36, 0.15)
	part.CFrame = head.CFrame * CFrame.new(0, 3.2, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = part
	weld.Parent = part
	part.Parent = player.Character
	c.visual = part

	local rarity = Cards.Rarities[Cards.ById[c.Id].Rarity]
	local label, gui = MapBuilder.billboard(head, UDim2.fromOffset(200, 34), Vector3.new(0, 6, 0), Cards.DisplayName(c.Id, c.F), rarity.Color, 150)
	gui.Name = "CarryTag"
	gui.AlwaysOnTop = true
	label.Name = "CarryLabel"
end

local function setCarry(player: Player, c: Carry?)
	local old = carrying[player]
	if old then
		clearCarryVisual(player, old)
	end
	carrying[player] = c
	player:SetAttribute("Carrying", c and c.Id or nil)
	if c then
		attachCarryVisual(player, c)
	end
	Hub.Combat.UpdateSpeed(player)
end

--------------------------------------------------------------------
-- Cartes tombées au sol
--------------------------------------------------------------------
local dropsFolder: Folder

local function spawnDrop(id: string, finish: string, zoneIndex: number, position: Vector3)
	local part = CardArt.part(id, finish, nil, true)
	part.CFrame = CFrame.new(position.X, 3.4, position.Z) * CFrame.Angles(0, math.rad(Hub.Loot.Random():NextNumber(0, 360)), 0)
	part.Parent = dropsFolder
	CollectionService:AddTag(part, "DroppedCard")
	local rarity = Cards.Rarities[Cards.ById[id].Rarity]
	MapBuilder.billboard(part, UDim2.fromOffset(200, 30), Vector3.new(0, 4.2, 0), Cards.DisplayName(id, finish), rarity.Color, 90)
	local prompt = MapBuilder.prompt(part, "Grab", Cards.DisplayName(id, finish), 0.3, 10)
	local taken = false
	prompt.Triggered:Connect(function(player)
		if taken or carrying[player] then
			return
		end
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local grabber = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not humanoid or humanoid.Health <= 0 or not grabber then
			return
		end
		if (grabber.Position - part.Position).Magnitude > 14 then
			return
		end
		taken = true
		part:Destroy()
		setCarry(player, { Id = id, F = finish, Zone = zoneIndex })
		Remotes.Notify:FireClient(player, "Got it! Run back to the hub!", "info")
		-- le gardien de la zone se réveille si on est encore chez lui
		local g = guardians[zoneIndex]
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if g and root and MapBuilder.ZoneAt(root.Position.Z) == zoneIndex and g.state ~= "chase" then
			g.alert(player)
		end
	end)
	task.delay(Config.DropLifetime, function()
		if not taken and part.Parent then
			taken = true
			part:Destroy()
		end
	end)
end

-- Le joueur lâche sa carte (attrapé, frappé, mort)
function ZoneService.Drop(player: Player, reason: string?)
	local c = carrying[player]
	if not c then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local position = root and root.Position
	setCarry(player, nil)
	if position and not MapBuilder.InHub(position) then
		spawnDrop(c.Id, c.F, c.Zone, position)
	end
	if reason then
		Remotes.Notify:FireClient(player, reason, "error")
	end
end

--------------------------------------------------------------------
-- Présentoirs
--------------------------------------------------------------------
local function restock(zoneIndex: number, pedestal)
	local zone = Config.Zones[zoneIndex]
	local rarity = Hub.Loot.RollRarity(zone.Rarity, Hub.Events.Luck())
	local id = Hub.Loot.RollCard(rarity)
	local finish = Hub.Loot.RollFinish()
	pedestal.card = { Id = id, F = finish }

	local part = CardArt.part(id, finish, nil, false)
	part.CFrame = pedestal.CardCFrame
	part.Parent = zones[zoneIndex].Folder
	CollectionService:AddTag(part, "ShopCard")
	pedestal.part = part

	local r = Cards.Rarities[Cards.ById[id].Rarity]
	MapBuilder.billboard(part, UDim2.fromOffset(220, 30), Vector3.new(0, 4.4, 0), Cards.DisplayName(id, finish), r.Color, 70)
	MapBuilder.billboard(
		part,
		UDim2.fromOffset(220, 24),
		Vector3.new(0, 3.3, 0),
		r.Name:upper() .. "  ·  " .. Format.cash(Cards.IncomeOf(id, finish, 6)) .. "/s",
		Color3.new(1, 1, 1),
		70
	)
	local prompt = MapBuilder.prompt(part, "Steal", Cards.DisplayName(id, finish), Config.StealHoldTime, 10)
	prompt.Triggered:Connect(function(player)
		ZoneService.TrySteal(player, zoneIndex, pedestal)
	end)

	if r.Order >= Cards.Rarities.Legendary.Order then
		Remotes.Announce:FireAllClients(
			r.Name:upper() .. " IN STOCK!",
			("%s at %s"):format(Cards.DisplayName(id, finish), zone.Name),
			r.Name
		)
	end
end

local function scheduleRestock(zoneIndex: number, pedestal)
	local rng = Hub.Loot.Random()
	local delay = rng:NextNumber(Config.RestockTime[1], Config.RestockTime[2]) / Hub.Events.RestockSpeed()
	task.delay(delay, function()
		if not pedestal.card then
			restock(zoneIndex, pedestal)
		end
	end)
end

function ZoneService.TrySteal(player: Player, zoneIndex: number, pedestal)
	if not pedestal.card or carrying[player] then
		return
	end
	local data = DataService.Get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not data or not humanoid or humanoid.Health <= 0 or not root then
		return
	end
	if data.Speed < Config.Zones[zoneIndex].Speed then
		return
	end
	if (root.Position - pedestal.Stand.Position).Magnitude > 16 then
		return
	end
	local card = pedestal.card
	pedestal.card = nil
	if pedestal.part then
		pedestal.part:Destroy()
		pedestal.part = nil
	end
	setCarry(player, { Id = card.Id, F = card.F, Zone = zoneIndex })
	scheduleRestock(zoneIndex, pedestal)
	Remotes.Notify:FireClient(player, "RUN! " .. Config.Zones[zoneIndex].Guardian .. " saw you!", "error")

	local g = guardians[zoneIndex]
	if g.state ~= "chase" and g.state ~= "alert" then
		g.alert(player)
	end
end

-- Panneau admin : remplit tous les présentoirs vides
function ZoneService.RestockAll()
	for i, z in zones do
		for _, pedestal in z.Pedestals do
			if not pedestal.card then
				restock(i, pedestal)
			end
		end
	end
end

--------------------------------------------------------------------
-- Gardiens
--------------------------------------------------------------------
local function buildGuardianModel(zoneIndex: number, home: CFrame): Model
	local zone = Config.Zones[zoneIndex]
	local model = Instance.new("Model")
	model.Name = zone.Guardian

	local function p(name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = home * offset
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = model
		return part
	end

	local skin = Color3.fromRGB(255, 205, 160)
	local root = p("Root", Vector3.new(4, 7, 2), CFrame.new(0, 3.5, 0), skin)
	root.Transparency = 1
	model.PrimaryPart = root
	p("LegL", Vector3.new(1.5, 3, 1.5), CFrame.new(-0.9, 1.5, 0), INK)
	p("LegR", Vector3.new(1.5, 3, 1.5), CFrame.new(0.9, 1.5, 0), INK)
	p("Body", Vector3.new(4, 3.6, 2.2), CFrame.new(0, 4.8, 0), zone.Main)
	-- tablier du vendeur
	p("Apron", Vector3.new(3, 3, 0.2), CFrame.new(0, 4.4, -1.15), zone.Accent)
	p("ArmL", Vector3.new(1.2, 3.4, 1.2), CFrame.new(-2.7, 4.8, 0), skin)
	p("ArmR", Vector3.new(1.2, 3.4, 1.2), CFrame.new(2.7, 4.8, 0), skin)
	local head = p("Head", Vector3.new(2.6, 2.6, 2.6), CFrame.new(0, 7.9, 0), skin)
	p("Cap", Vector3.new(2.8, 0.8, 2.8), CFrame.new(0, 9.4, 0), zone.Accent)
	p("Visor", Vector3.new(2.8, 0.25, 1.4), CFrame.new(0, 9.1, -1.8), zone.Accent)

	-- visage (yeux + sourcils fâchés)
	local face = Instance.new("SurfaceGui")
	face.Face = Enum.NormalId.Front
	face.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	face.PixelsPerStud = 40
	face.Parent = head
	for _, x in { 0.28, 0.72 } do
		local eye = Instance.new("Frame")
		eye.Size = UDim2.fromScale(0.16, 0.2)
		eye.Position = UDim2.fromScale(x, 0.42)
		eye.AnchorPoint = Vector2.new(0.5, 0.5)
		eye.BackgroundColor3 = INK
		eye.Parent = face
		local brow = Instance.new("Frame")
		brow.Size = UDim2.fromScale(0.26, 0.06)
		brow.Position = UDim2.fromScale(x, 0.26)
		brow.AnchorPoint = Vector2.new(0.5, 0.5)
		brow.Rotation = x < 0.5 and 18 or -18
		brow.BackgroundColor3 = INK
		brow.Parent = face
	end
	local mouth = Instance.new("Frame")
	mouth.Size = UDim2.fromScale(0.4, 0.07)
	mouth.Position = UDim2.fromScale(0.5, 0.72)
	mouth.AnchorPoint = Vector2.new(0.5, 0.5)
	mouth.BackgroundColor3 = INK
	mouth.Parent = face

	local label, gui = MapBuilder.billboard(head, UDim2.fromOffset(220, 34), Vector3.new(0, 3, 0), zone.Guardian:upper(), zone.Accent, 120)
	gui.Name = "NameTag"
	label.Name = "Name"
	model.Parent = zones[zoneIndex].Folder
	return model
end

local function makeGuardian(zoneIndex: number)
	local z = zones[zoneIndex]
	local zone = Config.Zones[zoneIndex]
	local home = z.GuardianHome * CFrame.Angles(0, math.pi, 0) -- regarde vers l'entrée
	local model = buildGuardianModel(zoneIndex, home)
	local tag = (model:FindFirstChild("Head") :: BasePart):FindFirstChild("NameTag") :: BillboardGui
	local nameLabel = tag:FindFirstChild("Name") :: TextLabel

	local g = {
		state = "idle",
		target = nil :: Player?,
		model = model,
		position = home.Position,
		alertAt = 0,
	}
	-- porte de la boutique (côté route) : le gardien passe par là pour sortir
	local door = z.ShopAt(0, 0, -6).Position

	local function speed(): number
		return Config.GuardianSpeedFor(zone) * Hub.Events.GuardianSpeedFactor()
	end

	local function insideShop(pos: Vector3): boolean
		local p = z.ShopCFrame:PointToObjectSpace(pos)
		return p.Z < 0 and p.Z > -56 and math.abs(p.X) < 35
	end

	function g.alert(player: Player)
		g.state = "alert"
		g.target = player
		-- temps de réaction exprimé en distance : même difficulté dans toutes les zones
		g.alertAt = os.clock() + Config.GuardianReaction / speed()
		nameLabel.Text = "!!!"
		nameLabel.TextColor3 = Color3.fromRGB(255, 60, 90)
	end

	local function giveUp()
		g.state = "return"
		g.passedDoor = false
		g.target = nil
		nameLabel.Text = zone.Guardian:upper()
		nameLabel.TextColor3 = zone.Accent
	end

	local function moveToward(goal: Vector3, step: number)
		local flat = Vector3.new(goal.X, g.position.Y, goal.Z)
		local offset = flat - g.position
		local dist = offset.Magnitude
		if dist < 0.05 then
			return 0
		end
		local move = math.min(step, dist)
		g.position += offset.Unit * move
		return dist - move
	end

	local bob = 0
	function g.update(dt: number)
		local t = os.clock()
		if g.state == "alert" then
			if t >= g.alertAt then
				g.state = "chase"
				nameLabel.Text = zone.Guardian:upper() .. "!"
			end
		elseif g.state == "chase" then
			local target = g.target
			local c = target and carrying[target]
			local root = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			-- le gardien abandonne si la cible n'a plus la carte ou est sortie de la zone
			local lost = not target or not target.Parent or not c or c.Zone ~= zoneIndex or not root
			if lost or root.Position.Z < z.GateZ - 8 or MapBuilder.InHub(root.Position) then
				giveUp()
			else
				local goal = root.Position
				if insideShop(g.position) and not insideShop(goal) then
					goal = door
				end
				moveToward(goal, speed() * dt)
				local flatDist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(g.position.X, 0, g.position.Z)).Magnitude
				if flatDist < Config.GuardianCatchRadius then
					local away = (root.Position - g.position) * Vector3.new(1, 0, 1)
					away = away.Magnitude > 0 and away.Unit or Vector3.new(0, 0, -1)
					Remotes.Knockback:FireClient(target, away * 70 + Vector3.new(0, 45, 0))
					ZoneService.Drop(target, "Caught by " .. zone.Guardian .. "!")
					giveUp()
				end
			end
		elseif g.state == "return" then
			-- d'abord la porte de la boutique, ensuite sa place
			if not g.passedDoor and insideShop(g.position) then
				g.passedDoor = true
			end
			local goal = g.passedDoor and home.Position or door
			local left = moveToward(goal, speed() * 1.5 * dt)
			if left <= 0.1 then
				if g.passedDoor then
					g.state = "idle"
					g.position = home.Position
				else
					g.passedDoor = true
				end
			end
		end

		-- orientation et petit rebond pendant la course
		local facing
		if g.state == "idle" or g.state == "alert" then
			facing = home.LookVector
			bob = 0
		else
			local goalPos = g.target and g.target.Character and g.target.Character:FindFirstChild("HumanoidRootPart")
			local dir = goalPos and ((goalPos :: BasePart).Position - g.position) or (home.Position - g.position)
			dir = Vector3.new(dir.X, 0, dir.Z)
			facing = dir.Magnitude > 0.1 and dir.Unit or home.LookVector
			bob += dt * 14
		end
		-- le sol de la boutique est à 1 stud, la route à 0,2
		local floor = insideShop(g.position) and 1 or 0.2
		local lift = Vector3.new(0, floor + 3.5 + math.abs(math.sin(bob)) * 0.6, 0)
		model:PivotTo(CFrame.lookAt(g.position + lift, g.position + lift + facing))
	end

	guardians[zoneIndex] = g
end

--------------------------------------------------------------------
-- Démarrage
--------------------------------------------------------------------
function ZoneService.Start(built)
	zones = built
	dropsFolder = Instance.new("Folder")
	dropsFolder.Name = "DroppedCards"
	dropsFolder.Parent = workspace

	for i, z in zones do
		for _, pedestal in z.Pedestals do
			restock(i, pedestal)
		end
		makeGuardian(i)
	end

	RunService.Heartbeat:Connect(function(dt)
		for _, g in guardians do
			g.update(dt)
		end
	end)

	-- livraison au hub, morts, portails de vitesse
	task.spawn(function()
		while true do
			task.wait(0.1)
			for _, player in Players:GetPlayers() do
				local data = DataService.Get(player)
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if data and root and humanoid then
					local c = carrying[player]
					if c then
						if humanoid.Health <= 0 then
							ZoneService.Drop(player, "You dropped the card!")
						elseif MapBuilder.InHub(root.Position) then
							setCarry(player, nil)
							data.Steals += 1
							Hub.Grading.Deliver(player, c.Id, c.F)
							Hub.Players.OnSteal(player, c.Id, c.F)
						end
					end

					local zoneIndex = MapBuilder.ZoneAt(root.Position.Z)
					if zoneIndex > 0 then
						local zone = Config.Zones[zoneIndex]
						if data.Speed < zone.Speed then
							-- pas assez rapide : renvoyé devant le portail
							character:PivotTo(CFrame.new(root.Position.X * 0.3, 4, MapBuilder.ZoneGateZ(zoneIndex) - 8))
							if (gateWarning[player] or 0) + 3 < os.clock() then
								gateWarning[player] = os.clock()
								Remotes.Notify:FireClient(player, ("You need %s Speed for %s"):format(Format.short(zone.Speed), zone.Name), "error")
							end
						elseif zoneIndex > data.BestZone then
							data.BestZone = zoneIndex
							Hub.Players.OnNewZone(player, zoneIndex)
						end
					end
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		carrying[player] = nil
		gateWarning[player] = nil
	end)
end

return ZoneService
