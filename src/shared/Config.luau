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

-- Tapis de course : chaque base a le sien, devant l'entrée, avec 9 niveaux.
-- Équilibrage (voir README) :
-- - chaque niveau donne environ 6 fois plus de Speed par seconde que le précédent ;
-- - le prix du niveau suivant vaut quelques minutes du revenu qu'on a quand on en a besoin ;
-- - avec le bon tapis, il faut 2 à 20 minutes de course (AFK possible) pour atteindre
--   la vitesse conseillée de la boutique suivante.
Config.TreadmillMaxLevel = 9
Config.TreadmillRates = { 5, 30, 180, 1100, 6500, 40000, 240000, 1400000, 8500000 }
-- prix pour passer au niveau suivant (index = niveau actuel)
Config.TreadmillCosts = { 250, 2500, 25000, 200000, 1500000, 12000000, 100000000, 1000000000 }
function Config.TreadmillRate(level: number): number
	-- Speed gagnée par seconde en courant dessus
	return Config.TreadmillRates[math.clamp(level, 1, Config.TreadmillMaxLevel)]
end
function Config.TreadmillCost(level: number): number
	-- prix pour passer du niveau level au niveau level + 1
	return Config.TreadmillCosts[math.clamp(level, 1, Config.TreadmillMaxLevel - 1)]
end
-- un look par niveau
Config.TreadmillTiers = {
	{ From = 1, Name = "Common", Color = Color3.fromRGB(190, 195, 205) },
	{ From = 2, Name = "Uncommon", Color = Color3.fromRGB(80, 235, 70) },
	{ From = 3, Name = "Rare", Color = Color3.fromRGB(40, 140, 255) },
	{ From = 4, Name = "Epic", Color = Color3.fromRGB(170, 70, 255) },
	{ From = 5, Name = "Legendary", Color = Color3.fromRGB(255, 195, 40) },
	{ From = 6, Name = "Mythic", Color = Color3.fromRGB(255, 40, 50) },
	{ From = 7, Name = "Divine", Color = Color3.fromRGB(60, 230, 255) },
	{ From = 8, Name = "Ancient", Color = Color3.fromRGB(190, 80, 255) },
	{ From = 9, Name = "Supreme", Color = Color3.fromRGB(255, 220, 90) },
}
function Config.TreadmillTier(level: number)
	local tier, index = Config.TreadmillTiers[1], 1
	for i, t in Config.TreadmillTiers do
		if level >= t.From then
			tier, index = t, i
		end
	end
	return tier, index
end

--------------------------------------------------------------------
-- BOUTIQUES (les zones sur la route, de la plus proche à la plus lointaine)
-- Speed = vitesse conseillée : à cette vitesse on ressort avec les cartes de devant
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
-- en dessous de la vitesse conseillée on se fait attraper, à la vitesse conseillée
-- on ressort avec les cartes de devant, il faut environ 3x pour celles du fond.
-- (le gardien accélère aussi pendant la poursuite, voir GuardianRamp plus bas)
Config.GuardianSpeedFactor = 0.9
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
-- les cartes rares sont mieux gardées : bonus de vitesse du gardien selon la rareté volée
Config.RarityGuardBonus = { Epic = 0.04, Legendary = 0.08, Mythic = 0.12, Secret = 0.16 }
Config.DropLifetime = 25 -- une carte tombée reste au sol tant de secondes

--------------------------------------------------------------------
-- SUPPORTS DE LA BASE ET ÉTAGES
-- Une carte volée se pose toute seule sur un support libre de ta base.
-- 8 supports par étage. Au début, 3 sont débloqués, les autres s'achètent
-- (chacun plus cher que le précédent). Un rebirth ajoute un étage.
--------------------------------------------------------------------
Config.CasesPerFloor = 8
Config.FloorRebirths = { 0, 1, 3 } -- rebirths nécessaires pour l'étage 1, 2, 3
Config.GalleryStartCases = 3
Config.GalleryMaxCases = 24
function Config.FloorsFor(rebirths: number): number
	local n = 0
	for _, need in Config.FloorRebirths do
		if rebirths >= need then
			n += 1
		end
	end
	return n
end
function Config.CaseCost(owned: number): number
	-- prix du support suivant (owned = supports déjà débloqués)
	return math.floor(150 * 3.2 ^ (owned - Config.GalleryStartCases))
end
Config.StorageMax = 30 -- cartes en réserve quand tous les supports sont pleins

--------------------------------------------------------------------
-- GRADATION (stand GRADING LAB au bout de la rue)
-- On paie, la note (1 à 10) tombe tout de suite. Le prix = 60 secondes
-- du revenu de la carte (moitié prix avec le pass). On peut regrader.
--------------------------------------------------------------------
Config.GradeSeconds = 60
Config.GradeMinimum = 25
function Config.GradeCost(income: number, cheap: boolean?): number
	local cost = math.max(Config.GradeMinimum, math.floor(income * Config.GradeSeconds))
	return cheap and math.floor(cost / 2) or cost
end

--------------------------------------------------------------------
-- PACKS (stand PACKS au bout de la rue)
-- Le stock change toutes les 5 minutes, le même pour tous les serveurs.
-- Chaque pack ouvert sans Legendary ou mieux donne +3% de chance pour les
-- suivants (jusqu'à +45%). Les packs Gold et plus donnent aussi +20% de cash
-- pendant 10 minutes. BonusChance = chance d'avoir une 2e carte.
--------------------------------------------------------------------
Config.PackRestockTime = 300
Config.PackLuckStep = 0.03
Config.PackLuckMax = 0.45
Config.PackCashBoost = 0.2
Config.PackCashBoostTime = 600
Config.PackOrder = { "Basic", "Silver", "Gold", "Diamond", "Cosmic" }
Config.Packs = {
	Basic = { Name = "Basic Pack", Price = 500, Odds = { Common = 70, Uncommon = 25, Rare = 5 }, Stock = { 3, 6 }, InStock = 1, BonusChance = 0.1, Color = Color3.fromRGB(170, 175, 190) },
	Silver = { Name = "Silver Pack", Price = 15000, Odds = { Uncommon = 50, Rare = 38, Epic = 11, Legendary = 1 }, Stock = { 2, 4 }, InStock = 0.85, BonusChance = 0.15, Color = Color3.fromRGB(200, 215, 235) },
	Gold = { Name = "Gold Pack", Price = 400000, Odds = { Rare = 45, Epic = 40, Legendary = 13, Mythic = 2 }, Stock = { 1, 3 }, InStock = 0.6, BonusChance = 0.2, CashBoost = true, Color = Color3.fromRGB(255, 200, 50) },
	Diamond = { Name = "Diamond Pack", Price = 12000000, Odds = { Epic = 45, Legendary = 42, Mythic = 12, Secret = 1 }, Stock = { 1, 2 }, InStock = 0.35, BonusChance = 0.25, CashBoost = true, Color = Color3.fromRGB(110, 230, 255) },
	Cosmic = { Name = "Cosmic Pack", Price = 500000000, Odds = { Legendary = 55, Mythic = 38, Secret = 7 }, Stock = { 1, 1 }, InStock = 0.15, BonusChance = 0.35, CashBoost = true, Color = Color3.fromRGB(200, 90, 255) },
}

--------------------------------------------------------------------
-- REFRESH DE LA MAP : toutes les 10 minutes, compte à rebours de 5 s,
-- tous ceux qui sont dans les boutiques retournent dans leur base et
-- tous les présentoirs changent.
--------------------------------------------------------------------
Config.MapRefreshEvery = 600
Config.MapRefreshCountdown = 5

--------------------------------------------------------------------
-- INDEX : récompenses par palier de cartes découvertes
--------------------------------------------------------------------
Config.IndexRewards = {
	{ Count = 5, Name = "$ Bag", Cash = 5000, CashMinutes = 5 },
	{ Count = 10, Name = "Silver Pack", Pack = "Silver" },
	{ Count = 15, Name = "+5% Cash forever", CashBonus = 0.05 },
	{ Count = 20, Name = "Gold Pack", Pack = "Gold" },
	{ Count = 25, Name = "+10% Cash forever", CashBonus = 0.1 },
	{ Count = 30, Name = "Diamond Pack", Pack = "Diamond" },
	{ Count = 40, Name = "+25% Cash forever", CashBonus = 0.25 },
	{ Count = 46, Name = "Cosmic Pack", Pack = "Cosmic" },
}

--------------------------------------------------------------------
-- REBIRTH
--------------------------------------------------------------------
Config.RebirthCashBonus = 0.5 -- +50% de cash par rebirth
Config.RebirthSpeedBonus = 0.25 -- +25% de Speed gagnée par rebirth
function Config.RebirthCost(rebirths: number): number
	return math.floor(300000 * 6 ^ rebirths)
end

Config.IndexBonusPerCard = 0.01 -- +1% de cash par carte différente découverte

-- Friend Boost : +10% de cash par ami présent dans le serveur (max +50%)
Config.FriendBoostPerFriend = 0.1
Config.FriendBoostMax = 0.5

--------------------------------------------------------------------
-- CODES (onglet Codes du shop). Ajoute les tiens ici.
-- Reward : Cash, Speed ou Card (= rareté d'une carte posée dans ta base)
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
	HoloStorm = { Name = "Holo Storm", Description = "Holo and Rainbow mutations everywhere", FinishBoost = { Holo = 4, Rainbow = 2 }, Icon = "cards", Palette = "Cyan" },
	GoldenHour = { Name = "Golden Hour", Description = "Gold mutation x4 in every shop", FinishBoost = { Gold = 4 }, Icon = "crown", Palette = "Gold" },
	RestockRush = { Name = "Restock Rush", Description = "Shops restock twice as fast", RestockSpeed = 2, Icon = "crate", Palette = "Orange" },
	LuckyMoon = { Name = "Lucky Moon", Description = "Rare cards x3 in every shop", Luck = 3, Icon = "clover", Palette = "Green" },
	SleepyGuards = { Name = "Sleepy Guards", Description = "Guards run 25% slower", GuardianSlow = 0.75, Icon = "clock", Palette = "Blue" },
	BloodMoon = { Name = "Blood Moon", Description = "Haunted mutation rising", FinishBoost = { Haunted = 5 }, Season = "Halloween", Icon = "gift", Palette = "Red" },
	Blizzard = { Name = "Blizzard", Description = "Frozen mutation rising", FinishBoost = { Frozen = 5 }, Season = "Winter", Icon = "snowflake", Palette = "Cyan" },
}
Config.ServerLuckDuration = 900
Config.ServerLuckMultiplier = 2

--------------------------------------------------------------------
-- RÉCOMPENSES QUOTIDIENNES (cycle de 7 jours)
-- Cash / Speed : minutes de revenu ou de tapis, avec un minimum.
-- Card : une carte brute de cette rareté envoyée au labo.
--------------------------------------------------------------------
Config.DailyRewards = {
	{ Kind = "Cash", Minutes = 3, Minimum = 500, Name = "Cash Bag", Icon = "cash" },
	{ Kind = "Speed", Minutes = 5, Minimum = 300, Name = "Speed Boost", Icon = "bolt" },
	{ Kind = "Card", Rarity = "Rare", Name = "Rare Pack", Icon = "cardpack" },
	{ Kind = "Cash", Minutes = 10, Minimum = 2500, Name = "Cash Pile", Icon = "cashpile" },
	{ Kind = "Card", Rarity = "Epic", Name = "Epic Pack", Icon = "cardpack" },
	{ Kind = "Speed", Minutes = 20, Minimum = 3000, Name = "Mega Speed", Icon = "bolt" },
	{ Kind = "Card", Rarity = "Legendary", Minutes = 15, Minimum = 10000, Name = "Legend Box", Icon = "gift" },
}
Config.DailyCooldown = 20 * 3600
Config.DailyStreakBreak = 48 * 3600

--------------------------------------------------------------------
-- GAME PASSES
--------------------------------------------------------------------
Config.GamePasses = {
	VIP = { Id = 0, Name = "VIP", Description = "x1.5 cash, VIP tag, golden name.", Color = Color3.fromRGB(255, 200, 40) },
	DoubleCash = { Id = 0, Name = "2x Cash", Description = "Double the cash from your gallery. Forever.", Color = Color3.fromRGB(80, 230, 140) },
	CheapGrading = { Id = 0, Name = "Half-Price Grading", Description = "Grading costs half price. Forever.", Color = Color3.fromRGB(70, 160, 255) },
	DoubleSpeed = { Id = 0, Name = "2x Training", Description = "Double Speed from every treadmill.", Color = Color3.fromRGB(255, 130, 60) },
	AutoCollect = { Id = 0, Name = "Auto Collect", Description = "Gallery cash goes straight to your wallet.", Color = Color3.fromRGB(0, 220, 220) },
	ExtraCases = { Id = 0, Name = "+2 Display Cases", Description = "Two more cases in your base, free.", Color = Color3.fromRGB(190, 120, 255) },
	Lucky = { Id = 0, Name = "x2 Luck", Description = "Best of two rolls on every grade and luckier packs.", Color = Color3.fromRGB(255, 90, 150) },
}
Config.GamePassOrder = { "VIP", "DoubleCash", "DoubleSpeed", "CheapGrading", "ExtraCases", "AutoCollect", "Lucky" }
Config.VipCashMultiplier = 1.5

--------------------------------------------------------------------
-- DEVELOPER PRODUCTS
--------------------------------------------------------------------
Config.Products = {
	SpeedSmall = { Id = 0, Kind = "Speed", Minutes = 10, Minimum = 1000, Name = "Speed Boost", Description = "10 minutes of training on your treadmill." },
	SpeedBig = { Id = 0, Kind = "Speed", Minutes = 60, Minimum = 8000, Name = "Speed Mega Boost", Description = "1 hour of training on your treadmill." },
	StarterPack = { Id = 0, Kind = "Starter", Name = "Starter Pack", Description = "1 Legendary+ card, 15 min of cash and 15 min of Speed." },
	RebirthSkip = { Id = 0, Kind = "RebirthSkip", Name = "Skip Rebirth", Description = "+1 rebirth and keep everything." },
	TreadmillUpgrade = { Id = 0, Kind = "Treadmill", Name = "Treadmill +1 Level", Description = "Upgrade your treadmill one level right now." },
	FreezeGuards = { Id = 0, Kind = "Freeze", Name = "Freeze Guards", Description = "Every guardian is frozen for 30 seconds. Go!" },
	PackRestock = { Id = 0, Kind = "PackRestock", Name = "Restock Packs", Description = "Refill the pack stand for you, right now." },
	ServerLuck = { Id = 0, Kind = "ServerLuck", Name = "Server Luck x2", Description = "Rare cards x2 for EVERYONE in the server for 15 min." },
	MysteryPack = { Id = 0, Kind = "Pack", Name = "Mystery Pack", Description = "A card placed in your base. Epic or better." },
	CashSmall = { Id = 0, Kind = "Cash", Minutes = 10, Minimum = 2000, Name = "Cash Bag", Description = "10 minutes of your income." },
	CashBig = { Id = 0, Kind = "Cash", Minutes = 60, Minimum = 15000, Name = "Cash Vault", Description = "1 hour of your income." },
	CashHuge = { Id = 0, Kind = "Cash", Minutes = 360, Minimum = 100000, Name = "Cash Mountain", Description = "6 hours of your income." },
}
Config.ProductOrder = { "FreezeGuards", "TreadmillUpgrade", "SpeedSmall", "SpeedBig", "PackRestock", "ServerLuck", "MysteryPack", "CashSmall", "CashBig", "CashHuge" }
Config.StarterWeights = { Legendary = 85, Mythic = 14, Secret = 1 }
Config.PackWeights = { Epic = 70, Legendary = 25, Mythic = 4.6, Secret = 0.4 }

--------------------------------------------------------------------
-- SONS ET MUSIQUE
-- Les valeurs par défaut sont des sons fournis avec Roblox (rbxasset://).
-- Pour de meilleurs sons : Creator Store > Audio, copie l'ID et mets
-- "rbxassetid://ID" à la place. Music : liste de musiques jouées en boucle.
--------------------------------------------------------------------
Config.Sounds = {
	Click = "rbxasset://sounds/clickfast.wav",
	Cash = "rbxasset://sounds/electronicpingshort.wav",
	Steal = "rbxasset://sounds/swoosh.wav",
	Caught = "rbxasset://sounds/hit.wav",
	Upgrade = "rbxasset://sounds/electronicpingshort.wav",
	Pack = "rbxasset://sounds/swoosh.wav",
	Reveal = "rbxasset://sounds/snap.wav",
	Error = "rbxasset://sounds/clickfast.wav",
	Event = "rbxasset://sounds/electronicpingshort.wav",
}
Config.SoundVolume = 0.5
Config.Music = {} -- ex. { "rbxassetid://1234567890" }
Config.MusicVolume = 0.25

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
