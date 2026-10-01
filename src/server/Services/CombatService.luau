-- Claque (pour faire lâcher une carte à un autre joueur) et vitesse de marche

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local MapBuilder = require(script.Parent.Parent.World.MapBuilder)
local Hub = require(script.Parent.Parent.Hub)

local CombatService = {}

local lastSlap: { [Player]: number } = {}

function CombatService.UpdateSpeed(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local data = DataService.Get(player)
	if not humanoid or not data then
		return
	end
	local speed = Config.WalkSpeedFor(data.Speed)
	if Hub.Zones.IsCarrying(player) then
		speed *= Config.CarrySpeedMultiplier
	end
	humanoid.WalkSpeed = speed
end

local function slap(player: Player)
	local t = os.clock()
	if (lastSlap[player] or 0) + Config.SlapCooldown > t then
		return
	end
	lastSlap[player] = t
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or MapBuilder.InHub(root.Position) then
		return -- pas de claques dans la zone sûre
	end
	local best, bestDist = nil, Config.SlapRange
	for _, other in Players:GetPlayers() do
		local oRoot = other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local oHum = oRoot and (other.Character :: Model):FindFirstChildOfClass("Humanoid")
		if oRoot and oHum and oHum.Health > 0 and not MapBuilder.InHub(oRoot.Position) then
			local offset = oRoot.Position - root.Position
			local dist = offset.Magnitude
			local facing = dist > 0 and root.CFrame.LookVector:Dot(offset.Unit) or 1
			if dist < bestDist and facing > 0.2 then
				best, bestDist = other, dist
			end
		end
	end
	if not best then
		return
	end
	local victimRoot = (best.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
	local dir = (victimRoot.Position - root.Position) * Vector3.new(1, 0, 1)
	dir = dir.Magnitude > 0 and dir.Unit or root.CFrame.LookVector
	Remotes.Knockback:FireClient(best, dir * 55 + Vector3.new(0, 30, 0))
	if Hub.Zones.IsCarrying(best) then
		Hub.Zones.Drop(best, player.DisplayName .. " slapped you! Card dropped")
		Remotes.Notify:FireClient(player, "Card knocked loose! Grab it!", "reward")
	end
end

function CombatService.GiveTools(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack or backpack:FindFirstChild("Slap") then
		return
	end
	local tool = Instance.new("Tool")
	tool.Name = "Slap"
	tool.ToolTip = "Slap a player carrying a card to make them drop it"
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1.2, 1.2, 1.6)
	handle.Color = Color3.fromRGB(255, 200, 170)
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool
	tool.Activated:Connect(function()
		slap(player)
	end)
	tool.Parent = backpack
end

function CombatService.OnSpawn(player: Player)
	CombatService.GiveTools(player)
	CombatService.UpdateSpeed(player)
end

function CombatService.Start()
	Players.PlayerRemoving:Connect(function(player)
		lastSlap[player] = nil
	end)
end

return CombatService
