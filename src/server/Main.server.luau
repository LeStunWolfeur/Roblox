-- Point d'entrée serveur : construit la map puis démarre tous les services

local Lighting = game:GetService("Lighting")

local Services = script.Parent.Services
local Hub = require(script.Parent.Hub)
local MapBuilder = require(script.Parent.World.MapBuilder)
local DataService = require(Services.DataService)
local MonetizationService = require(Services.MonetizationService)
local LeaderboardService = require(Services.LeaderboardService)

-- Ambiance générale
if not Lighting:FindFirstChildOfClass("Atmosphere") then
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.25
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(200, 215, 255)
	atmosphere.Decay = Color3.fromRGB(110, 120, 170)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1
	atmosphere.Parent = Lighting
end
if not Lighting:FindFirstChildOfClass("BloomEffect") then
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 28
	bloom.Threshold = 1.5
	bloom.Parent = Lighting
end

Hub.Map = MapBuilder.Build()
Hub.Loot = require(Services.LootService)
Hub.Events = require(Services.EventService)
Hub.Gallery = require(Services.GalleryService)
Hub.Grading = require(Services.GradingService)
Hub.Training = require(Services.TrainingService)
Hub.Zones = require(Services.ZoneService)
Hub.Combat = require(Services.CombatService)
Hub.Players = require(Services.PlayerService)

DataService.Start()
MonetizationService.Start()
Hub.Events.Start()
Hub.Gallery.Start(Hub.Map.Galleries)
Hub.Grading.Start()
Hub.Training.Start(Hub.Map.Training)
Hub.Zones.Start(Hub.Map.Zones)
Hub.Combat.Start()
Hub.Players.Start()
LeaderboardService.Start(Hub.Map.Boards, Hub.Gallery.Income)

print("[Steal a Card] server ready")
