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
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local MapBuilder = require(script.Parent.Parent.World.MapBuilder)
local GuardModel = require(script.Parent.Parent.World.GuardModel)
local Showcase = require(script.Parent.Parent.World.Showcase)
local Entity = require(ReplicatedStorage.Shared.Entity)
local Nameplate = require(ReplicatedStorage.Shared.Nameplate)
local Hub = require(script.Parent.Parent.Hub)

local ZoneService = {}

type Carry = { Id: string, F: string, Zone: number, visual: BasePart? }

local zones = {}
local carrying: { [Player]: Carry } = {}
local guardians = {}
local gateWarning: { [Player]: number } = {}


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

	Showcase.style(pedestal.Show, Cards.ById[id].Rarity)
	-- la créature de la carte sur le présentoir, la carte qui flotte au-dessus
	local display = Instance.new("Model")
	display.Name = "Display"
	local entity = Entity.build(id, finish)
	local facing = pedestal.CardCFrame - pedestal.CardCFrame.Position
	Entity.place(entity, CFrame.new(pedestal.Show.Top.Position + Vector3.new(0, 0.2, 0)) * facing, 0.85)
	entity.Parent = display
	local card = CardArt.part(id, finish, nil, false)
	card.Size = Vector3.new(2.2, 3.08, 0.12)
	card.CFrame = CFrame.new(pedestal.Show.Top.Position + Vector3.new(0, 8.6, 0)) * facing
	card.Parent = display
	CollectionService:AddTag(card, "DisplayCard")
	display.Parent = zones[zoneIndex].Folder
	pedestal.part = display

	local r = Cards.Rarities[Cards.ById[id].Rarity]
	Nameplate.attach(entity.PrimaryPart, id, finish, nil, Vector3.new(0, 12.5, 0))
	local prompt = MapBuilder.prompt(entity.PrimaryPart, "Steal", Cards.DisplayName(id, finish), Config.StealHoldTime, 11)
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
	if (root.Position - pedestal.Stand.Position).Magnitude > 16 then
		return
	end
	local card = pedestal.card
	pedestal.card = nil
	Showcase.style(pedestal.Show, nil)
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
local frozenUntil = 0

function ZoneService.FreezeGuards(seconds: number)
	frozenUntil = math.max(frozenUntil, os.clock()) + seconds
	workspace:SetAttribute("GuardsFrozenUntil", workspace:GetServerTimeNow() + (frozenUntil - os.clock()))
end

local function makeGuardian(zoneIndex: number)
	local z = zones[zoneIndex]
	local zone = Config.Zones[zoneIndex]
	local home = z.GuardianHome * CFrame.Angles(0, math.pi, 0) -- regarde vers l'entrée
	local body = GuardModel.new(zone.Guardian, zone.Main:Lerp(Color3.fromRGB(40, 60, 120), 0.5), zone.Accent, z.Folder)
	local nameLabel, tag = MapBuilder.billboard(body.Head, UDim2.fromOffset(240, 36), Vector3.new(0, 3.4, 0), zone.Guardian:upper(), zone.Accent, 120)
	tag.Name = "NameTag"

	local g = {
		state = "idle",
		target = nil :: Player?,
		position = home.Position,
		alertAt = 0,
		chased = 0, -- distance parcourue pendant la poursuite (le fait accélérer)
		passedDoor = false,
		phase = 0,
		dirty = true,
	}
	-- porte de la boutique (côté route) : le gardien passe par là pour sortir et rentrer
	local door = z.ShopAt(0, 0, -6).Position

	local function baseSpeed(): number
		return Config.GuardianSpeedFor(zone) * Hub.Events.GuardianSpeedFactor()
	end

	-- les cartes rares sont mieux gardées : le gardien court plus vite
	local function rarityBonus(): number
		local target = g.target
		local c = target and carrying[target]
		if not c then
			return 0
		end
		return Config.RarityGuardBonus[Cards.ById[c.Id].Rarity] or 0
	end

	local function chaseSpeed(): number
		local ramp = math.min(g.chased * Config.GuardianRampPerStud, Config.GuardianRampMax)
		return baseSpeed() * (1 + ramp + rarityBonus())
	end

	local function insideShop(pos: Vector3): boolean
		local p = z.ShopCFrame:PointToObjectSpace(pos)
		return p.Z < 0 and p.Z > -56 and math.abs(p.X) < 35
	end

	local function setTag(text: string, color: Color3)
		nameLabel.Text = text
		nameLabel.TextColor3 = color
	end

	function g.alert(player: Player)
		g.state = "alert"
		g.target = player
		g.chased = 0
		-- temps de réaction exprimé en distance : même difficulté dans toutes les zones
		g.alertAt = os.clock() + Config.GuardianReaction / baseSpeed()
		setTag("!!!", Color3.fromRGB(255, 60, 90))
	end

	local function giveUp()
		g.state = "return"
		g.target = nil
		g.passedDoor = false
		setTag(zone.Guardian:upper(), zone.Accent)
	end

	local function moveToward(goal: Vector3, step: number): number
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

	local wasFrozen = false
	function g.update(dt: number)
		local frozen = os.clock() < frozenUntil
		if frozen ~= wasFrozen then
			wasFrozen = frozen
			g.dirty = true
			if frozen then
				setTag("FROZEN", Color3.fromRGB(150, 220, 255))
			elseif g.state == "chase" then
				setTag(zone.Guardian:upper() .. "!", Color3.fromRGB(255, 60, 90))
			else
				setTag(zone.Guardian:upper(), zone.Accent)
			end
		end

		local moving = false
		if g.state == "alert" then
			if os.clock() >= g.alertAt and not frozen then
				g.state = "chase"
				setTag(zone.Guardian:upper() .. "!", Color3.fromRGB(255, 60, 90))
			end
		elseif g.state == "chase" then
			local target = g.target
			local c = target and carrying[target]
			local root = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			-- le gardien abandonne si la cible n'a plus la carte ou est sortie de la zone
			local lost = not target or not target.Parent or not c or c.Zone ~= zoneIndex or not root
			if lost or root.Position.Z < z.GateZ - 8 or MapBuilder.InHub(root.Position) then
				giveUp()
			elseif not frozen then
				local goal = root.Position
				if insideShop(g.position) and not insideShop(goal) then
					goal = door
				end
				local step = chaseSpeed() * dt
				moveToward(goal, step)
				g.chased += step
				moving = true
				local flatDist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(g.position.X, 0, g.position.Z)).Magnitude
				if flatDist < Config.GuardianCatchRadius then
					local away = (root.Position - g.position) * Vector3.new(1, 0, 1)
					away = away.Magnitude > 0 and away.Unit or Vector3.new(0, 0, -1)
					Remotes.Knockback:FireClient(target, away * 70 + Vector3.new(0, 45, 0))
					-- attrapé par le gardien : la carte retourne à la boutique (elle disparaît)
					local lostCard = carrying[target]
					setCarry(target, nil)
					Remotes.Notify:FireClient(target, zone.Guardian .. " took the card back!", "error")
					if lostCard then
						Remotes.Announce:FireClient(target, "CAUGHT!", Cards.DisplayName(lostCard.Id, lostCard.F) .. " went back to the shop", "steal")
					end
					giveUp()
				end
			end
		elseif g.state == "return" and not frozen then
			-- d'abord la porte de la boutique, ensuite sa place
			if not g.passedDoor and insideShop(g.position) then
				g.passedDoor = true
			end
			local goal = g.passedDoor and home.Position or door
			local left = moveToward(goal, baseSpeed() * 1.2 * dt)
			moving = true
			if left <= 0.1 then
				if g.passedDoor then
					g.state = "idle"
					g.position = home.Position
					g.dirty = true
				else
					g.passedDoor = true
				end
			end
		end

		-- on ne redessine que si le gardien bouge (économise le réseau)
		if not moving and not g.dirty then
			return
		end
		g.dirty = false
		local facing
		if moving then
			local goalPos = g.target and g.target.Character and g.target.Character:FindFirstChild("HumanoidRootPart")
			local dir = goalPos and ((goalPos :: BasePart).Position - g.position) or (home.Position - g.position)
			if g.state == "return" and not g.passedDoor then
				dir = door - g.position
			end
			dir = Vector3.new(dir.X, 0, dir.Z)
			facing = dir.Magnitude > 0.1 and dir.Unit or home.LookVector
			g.phase += dt * (8 + chaseSpeed() * 0.12)
		else
			facing = home.LookVector
		end
		local floor = insideShop(g.position) and 1 or 0.2
		local at = g.position + Vector3.new(0, floor, 0)
		body:Place(CFrame.lookAt(at, at + facing), g.phase, moving, frozen)
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
						if zoneIndex > data.BestZone then
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
