-- Arrivée / départ des joueurs, multiplicateurs, rebirth, récompense quotidienne,
-- index, achats Robux livrés, panneau admin, actions de l'interface.

local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Cards = require(ReplicatedStorage.Shared.Cards)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local Hub = require(script.Parent.Parent.Hub)

local PlayerService = {}

local lastAction: { [Player]: number } = {}

--------------------------------------------------------------------
-- Utilitaires
--------------------------------------------------------------------
local function notify(player: Player, text: string, kind: string?)
	Remotes.Notify:FireClient(player, text, kind or "info")
end

local function awardBadge(player: Player, key: string)
	local id = Config.Badges[key]
	if not id or id == 0 then
		return
	end
	task.spawn(function()
		local ok, has = pcall(BadgeService.UserHasBadgeAsync, BadgeService, player.UserId, id)
		if ok and not has then
			pcall(BadgeService.AwardBadge, BadgeService, player.UserId, id)
		end
	end)
end

local function isAdmin(player: Player): boolean
	if table.find(Config.Admins, player.UserId) then
		return true
	end
	return game.CreatorType == Enum.CreatorType.User and game.CreatorId == player.UserId
end

local function indexCount(data): number
	local n = 0
	for _ in data.Index do
		n += 1
	end
	return n
end

function PlayerService.CashMultiplier(player: Player): number
	local data = DataService.Get(player)
	if not data then
		return 1
	end
	local m = 1 + data.Rebirths * Config.RebirthCashBonus
	if MonetizationService.Owns(player, "VIP") then
		m *= Config.VipCashMultiplier
	end
	if MonetizationService.Owns(player, "DoubleCash") then
		m *= 2
	end
	m *= 1 + indexCount(data) * Config.IndexBonusPerCard
	return m
end

local function dailyStatus(data)
	local elapsed = os.time() - (data.LastDaily or 0)
	local streak = data.DailyStreak or 0
	if elapsed > Config.DailyStreakBreak then
		streak = 0
	end
	return elapsed >= Config.DailyCooldown, math.max(0, Config.DailyCooldown - elapsed), streak + 1
end

local function dailyReward(player: Player, day: number): number
	local i = math.min(day, #Config.DailyMinutes)
	return math.max(Config.DailyMinimum[i], math.floor(Hub.Gallery.Income(player) * 60 * Config.DailyMinutes[i]))
end

--------------------------------------------------------------------
-- État envoyé à l'interface
--------------------------------------------------------------------
function PlayerService.SendState(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local index = {}
	for id in data.Index do
		table.insert(index, id)
	end
	local ready, wait, day = dailyStatus(data)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		(stats:FindFirstChild("Rebirths") :: IntValue).Value = data.Rebirths
	end
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("VIP", MonetizationService.Owns(player, "VIP"))
	player:SetAttribute("Speed", data.Speed)
	player:SetAttribute("Cash", data.Cash)
	Remotes.State:FireClient(player, {
		Now = os.time(),
		Rebirths = data.Rebirths,
		RebirthCost = Config.RebirthCost(data.Rebirths),
		CashMultiplier = PlayerService.CashMultiplier(player),
		SpeedMultiplier = Hub.Training.Multiplier(player),
		Treadmill = data.Treadmill,
		BestZone = data.BestZone,
		Cases = Hub.Gallery.CaseCount(player),
		CardCount = #data.Cards,
		Raw = data.Raw,
		Grading = data.Grading,
		GradingSlots = Hub.Grading.SlotCount(player),
		Passes = MonetizationService.OwnedList(player),
		Index = index,
		Steals = data.Steals,
		DailyReady = ready,
		DailyWait = wait,
		DailyDay = day,
		DailyReward = dailyReward(player, day),
		IsAdmin = isAdmin(player),
	})
end

function PlayerService.OnCardGained(player: Player, id: string, finish: string, grade: number)
	local data = DataService.Get(player)
	if not data then
		return
	end
	data.Index[id] = true
	local card = Cards.ById[id]
	local order = Cards.Rarities[card.Rarity].Order
	if order >= Cards.Rarities.Legendary.Order then
		awardBadge(player, "FirstLegendary")
	end
	if grade == 10 then
		awardBadge(player, "GemMint")
		if order >= Cards.Rarities.Epic.Order then
			Remotes.Announce:FireAllClients("GEM MINT 10!", ("%s graded a perfect %s"):format(player.DisplayName, Cards.DisplayName(id, finish)), card.Rarity)
		end
	end
	PlayerService.SendState(player)
end

function PlayerService.OnSteal(player: Player, id: string, finish: string)
	awardBadge(player, "FirstSteal")
	local card = Cards.ById[id]
	if Cards.Rarities[card.Rarity].Order >= Cards.Rarities.Mythic.Order or finish == "DarkMatter" then
		Remotes.Announce:FireAllClients("HEIST!", ("%s escaped with %s"):format(player.DisplayName, Cards.DisplayName(id, finish)), card.Rarity)
	end
end

function PlayerService.OnNewZone(player: Player, zone: number)
	notify(player, "New shop unlocked: " .. Config.Zones[zone].Name, "reward")
	if zone == #Config.Zones then
		awardBadge(player, "LastZone")
	end
end

--------------------------------------------------------------------
-- Actions de l'interface
--------------------------------------------------------------------
local actions = {}

function actions.Sync(player: Player)
	PlayerService.SendState(player)
	Hub.Events.Broadcast(player)
end

function actions.SellCase(player: Player, case: any)
	if type(case) == "number" then
		Hub.Gallery.Sell(player, case)
		PlayerService.SendState(player)
	end
end

function actions.UnlockCase(player: Player)
	Hub.Gallery.UnlockCase(player)
	PlayerService.SendState(player)
end

function actions.Collect(player: Player, index: any)
	if type(index) == "number" then
		Hub.Grading.Collect(player, index)
		PlayerService.SendState(player)
	end
end

function actions.CollectAll(player: Player)
	Hub.Grading.CollectAll(player)
end

function actions.StartRaw(player: Player, index: any)
	if type(index) == "number" then
		Hub.Grading.StartRaw(player, index)
	end
end

function actions.SellRaw(player: Player, index: any)
	if type(index) == "number" then
		Hub.Grading.SellRaw(player, index)
	end
end

function actions.UnlockTreadmill(player: Player, index: any)
	if type(index) == "number" then
		Hub.Training.Unlock(player, index)
	end
end

function actions.Rebirth(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local cost = Config.RebirthCost(data.Rebirths)
	if data.Cash < cost then
		notify(player, "You need " .. Format.cash(cost) .. " to rebirth", "error")
		return
	end
	if Hub.Zones.IsCarrying(player) then
		return
	end
	data.Rebirths += 1
	data.Cash = 0
	data.Speed = 0
	data.Treadmill = 1
	data.Raw = {}
	data.Grading = {}
	Hub.Gallery.ClearCards(player)
	player:SetAttribute("Cash", 0)
	player:SetAttribute("Speed", 0)
	Hub.Combat.UpdateSpeed(player)
	Remotes.Announce:FireAllClients("REBIRTH " .. data.Rebirths, player.DisplayName .. " just rebirthed!", "rebirth")
	awardBadge(player, "FirstRebirth")
	PlayerService.SendState(player)
	actions.Home(player)
	task.spawn(DataService.Save, player)
end

function actions.ClaimDaily(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local ready, _, day = dailyStatus(data)
	if not ready then
		notify(player, "Daily reward not ready yet", "error")
		return
	end
	local amount = dailyReward(player, day)
	data.DailyStreak = day
	data.LastDaily = os.time()
	data.Cash += amount
	player:SetAttribute("Cash", data.Cash)
	notify(player, ("Day %d: +%s"):format(day, Format.cash(amount)), "cash")
	PlayerService.SendState(player)
end

function actions.BuyPass(player: Player, key: any)
	if type(key) == "string" then
		MonetizationService.PromptPass(player, key)
	end
end

function actions.BuyProduct(player: Player, key: any)
	if type(key) == "string" and Config.Products[key] then
		MonetizationService.PromptProduct(player, key)
	end
end

local function teleport(player: Player, cf: CFrame)
	if Hub.Zones.IsCarrying(player) then
		notify(player, "Not while carrying a card!", "error")
		return
	end
	if player.Character then
		player.Character:PivotTo(cf)
	end
end

function actions.Home(player: Player)
	local g = Hub.Gallery.Get(player)
	if g then
		teleport(player, g.Spawn)
	end
end

function actions.GoLab(player: Player)
	teleport(player, Hub.Map.Lab.Spawn)
end

function actions.GoTraining(player: Player)
	teleport(player, CFrame.new(40, 4, -35))
end

local function onAction(player: Player, action: any, a: any, b: any)
	if type(action) ~= "string" or not actions[action] then
		return
	end
	local t = os.clock()
	if (lastAction[player] or 0) > t then
		return
	end
	lastAction[player] = t + 0.15
	actions[action](player, a, b)
end

--------------------------------------------------------------------
-- Panneau admin
--------------------------------------------------------------------
local function onAdmin(player: Player, command: any, a: any)
	if not isAdmin(player) or type(command) ~= "string" then
		return
	end
	local data = DataService.Get(player)
	if command == "Event" and type(a) == "string" then
		Hub.Events.StartEvent(a)
	elseif command == "Luck" then
		Hub.Events.AddServerLuck(Config.ServerLuckDuration, player.DisplayName)
	elseif command == "Restock" then
		Hub.Zones.RestockAll()
	elseif command == "Cash" and type(a) == "number" and data then
		data.Cash += math.clamp(a, 0, 1e15)
		player:SetAttribute("Cash", data.Cash)
	elseif command == "Speed" and type(a) == "number" and data then
		Hub.Training.AddSpeed(player, math.clamp(a, 0, 1e15))
	elseif command == "Card" and type(a) == "string" and Cards.Rarities[a] then
		Hub.Grading.Deliver(player, Hub.Loot.RollCard(a), Hub.Loot.RollFinish())
	end
	PlayerService.SendState(player)
end

--------------------------------------------------------------------
-- Achats Robux
--------------------------------------------------------------------
local function handleSpeed(player: Player, product): boolean
	local amount = math.max(product.Minimum, math.floor(Hub.Training.BestRate(player) * 60 * product.Minutes))
	Hub.Training.AddSpeed(player, amount)
	notify(player, "+" .. Format.short(amount) .. " Speed!", "reward")
	PlayerService.SendState(player)
	return true
end

local function handleInstantGrade(player: Player): boolean
	return Hub.Grading.FinishAll(player)
end

local function handleServerLuck(player: Player): boolean
	Hub.Events.AddServerLuck(Config.ServerLuckDuration, player.DisplayName)
	return true
end

local function handlePack(player: Player): boolean
	local rarity = Hub.Loot.RollRarity(Config.PackWeights, 1)
	Hub.Grading.Deliver(player, Hub.Loot.RollCard(rarity), Hub.Loot.RollFinish())
	return true
end

local function handleCash(player: Player, product): boolean
	local data = DataService.Get(player)
	if not data then
		return false
	end
	local amount = math.max(product.Minimum, math.floor(Hub.Gallery.Income(player) * 60 * product.Minutes))
	data.Cash += amount
	player:SetAttribute("Cash", data.Cash)
	notify(player, "+" .. Format.cash(amount) .. ". Thanks for the support!", "cash")
	return true
end

--------------------------------------------------------------------
-- Joueurs
--------------------------------------------------------------------
local function onCharacterAdded(player: Player, character: Model)
	local data = DataService.WaitFor(player)
	if not data or not character.Parent then
		return
	end
	character:WaitForChild("Humanoid", 10)
	character:WaitForChild("HumanoidRootPart", 10)
	local g = Hub.Gallery.Get(player)
	if g then
		task.defer(function()
			if character.Parent then
				character:PivotTo(g.Spawn)
			end
		end)
	end
	Hub.Combat.OnSpawn(player)
end

local function onPlayerAdded(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in { "Cash", "Speed" } do
		local v = Instance.new("StringValue")
		v.Name = name
		v.Parent = stats
	end
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = stats
	stats.Parent = player

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end

	MonetizationService.LoadPlayer(player)
	DataService.Load(player)
	if not DataService.Get(player) then
		return
	end
	if not Hub.Gallery.Assign(player) then
		player:Kick("This server is full, please join another one.")
		return
	end

	awardBadge(player, "Welcome")
	PlayerService.SendState(player)
	Hub.Events.Broadcast(player)
	if dailyStatus(DataService.Get(player)) then
		task.delay(4, notify, player, "Your daily reward is ready!", "reward")
	end
end

local function onPlayerRemoving(player: Player)
	Hub.Gallery.Release(player)
	lastAction[player] = nil
end

function PlayerService.Start()
	MonetizationService.RegisterHandler("Speed", handleSpeed)
	MonetizationService.RegisterHandler("InstantGrade", handleInstantGrade)
	MonetizationService.RegisterHandler("ServerLuck", handleServerLuck)
	MonetizationService.RegisterHandler("Pack", handlePack)
	MonetizationService.RegisterHandler("Cash", handleCash)

	MonetizationService.PassChanged:Connect(function(player, key)
		notify(player, Config.GamePasses[key].Name .. " unlocked!", "reward")
		Hub.Gallery.Render(player)
		PlayerService.SendState(player)
	end)

	Remotes.Action.OnServerEvent:Connect(onAction)
	Remotes.Admin.OnServerEvent:Connect(onAdmin)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	task.spawn(function()
		local tick = 0
		while true do
			task.wait(1)
			tick += 1
			for _, player in Players:GetPlayers() do
				local data = DataService.Get(player)
				local stats = player:FindFirstChild("leaderstats")
				if data and stats then
					(stats:FindFirstChild("Cash") :: StringValue).Value = Format.cash(data.Cash);
					(stats:FindFirstChild("Speed") :: StringValue).Value = Format.short(data.Speed)
				end
				if tick % 60 == 0 then
					PlayerService.SendState(player)
				end
			end
		end
	end)
end

return PlayerService
