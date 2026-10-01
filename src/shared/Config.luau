--[[
	STEAL A CARD - configuration centrale

	Pour publier :
	1. Crée les Game Passes et Developer Products sur create.roblox.com
	   (Creations > ton jeu > Monetization) et colle leurs IDs à la place des 0.
	   Un ID à 0 = article caché, rien ne casse.
	2. Mets ton UserId Roblox dans Admins pour avoir le panneau admin en jeu
	   (le créateur du jeu y a accès automatiquement).
]]

local Config = {}

Config.GameName = "STEAL A CARD"

Config.Admins = {
	-- 123456789,
}

--------------------------------------------------------------------
-- VITESSE
-- La stat "Speed" grimpe sur les tapis de course. Elle est convertie en vitesse
-- de marche avec une courbe douce : 16 au départ, environ 90 à la dernière zone.
-- Une même proportion de Speed en plus donne le même avantage dans toutes les zones.
--------------------------------------------------------------------
Config.SpeedCurve = math.log(90 / 16) / math.log(1.2e10)
function Config.WalkSpeedFor(speed: number): number
	return 16 * (1 + math.max(speed, 0)) ^ Config.SpeedCurve
end
Config.CarrySpeedMultiplier = 0.85 -- porter une carte ralentit
Config.StartCash = 0

-- Tapis de course (Training Track). Rate = Speed gagnée par seconde en courant dessus.
Config.Treadmills = {
	{ Name = "Basic", Price = 0, Rate = 5, Color = Color3.fromRGB(180, 185, 195) },
	{ Name = "Sport", Price = 500, Rate = 25, Color = Color3.fromRGB(90, 210, 120) },
	{ Name = "Pro", Price = 8000, Rate = 150, Color = Color3.fromRGB(70, 150, 255) },
	{ Name = "Turbo", Price = 120000, Rate = 1200, Color = Color3.fromRGB(170, 90, 255) },
	{ Name = "Hyper", Price = 2000000, Rate = 10000, Color = Color3.fromRGB(255, 180, 30) },
	{ Name = "Quantum", Price = 40000000, Rate = 90000, Color = Color3.fromRGB(255, 60, 110) },
	{ Name = "Warp", Price = 800000000, Rate = 800000, Color = Color3.fromRGB(0, 220, 220) },
	{ Name = "Singularity", Price = 15000000000, Rate = 7000000, Color = Color3.fromRGB(30, 30, 30) },
}

--------------------------------------------------------------------
-- BOUTIQUES (les zones sur la route, de la plus proche à la plus lointaine)
-- Speed = vitesse minimum pour entrer
-- Rarity = chances d'apparition des raretés sur les présentoirs
-- GuardianSpeed (zone 1 seulement) = gardien plus lent que le joueur, pour apprendre
--------------------------------------------------------------------
Config.Zones = {
	{
		Name = "Corner Shop", Guardian = "Grandpa Gus", Speed = 0, GuardianSpeed = 0.8,
		Main = Color3.fromRGB(120, 200, 90), Accent = Color3.fromRGB(255, 240, 200),
		Rarity = { Common = 80, Uncommon = 18, Rare = 2 },
	},
	{
		Name = "Comic Corner", Guardian = "Comic Kev", Speed = 600,
		Main = Color3.fromRGB(255, 200, 40), Accent = Color3.fromRGB(255, 70, 110),
		Rarity = { Common = 50, Uncommon = 35, Rare = 13, Epic = 2 },
	},
	{
		Name = "Pixel Arcade", Guardian = "Arcade Ace", Speed = 6000,
		Main = Color3.fromRGB(40, 30, 70), Accent = Color3.fromRGB(0, 255, 200),
		Rarity = { Common = 25, Uncommon = 40, Rare = 28, Epic = 6.5, Legendary = 0.5 },
	},
	{
		Name = "Mall Kiosk", Guardian = "Mall Cop Mike", Speed = 50000,
		Main = Color3.fromRGB(230, 230, 240), Accent = Color3.fromRGB(70, 160, 255),
		Rarity = { Uncommon = 35, Rare = 40, Epic = 21, Legendary = 3.8, Mythic = 0.2 },
	},
	{
		Name = "Collector's Den", Guardian = "The Collector", Speed = 400000,
		Main = Color3.fromRGB(110, 60, 40), Accent = Color3.fromRGB(255, 180, 60),
		Rarity = { Uncommon = 15, Rare = 40, Epic = 35, Legendary = 9, Mythic = 1 },
	},
	{
		Name = "Auction House", Guardian = "The Auctioneer", Speed = 3000000,
		Main = Color3.fromRGB(120, 20, 40), Accent = Color3.fromRGB(255, 215, 120),
		Rarity = { Rare = 35, Epic = 45, Legendary = 17, Mythic = 2.9, Secret = 0.1 },
	},
	{
		Name = "Bank Vault", Guardian = "Vault Guard", Speed = 25000000,
		Main = Color3.fromRGB(70, 75, 85), Accent = Color3.fromRGB(255, 200, 40),
		Rarity = { Rare = 15, Epic = 45, Legendary = 32, Mythic = 7.6, Secret = 0.4 },
	},
	{
		Name = "Grand Museum", Guardian = "The Curator", Speed = 200000000,
		Main = Color3.fromRGB(235, 225, 205), Accent = Color3.fromRGB(150, 40, 60),
		Rarity = { Epic = 40, Legendary = 45, Mythic = 14, Secret = 1 },
	},
	{
		Name = "Sky Exchange", Guardian = "Sky Broker", Speed = 1600000000,
		Main = Color3.fromRGB(170, 220, 255), Accent = Color3.fromRGB(255, 255, 255),
		Rarity = { Epic = 20, Legendary = 50, Mythic = 27, Secret = 3 },
	},
	{
		Name = "Cosmic Archive", Guardian = "The Archivist", Speed = 12000000000,
		Main = Color3.fromRGB(20, 10, 40), Accent = Color3.fromRGB(255, 80, 230),
		Rarity = { Legendary = 45, Mythic = 45, Secret = 10 },
	},
}

Config.PedestalsPerZone = 6
Config.RestockTime = { 18, 32 } -- secondes avant qu'un présentoir vide se remplisse
Config.StealHoldTime = 0.6

-- Vitesse des gardiens. Réglée avec une simulation de poursuite :
-- à la vitesse minimum on se fait attraper, avec environ 2-3x la Speed demandée
-- on ressort avec les cartes de devant, environ 6-10x pour celles du fond.
-- (le gardien accélère aussi pendant la poursuite, voir GuardianRamp plus bas)
Config.GuardianSpeedFactor = 0.95
Config.GuardianReaction = 15 -- le gardien démarre après que le voleur a parcouru ~15 studs
function Config.GuardianSpeedFor(zone): number
	if zone.GuardianSpeed then
		return Config.WalkSpeedFor(zone.Speed) * zone.GuardianSpeed
	end
	return Config.WalkSpeedFor(zone.Speed) * Config.GuardianSpeedFactor
end
Config.GuardianCatchRadius = 4.5
-- les gardiens accélèrent pendant la poursuite : +1% tous les 4 studs parcourus, jusqu'à +25%
Config.GuardianRampPerStud = 0.0025
Config.GuardianRampMax = 0.25
Config.FreezeDuration = 30
Config.DropLifetime = 25 -- une carte tombée reste au sol tant de secondes

--------------------------------------------------------------------
-- GRADATION ET GALERIE
--------------------------------------------------------------------
Config.GradingSlots = 2
Config.GradingSlotsPerRebirth = 1
Config.MaxRawCards = 12 -- cartes en attente de gradation

Config.GalleryStartCases = 6
Config.GalleryMaxCases = 16
function Config.CaseCost(owned: number): number
	-- prix de la vitrine suivante
	return math.floor(250 * 6 ^ (owned - Config.GalleryStartCases))
end

--------------------------------------------------------------------
-- REBIRTH
--------------------------------------------------------------------
Config.RebirthCashBonus = 0.5 -- +50% de cash par rebirth
Config.RebirthSpeedBonus = 0.25 -- +25% de Speed gagnée par rebirth
function Config.RebirthCost(rebirths: number): number
	return math.floor(2e6 * 12 ^ rebirths)
end

Config.IndexBonusPerCard = 0.01 -- +1% de cash par carte différente découverte

-- Friend Boost : +10% de cash par ami présent dans le serveur (max +50%)
Config.FriendBoostPerFriend = 0.1
Config.FriendBoostMax = 0.5

--------------------------------------------------------------------
-- CODES (onglet Codes du shop). Ajoute les tiens ici.
-- Reward : Cash, Speed ou Card (= rareté d'une carte brute envoyée au labo)
--------------------------------------------------------------------
Config.Codes = {
	RELEASE = { Cash = 2500, Speed = 500 },
	SPOOKY = { Card = "Rare", Expires = { 2026, 11, 5 } },
	THANKYOU = { Cash = 10000 },
}

--------------------------------------------------------------------
-- CLAQUE (pour faire lâcher une carte à un autre joueur)
--------------------------------------------------------------------
Config.SlapCooldown = 1
Config.SlapRange = 9

--------------------------------------------------------------------
-- EVENTS
--------------------------------------------------------------------
Config.EventEvery = { 480, 720 }
Config.EventDuration = 180
Config.Events = {
	HoloStorm = { Name = "HOLO STORM", Description = "Holo cards everywhere", FinishBoost = { Holo = 4, Rainbow = 2 } },
	GoldenHour = { Name = "GOLDEN HOUR", Description = "Gold finish x4", FinishBoost = { Gold = 4 } },
	RestockRush = { Name = "RESTOCK RUSH", Description = "Shops restock twice as fast", RestockSpeed = 2 },
	LuckyMoon = { Name = "LUCKY MOON", Description = "Rare cards x3", Luck = 3 },
	SleepyGuards = { Name = "SLEEPY GUARDS", Description = "Guardians are 25% slower", GuardianSlow = 0.75 },
	BloodMoon = { Name = "BLOOD MOON", Description = "Haunted cards rising", FinishBoost = { Haunted = 5 }, Season = "Halloween" },
	Blizzard = { Name = "BLIZZARD", Description = "Frozen cards rising", FinishBoost = { Frozen = 5 }, Season = "Winter" },
}
Config.ServerLuckDuration = 900
Config.ServerLuckMultiplier = 2

--------------------------------------------------------------------
-- RÉCOMPENSE QUOTIDIENNE (minutes de revenu, avec un minimum)
--------------------------------------------------------------------
Config.DailyMinutes = { 2, 3, 4, 5, 6, 8, 12 }
Config.DailyMinimum = { 300, 500, 800, 1200, 2000, 3500, 6000 }
Config.DailyCooldown = 20 * 3600
Config.DailyStreakBreak = 48 * 3600

--------------------------------------------------------------------
-- GAME PASSES
--------------------------------------------------------------------
Config.GamePasses = {
	VIP = { Id = 0, Name = "VIP", Description = "x1.5 cash, VIP tag, golden name.", Color = Color3.fromRGB(255, 200, 40) },
	DoubleCash = { Id = 0, Name = "2x Cash", Description = "Double the cash from your gallery. Forever.", Color = Color3.fromRGB(80, 230, 140) },
	FastGrading = { Id = 0, Name = "2x Grading", Description = "Cards get graded twice as fast.", Color = Color3.fromRGB(70, 160, 255) },
	DoubleSpeed = { Id = 0, Name = "2x Training", Description = "Double Speed from every treadmill.", Color = Color3.fromRGB(255, 130, 60) },
	AutoCollect = { Id = 0, Name = "Auto Collect", Description = "Gallery cash goes straight to your wallet.", Color = Color3.fromRGB(0, 220, 220) },
	MoreGrading = { Id = 0, Name = "+2 Grading Slots", Description = "Grade two more cards at the same time.", Color = Color3.fromRGB(190, 120, 255) },
	AutoTrain = { Id = 0, Name = "Auto Train", Description = "Train on treadmills without holding any key. AFK friendly.", Color = Color3.fromRGB(255, 70, 110) },
	Lucky = { Id = 0, Name = "Lucky Grader", Description = "Better grades: best of two rolls.", Color = Color3.fromRGB(255, 90, 150) },
}
Config.GamePassOrder = { "VIP", "DoubleCash", "DoubleSpeed", "AutoTrain", "FastGrading", "MoreGrading", "AutoCollect", "Lucky" }
Config.VipCashMultiplier = 1.5

--------------------------------------------------------------------
-- DEVELOPER PRODUCTS
--------------------------------------------------------------------
Config.Products = {
	SpeedSmall = { Id = 0, Kind = "Speed", Minutes = 10, Minimum = 1000, Name = "Speed Boost", Description = "10 minutes of training on your best treadmill." },
	SpeedBig = { Id = 0, Kind = "Speed", Minutes = 60, Minimum = 8000, Name = "Speed Mega Boost", Description = "1 hour of training on your best treadmill." },
	FreezeGuards = { Id = 0, Kind = "Freeze", Name = "Freeze Guards", Description = "Every guardian is frozen for 30 seconds. Go!" },
	InstantGrade = { Id = 0, Kind = "InstantGrade", Name = "Grade All Now", Description = "Finish every card in the lab instantly." },
	ServerLuck = { Id = 0, Kind = "ServerLuck", Name = "Server Luck x2", Description = "Rare cards x2 for EVERYONE in the server for 15 min." },
	MysteryPack = { Id = 0, Kind = "Pack", Name = "Mystery Pack", Description = "A raw card sent to your lab. Epic or better." },
	CashSmall = { Id = 0, Kind = "Cash", Minutes = 10, Minimum = 2000, Name = "Cash Bag", Description = "10 minutes of your income." },
	CashBig = { Id = 0, Kind = "Cash", Minutes = 60, Minimum = 15000, Name = "Cash Vault", Description = "1 hour of your income." },
}
Config.ProductOrder = { "FreezeGuards", "SpeedSmall", "SpeedBig", "InstantGrade", "ServerLuck", "MysteryPack", "CashSmall", "CashBig" }
Config.PackWeights = { Epic = 70, Legendary = 25, Mythic = 4.6, Secret = 0.4 }

--------------------------------------------------------------------
-- BADGES (optionnel, 0 = désactivé)
--------------------------------------------------------------------
Config.Badges = {
	Welcome = 0,
	FirstSteal = 0,
	FirstLegendary = 0,
	FirstRebirth = 0,
	GemMint = 0,
	LastZone = 0,
}

--------------------------------------------------------------------
-- DIVERS
--------------------------------------------------------------------
Config.DataStoreName = "StealACard_v1"
Config.IncomeBoardStore = "StealACard_Income_v1"
Config.SpeedBoardStore = "StealACard_Speed_v1"
Config.LeaderboardRefresh = 90
Config.AutosaveInterval = 120

-- true = tous les passes offerts dans Studio pour tester (jamais en jeu publié)
Config.StudioGrantAllPasses = false

return Config
