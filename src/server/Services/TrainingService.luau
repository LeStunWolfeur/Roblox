--[[
	Tapis de course de la base.
	- Chaque base a son tapis devant l'entrée. Seul le propriétaire peut l'utiliser.
	- E pour monter dessus : le personnage court tout seul, plus vite selon le niveau.
	  On peut rester AFK dessus : la Speed continue de monter.
	- 9 niveaux (cash ou Robux). Chaque niveau a son propre modèle 3D.
	- Un gros bouton à côté du tapis permet d'améliorer en cliquant, le prix est affiché dessus.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local TreadmillModels = require(script.Parent.Parent.World.TreadmillModels)
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
	-- traînée équipée et cartes pouvoir
	m *= Hub.Powers.TrailMult(player) * (1 + Hub.Powers.Bonus(player, "Training"))
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

local GREEN = { Color3.fromRGB(140, 255, 100), Color3.fromRGB(30, 170, 60), Color3.fromRGB(10, 60, 20), Color3.fromRGB(80, 255, 120) }
local GREY = { Color3.fromRGB(150, 156, 175), Color3.fromRGB(80, 86, 104), Color3.fromRGB(30, 32, 42), Color3.fromRGB(120, 126, 145) }
local GOLD = { Color3.fromRGB(255, 240, 140), Color3.fromRGB(230, 150, 20), Color3.fromRGB(90, 45, 0), Color3.fromRGB(255, 200, 40) }

local function paint(t, pal)
	local ui = t.Screen
	ui.PriceGradient.Color = ColorSequence.new(pal[1], pal[2])
	ui.PriceStroke.Color = pal[3]
	t.Button.Color = pal[4]
	t.ButtonRing.Color = pal[4]
end

-- Met à jour l'écran de la borne : prochain niveau, gain, prix (vert si on peut payer)
local function renderTag(base, player: Player?)
	local t = base.Treadmill
	local ui = t.Screen
	if not player then
		ui.Level.Text = "LV -"
		ui.Tier.Text = "FREE BASE"
		ui.Tier.TextColor3 = Color3.fromRGB(200, 205, 220)
		ui.Gain.Text = "Waiting for a player"
		ui.Price.Text = "---"
		paint(t, GREY)
		return
	end
	local level = TrainingService.Level(player)
	ui.Level.Text = "LV " .. level
	if level >= Config.TreadmillMaxLevel then
		local tier = Config.TreadmillTier(level)
		ui.Tier.Text = tier.Name:upper()
		ui.Tier.TextColor3 = tier.Color or Color3.fromRGB(255, 215, 60)
		ui.Gain.Text = "+" .. Format.short(TrainingService.BestRate(player)) .. " SPEED/S"
		ui.Price.Text = "MAX LEVEL"
		paint(t, GOLD)
		return
	end
	local cost = Config.TreadmillCost(level)
	local nextTier = Config.TreadmillTier(level + 1)
	ui.Tier.Text = nextTier.Name:upper()
	ui.Tier.TextColor3 = nextTier.Color or Color3.new(1, 1, 1)
	ui.Gain.Text = ("+%s SPEED/S  (now +%s)"):format(
		Format.short(Config.TreadmillRate(level + 1) * TrainingService.Multiplier(player)),
		Format.short(TrainingService.BestRate(player))
	)
	ui.Price.Text = Format.cash(cost)
	local data = DataService.Get(player)
	paint(t, (data and data.Cash >= cost) and GREEN or GREY)
end

-- Reconstruit le modèle du tapis quand le niveau change, et met à jour le bouton
function TrainingService.Render(base, player: Player?)
	local t = base.Treadmill
	t.Owner = player
	local level = player and TrainingService.Level(player) or 1
	if t.ModelLevel ~= level then
		if t.Model then
			t.Model:Destroy()
		end
		t.Model = TreadmillModels.build(level, t.ModelCFrame, t.Folder)
		t.ModelLevel = level
	end
	renderTag(base, player)
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

-- petit enfoncement du bouton quand on clique
local function press(button: BasePart)
	if button:GetAttribute("Pressing") then
		return
	end
	button:SetAttribute("Pressing", true)
	local cf = button.CFrame
	button.CFrame = cf * CFrame.new(-0.35, 0, 0)
	task.delay(0.15, function()
		button.CFrame = cf
		button:SetAttribute("Pressing", nil)
	end)
end

function TrainingService.Start(builtBases)
	bases = builtBases
	for _, base in bases do
		TrainingService.Render(base, nil)
		for _, target in { base.Treadmill.Button, base.Treadmill.ScreenPart } do
			local click = target and target:FindFirstChildOfClass("ClickDetector")
			if click then
				click.MouseClick:Connect(function(player: Player)
					if base.Treadmill.Owner ~= player then
						Remotes.Notify:FireClient(player, "This is not your treadmill", "error")
						return
					end
					press(base.Treadmill.Button)
					TrainingService.Upgrade(player)
				end)
			end
		end
	end

	-- le prix de la borne passe au vert dès qu'on a assez d'argent
	task.spawn(function()
		while true do
			task.wait(1)
			for _, base in bases do
				if base.Treadmill.Owner and base.Treadmill.Owner.Parent then
					renderTag(base, base.Treadmill.Owner)
				end
			end
		end
	end)

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
