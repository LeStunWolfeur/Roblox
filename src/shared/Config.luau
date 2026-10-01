--[[
	SKY RUSH OBBY - configuration centrale

	Tout ce que tu dois toucher pour publier est ici.
	1. Crée les Game Passes et Developer Products sur create.roblox.com
	   (Creations > ton jeu > Monetization).
	2. Colle leurs IDs ci-dessous à la place des 0.
	Un ID à 0 = l'article est caché dans la boutique, rien ne casse.
]]

local Config = {}

Config.GameName = "SKY RUSH"
Config.Subtitle = "OBBY"

-- Nombre de stages par monde, et liste des mondes (dans l'ordre)
Config.StagesPerWorld = 10
Config.Worlds = {
	{ Name = "Meadow", Main = Color3.fromRGB(120, 200, 90), Alt = Color3.fromRGB(240, 230, 200), Material = Enum.Material.Grass },
	{ Name = "Desert", Main = Color3.fromRGB(225, 180, 110), Alt = Color3.fromRGB(170, 110, 70), Material = Enum.Material.Sandstone },
	{ Name = "Frost", Main = Color3.fromRGB(170, 220, 255), Alt = Color3.fromRGB(240, 250, 255), Material = Enum.Material.Ice },
	{ Name = "Magma", Main = Color3.fromRGB(60, 50, 55), Alt = Color3.fromRGB(255, 140, 40), Material = Enum.Material.Basalt },
	{ Name = "Neon City", Main = Color3.fromRGB(30, 30, 45), Alt = Color3.fromRGB(0, 255, 200), Material = Enum.Material.SmoothPlastic },
	{ Name = "Void", Main = Color3.fromRGB(15, 10, 25), Alt = Color3.fromRGB(255, 60, 220), Material = Enum.Material.Glass },
}

function Config.TotalStages(): number
	return #Config.Worlds * Config.StagesPerWorld
end

function Config.WorldForStage(stage: number)
	local index = math.clamp(math.floor((math.max(stage, 1) - 1) / Config.StagesPerWorld) + 1, 1, #Config.Worlds)
	return Config.Worlds[index], index
end

-- Couleur des pièces mortelles
Config.KillColor = Color3.fromRGB(255, 45, 70)

-- Nombre de morts sur un même stage avant de proposer le skip
Config.DeathsBeforeSkipOffer = 4

--------------------------------------------------------------------
-- PROGRESSION : coins, XP / niveaux, rebirths, récompense quotidienne
--------------------------------------------------------------------

-- Coins et XP gagnés la première fois qu'on atteint un checkpoint dans une run.
-- Plus le stage est loin, plus ça rapporte.
function Config.CoinsForStage(stage: number): number
	return 5 + math.floor(stage * 1.5)
end

function Config.XPForStage(stage: number): number
	return 10 + stage * 2
end

Config.WinCoins = 500 -- bonus en finissant l'obby
Config.WinXP = 400

-- XP nécessaire pour passer du niveau L au niveau L+1
function Config.XPToNext(level: number): number
	return math.floor(80 * level ^ 1.35)
end

-- Rebirth : possible quand on a fini l'obby. Remet le stage à 0
-- et donne un multiplicateur permanent sur les coins et l'XP.
Config.RebirthBonus = 0.5 -- +50% par rebirth
function Config.Multiplier(rebirths: number, hasDoubleCoins: boolean): number
	local m = 1 + rebirths * Config.RebirthBonus
	if hasDoubleCoins then
		m *= 2
	end
	return m
end

-- Récompense quotidienne (série de connexions, jour 7 et plus = max)
Config.DailyRewards = { 100, 150, 200, 300, 400, 600, 1000 }
Config.DailyCooldown = 20 * 3600 -- on peut réclamer toutes les 20h
Config.DailyStreakBreak = 48 * 3600 -- au-delà de 48h sans réclamer, la série repart à 1

-- Trails achetables avec les coins (débloqués par niveau ou rebirth)
Config.Trails = {
	{ Id = "Cloud", Name = "Cloud", Price = 0, Level = 1, Rebirths = 0, Colors = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 220, 255) } },
	{ Id = "Mint", Name = "Mint", Price = 400, Level = 3, Rebirths = 0, Colors = { Color3.fromRGB(120, 255, 200), Color3.fromRGB(40, 200, 160) } },
	{ Id = "Sunset", Name = "Sunset", Price = 1200, Level = 6, Rebirths = 0, Colors = { Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 70, 110) } },
	{ Id = "Ocean", Name = "Ocean", Price = 2500, Level = 10, Rebirths = 0, Colors = { Color3.fromRGB(40, 140, 255), Color3.fromRGB(0, 230, 255) } },
	{ Id = "Toxic", Name = "Toxic", Price = 5000, Level = 15, Rebirths = 1, Colors = { Color3.fromRGB(170, 255, 0), Color3.fromRGB(40, 120, 0) } },
	{ Id = "Inferno", Name = "Inferno", Price = 9000, Level = 20, Rebirths = 2, Colors = { Color3.fromRGB(255, 240, 80), Color3.fromRGB(255, 40, 0) } },
	{ Id = "Galaxy", Name = "Galaxy", Price = 16000, Level = 30, Rebirths = 4, Colors = { Color3.fromRGB(120, 60, 255), Color3.fromRGB(255, 80, 230) } },
	{ Id = "Shadow", Name = "Shadow", Price = 30000, Level = 40, Rebirths = 7, Colors = { Color3.fromRGB(20, 20, 20), Color3.fromRGB(120, 0, 40) } },
}

function Config.GetTrail(id: string)
	for _, trail in Config.Trails do
		if trail.Id == id then
			return trail
		end
	end
	return nil
end

--------------------------------------------------------------------
-- GAME PASSES (achat unique, permanent)
--------------------------------------------------------------------
Config.GamePasses = {
	VIP = {
		Id = 0,
		Name = "VIP",
		Description = "VIP tag above your head and in chat, gold trail, +15% speed.",
		Color = Color3.fromRGB(255, 200, 40),
	},
	Speed = {
		Id = 0,
		Name = "Speed Boost",
		Description = "Run 40% faster on every stage.",
		Color = Color3.fromRGB(60, 170, 255),
	},
	DoubleCoins = {
		Id = 0,
		Name = "2x Coins",
		Description = "Double coins and XP forever. Stacks with rebirths.",
		Color = Color3.fromRGB(255, 150, 40),
	},
	DoubleJump = {
		Id = 0,
		Name = "Double Jump",
		Description = "Jump again in mid-air. Makes hard stages way easier.",
		Color = Color3.fromRGB(140, 255, 120),
	},
	Gravity = {
		Id = 0,
		Name = "Low Gravity",
		Description = "Jump higher on every stage.",
		Color = Color3.fromRGB(190, 120, 255),
	},
	RainbowTrail = {
		Id = 0,
		Name = "Rainbow Trail",
		Description = "A rainbow trail that follows you everywhere.",
		Color = Color3.fromRGB(255, 90, 150),
	},
}

-- Ordre d'affichage dans la boutique
Config.GamePassOrder = { "VIP", "DoubleCoins", "DoubleJump", "Speed", "Gravity", "RainbowTrail" }

-- Bonus appliqués par les passes
Config.BaseWalkSpeed = 16
Config.SpeedPassWalkSpeed = 22.4 -- +40%
Config.VipSpeedMultiplier = 1.15
Config.BaseJumpHeight = 7.2
Config.GravityPassJumpHeight = 11

--------------------------------------------------------------------
-- DEVELOPER PRODUCTS (achats répétables)
--------------------------------------------------------------------
Config.Products = {
	SkipStage = { Id = 0, Kind = "Skip", Amount = 1, Name = "Skip Stage" },
	Skip5 = { Id = 0, Kind = "Skip", Amount = 5, Name = "Skip 5 Stages" },
	Coins1 = { Id = 0, Kind = "Coins", Amount = 2500, Name = "2,500 Coins" },
	Coins2 = { Id = 0, Kind = "Coins", Amount = 15000, Name = "15,000 Coins" },
	Donate10 = { Id = 0, Kind = "Donate", Amount = 10, Name = "Donate 10" },
	Donate100 = { Id = 0, Kind = "Donate", Amount = 100, Name = "Donate 100" },
	Donate1000 = { Id = 0, Kind = "Donate", Amount = 1000, Name = "Donate 1000" },
}
Config.DonationOrder = { "Donate10", "Donate100", "Donate1000" }
Config.CoinPackOrder = { "Coins1", "Coins2" }

--------------------------------------------------------------------
-- BADGES (optionnel, 0 = désactivé)
--------------------------------------------------------------------
Config.Badges = {
	Welcome = 0,
	FirstWorld = 0, -- fin du monde 1
	Finish = 0, -- dernier stage atteint
	FirstRebirth = 0,
	Level10 = 0,
}

--------------------------------------------------------------------
-- DIVERS
--------------------------------------------------------------------
Config.DataStoreName = "SkyRushData_v1"
Config.StageBoardStore = "SkyRushStages_v1"
Config.DonationBoardStore = "SkyRushDonations_v1"
Config.LeaderboardRefresh = 90 -- secondes
Config.AutosaveInterval = 120 -- secondes

-- Mettre à true pour tester tous les passes dans Studio sans les acheter.
-- Ne marche QUE dans Studio, jamais en jeu publié.
Config.StudioGrantAllPasses = false

return Config
