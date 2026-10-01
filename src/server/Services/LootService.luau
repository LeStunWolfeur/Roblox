-- Tirages au sort : rareté, carte, finition, note de condition

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cards = require(ReplicatedStorage.Shared.Cards)
local Hub = require(script.Parent.Parent.Hub)

local LootService = {}

local rng = Random.new()

local function weightedPick(weights: { [string]: number }): string
	local total = 0
	for _, w in weights do
		total += w
	end
	local roll = rng:NextNumber() * total
	local last
	for _, name in Cards.RarityOrder do
		local w = weights[name]
		if w then
			last = name
			roll -= w
			if roll <= 0 then
				return name
			end
		end
	end
	return last
end

-- weights = { Common = 80, ... } ; la chance multiplie les raretés Rare et plus
function LootService.RollRarity(weights: { [string]: number }, luck: number): string
	local adjusted = {}
	for name, w in weights do
		adjusted[name] = Cards.Rarities[name].Order >= 3 and w * luck or w
	end
	return weightedPick(adjusted)
end

local function poolFor(rarity: string, season: string?)
	local pool = {}
	for _, c in Cards.List do
		if c.Rarity == rarity and c.Season == season then
			table.insert(pool, c.Id)
		end
	end
	return pool
end

function LootService.RollCard(rarity: string): string
	local season = Hub.Events.Season()
	if season and rng:NextNumber() < Cards.Seasons[season].Share then
		local pool = poolFor(rarity, season)
		if #pool > 0 then
			return pool[rng:NextInteger(1, #pool)]
		end
	end
	local pool = poolFor(rarity, nil)
	return pool[rng:NextInteger(1, #pool)]
end

function LootService.RollFinish(): string
	local boosts = Hub.Events.FinishBoosts()
	local season = Hub.Events.Season()
	for _, name in Cards.FinishRollOrder do
		local f = Cards.Finishes[name]
		if not f.Season or f.Season == season then
			if rng:NextNumber() < f.Chance * (boosts[name] or 1) then
				return name
			end
		end
	end
	return "Normal"
end

function LootService.RollGrade(lucky: boolean): number
	local function roll()
		local total = 0
		for _, w in Cards.GradeWeights do
			total += w
		end
		local r = rng:NextNumber() * total
		for grade, w in Cards.GradeWeights do
			r -= w
			if r <= 0 then
				return grade
			end
		end
		return 6
	end
	local g = roll()
	if lucky then
		g = math.max(g, roll())
	end
	return g
end

function LootService.Random(): Random
	return rng
end

return LootService
