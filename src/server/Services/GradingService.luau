--[[
	Stand GRADING LAB (au bout de la rue des bases).
	On apporte une carte dans ses mains (ramassée sur un support), on paie,
	la note (1 à 10) tombe tout de suite. Le prix dépend du revenu de la carte
	(Config.GradeCost). Une carte déjà notée peut être regradée : la nouvelle note
	remplace l'ancienne, c'est un pari.
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

function GradingService.Cost(player: Player, id: string, finish: string?): number
	-- prix calculé sur le revenu de la carte sans note
	return Config.GradeCost(Cards.IncomeOf(id, finish, nil), MonetizationService.Owns(player, "CheapGrading"))
end

-- Garde l'ancien nom : donner une carte = la poser dans la base
function GradingService.Deliver(player: Player, id: string, finish: string)
	return Hub.Gallery.Give(player, id, finish, nil)
end

function GradingService.GradeHeld(player: Player): boolean
	local data = DataService.Get(player)
	local held = Hub.Zones.GetCarry(player)
	if not data or not held then
		Remotes.Notify:FireClient(player, "Pick up a card from your base first", "error")
		return false
	end
	local cost = GradingService.Cost(player, held.Id, held.F)
	if data.Cash < cost then
		Remotes.Notify:FireClient(player, "Grading costs " .. Format.cash(cost), "error")
		return false
	end
	data.Cash -= cost
	player:SetAttribute("Cash", data.Cash)
	local grade = Hub.Loot.RollGrade(MonetizationService.TierMult(player, Config.LuckTiers) + Hub.Powers.Bonus(player, "Grade"))
	local before = held.G
	Hub.Zones.SetCarry(player, { Id = held.Id, F = held.F, G = grade, Zone = held.Zone })
	Remotes.Reveal:FireClient(player, { Id = held.Id, F = held.F, G = grade, Before = before })
	if grade == 10 then
		Hub.Players.Badge(player, "GemMint")
		Remotes.Announce:FireAllClients("GEM MINT 10!", player.DisplayName .. " graded " .. Cards.DisplayName(held.Id, held.F), "Legendary")
	end
	Hub.Players.SendState(player)
	return true
end

function GradingService.Start() end

return GradingService
