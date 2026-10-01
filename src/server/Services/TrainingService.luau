--[[
	Training Track.
	- E devant un tapis débloqué : le joueur monte dessus (il est placé et bloqué).
	- Tant qu'il reste appuyé (Espace, W, clic ou bouton à l'écran), il court et gagne de la Speed.
	- Le pass Auto Train fait courir sans appuyer.
	- Le tapis suivant se débloque avec du cash.
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
local treadmills = {}
local training: { [Player]: number } = {} -- joueur -> index du tapis
local holding: { [Player]: boolean } = {}

function TrainingService.Multiplier(player: Player): number
	local data = DataService.Get(player)
	local m = 1 + (data and data.Rebirths or 0) * Config.RebirthSpeedBonus
	if MonetizationService.Owns(player, "DoubleSpeed") then
		m *= 2
	end
	return m
end

-- Speed par seconde sur le meilleur tapis possédé
function TrainingService.BestRate(player: Player): number
	local data = DataService.Get(player)
	local tier = data and Config.Treadmills[data.Treadmill] or Config.Treadmills[1]
	return tier.Rate * TrainingService.Multiplier(player)
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

function TrainingService.Unlock(player: Player, index: number)
	local data = DataService.Get(player)
	local tier = Config.Treadmills[index]
	if not data or not tier or index <= data.Treadmill then
		return
	end
	if index > data.Treadmill + 1 then
		Remotes.Notify:FireClient(player, "Unlock " .. Config.Treadmills[data.Treadmill + 1].Name .. " first", "error")
		return
	end
	if data.Cash < tier.Price then
		Remotes.Notify:FireClient(player, "You need " .. Format.cash(tier.Price), "error")
		return
	end
	data.Cash -= tier.Price
	data.Treadmill = index
	player:SetAttribute("Cash", data.Cash)
	Remotes.Notify:FireClient(player, tier.Name .. " treadmill unlocked!", "reward")
	Hub.Players.SendState(player)
end

function TrainingService.Stop(player: Player)
	if training[player] then
		training[player] = nil
		holding[player] = nil
		player:SetAttribute("Training", nil)
	end
end

function TrainingService.StartOn(player: Player, index: any)
	if type(index) ~= "number" then
		return
	end
	local data = DataService.Get(player)
	local t = treadmills[index]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not data or not t or not root then
		return
	end
	if Hub.Zones.IsCarrying(player) then
		return
	end
	if index > data.Treadmill then
		Remotes.Notify:FireClient(player, "Unlock this treadmill first", "error")
		return
	end
	if (root.Position - t.Belt.Position).Magnitude > 16 then
		return
	end
	-- un seul joueur par tapis
	for other, i in training do
		if i == index and other ~= player and other.Parent then
			Remotes.Notify:FireClient(player, "Someone is already on this treadmill", "error")
			return
		end
	end
	training[player] = index
	holding[player] = false
	player:SetAttribute("Training", index)
	player.Character:PivotTo(t.Spot)
end

function TrainingService.SetHolding(player: Player, value: any)
	if training[player] then
		holding[player] = value == true
	end
end

function TrainingService.Start(built)
	treadmills = built.Treadmills
	for _, t in treadmills do
		local tier = Config.Treadmills[t.Index]
		t.Label.Text = ("%s\n+%s SPEED/S"):format(tier.Name:upper(), Format.short(tier.Rate))
	end

	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(TICK)
			-- on crédite le temps réellement écoulé (task.wait n'est jamais pile à l'heure)
			local now = os.clock()
			local dt = math.min(now - last, 1)
			last = now
			for player, index in training do
				local t = treadmills[index]
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if not player.Parent or not root or not humanoid or humanoid.Health <= 0 or (root.Position - t.Spot.Position).Magnitude > 6 then
					TrainingService.Stop(player)
				elseif holding[player] or MonetizationService.Owns(player, "AutoTrain") then
					TrainingService.AddSpeed(player, Config.Treadmills[index].Rate * TrainingService.Multiplier(player) * dt)
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
