--[[
	Grading Lab. Une carte volée arrive "brute" : il faut la faire grader
	avant de pouvoir l'exposer. La gradation prend du temps (selon la rareté)
	et continue même quand le joueur est déconnecté. À la fin, on tire la note
	de condition (1 à 10) qui multiplie le revenu de la carte.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Cards = require(ReplicatedStorage.Shared.Cards)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local Hub = require(script.Parent.Parent.Hub)

local GradingService = {}

local notified: { [Player]: { [number]: boolean } } = {}

function GradingService.SlotCount(player: Player): number
	local data = DataService.Get(player)
	local n = Config.GradingSlots + (data and data.Rebirths or 0) * Config.GradingSlotsPerRebirth
	if MonetizationService.Owns(player, "MoreGrading") then
		n += 2
	end
	return math.min(n, 10)
end

function GradingService.Duration(player: Player, id: string): number
	local t = Cards.Rarities[Cards.ById[id].Rarity].GradeTime
	if MonetizationService.Owns(player, "FastGrading") then
		t /= 2
	end
	return math.max(1, math.floor(t))
end

local function startNext(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	while #data.Grading < GradingService.SlotCount(player) and #data.Raw > 0 do
		local raw = table.remove(data.Raw, 1)
		table.insert(data.Grading, { Id = raw.Id, F = raw.F, Ends = os.time() + GradingService.Duration(player, raw.Id) })
	end
end

-- Une carte brute arrive au hub (vol réussi, pack...)
function GradingService.Deliver(player: Player, id: string, finish: string)
	local data = DataService.Get(player)
	if not data then
		return
	end
	data.Index[id] = true
	if #data.Grading < GradingService.SlotCount(player) then
		table.insert(data.Grading, { Id = id, F = finish, Ends = os.time() + GradingService.Duration(player, id) })
		Remotes.Notify:FireClient(player, Cards.DisplayName(id, finish) .. " sent to the Grading Lab", "info")
	elseif #data.Raw < Config.MaxRawCards then
		table.insert(data.Raw, { Id = id, F = finish })
		Remotes.Notify:FireClient(player, "Lab busy: " .. Cards.Name(id) .. " is waiting in line", "info")
	else
		local value = math.floor(Cards.SellValue(id, finish, 6) * 0.5)
		data.Cash += value
		player:SetAttribute("Cash", data.Cash)
		Remotes.Notify:FireClient(player, ("Lab full! %s sold for %s"):format(Cards.Name(id), Format.cash(value)), "error")
	end
	Hub.Players.SendState(player)
end

-- Récupère une carte gradée et la met en vitrine
function GradingService.Collect(player: Player, index: number): boolean
	local data = DataService.Get(player)
	local entry = data and data.Grading[index]
	if not entry or entry.Ends > os.time() then
		return false
	end
	if not Hub.Gallery.FreeCase(player) then
		Remotes.Notify:FireClient(player, "Your gallery is full! Sell a card or unlock a case.", "error")
		return false
	end
	local grade = Hub.Loot.RollGrade(MonetizationService.Owns(player, "Lucky"))
	table.remove(data.Grading, index)
	Hub.Gallery.AddCard(player, { Id = entry.Id, F = entry.F, G = grade })
	Remotes.Reveal:FireClient(player, { Id = entry.Id, F = entry.F, G = grade })
	Hub.Players.OnCardGained(player, entry.Id, entry.F, grade)
	startNext(player)
	notified[player] = nil
	return true
end

function GradingService.CollectAll(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local i = 1
	while i <= #data.Grading do
		local entry = data.Grading[i]
		if entry.Ends <= os.time() then
			if not GradingService.Collect(player, i) then
				break
			end
		else
			i += 1
		end
	end
	Hub.Players.SendState(player)
end

-- Lance la gradation d'une carte en attente (si un slot est libre)
function GradingService.StartRaw(player: Player, index: number)
	local data = DataService.Get(player)
	if not data or not data.Raw[index] then
		return
	end
	if #data.Grading >= GradingService.SlotCount(player) then
		Remotes.Notify:FireClient(player, "All grading slots are busy", "error")
		return
	end
	local raw = table.remove(data.Raw, index)
	table.insert(data.Grading, { Id = raw.Id, F = raw.F, Ends = os.time() + GradingService.Duration(player, raw.Id) })
	Hub.Players.SendState(player)
end

function GradingService.SellRaw(player: Player, index: number)
	local data = DataService.Get(player)
	local raw = data and data.Raw[index]
	if not raw then
		return
	end
	table.remove(data.Raw, index)
	local value = math.floor(Cards.SellValue(raw.Id, raw.F, 6) * 0.5)
	data.Cash += value
	player:SetAttribute("Cash", data.Cash)
	Remotes.Notify:FireClient(player, ("Sold raw %s for %s"):format(Cards.Name(raw.Id), Format.cash(value)), "cash")
	Hub.Players.SendState(player)
end

-- Produit Robux "Grade All Now"
function GradingService.FinishAll(player: Player): boolean
	local data = DataService.Get(player)
	if not data then
		return false
	end
	startNext(player)
	for _, entry in data.Grading do
		entry.Ends = os.time()
	end
	Hub.Players.SendState(player)
	return true
end

function GradingService.Start()
	-- prévient le joueur quand une carte est prête
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in game:GetService("Players"):GetPlayers() do
				local data = DataService.Get(player)
				if data then
					startNext(player)
					local seen = notified[player] or {}
					notified[player] = seen
					for i, entry in data.Grading do
						if entry.Ends <= os.time() and not seen[i] then
							seen[i] = true
							Remotes.Notify:FireClient(player, Cards.Name(entry.Id) .. " is graded! Collect it at the lab", "reward")
							Hub.Players.SendState(player)
						end
					end
				end
			end
		end
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		notified[player] = nil
	end)
end

return GradingService
