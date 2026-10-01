-- Progression du joueur : checkpoints, coins, XP / niveaux, rebirths,
-- récompense quotidienne, trails, skips, et toutes les actions envoyées par l'interface.

local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local CharacterService = require(script.Parent.CharacterService)

local ProgressionService = {}

local TOTAL = Config.TotalStages()
local checkpoints: { [number]: BasePart } = {}
local deaths: { [Player]: { stage: number, count: number } } = {}
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

local function multiplier(player: Player, data): number
	return Config.Multiplier(data.Rebirths, MonetizationService.Owns(player, "DoubleCoins"))
end

local function dailyStatus(data)
	local now = os.time()
	local elapsed = now - (data.LastDaily or 0)
	local ready = elapsed >= Config.DailyCooldown
	local streak = data.DailyStreak or 0
	if elapsed > Config.DailyStreakBreak then
		streak = 0
	end
	local nextStreak = streak + 1
	local reward = Config.DailyRewards[math.min(nextStreak, #Config.DailyRewards)]
	return ready, math.max(0, Config.DailyCooldown - elapsed), nextStreak, reward
end

local function updateLeaderstats(player: Player, data)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		return
	end
	(stats:FindFirstChild("Stage") :: IntValue).Value = data.Stage;
	(stats:FindFirstChild("Level") :: IntValue).Value = data.Level;
	(stats:FindFirstChild("Rebirths") :: IntValue).Value = data.Rebirths
	player:SetAttribute("Level", data.Level)
	player:SetAttribute("Rebirths", data.Rebirths)
end

function ProgressionService.SendState(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	updateLeaderstats(player, data)
	local ready, wait, nextStreak, reward = dailyStatus(data)
	Remotes.State:FireClient(player, {
		Stage = data.Stage,
		BestStage = data.BestStage,
		Total = TOTAL,
		Coins = data.Coins,
		XP = data.XP,
		XPNext = Config.XPToNext(data.Level),
		Level = data.Level,
		Rebirths = data.Rebirths,
		Wins = data.Wins,
		Multiplier = multiplier(player, data),
		NextMultiplier = Config.Multiplier(data.Rebirths + 1, MonetizationService.Owns(player, "DoubleCoins")),
		CanRebirth = data.BestStage >= TOTAL,
		Trails = data.Trails,
		EquippedTrail = data.EquippedTrail,
		Passes = MonetizationService.OwnedList(player),
		DailyReady = ready,
		DailyWait = wait,
		DailyStreak = nextStreak,
		DailyReward = reward,
	})
end

local function teleportToStage(player: Player, stage: number)
	local character = player.Character
	local pad = checkpoints[stage]
	if not character or not pad then
		return
	end
	if stage == 0 then
		character:PivotTo(pad.CFrame * CFrame.new(0, 4, -3))
	else
		character:PivotTo(pad.CFrame * CFrame.new(0, 4, 0))
	end
end

--------------------------------------------------------------------
-- Récompenses
--------------------------------------------------------------------
local function addXP(player: Player, data, amount: number)
	data.XP += amount
	local leveled = false
	while data.XP >= Config.XPToNext(data.Level) do
		data.XP -= Config.XPToNext(data.Level)
		data.Level += 1
		leveled = true
	end
	if leveled then
		Remotes.Celebrate:FireClient(player, "Level", data.Level)
		CharacterService.RefreshOverhead(player)
		if data.Level >= 10 then
			awardBadge(player, "Level10")
		end
	end
end

local function reward(player: Player, data, coins: number, xp: number)
	local m = multiplier(player, data)
	local c = math.floor(coins * m)
	local x = math.floor(xp * m)
	data.Coins += c
	addXP(player, data, x)
	return c, x
end

local function onFinish(player: Player, data)
	data.Wins += 1
	local c = reward(player, data, Config.WinCoins, Config.WinXP)
	Remotes.Celebrate:FireClient(player, "Finish", c)
	awardBadge(player, "Finish")
end

-- Le joueur atteint un nouveau checkpoint (en jouant ou via un skip)
local function setStage(player: Player, data, stage: number, earned: boolean)
	stage = math.clamp(stage, 0, TOTAL)
	if stage <= data.Stage then
		return
	end
	local wasFinished = data.BestStage >= TOTAL
	data.Stage = stage

	if stage > data.BestStage then
		if earned then
			local c, x = reward(player, data, Config.CoinsForStage(stage), Config.XPForStage(stage))
			notify(player, ("+%d coins   +%d XP"):format(c, x), "reward")
		end
		data.BestStage = stage
	end

	if stage == Config.StagesPerWorld then
		awardBadge(player, "FirstWorld")
	end
	if stage == TOTAL and not wasFinished then
		onFinish(player, data)
	end

	deaths[player] = nil
	ProgressionService.SendState(player)
end

--------------------------------------------------------------------
-- Checkpoints
--------------------------------------------------------------------
local touchCooldown: { [Player]: number } = {}

local function onCheckpointTouched(pad: BasePart, hit: BasePart)
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local now = os.clock()
	if (touchCooldown[player] or 0) > now then
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end
	local stage = pad:GetAttribute("Stage") :: number
	-- on ne peut valider que le checkpoint suivant : impossible de sauter des stages
	if stage ~= data.Stage + 1 then
		return
	end
	touchCooldown[player] = now + 0.3
	setStage(player, data, stage, true)
end

--------------------------------------------------------------------
-- Actions envoyées par l'interface
--------------------------------------------------------------------
local actions = {}

function actions.Skip(player: Player)
	local data = DataService.Get(player)
	if data and data.Stage < TOTAL then
		MonetizationService.PromptProduct(player, "SkipStage")
	end
end

function actions.Skip5(player: Player)
	local data = DataService.Get(player)
	if data and data.Stage < TOTAL then
		MonetizationService.PromptProduct(player, "Skip5")
	end
end

function actions.BuyPass(player: Player, key: any)
	if type(key) == "string" and Config.GamePasses[key] then
		MonetizationService.PromptPass(player, key)
	end
end

function actions.BuyProduct(player: Player, key: any)
	if type(key) ~= "string" then
		return
	end
	local product = Config.Products[key]
	if product and (product.Kind == "Donate" or product.Kind == "Coins") then
		MonetizationService.PromptProduct(player, key)
	end
end

-- l'interface demande l'état complet quand elle démarre
function actions.Sync(player: Player)
	ProgressionService.SendState(player)
end

function actions.Respawn(player: Player)
	player:LoadCharacter()
end

function actions.Rebirth(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	if data.BestStage < TOTAL then
		notify(player, "Finish the obby to rebirth!", "error")
		return
	end
	data.Rebirths += 1
	data.Stage = 0
	data.BestStage = 0
	deaths[player] = nil
	Remotes.Celebrate:FireClient(player, "Rebirth", data.Rebirths)
	awardBadge(player, "FirstRebirth")
	ProgressionService.SendState(player)
	player:LoadCharacter()
	task.spawn(DataService.Save, player)
end

function actions.ClaimDaily(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local ready, _, nextStreak, amount = dailyStatus(data)
	if not ready then
		notify(player, "Daily reward not ready yet", "error")
		return
	end
	data.DailyStreak = nextStreak
	data.LastDaily = os.time()
	data.Coins += amount
	notify(player, ("Day %d reward: +%d coins"):format(nextStreak, amount), "reward")
	ProgressionService.SendState(player)
end

function actions.BuyTrail(player: Player, id: any)
	local data = DataService.Get(player)
	if not data or type(id) ~= "string" then
		return
	end
	local trail = Config.GetTrail(id)
	if not trail or table.find(data.Trails, id) then
		return
	end
	if data.Level < trail.Level then
		notify(player, ("Reach level %d to unlock %s"):format(trail.Level, trail.Name), "error")
		return
	end
	if data.Rebirths < trail.Rebirths then
		notify(player, ("You need %d rebirth(s) for %s"):format(trail.Rebirths, trail.Name), "error")
		return
	end
	if data.Coins < trail.Price then
		notify(player, "Not enough coins", "error")
		return
	end
	data.Coins -= trail.Price
	table.insert(data.Trails, id)
	data.EquippedTrail = id
	CharacterService.RefreshTrail(player)
	notify(player, trail.Name .. " trail unlocked!", "reward")
	ProgressionService.SendState(player)
end

function actions.EquipTrail(player: Player, id: any)
	local data = DataService.Get(player)
	if not data or type(id) ~= "string" then
		return
	end
	if id ~= "None" and not CharacterService.CanUseTrail(player, id) then
		local pass = CharacterService.PassTrails[id]
		if pass then
			MonetizationService.PromptPass(player, pass.Pass)
		end
		return
	end
	data.EquippedTrail = id
	CharacterService.RefreshTrail(player)
	ProgressionService.SendState(player)
end

local function onAction(player: Player, action: any, arg: any)
	if type(action) ~= "string" or not actions[action] then
		return
	end
	local now = os.clock()
	if (lastAction[player] or 0) > now then
		return
	end
	lastAction[player] = now + 0.25
	actions[action](player, arg)
end

--------------------------------------------------------------------
-- Achats Robux livrés par MonetizationService
--------------------------------------------------------------------
local function handleSkip(player: Player, product): boolean
	local data = DataService.Get(player)
	if not data then
		return false
	end
	local target = math.min(data.Stage + product.Amount, TOTAL)
	setStage(player, data, target, false)
	teleportToStage(player, data.Stage)
	notify(player, ("Skipped to stage %d!"):format(data.Stage), "reward")
	return true
end

local function handleCoins(player: Player, product): boolean
	local data = DataService.Get(player)
	if not data then
		return false
	end
	data.Coins += product.Amount
	notify(player, ("+%d coins. Thanks for the support!"):format(product.Amount), "reward")
	ProgressionService.SendState(player)
	return true
end

local function handleDonate(player: Player, product): boolean
	local data = DataService.Get(player)
	if not data then
		return false
	end
	data.Donated += product.Amount
	notify(player, ("Thank you for donating %d Robux!"):format(product.Amount), "reward")
	Remotes.Celebrate:FireClient(player, "Donate", product.Amount)
	return true
end

--------------------------------------------------------------------
-- Joueurs
--------------------------------------------------------------------
local function onCharacterAdded(player: Player, character: Model)
	local data = DataService.WaitFor(player)
	if not data or character.Parent == nil then
		return
	end
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid then
		return
	end

	CharacterService.Apply(player)
	if data.Stage > 0 then
		task.defer(teleportToStage, player, data.Stage)
	end

	humanoid.Died:Connect(function()
		local d = DataService.Get(player)
		if not d then
			return
		end
		local entry = deaths[player]
		if not entry or entry.stage ~= d.Stage then
			entry = { stage = d.Stage, count = 0 }
			deaths[player] = entry
		end
		entry.count += 1
		if entry.count % Config.DeathsBeforeSkipOffer == 0 and d.Stage < TOTAL and Config.Products.SkipStage.Id ~= 0 then
			Remotes.StuckOffer:FireClient(player, d.Stage + 1)
		end
	end)
end

local function onPlayerAdded(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in { "Stage", "Level", "Rebirths" } do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = stats
	end
	stats.Parent = player

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		-- personnage déjà là (le script a démarré après le joueur)
		task.spawn(onCharacterAdded, player, player.Character)
	end

	MonetizationService.LoadPlayer(player)
	DataService.Load(player)
	local data = DataService.Get(player)
	if not data then
		return
	end

	awardBadge(player, "Welcome")
	ProgressionService.SendState(player)

	local ready = dailyStatus(data)
	if ready then
		task.delay(3, notify, player, "Your daily reward is ready!", "reward")
	end
end

function ProgressionService.Start(cps: { [number]: BasePart })
	checkpoints = cps
	for _, pad in checkpoints do
		pad.Touched:Connect(function(hit)
			onCheckpointTouched(pad, hit)
		end)
	end

	MonetizationService.RegisterHandler("Skip", handleSkip)
	MonetizationService.RegisterHandler("Coins", handleCoins)
	MonetizationService.RegisterHandler("Donate", handleDonate)

	MonetizationService.PassChanged:Connect(function(player, key)
		CharacterService.Apply(player)
		notify(player, Config.GamePasses[key].Name .. " unlocked. Enjoy!", "reward")
		ProgressionService.SendState(player)
	end)

	Remotes.Action.OnServerEvent:Connect(onAction)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		deaths[player] = nil
		lastAction[player] = nil
		touchCooldown[player] = nil
	end)

	-- le compte à rebours de la récompense quotidienne se met à jour tout seul
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do
				ProgressionService.SendState(player)
			end
		end
	end)
end

return ProgressionService
