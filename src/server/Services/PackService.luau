--[[
	Stand PACKS (au bout de la rue des bases).
	- Le stock change toutes les 5 minutes. Il est tiré à partir du numéro de cycle,
	  donc c'est le même dans tous les serveurs (comme les shops à restock des jeux du genre).
	- Chaque joueur peut acheter les packs en stock pendant le cycle.
	- Chaque pack ouvert sans Legendary ou mieux augmente la chance des suivants
	  (Config.PackLuckStep, jusqu'à Config.PackLuckMax). Elle retombe à 0 sur un gros tirage.
	- Les packs Gold et plus donnent aussi +20% de cash pendant 10 minutes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Cards = require(ReplicatedStorage.Shared.Cards)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local Hub = require(script.Parent.Parent.Hub)

local PackService = {}

function PackService.Cycle(): number
	return math.floor(os.time() / Config.PackRestockTime)
end

function PackService.NextRestock(): number
	return (PackService.Cycle() + 1) * Config.PackRestockTime
end

-- stock du cycle : identique partout (graine = numéro du cycle)
local stockCache: { [number]: { [string]: number } } = {}
function PackService.Stock(cycle: number): { [string]: number }
	if stockCache[cycle] then
		return stockCache[cycle]
	end
	local rng = Random.new(cycle * 7919 + 17)
	local stock = {}
	for _, key in Config.PackOrder do
		local pack = Config.Packs[key]
		if rng:NextNumber() < pack.InStock then
			stock[key] = rng:NextInteger(pack.Stock[1], pack.Stock[2])
		else
			stock[key] = 0
		end
	end
	stockCache = { [cycle] = stock }
	return stock
end

function PackService.Remaining(player: Player): { [string]: number }
	local data = DataService.Get(player)
	local cycle = PackService.Cycle()
	local stock = PackService.Stock(cycle)
	local out = {}
	if data and data.PackCycle ~= cycle then
		data.PackCycle = cycle
		data.PackBought = {}
	end
	for key, n in stock do
		local bought = data and data.PackBought[key] or 0
		out[key] = math.max(0, n - bought)
	end
	return out
end

-- Tire et donne les cartes d'un pack (sans payer). Renvoie la liste des cartes.
function PackService.Open(player: Player, key: string)
	local data = DataService.Get(player)
	local pack = Config.Packs[key]
	if not data or not pack then
		return nil
	end
	local rng = Hub.Loot.Random()
	local count = 1 + ((rng:NextNumber() < pack.BonusChance) and 1 or 0)
	local luck = (1 + data.PackLuck + Hub.Powers.Bonus(player, "Luck")) * Config.PackLuckFromTier(MonetizationService.TierMult(player, Config.LuckTiers))
	local cards = {}
	local best = 0
	for _ = 1, count do
		local rarity = Hub.Loot.RollRarity(pack.Odds, luck)
		local id = Hub.Loot.RollCard(rarity)
		local finish = Hub.Loot.RollFinish()
		table.insert(cards, { Id = id, F = finish })
		best = math.max(best, Cards.Rarities[rarity].Order)
		Hub.Gallery.Give(player, id, finish, nil)
	end
	-- carte pouvoir
	local power = nil
	if pack.PowerChance and rng:NextNumber() < pack.PowerChance then
		power = Hub.Powers.Give(player, Hub.Powers.Roll(pack.PowerOdds))
	end
	-- chance des prochains packs
	if best >= Cards.Rarities.Legendary.Order then
		data.PackLuck = 0
	else
		data.PackLuck = math.min(Config.PackLuckMax, data.PackLuck + Config.PackLuckStep)
	end
	if pack.CashBoost then
		local now = os.time()
		local untilT = math.max(player:GetAttribute("CashBoostUntil") or 0, now) + Config.PackCashBoostTime
		player:SetAttribute("CashBoostUntil", untilT)
	end
	Remotes.PackOpened:FireClient(player, { Pack = key, Cards = cards, Luck = data.PackLuck, Bonus = count > 1, Power = power })
	if best >= Cards.Rarities.Mythic.Order then
		local top = cards[1]
		for _, c in cards do
			if Cards.Rarities[Cards.ById[c.Id].Rarity].Order > Cards.Rarities[Cards.ById[top.Id].Rarity].Order then
				top = c
			end
		end
		local r = Cards.ById[top.Id].Rarity
		Remotes.Announce:FireAllClients(r:upper() .. " PULL!", player.DisplayName .. " opened " .. Cards.DisplayName(top.Id, top.F), r)
	end
	Hub.Players.SendState(player)
	return cards
end

function PackService.Buy(player: Player, key: string)
	local data = DataService.Get(player)
	local pack = Config.Packs[key]
	if not data or not pack then
		return
	end
	local remaining = PackService.Remaining(player)
	if (remaining[key] or 0) <= 0 then
		Remotes.Notify:FireClient(player, pack.Name .. " is out of stock", "error")
		return
	end
	if data.Cash < pack.Price then
		Remotes.Notify:FireClient(player, "You need " .. Format.cash(pack.Price), "error")
		return
	end
	data.Cash -= pack.Price
	player:SetAttribute("Cash", data.Cash)
	data.PackBought[key] = (data.PackBought[key] or 0) + 1
	PackService.Open(player, key)
end

-- Produit Robux "Restock Packs" : le stock du joueur se remplit
function PackService.RestockFor(player: Player): boolean
	local data = DataService.Get(player)
	if not data then
		return false
	end
	data.PackCycle = PackService.Cycle()
	data.PackBought = {}
	Remotes.Notify:FireClient(player, "Packs restocked!", "reward")
	Hub.Players.SendState(player)
	return true
end

return PackService
