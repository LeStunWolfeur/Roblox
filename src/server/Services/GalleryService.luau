-- Galeries des joueurs : vitrines, cartes exposées, cash produit, collecte, déblocage de vitrines

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Cards = require(ReplicatedStorage.Shared.Cards)
local CardArt = require(ReplicatedStorage.Shared.CardArt)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local Hub = require(script.Parent.Parent.Hub)
local Showcase = require(script.Parent.Parent.World.Showcase)

local GalleryService = {}

local galleries = {}
local galleryOf: { [Player]: any } = {}
local state: { [any]: { owner: Player?, pending: number, cardParts: { [number]: BasePart } } } = {}

--------------------------------------------------------------------
-- Infos
--------------------------------------------------------------------
function GalleryService.Get(player: Player)
	return galleryOf[player]
end

function GalleryService.CaseCount(player: Player): number
	local data = DataService.Get(player)
	return data and math.min(data.Cases, Config.GalleryMaxCases) or Config.GalleryStartCases
end

function GalleryService.CardAt(player: Player, case: number)
	local data = DataService.Get(player)
	if not data then
		return nil
	end
	for i, c in data.Cards do
		if c.S == case then
			return c, i
		end
	end
	return nil
end

function GalleryService.FreeCase(player: Player): number?
	for case = 1, GalleryService.CaseCount(player) do
		if not GalleryService.CardAt(player, case) then
			return case
		end
	end
	return nil
end

function GalleryService.RawIncome(player: Player): number
	local data = DataService.Get(player)
	if not data then
		return 0
	end
	local total = 0
	for _, c in data.Cards do
		total += Cards.IncomeOf(c.Id, c.F, c.G)
	end
	return total
end

function GalleryService.Income(player: Player): number
	return GalleryService.RawIncome(player) * Hub.Players.CashMultiplier(player)
end

function GalleryService.Pending(player: Player): number
	local g = galleryOf[player]
	return g and state[g].pending or 0
end

--------------------------------------------------------------------
-- Affichage
--------------------------------------------------------------------
local function renderCase(gallery, index: number)
	local s = state[gallery]
	local case = gallery.Cases[index]
	local old = s.cardParts[index]
	if old then
		old:Destroy()
		s.cardParts[index] = nil
	end
	local plinth = case.Plinth
	for _, attr in { "CardId", "Finish", "Grade", "Value", "Cost" } do
		plinth:SetAttribute(attr, nil)
	end

	local owner = s.owner
	Showcase.style(case.Show, nil)
	if not owner then
		plinth:SetAttribute("Locked", nil)
		case.Show.Top.Color = Color3.fromRGB(150, 150, 165)
		case.Label.Text = ""
		return
	end

	local unlocked = index <= GalleryService.CaseCount(owner)
	plinth:SetAttribute("Locked", not unlocked)
	case.Show.Top.Color = unlocked and Color3.fromRGB(235, 235, 245) or Color3.fromRGB(110, 110, 125)
	if not unlocked then
		-- seule la prochaine vitrine est achetable
		if index == GalleryService.CaseCount(owner) + 1 then
			local cost = Config.CaseCost(GalleryService.CaseCount(owner))
			plinth:SetAttribute("Cost", cost)
			case.Label.Text = "UNLOCK " .. Format.cash(cost)
			case.Label.TextColor3 = Color3.fromRGB(255, 210, 60)
		else
			case.Label.Text = "LOCKED"
			case.Label.TextColor3 = Color3.fromRGB(150, 150, 165)
		end
		return
	end

	local c = GalleryService.CardAt(owner, index)
	if not c then
		case.Label.Text = "EMPTY"
		case.Label.TextColor3 = Color3.fromRGB(150, 150, 165)
		return
	end
	local part = CardArt.part(c.Id, c.F, c.G, false)
	part.CFrame = case.CardCFrame
	part.Parent = gallery.Folder
	CollectionService:AddTag(part, "DisplayCard")
	s.cardParts[index] = part
	plinth:SetAttribute("CardId", c.Id)
	plinth:SetAttribute("Finish", c.F)
	plinth:SetAttribute("Grade", c.G)
	plinth:SetAttribute("Value", Cards.SellValue(c.Id, c.F, c.G))
	Showcase.style(case.Show, Cards.ById[c.Id].Rarity)
	case.Label.Text = "+" .. Format.cash(Cards.IncomeOf(c.Id, c.F, c.G) * Hub.Players.CashMultiplier(owner)) .. "/s"
	case.Label.TextColor3 = Color3.fromRGB(80, 230, 140)
end

function GalleryService.Render(player: Player)
	local g = galleryOf[player]
	if g then
		for i = 1, #g.Cases do
			renderCase(g, i)
		end
	end
end

--------------------------------------------------------------------
-- Cartes
--------------------------------------------------------------------
function GalleryService.AddCard(player: Player, card): number?
	local data = DataService.Get(player)
	local case = GalleryService.FreeCase(player)
	if not data or not case then
		return nil
	end
	table.insert(data.Cards, { S = case, Id = card.Id, F = card.F, G = card.G })
	GalleryService.Render(player)
	return case
end

function GalleryService.Sell(player: Player, case: number)
	local data = DataService.Get(player)
	local c, i = GalleryService.CardAt(player, case)
	if not data or not c then
		return
	end
	local value = Cards.SellValue(c.Id, c.F, c.G)
	table.remove(data.Cards, i)
	data.Cash += value
	player:SetAttribute("Cash", data.Cash)
	GalleryService.Render(player)
	Remotes.Notify:FireClient(player, ("Sold %s for %s"):format(Cards.DisplayName(c.Id, c.F), Format.cash(value)), "cash")
end

function GalleryService.UnlockCase(player: Player)
	local data = DataService.Get(player)
	if not data or data.Cases >= Config.GalleryMaxCases then
		return
	end
	local cost = Config.CaseCost(data.Cases)
	if data.Cash < cost then
		Remotes.Notify:FireClient(player, "You need " .. Format.cash(cost), "error")
		return
	end
	data.Cash -= cost
	data.Cases += 1
	player:SetAttribute("Cash", data.Cash)
	GalleryService.Render(player)
	Remotes.Notify:FireClient(player, "New display case unlocked!", "reward")
end

function GalleryService.ClearCards(player: Player)
	local data = DataService.Get(player)
	if data then
		data.Cards = {}
		GalleryService.Render(player)
	end
end

function GalleryService.Collect(player: Player)
	local g = galleryOf[player]
	local data = DataService.Get(player)
	if not g or not data then
		return
	end
	local s = state[g]
	if s.pending < 1 then
		return
	end
	local amount = s.pending
	s.pending = 0
	data.Cash += amount
	player:SetAttribute("Cash", data.Cash)
	g.CollectLabel.Text = "$0"
	Remotes.Notify:FireClient(player, "+" .. Format.cash(amount), "cash")
end

--------------------------------------------------------------------
-- Attribution
--------------------------------------------------------------------
function GalleryService.Assign(player: Player)
	for _, g in galleries do
		local s = state[g]
		if not s.owner then
			s.owner = player
			s.pending = 0
			galleryOf[player] = g
			g.Folder:SetAttribute("OwnerId", player.UserId)
			g.SignLabel.Text = player.DisplayName:upper() .. "'S BASE"
			for _, label in g.SignLabel.Parent.Parent:GetChildren() do
				local l = label:FindFirstChildOfClass("TextLabel")
				if label:IsA("SurfaceGui") and l then
					l.Text = player.DisplayName:upper() .. "'S BASE"
				end
			end
			player:SetAttribute("GalleryIndex", g.Index)
			GalleryService.Render(player)
			Hub.Training.Render(g, player)
			return g
		end
	end
	return nil
end

function GalleryService.Release(player: Player)
	local g = galleryOf[player]
	if not g then
		return
	end
	local s = state[g]
	s.owner = nil
	s.pending = 0
	galleryOf[player] = nil
	g.Folder:SetAttribute("OwnerId", nil)
	for _, label in g.SignLabel.Parent.Parent:GetChildren() do
		local l = label:FindFirstChildOfClass("TextLabel")
		if label:IsA("SurfaceGui") and l then
			l.Text = "FREE BASE"
		end
	end
	g.MachineTag.Text = ""
	Hub.Training.Render(g, nil)
	g.MachineLabel.Text = "GRADING LAB"
	g.CollectLabel.Text = ""
	for i = 1, #g.Cases do
		renderCase(g, i)
	end
end

function GalleryService.Start(built)
	galleries = built
	for _, g in galleries do
		state[g] = { owner = nil, pending = 0, cardParts = {} }
		g.Folder:SetAttribute("GalleryIndex", g.Index)
		for i, case in g.Cases do
			case.Plinth:SetAttribute("GalleryIndex", g.Index)
			case.Plinth:SetAttribute("CaseIndex", i)
			CollectionService:AddTag(case.Plinth, "Case")
			renderCase(g, i)
		end
		g.Collect.Touched:Connect(function(hit)
			local model = hit:FindFirstAncestorOfClass("Model")
			local player = model and Players:GetPlayerFromCharacter(model)
			if player and state[g].owner == player then
				GalleryService.Collect(player)
			end
		end)
	end

	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(1)
			local now = os.clock()
			local dt = math.min(now - last, 5)
			last = now
			for player, g in galleryOf do
				local data = DataService.Get(player)
				if data then
					local perSecond = GalleryService.Income(player)
					local income = perSecond * dt
					data.TotalEarned += income
					local s = state[g]
					if MonetizationService.Owns(player, "AutoCollect") then
						data.Cash += income + s.pending
						s.pending = 0
						g.CollectLabel.Text = "AUTO COLLECT"
					else
						s.pending += income
						g.CollectLabel.Text = Format.cash(s.pending)
					end
					player:SetAttribute("Cash", data.Cash)
					player:SetAttribute("Income", perSecond)
					-- état de la machine de gradation
					local ready, busy = 0, #data.Grading
					for _, e in data.Grading do
						if e.Ends <= os.time() then
							ready += 1
						end
					end
					g.MachineLabel.Text = ("GRADING LAB\n%d / %d SLOTS"):format(busy, Hub.Grading.SlotCount(player))
					g.MachineTag.Text = ready > 0 and (ready .. " CARD" .. (ready > 1 and "S" or "") .. " READY!") or ""
				end
			end
		end
	end)
end

return GalleryService
