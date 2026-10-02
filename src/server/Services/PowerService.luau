--[[
	Cartes pouvoir (Config.PowerCards) et traînées (Config.Trails).
	- Les cartes pouvoir sortent des packs. Un double fait monter la carte d'un niveau.
	- On en équipe un nombre limité (Config.PowerSlots) dans la fenêtre Cards.
	- Bonus(player, effet) additionne les effets des cartes équipées.
	- Les traînées s'achètent dans l'ordre (fenêtre Upgrades) ; la meilleure est équipée.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local Hub = require(script.Parent.Parent.Hub)

local PowerService = {}

function PowerService.Slots(player: Player): number
	local data = DataService.Get(player)
	return Config.PowerSlots(data and data.Rebirths or 0, MonetizationService.Owns(player, "ExtraEquip"))
end

function PowerService.Level(data, id: string): number
	return math.min(Config.PowerMaxLevel, data.Powers[id] or 0)
end

-- Somme d'un effet sur les cartes équipées (niveau compris)
function PowerService.Bonus(player: Player, effect: string): number
	local data = DataService.Get(player)
	if not data then
		return 0
	end
	local total = 0
	for _, id in data.Equipped do
		local def = Config.PowerById[id]
		local lv = PowerService.Level(data, id)
		if def and lv > 0 and def.Effects[effect] then
			local value = def.Effects[effect]
			if effect == "Grade" then
				total += value -- tirages en plus : pas d'effet de niveau
			else
				total += value * (1 + (lv - 1) * Config.PowerLevelBonus)
			end
		end
	end
	return total
end

local function refresh(player: Player)
	Hub.Combat.UpdateSpeed(player)
	Hub.Players.SendState(player)
end

-- Donne une carte pouvoir. Renvoie { Id, Level, New }
function PowerService.Give(player: Player, id: string)
	local data = DataService.Get(player)
	if not data or not Config.PowerById[id] then
		return nil
	end
	local before = data.Powers[id] or 0
	data.Powers[id] = before + 1
	-- première carte : on l'équipe tout de suite s'il reste une place
	if before == 0 and #data.Equipped < PowerService.Slots(player) then
		table.insert(data.Equipped, id)
	end
	refresh(player)
	return { Id = id, Level = PowerService.Level(data, id), New = before == 0 }
end

-- Tire une carte pouvoir selon les chances d'un pack
function PowerService.Roll(odds: { [string]: number }): string
	local rarity = Hub.Loot.RollRarity(odds, 1)
	local pool = {}
	for _, p in Config.PowerCards do
		if p.Rarity == rarity then
			table.insert(pool, p.Id)
		end
	end
	if #pool == 0 then
		return Config.PowerCards[1].Id
	end
	return pool[Hub.Loot.Random():NextInteger(1, #pool)]
end

function PowerService.Equip(player: Player, id: string)
	local data = DataService.Get(player)
	if not data or (data.Powers[id] or 0) <= 0 then
		return
	end
	for i, e in data.Equipped do
		if e == id then
			table.remove(data.Equipped, i)
			refresh(player)
			return
		end
	end
	if #data.Equipped >= PowerService.Slots(player) then
		Remotes.Notify:FireClient(player, "All power slots are full. Unequip a card first.", "error")
		return
	end
	table.insert(data.Equipped, id)
	refresh(player)
end

-- Multiplicateur de Speed de la traînée équipée
function PowerService.TrailMult(player: Player): number
	local data = DataService.Get(player)
	local t = data and Config.Trails[data.Trail or 0]
	return t and t.Mult or 1
end

function PowerService.BuyTrail(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local nextIndex = (data.Trail or 0) + 1
	local trail = Config.Trails[nextIndex]
	if not trail then
		Remotes.Notify:FireClient(player, "You already have the best trail", "error")
		return
	end
	if data.Cash < trail.Price then
		Remotes.Notify:FireClient(player, "You need " .. Format.cash(trail.Price), "error")
		return
	end
	data.Cash -= trail.Price
	player:SetAttribute("Cash", data.Cash)
	data.Trail = nextIndex
	player:SetAttribute("Trail", nextIndex)
	Remotes.Notify:FireClient(player, ("%s equipped! x%s Speed"):format(trail.Name, tostring(trail.Mult)), "reward")
	PowerService.ApplyTrail(player)
	refresh(player)
end

-- Traînée achetée : créée côté serveur pour que tout le monde la voie
function PowerService.ApplyTrail(player: Player)
	local data = DataService.Get(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not data or not root then
		return
	end
	local old = root:FindFirstChild("BoughtTrail")
	if old then
		old:Destroy()
	end
	local def = Config.Trails[data.Trail or 0]
	if not def then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Name = "BoughtTrailTop"
	a0.Position = Vector3.new(0, 1.3, 0.4)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Name = "BoughtTrailBottom"
	a1.Position = Vector3.new(0, -1.7, 0.4)
	a1.Parent = root
	local t = Instance.new("Trail")
	t.Name = "BoughtTrail"
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Lifetime = 0.45
	t.LightEmission = 0.7
	t.Transparency = NumberSequence.new(0.2, 1)
	t.WidthScale = NumberSequence.new(1, 0.15)
	if def.Rainbow then
		local keys = {}
		for i = 0, 6 do
			table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.75, 1)))
		end
		t.Color = ColorSequence.new(keys)
	else
		t.Color = ColorSequence.new(def.Color, def.Color:Lerp(Color3.new(1, 1, 1), 0.5))
	end
	t.Parent = root
end

-- garde les cartes équipées valides (emplacements perdus, cartes inconnues)
function PowerService.Clean(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local slots = PowerService.Slots(player)
	local seen = {}
	for i = #data.Equipped, 1, -1 do
		local id = data.Equipped[i]
		if not Config.PowerById[id] or (data.Powers[id] or 0) <= 0 or seen[id] then
			table.remove(data.Equipped, i)
		else
			seen[id] = true
		end
	end
	while #data.Equipped > slots do
		table.remove(data.Equipped)
	end
	player:SetAttribute("Trail", data.Trail or 0)
end

return PowerService
