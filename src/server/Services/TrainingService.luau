--[[
	Tapis de course de la base.
	- Chaque base a son tapis devant l'entrée. Seul le propriétaire peut l'utiliser.
	- E pour monter dessus : le personnage court tout seul, plus vite selon le niveau.
	- Le tapis s'améliore par niveaux (cash ou Robux) : plus de Speed par seconde,
	  et son look change (couleur, cristaux) tous les 5 niveaux.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local Hub = require(script.Parent.Parent.Hub)

local TrainingService = {}

local TICK = 0.25
local bases = {}
local training: { [Player]: any } = {} -- joueur -> base
local holding: { [Player]: boolean } = {}

function TrainingService.Multiplier(player: Player): number
	local data = DataService.Get(player)
	local m = 1 + (data and data.Rebirths or 0) * Config.RebirthSpeedBonus
	if MonetizationService.Owns(player, "DoubleSpeed") then
		m *= 2
	end
	return m
end

function TrainingService.Level(player: Player): number
	local data = DataService.Get(player)
	return data and math.clamp(data.Treadmill, 1, Config.TreadmillMaxLevel) or 1
end

-- Speed par seconde sur le tapis (multiplicateurs compris)
function TrainingService.BestRate(player: Player): number
	return Config.TreadmillRate(TrainingService.Level(player)) * TrainingService.Multiplier(player)
end

function TrainingService.AddSpeed(player: Player, amount: number)
	local data = DataService.Get(player)
	if not data then
		return
	end
	data.Speed += amount
	player:SetAttribute("Speed", data.Speed)
	Hub.Combat.UpdateSpeed(player)
end

-- Met à jour le look du tapis et son panneau
function TrainingService.Render(base, player: Player?)
	local t = base.Treadmill
	local level = player and TrainingService.Level(player) or 1
	local tier, tierIndex = Config.TreadmillTier(level)
	for n, parts in t.Tiers do
		for _, p in parts do
			p.Transparency = (n == tierIndex) and (p:GetAttribute("BaseT") or 0) or 1
		end
	end
	t.Glow.Color = tier.Color
	t.Screen.Color = tier.Color:Lerp(Color3.new(1, 1, 1), 0.3)
	local text
	if not player then
		text = "TREADMILL"
	elseif level >= Config.TreadmillMaxLevel then
		text = ("LEVEL %d (MAX)\n+%s SPEED/S"):format(level, Format.short(TrainingService.BestRate(player)))
	else
		text = ("LEVEL %d > %d\n%s"):format(level, level + 1, Format.cash(Config.TreadmillCost(level)))
	end
	for _, label in t.SignLabels do
		label.Text = text
	end
end

function TrainingService.Upgrade(player: Player, free: boolean?): boolean
	local data = DataService.Get(player)
	if not data then
		return false
	end
	local level = TrainingService.Level(player)
	if level >= Config.TreadmillMaxLevel then
		Remotes.Notify:FireClient(player, "Your treadmill is already max level", "error")
		return false
	end
	if not free then
		local cost = Config.TreadmillCost(level)
		if data.Cash < cost then
			Remotes.Notify:FireClient(player, "You need " .. Format.cash(cost), "error")
			return false
		end
		data.Cash -= cost
		player:SetAttribute("Cash", data.Cash)
	end
	data.Treadmill = level + 1
	local base = Hub.Gallery.Get(player)
	if base then
		TrainingService.Render(base, player)
	end
	Remotes.Notify:FireClient(player, ("Treadmill level %d! +%s Speed/s"):format(data.Treadmill, Format.short(TrainingService.BestRate(player))), "reward")
	Hub.Players.SendState(player)
	return true
end

function TrainingService.Stop(player: Player)
	if training[player] then
		training[player] = nil
		holding[player] = nil
		player:SetAttribute("Training", nil)
	end
end

function TrainingService.StartOn(player: Player)
	local base = Hub.Gallery.Get(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not base or not root or Hub.Zones.IsCarrying(player) then
		return
	end
	if (root.Position - base.Treadmill.Belt.Position).Magnitude > 18 then
		return
	end
	training[player] = base
	holding[player] = false
	player:SetAttribute("Training", base.Index)
	player.Character:PivotTo(base.Treadmill.Spot)
end

function TrainingService.SetHolding(player: Player, value: any)
	if training[player] then
		holding[player] = value == true
	end
end

function TrainingService.Start(builtBases)
	bases = builtBases
	for _, base in bases do
		TrainingService.Render(base, nil)
	end

	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(TICK)
			-- on crédite le temps réellement écoulé (task.wait n'est jamais pile à l'heure)
			local now = os.clock()
			local dt = math.min(now - last, 1)
			last = now
			for player, base in training do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if not player.Parent or not root or not humanoid or humanoid.Health <= 0 or (root.Position - base.Treadmill.Spot.Position).Magnitude > 6 then
					TrainingService.Stop(player)
				else
					-- on court tout seul dès qu'on est sur le tapis
					TrainingService.AddSpeed(player, TrainingService.BestRate(player) * dt)
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		training[player] = nil
		holding[player] = nil
	end)
end

return TrainingService
