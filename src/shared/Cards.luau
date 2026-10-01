--[[
	Catalogue des cartes : raretés, finitions, notes de condition, sets saisonniers.

	Pour mettre une vraie illustration sur une carte : importe une image dans
	Studio (ou sur create.roblox.com), copie son ID et mets-le dans Image,
	par exemple Image = "rbxassetid://1234567890".
	Sans image, la carte a un design généré (couleurs + monogramme).
]]

local Cards = {}

--------------------------------------------------------------------
-- RARETÉS (GradeTime = secondes de gradation au labo)
--------------------------------------------------------------------
Cards.Rarities = {
	Common = { Order = 1, Name = "Common", Color = Color3.fromRGB(180, 185, 195), GradeTime = 20 },
	Uncommon = { Order = 2, Name = "Uncommon", Color = Color3.fromRGB(90, 210, 120), GradeTime = 45 },
	Rare = { Order = 3, Name = "Rare", Color = Color3.fromRGB(70, 150, 255), GradeTime = 90 },
	Epic = { Order = 4, Name = "Epic", Color = Color3.fromRGB(170, 90, 255), GradeTime = 180 },
	Legendary = { Order = 5, Name = "Legendary", Color = Color3.fromRGB(255, 180, 30), GradeTime = 360 },
	Mythic = { Order = 6, Name = "Mythic", Color = Color3.fromRGB(255, 60, 110), GradeTime = 720 },
	Secret = { Order = 7, Name = "Secret", Color = Color3.fromRGB(20, 20, 20), GradeTime = 1500 },
}
Cards.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

--------------------------------------------------------------------
-- FINITIONS (multiplient le revenu, tirées quand la carte apparaît en boutique)
-- Chance = probabilité de base. Season = finition réservée à une saison.
--------------------------------------------------------------------
Cards.Finishes = {
	Normal = { Name = "", Mult = 1, Chance = 0 },
	Holo = { Name = "Holo", Mult = 1.5, Chance = 0.08, Color = Color3.fromRGB(150, 230, 255) },
	Gold = { Name = "Gold", Mult = 2.5, Chance = 0.03, Color = Color3.fromRGB(255, 200, 50) },
	Rainbow = { Name = "Rainbow", Mult = 5, Chance = 0.007, Color = Color3.fromRGB(255, 120, 200) },
	DarkMatter = { Name = "Dark Matter", Mult = 10, Chance = 0.001, Color = Color3.fromRGB(110, 40, 200) },
	Haunted = { Name = "Haunted", Mult = 4, Chance = 0.02, Color = Color3.fromRGB(255, 120, 20), Season = "Halloween" },
	Frozen = { Name = "Frozen", Mult = 4, Chance = 0.02, Color = Color3.fromRGB(170, 240, 255), Season = "Winter" },
}
-- ordre de tirage : de la plus rare à la plus commune
Cards.FinishRollOrder = { "DarkMatter", "Rainbow", "Haunted", "Frozen", "Gold", "Holo" }

--------------------------------------------------------------------
-- NOTE DE CONDITION (comme une carte gradée PSA), tirée à l'achat
--------------------------------------------------------------------
Cards.GradeWeights = { 2, 3, 5, 8, 12, 16, 20, 17, 12, 5 } -- notes 1 à 10
Cards.GradeMult = { 0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.1, 1.25, 1.5, 2.5 }
Cards.GradeNames = {
	"Poor", "Fair", "Good", "Very Good", "Fine", "Excellent", "Near Mint", "Mint", "Gem", "GEM MINT",
}

--------------------------------------------------------------------
-- SAISONS : les cartes saisonnières n'apparaissent que pendant la fenêtre.
-- Après, celles que les joueurs possèdent deviennent introuvables.
-- Dates en UTC, { mois, jour }. Une fenêtre peut passer le Nouvel An.
--------------------------------------------------------------------
Cards.Seasons = {
	Halloween = {
		Name = "Spooky Set",
		From = { 10, 1 },
		To = { 11, 5 },
		Share = 0.18, -- part des apparitions réservée aux cartes du set
		Lighting = { ClockTime = 19.6, Atmosphere = Color3.fromRGB(255, 140, 60) },
	},
	Winter = {
		Name = "Frost Set",
		From = { 12, 10 },
		To = { 1, 8 },
		Share = 0.18,
		Lighting = { ClockTime = 9, Atmosphere = Color3.fromRGB(200, 230, 255) },
	},
	Spring = {
		Name = "Bloom Set",
		From = { 3, 20 },
		To = { 4, 25 },
		Share = 0.15,
		Lighting = { ClockTime = 13, Atmosphere = Color3.fromRGB(255, 210, 230) },
	},
	Summer = {
		Name = "Heatwave Set",
		From = { 6, 21 },
		To = { 8, 20 },
		Share = 0.15,
		Lighting = { ClockTime = 14, Atmosphere = Color3.fromRGB(255, 230, 170) },
	},
}

--------------------------------------------------------------------
-- LES CARTES
-- Income = cash par seconde une fois gradée et exposée
-- A/B = couleurs du design généré
--------------------------------------------------------------------
local function card(id, name, rarity, income, a, b, season)
	return {
		Id = id,
		Name = name,
		Rarity = rarity,
		Income = income,
		A = a,
		B = b,
		Season = season,
		Image = "",
	}
end

local rgb = Color3.fromRGB

Cards.List = {
	-- Common
	card("toastini", "Toastini", "Common", 1, rgb(240, 190, 110), rgb(160, 90, 40)),
	card("sockrates", "Sockrates", "Common", 2, rgb(230, 230, 240), rgb(120, 120, 160)),
	card("bloop", "Bloop", "Common", 2, rgb(120, 220, 255), rgb(40, 110, 200)),
	card("pebblepete", "Pebble Pete", "Common", 3, rgb(170, 170, 160), rgb(90, 90, 85)),
	card("mrnoodle", "Mr. Noodle", "Common", 4, rgb(255, 225, 120), rgb(220, 140, 40)),
	card("cardboardcarl", "Cardboard Carl", "Common", 5, rgb(205, 160, 110), rgb(130, 90, 50)),
	card("wobbles", "Wobbles", "Common", 6, rgb(255, 150, 200), rgb(200, 60, 130)),

	-- Uncommon
	card("spaghettron", "Spaghettron", "Uncommon", 10, rgb(255, 200, 90), rgb(220, 60, 40)),
	card("bananaut", "Bananaut", "Uncommon", 14, rgb(255, 235, 80), rgb(80, 80, 120)),
	card("cactuso", "Cactuso", "Uncommon", 18, rgb(120, 210, 90), rgb(240, 200, 120)),
	card("duckmaster", "Duckmaster", "Uncommon", 23, rgb(255, 220, 60), rgb(255, 130, 30)),
	card("jellybyte", "Jellybyte", "Uncommon", 30, rgb(140, 255, 220), rgb(60, 120, 255)),

	-- Rare
	card("captaincrumb", "Captain Crumb", "Rare", 60, rgb(60, 90, 200), rgb(255, 210, 120)),
	card("turbotortellini", "Turbo Tortellini", "Rare", 85, rgb(255, 90, 60), rgb(255, 230, 150)),
	card("neonnana", "Neon Nana", "Rare", 110, rgb(255, 60, 200), rgb(60, 255, 230)),
	card("sirpickles", "Sir Pickles", "Rare", 140, rgb(110, 170, 60), rgb(40, 70, 30)),
	card("glitchygus", "Glitchy Gus", "Rare", 180, rgb(0, 255, 140), rgb(30, 30, 40)),

	-- Epic
	card("pizzasaurus", "Pizzasaurus", "Epic", 400, rgb(255, 120, 50), rgb(90, 160, 60)),
	card("roboraccoon", "Robo Raccoon", "Epic", 600, rgb(150, 160, 180), rgb(40, 50, 70)),
	card("thundertaco", "Thunder Taco", "Epic", 850, rgb(255, 220, 60), rgb(90, 60, 200)),
	card("moonmoo", "Moonmoo", "Epic", 1200, rgb(220, 220, 255), rgb(60, 60, 140)),

	-- Legendary
	card("kingcroissant", "King Croissant", "Legendary", 3500, rgb(240, 180, 90), rgb(180, 40, 60)),
	card("dragonfruitdrake", "Dragonfruit Drake", "Legendary", 5500, rgb(255, 60, 150), rgb(120, 230, 90)),
	card("cybershiba", "Cyber Shiba", "Legendary", 8000, rgb(255, 170, 80), rgb(0, 220, 255)),
	card("maestromeatball", "Maestro Meatball", "Legendary", 12000, rgb(150, 70, 40), rgb(255, 240, 220)),

	-- Mythic
	card("galacticat", "Galacti-Cat", "Mythic", 60000, rgb(40, 20, 90), rgb(255, 120, 230)),
	card("overlordonion", "Overlord Onion", "Mythic", 110000, rgb(200, 120, 220), rgb(60, 20, 60)),
	card("goldengoose", "The Golden Goose", "Mythic", 200000, rgb(255, 215, 80), rgb(255, 250, 220)),

	-- Secret
	card("omegatoaster", "Omega Toaster", "Secret", 1500000, rgb(30, 30, 30), rgb(255, 80, 30)),
	card("cardzero", "Card Zero", "Secret", 5000000, rgb(10, 10, 10), rgb(255, 255, 255)),

	-- Halloween (Spooky Set)
	card("pumpking", "Pumpking", "Rare", 150, rgb(255, 130, 20), rgb(40, 20, 50), "Halloween"),
	card("countspudula", "Count Spudula", "Epic", 1000, rgb(150, 20, 40), rgb(230, 200, 150), "Halloween"),
	card("ghostini", "Ghostini", "Legendary", 7500, rgb(240, 240, 255), rgb(120, 80, 200), "Halloween"),
	card("witchywhiskers", "Witchy Whiskers", "Legendary", 10500, rgb(90, 40, 140), rgb(120, 255, 90), "Halloween"),
	card("skeleboi", "Skeleboi", "Mythic", 150000, rgb(240, 240, 230), rgb(30, 30, 30), "Halloween"),
	card("hollowcard", "The Hollow Card", "Secret", 3500000, rgb(20, 0, 30), rgb(255, 120, 0), "Halloween"),

	-- Winter (Frost Set)
	card("frostbitefred", "Frostbite Fred", "Rare", 150, rgb(170, 230, 255), rgb(40, 90, 160), "Winter"),
	card("jinglejelly", "Jingle Jelly", "Epic", 1000, rgb(220, 40, 60), rgb(40, 180, 90), "Winter"),
	card("snowmancer", "Snowmancer", "Legendary", 9500, rgb(240, 250, 255), rgb(90, 140, 255), "Winter"),
	card("polarpudding", "Polar Pudding", "Mythic", 150000, rgb(255, 250, 240), rgb(120, 200, 255), "Winter"),

	-- Spring (Bloom Set)
	card("petalpup", "Petal Pup", "Rare", 150, rgb(255, 180, 210), rgb(120, 200, 120), "Spring"),
	card("bunnybun", "Bunny Bun", "Epic", 1000, rgb(255, 240, 220), rgb(255, 150, 190), "Spring"),
	card("bloomlord", "Bloom Lord", "Legendary", 9500, rgb(255, 120, 180), rgb(60, 160, 80), "Spring"),

	-- Summer (Heatwave Set)
	card("surfslug", "Surf Slug", "Rare", 150, rgb(60, 200, 255), rgb(255, 230, 120), "Summer"),
	card("sunnysundae", "Sunny Sundae", "Epic", 1000, rgb(255, 200, 220), rgb(255, 120, 60), "Summer"),
	card("lavalamp", "Lava Lamp Larry", "Legendary", 9500, rgb(255, 80, 40), rgb(255, 220, 60), "Summer"),
}

Cards.ById = {}
for _, c in Cards.List do
	Cards.ById[c.Id] = c
end

-- Revenu réel d'une carte possédée
function Cards.IncomeOf(id: string, finish: string?, grade: number?): number
	local c = Cards.ById[id]
	if not c then
		return 0
	end
	local f = Cards.Finishes[finish or "Normal"] or Cards.Finishes.Normal
	local g = Cards.GradeMult[grade or 6] or 1
	return c.Income * f.Mult * g
end

-- Prix de revente : 90 secondes de revenu
function Cards.SellValue(id: string, finish: string?, grade: number?): number
	return math.floor(Cards.IncomeOf(id, finish, grade) * 90)
end

-- Saison active à une date donnée (os.date("!*t") côté serveur)
function Cards.ActiveSeason(now: { month: number, day: number }): string?
	local today = now.month * 100 + now.day
	for id, s in Cards.Seasons do
		local from = s.From[1] * 100 + s.From[2]
		local to = s.To[1] * 100 + s.To[2]
		if from <= to then
			if today >= from and today <= to then
				return id
			end
		elseif today >= from or today <= to then
			return id
		end
	end
	return nil
end

function Cards.Name(id: string): string
	local c = Cards.ById[id]
	return c and c.Name or "?"
end

function Cards.DisplayName(id: string, finish: string?): string
	local c = Cards.ById[id]
	local f = Cards.Finishes[finish or "Normal"]
	if not c then
		return "?"
	end
	if f and f.Name ~= "" then
		return f.Name .. " " .. c.Name
	end
	return c.Name
end

return Cards
