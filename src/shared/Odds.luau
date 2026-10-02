--[[
	Chances d'apparition des cartes dans chaque boutique.
	Une boutique tire d'abord une rareté (poids de Config.Zones[i].Rarity),
	puis une carte au hasard parmi les cartes de cette rareté.
	Les cartes de saison n'apparaissent que pendant leur event.
]]

local Config = require(script.Parent.Config)
local Cards = require(script.Parent.Cards)

local Odds = {}

local poolSize: { [string]: number } = {}
local seasonPool: { [string]: number } = {}
for _, c in Cards.List do
	if c.Season then
		local key = c.Season .. ":" .. c.Rarity
		seasonPool[key] = (seasonPool[key] or 0) + 1
	else
		poolSize[c.Rarity] = (poolSize[c.Rarity] or 0) + 1
	end
end

-- probabilité (0..1) qu'un présentoir de la boutique zone affiche cette carte
function Odds.chance(cardId: string, zone: number): number
	local card = Cards.ById[cardId]
	local z = Config.Zones[zone]
	if not card or not z then
		return 0
	end
	local total = 0
	for _, w in z.Rarity do
		total += w
	end
	local w = z.Rarity[card.Rarity] or 0
	if w <= 0 or total <= 0 then
		return 0
	end
	if card.Season then
		local share = Cards.Seasons[card.Season].Share or 0
		return w / total * share / (seasonPool[card.Season .. ":" .. card.Rarity] or 1)
	end
	return w / total / (poolSize[card.Rarity] or 1)
end

-- première boutique où la carte peut apparaître, et la boutique où c'est le plus probable
function Odds.where(cardId: string): (number?, number?, number)
	local first, best, bestChance = nil, nil, 0
	for i in Config.Zones do
		local c = Odds.chance(cardId, i)
		if c > 0 then
			first = first or i
			if c > bestChance then
				best, bestChance = i, c
			end
		end
	end
	return first, best, bestChance
end

-- "1 in 250" ou "12%"
function Odds.text(p: number): string
	if p <= 0 then
		return "-"
	end
	if p >= 0.01 then
		local pct = p * 100
		return (pct >= 10 and "%d%%" or "%.1f%%"):format(pct)
	end
	local n = 1 / p
	if n >= 1e6 then
		return ("1 in %.1fM"):format(n / 1e6)
	elseif n >= 1e4 then
		return ("1 in %dK"):format(math.floor(n / 1e3 + 0.5))
	end
	return ("1 in %d"):format(math.floor(n + 0.5))
end

return Odds
