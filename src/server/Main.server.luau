-- Point d'entrée serveur : construit la map puis démarre tous les services

local Lighting = game:GetService("Lighting")

local Services = script.Parent.Services
local World = script.Parent.World

local Build = require(World.Build)
local ObbyBuilder = require(World.ObbyBuilder)
local DataService = require(Services.DataService)
local MonetizationService = require(Services.MonetizationService)
local ProgressionService = require(Services.ProgressionService)
local LeaderboardService = require(Services.LeaderboardService)

-- Ambiance : ciel, brume légère et un peu de bloom
if not Lighting:FindFirstChildOfClass("Atmosphere") then
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(200, 220, 255)
	atmosphere.Decay = Color3.fromRGB(120, 140, 190)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting
end
if not Lighting:FindFirstChildOfClass("BloomEffect") then
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 30
	bloom.Threshold = 1.6
	bloom.Parent = Lighting
end

local checkpoints, boards = ObbyBuilder.Build()
Build.Start()

DataService.Start()
MonetizationService.Start()
ProgressionService.Start(checkpoints)
LeaderboardService.Start(boards)

print(("[Sky Rush] Ready with %d stages"):format(#checkpoints))
