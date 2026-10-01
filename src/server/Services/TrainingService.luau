-- Training Track : courir sur un tapis fait monter la stat Speed

local CollectionService = game:GetService("CollectionService")
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
local lastWarning: { [Player]: number } = {}

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
	if not data or not tier then
		return
	end
	if index <= data.Treadmill then
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

local function treadmillUnder(position: Vector3)
	for _, t in treadmills do
		local p = t.Belt.CFrame:PointToObjectSpace(position)
		if math.abs(p.X) < 7.5 and math.abs(p.Z) < 3.5 and p.Y > 0 and p.Y < 6 then
			return t
		end
	end
	return nil
end

function TrainingService.Start(built)
	treadmills = built.Treadmills
	for _, t in treadmills do
		local tier = Config.Treadmills[t.Index]
		t.Label.Text = ("%s  ·  +%s/s"):format(tier.Name:upper(), Format.short(tier.Rate))
		CollectionService:AddTag(t.Console, "Treadmill")
	end

	task.spawn(function()
		while true do
			task.wait(TICK)
			for _, player in Players:GetPlayers() do
				local data = DataService.Get(player)
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if data and root and humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
					local t = treadmillUnder(root.Position)
					if t then
						if t.Index <= data.Treadmill then
							local gain = Config.Treadmills[t.Index].Rate * TrainingService.Multiplier(player) * TICK
							TrainingService.AddSpeed(player, gain)
						elseif (lastWarning[player] or 0) + 4 < os.clock() then
							lastWarning[player] = os.clock()
							Remotes.Notify:FireClient(player, "Unlock this treadmill first", "error")
						end
					end
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastWarning[player] = nil
	end)
end

return TrainingService
