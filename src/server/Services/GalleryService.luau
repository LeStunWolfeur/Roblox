--[[
	Bases des joueurs : supports (vitrines), cartes exposées, cash produit, collecte,
	cartes en main (ramassées), réserve, déblocage des supports, étages.

	- Une carte volée qui arrive dans la zone sûre se pose toute seule sur un support libre.
	  S'il n'y en a plus, elle part dans la réserve (Storage).
	- Sur un support de sa base, on peut VENDRE la carte ou la RAMASSER (elle passe dans
	  les mains, pour aller la faire grader au stand puis la reposer).
	- 8 supports par étage. Un rebirth ajoute un étage (voir Config.FloorRebirths).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Cards = require(ReplicatedStorage.Shared.Cards)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local Hub = require(script.Parent.Parent.Hub)
local Showcase = require(script.Parent.Parent.World.Showcase)
local CardDisplay = require(script.Parent.Parent.World.CardDisplay)

local GalleryService = {}

local galleries = {}
local galleryOf: { [Player]: any } = {}
local state: { [any]: { owner: Player?, pending: number, cardParts: { [number]: Instance } } } = {}

local function notify(player: Player, text: string, kind: string)
	Remotes.Notify:FireClient(player, text, kind)
end

--------------------------------------------------------------------
-- Infos
--------------------------------------------------------------------
function GalleryService.Get(player: Player)
	return galleryOf[player]
end

function GalleryService.Floors(player: Player): number
	local data = DataService.Get(player)
	return Config.FloorsFor(data and data.Rebirths or 0)
end

function GalleryService.MaxCases(player: Player): number
	return math.min(Config.CasesPerFloor * GalleryService.Floors(player), Config.GalleryMaxCases)
end

-- supports débloqués (le pass +2 en offre deux de plus)
function GalleryService.CaseCount(player: Player): number
	local data = DataService.Get(player)
	if not data then
		return Config.GalleryStartCases
	end
	local bonus = MonetizationService.Owns(player, "ExtraCases") and 2 or 0
	return math.min(data.Cases + bonus, GalleryService.MaxCases(player))
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
-- Étages : visibles seulement si le propriétaire les a débloqués
--------------------------------------------------------------------
local function setVisible(folder: Instance, visible: boolean)
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then
			if d:GetAttribute("T0") == nil then
				d:SetAttribute("T0", d.Transparency)
				d:SetAttribute("C0", d.CanCollide)
			end
			d.Transparency = visible and d:GetAttribute("T0") or 1
			d.CanCollide = visible and d:GetAttribute("C0") or false
		elseif d:IsA("SurfaceGui") or d:IsA("BillboardGui") or d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("ProximityPrompt") then
			d.Enabled = visible
		end
	end
end

local function renderFloors(gallery, floors: number)
	for n, folder in gallery.Floors do
		setVisible(folder, n <= floors)
	end
	gallery.Folder:SetAttribute("Floors", floors)
end

--------------------------------------------------------------------
-- Affichage d'un support
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
	for _, attr in { "CardId", "Finish", "Grade", "Value", "Cost", "State", "Income" } do
		plinth:SetAttribute(attr, nil)
	end

	local owner = s.owner
	local floors = owner and GalleryService.Floors(owner) or 1
	if case.Floor > floors then
		plinth:SetAttribute("State", "hidden")
		return
	end
	if not owner then
		Showcase.style(case.Show, nil, true)
		plinth:SetAttribute("State", "free")
		return
	end

	local count = GalleryService.CaseCount(owner)
	if index > count then
		Showcase.style(case.Show, nil, true)
		-- seul le support suivant est achetable
		if index == count + 1 then
			plinth:SetAttribute("State", "buy")
			local data = DataService.Get(owner)
			plinth:SetAttribute("Cost", Config.CaseCost(data and data.Cases or count))
		else
			plinth:SetAttribute("State", "locked")
		end
		return
	end

	local c = GalleryService.CardAt(owner, index)
	if not c then
		Showcase.style(case.Show, nil, false)
		plinth:SetAttribute("State", "empty")
		return
	end
	local display = CardDisplay.build(c.Id, c.F, c.G, case.CardCFrame, 0.62, gallery.Folder)
	s.cardParts[index] = display
	plinth:SetAttribute("State", "card")
	plinth:SetAttribute("CardId", c.Id)
	plinth:SetAttribute("Finish", c.F)
	plinth:SetAttribute("Grade", c.G)
	plinth:SetAttribute("Value", Cards.SellValue(c.Id, c.F, c.G))
	plinth:SetAttribute("Income", Cards.IncomeOf(c.Id, c.F, c.G))
	Showcase.style(case.Show, Cards.ById[c.Id].Rarity, false)
end

function GalleryService.Render(player: Player)
	local g = galleryOf[player]
	if g then
		renderFloors(g, GalleryService.Floors(player))
		for i = 1, #g.Cases do
			renderCase(g, i)
		end
	end
end

--------------------------------------------------------------------
-- Cartes
--------------------------------------------------------------------
-- Pose une carte sur un support libre, sinon dans la réserve. Renvoie "case", "storage" ou nil.
function GalleryService.Give(player: Player, id: string, finish: string?, grade: number?): string?
	local data = DataService.Get(player)
	if not data then
		return nil
	end
	Hub.Players.Discover(player, id)
	local case = GalleryService.FreeCase(player)
	if case then
		table.insert(data.Cards, { S = case, Id = id, F = finish or "Normal", G = grade })
		GalleryService.Render(player)
		return "case"
	end
	if #data.Storage < Config.StorageMax then
		table.insert(data.Storage, { Id = id, F = finish or "Normal", G = grade })
		notify(player, "Your cases are full: " .. Cards.Name(id) .. " went to your storage", "info")
		return "storage"
	end
	-- réserve pleine : la carte est vendue automatiquement pour ne rien perdre
	local value = Cards.SellValue(id, finish, grade)
	data.Cash += value
	player:SetAttribute("Cash", data.Cash)
	notify(player, ("Storage full: %s sold for %s"):format(Cards.Name(id), Format.cash(value)), "cash")
	return nil
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
	notify(player, ("Sold %s for %s"):format(Cards.DisplayName(c.Id, c.F), Format.cash(value)), "cash")
end

-- La carte du support passe dans les mains du joueur
function GalleryService.PickUp(player: Player, case: number)
	local data = DataService.Get(player)
	local c, i = GalleryService.CardAt(player, case)
	if not data or not c then
		return
	end
	if Hub.Zones.IsCarrying(player) then
		notify(player, "Your hands are full", "error")
		return
	end
	table.remove(data.Cards, i)
	Hub.Zones.SetCarry(player, { Id = c.Id, F = c.F, G = c.G, Zone = 0 })
	GalleryService.Render(player)
end

-- Pose la carte qu'on a en main sur un support libre de sa base
function GalleryService.Place(player: Player, case: number?)
	local data = DataService.Get(player)
	local held = Hub.Zones.GetCarry(player)
	if not data or not held then
		return
	end
	if case == nil then
		case = GalleryService.FreeCase(player)
	end
	if not case or case > GalleryService.CaseCount(player) or GalleryService.CardAt(player, case) then
		notify(player, "No free case here", "error")
		return
	end
	Hub.Zones.SetCarry(player, nil)
	table.insert(data.Cards, { S = case, Id = held.Id, F = held.F, G = held.G })
	GalleryService.Render(player)
end

-- Réserve : sortir une carte (dans les mains) ou la vendre
function GalleryService.TakeFromStorage(player: Player, index: number)
	local data = DataService.Get(player)
	local c = data and data.Storage[index]
	if not c then
		return
	end
	if Hub.Zones.IsCarrying(player) then
		notify(player, "Your hands are full", "error")
		return
	end
	table.remove(data.Storage, index)
	Hub.Zones.SetCarry(player, { Id = c.Id, F = c.F, G = c.G, Zone = 0 })
end

function GalleryService.SellStorage(player: Player, index: number)
	local data = DataService.Get(player)
	local c = data and data.Storage[index]
	if not c then
		return
	end
	table.remove(data.Storage, index)
	local value = Cards.SellValue(c.Id, c.F, c.G)
	data.Cash += value
	player:SetAttribute("Cash", data.Cash)
	notify(player, ("Sold %s for %s"):format(Cards.DisplayName(c.Id, c.F), Format.cash(value)), "cash")
end

function GalleryService.UnlockCase(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	if GalleryService.CaseCount(player) >= GalleryService.MaxCases(player) then
		if GalleryService.Floors(player) < #Config.FloorRebirths then
			notify(player, "Rebirth to unlock a new floor!", "error")
		end
		return
	end
	local cost = Config.CaseCost(data.Cases)
	if data.Cash < cost then
		notify(player, "You need " .. Format.cash(cost), "error")
		return
	end
	data.Cash -= cost
	data.Cases += 1
	player:SetAttribute("Cash", data.Cash)
	GalleryService.Render(player)
	notify(player, "New display case unlocked!", "reward")
end

function GalleryService.ClearCards(player: Player)
	local data = DataService.Get(player)
	if data then
		table.clear(data.Cards)
		table.clear(data.Storage)
	end
	GalleryService.Render(player)
end

function GalleryService.Collect(player: Player)
	local g = galleryOf[player]
	local data = DataService.Get(player)
	if not g or not data then
		return
	end
	local amount = math.floor(state[g].pending)
	if amount <= 0 then
		return
	end
	state[g].pending -= amount
	data.Cash += amount
	player:SetAttribute("Cash", data.Cash)
	g.CollectLabel.Text = ""
	Remotes.CashFx:FireClient(player, amount)
end

--------------------------------------------------------------------
-- Attribution
--------------------------------------------------------------------
local function setSign(g, title: string, sub: string)
	for _, l in g.SignTitles do
		l.Text = title
	end
	for _, l in g.SignSubs do
		l.Text = sub
	end
	for _, f in g.SignFrames do
		f.Visible = title ~= ""
	end
end

function GalleryService.Assign(player: Player)
	for _, g in galleries do
		local s = state[g]
		if not s.owner then
			s.owner = player
			s.pending = 0
			galleryOf[player] = g
			g.Folder:SetAttribute("OwnerId", player.UserId)
			setSign(g, player.DisplayName, "")
			player:SetAttribute("GalleryIndex", g.Index)
			-- cartes posées sur un support qui n'existe plus (anciennes sauvegardes) : en réserve
			local data = DataService.Get(player)
			if data then
				local count = GalleryService.CaseCount(player)
				local used = {}
				for i = #data.Cards, 1, -1 do
					local c = data.Cards[i]
					if c.S > count or used[c.S] then
						table.remove(data.Cards, i)
						table.insert(data.Storage, { Id = c.Id, F = c.F, G = c.G })
					else
						used[c.S] = true
					end
				end
			end
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
	-- base libre : pas de nom, l'enseigne reste vide
	setSign(g, "", "")
	Hub.Training.Render(g, nil)
	g.CollectLabel.Text = ""
	renderFloors(g, 1)
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
			game:GetService("CollectionService"):AddTag(case.Plinth, "Case")
		end
		setSign(g, "", "")
		renderFloors(g, 1)
		for i = 1, #g.Cases do
			renderCase(g, i)
		end
		g.Collect.Touched:Connect(function(hit)
			local model = hit:FindFirstAncestorOfClass("Model")
			local player = model and Players:GetPlayerFromCharacter(model)
			if player and state[g].owner == player then
				GalleryService.Collect(player)
			end
		end)
		-- monte-charges entre les étages
		for _, pad in g.Pads do
			pad.Part.Touched:Connect(function(hit)
				local model = hit:FindFirstAncestorOfClass("Model")
				local player = model and Players:GetPlayerFromCharacter(model)
				if not player or state[g].owner ~= player or pad.Part.Transparency >= 1 then
					return
				end
				local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root and (os.clock() - (root:GetAttribute("PadAt") or 0)) > 1.2 then
					root:SetAttribute("PadAt", os.clock())
					model:PivotTo(pad.Target)
				end
			end)
		end
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
						g.CollectLabel.Text = s.pending >= 1 and Format.cash(s.pending) or ""
					end
					player:SetAttribute("Cash", data.Cash)
					player:SetAttribute("Income", perSecond)
					for _, l in g.SignSubs do
						l.Text = Format.cash(perSecond) .. "/s"
					end
				end
			end
		end
	end)
end

return GalleryService
