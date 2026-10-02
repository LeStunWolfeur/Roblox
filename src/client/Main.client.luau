-- Interface du joueur : HUD + fenêtres (Shop, Pass, Daily, Rebirth, Index, Upgrades, Lab)

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Cards = require(ReplicatedStorage.Shared.Cards)
local CardArt = require(ReplicatedStorage.Shared.CardArt)
local Format = require(ReplicatedStorage.Shared.Format)
local Odds = require(ReplicatedStorage.Shared.Odds)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Kit = require(script.Parent.UI.Kit)
local Icons3D = require(script.Parent.UI.Icons3D)

local C = Kit.Colors
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local state: any = nil
local stateAt = os.clock()
local eventState: any = {}

local function send(action: string, a: any?, b: any?)
	Remotes.Action:FireServer(action, a, b)
end

local function icon(kind: string, props: { [string]: any }): ViewportFrame
	return Icons3D.view(kind, props)
end

local function bigCash(n: number): string
	if n < 1e9 then
		return "$" .. Kit.formatNumber(n)
	end
	return Format.cash(n)
end

local function mult(x: number): string
	local r = math.floor(x * 100 + 0.5) / 100
	return "X" .. tostring(r)
end

local RARITY_PALETTE = {
	Common = "Grey",
	Uncommon = "Green",
	Rare = "Blue",
	Epic = "Purple",
	Legendary = "Gold",
	Mythic = "Pink",
	Secret = "Dark",
}

--------------------------------------------------------------------
-- Racine + échelle
--------------------------------------------------------------------
local gui = Kit.new("ScreenGui", {
	Name = "StealACardUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})
local rootScale = Kit.new("UIScale", { Parent = gui })
local function updateScale()
	local size = Workspace.CurrentCamera.ViewportSize
	rootScale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 760), 0.5, 1.2)
end
updateScale()
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

-- prix Robux (mis en cache)
local priceCache: { [string]: string } = {}
local function priceOf(id: number, infoType: Enum.InfoType): string
	if id == 0 then
		return "--"
	end
	local key = tostring(infoType) .. id
	if not priceCache[key] then
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
		priceCache[key] = (ok and info and info.PriceInRobux) and tostring(info.PriceInRobux) or "--"
	end
	return priceCache[key]
end
local function fillPrice(label: TextLabel, id: number, infoType: Enum.InfoType)
	task.spawn(function()
		label.Text = priceOf(id, infoType)
	end)
end
local function productPrice(label: TextLabel, key: string)
	fillPrice(label, Config.Products[key].Id, Enum.InfoType.Product)
end
local function passPrice(label: TextLabel, key: string)
	fillPrice(label, Config.GamePasses[key].Id, Enum.InfoType.GamePass)
end

local function serverNow(): number
	if not state then
		return os.time()
	end
	return state.Now + (os.clock() - stateAt)
end

--------------------------------------------------------------------
-- Fenêtres
--------------------------------------------------------------------
local panels: { [string]: Frame } = {}
local openPanel: string? = nil
local refreshers: { [string]: () -> () } = {}

local function closePanels()
	for _, p in panels do
		p.Visible = false
	end
	openPanel = nil
end

local function showPanel(name: string)
	closePanels()
	panels[name].Visible = true
	Kit.pop(panels[name])
end

local function togglePanel(name: string)
	if openPanel == name then
		closePanels()
	else
		showPanel(name)
	end
end

-- Fenêtre : bandeau coloré avec grosse icône 3D qui déborde, titre, X rouge,
-- corps sombre semi-transparent. Renvoie la zone de contenu et le bandeau.
local function makePanel(name: string, title: string, palette: string, iconKind: string, size: Vector2): (Frame, Frame)
	local holder = Kit.new("Frame", {
		Name = name .. "Panel",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size.X, size.Y),
		Position = UDim2.new(0.5, 0, 0.5, 36),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = false,
		ZIndex = 20,
		Parent = gui,
	})
	Kit.new("UIScale", { Parent = holder })
	local body = Kit.well({
		Name = "Body",
		Parent = holder,
		Size = UDim2.new(1, 0, 1, -46),
		Position = UDim2.fromOffset(0, 46),
		Color = Color3.fromRGB(22, 26, 38),
		Transparency = 0.1,
		Border = 4,
		Radius = 8,
	})
	local header = Kit.tile({
		Name = "Header",
		Parent = holder,
		Size = UDim2.new(1, 0, 0, 72),
		Palette = palette,
		Border = 4,
		Radius = 8,
		ZIndex = 2,
	})
	icon(iconKind, {
		Parent = holder,
		Size = UDim2.fromOffset(112, 112),
		Position = UDim2.fromOffset(-34, -36),
		Rotation = -8,
		ZIndex = 4,
	})
	Kit.text({
		Name = "Title",
		Parent = header,
		Text = title,
		Size = UDim2.new(1, -300, 0, 50),
		Position = UDim2.fromOffset(86, 10),
		TextXAlignment = Enum.TextXAlignment.Left,
		Stroke = 3.5,
	})
	Kit.button({
		Name = "Close",
		Parent = header,
		Size = UDim2.fromOffset(56, 54),
		Position = UDim2.new(1, -66, 0, 9),
		Palette = "Red",
		Text = "X",
		Radius = 6,
		TextStroke = 3,
	}, closePanels)
	local content = Kit.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -32, 1, -56),
		Position = UDim2.fromOffset(16, 40),
		Parent = body,
	})
	panels[name] = holder
	-- la fenêtre se met à jour dès qu'elle s'affiche
	holder:GetPropertyChangedSignal("Visible"):Connect(function()
		if holder.Visible then
			openPanel = name
			if refreshers[name] then
				refreshers[name]()
			end
		elseif openPanel == name then
			openPanel = nil
		end
	end)
	return content, header
end

local function scroller(parent: Instance, size: UDim2?, position: UDim2?): ScrollingFrame
	return Kit.new("ScrollingFrame", {
		Parent = parent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = size or UDim2.fromScale(1, 1),
		Position = position or UDim2.new(),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Color3.fromRGB(230, 230, 240),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	})
end

local function list(parent: Instance, padding: number, horizontal: boolean?, align: Enum.HorizontalAlignment?)
	return Kit.new("UIListLayout", {
		Parent = parent,
		Padding = UDim.new(0, padding),
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

local function grid(parent: Instance, cell: Vector2, gap: number, cols: number?)
	return Kit.new("UIGridLayout", {
		Parent = parent,
		CellSize = UDim2.fromOffset(cell.X, cell.Y),
		CellPadding = UDim2.fromOffset(gap, gap),
		FillDirectionMaxCells = cols or 0,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

local function pad(parent: Instance, top: number, side: number?)
	Kit.new("UIPadding", {
		Parent = parent,
		PaddingTop = UDim.new(0, top),
		PaddingBottom = UDim.new(0, top),
		PaddingLeft = UDim.new(0, side or top),
		PaddingRight = UDim.new(0, (side or top) + 6),
	})
end

-- Bouton prix Robux : tuile + hexagone + prix (+ légende en dessous optionnelle)
local function robuxButton(props: { [string]: any }, onClick: () -> ()): (Frame, TextLabel)
	local face = Kit.button({
		Parent = props.Parent,
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Palette = props.Palette or "Green",
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		Radius = 6,
	}, onClick)
	local h = face.Size.Y.Offset
	local _, priceLabel = Kit.price({
		Parent = face,
		Size = UDim2.new(1, -12, 0, props.Caption and h * 0.56 or h * 0.72),
		Position = UDim2.new(0.5, 0, 0, props.Caption and 4 or h * 0.14),
		AnchorPoint = Vector2.new(0.5, 0),
		IconSize = math.floor(h * (props.Caption and 0.44 or 0.52)),
		TextWidth = props.TextWidth or 60,
		Color = C.White,
		Stroke = 3,
		ZIndex = 3,
	})
	if props.Caption then
		Kit.text({
			Parent = face,
			Text = props.Caption,
			Size = UDim2.new(1, -12, 0, h * 0.3),
			Position = UDim2.new(0.5, 0, 1, -4),
			AnchorPoint = Vector2.new(0.5, 1),
			Stroke = 2,
			ZIndex = 3,
		})
	end
	return face, priceLabel
end

--------------------------------------------------------------------
-- SHOP
--------------------------------------------------------------------
local shopContent = makePanel("Shop", "Shop", "Red", "basket", Vector2.new(800, 560))
local shopScroll = scroller(shopContent, UDim2.new(1, 0, 1, -70))
list(shopScroll, 14)
pad(shopScroll, 4, 4)

-- DOLLARS : trois packs de cash, en premier dans le shop
local cashAmounts: { { label: TextLabel, key: string } } = {}
do
	Kit.text({ Parent = shopScroll, Text = "Cash", Size = UDim2.new(1, -14, 0, 34), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = -2, TextColor3 = C.Money, Stroke = 3 })
	local row = Kit.new("Frame", { Parent = shopScroll, BackgroundTransparency = 1, Size = UDim2.new(1, -14, 0, 214), LayoutOrder = -1 })
	grid(row, Vector2.new(236, 214), 12, 3)
	for i, info in { { "CashSmall", "cash", "Green", "Cash Bag" }, { "CashBig", "cashpile", "Lime", "Cash Vault" }, { "CashHuge", "cashpile", "Gold", "Cash Mountain" } } do
		local tile = Kit.tile({ Parent = row, Palette = info[3], LayoutOrder = i, Border = 3, Rot = 20 })
		icon(info[2], { Parent = tile, Size = UDim2.fromOffset(i == 3 and 108 or 92, i == 3 and 108 or 92), Position = UDim2.new(0.5, 0, 0, i == 3 and -4 or 4), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 2 })
		Kit.text({ Parent = tile, Text = info[4], Size = UDim2.new(1, -12, 0, 26), Position = UDim2.new(0.5, 0, 0, 98), AnchorPoint = Vector2.new(0.5, 0), Stroke = 2.5 })
		local amount = Kit.text({ Parent = tile, Text = "", Size = UDim2.new(1, -12, 0, 26), Position = UDim2.new(0.5, 0, 0, 124), AnchorPoint = Vector2.new(0.5, 0), TextColor3 = C.Money, Stroke = 3 })
		table.insert(cashAmounts, { label = amount, key = info[1] })
		local _, price = robuxButton({ Parent = tile, Size = UDim2.new(1, -24, 0, 42), Position = UDim2.new(0.5, 0, 1, -8), AnchorPoint = Vector2.new(0.5, 1), Palette = "Green" }, function()
			send("BuyProduct", info[1])
		end)
		productPrice(price, info[1])
		if i == 3 then
			Kit.tag({ Parent = tile, Text = "BEST!", Position = UDim2.new(1, -24, 0, 18), Size = UDim2.fromOffset(80, 30), Rotation = 18 })
		end
	end
end
local function refreshCashAmounts()
	local income = player:GetAttribute("Income") or 0
	for _, c in cashAmounts do
		local product = Config.Products[c.key]
		c.label.Text = "+" .. Format.cash(math.max(product.Minimum, math.floor(income * 60 * product.Minutes)))
	end
end
refreshCashAmounts()

-- carte "Mystery Pack" avec les chances
do
	local card = Kit.tile({ Parent = shopScroll, Size = UDim2.new(1, -14, 0, 230), Palette = "Rainbow", LayoutOrder = 1, Border = 4, Rot = 15 })
	icon("crate", { Parent = card, Size = UDim2.fromOffset(150, 150), Position = UDim2.fromOffset(12, 10), Rotation = -6, ZIndex = 2 })
	Kit.text({ Parent = card, Text = "Mystery", Size = UDim2.fromOffset(160, 30), Position = UDim2.fromOffset(14, 158), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Yellow, Stroke = 3 })
	Kit.text({ Parent = card, Text = "Card Pack", Size = UDim2.fromOffset(160, 30), Position = UDim2.fromOffset(14, 188), TextXAlignment = Enum.TextXAlignment.Left, Stroke = 3 })
	Kit.text({ Parent = card, Text = "Mystery Card Pack!", Size = UDim2.new(1, -200, 0, 40), Position = UDim2.fromOffset(186, 8), TextXAlignment = Enum.TextXAlignment.Left, Stroke = 3.5 })
	local row = Kit.new("Frame", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, -196, 0, 104), Position = UDim2.fromOffset(186, 66), ZIndex = 2 })
	list(row, 8, true)
	local total = 0
	for _, w in Config.PackWeights do
		total += w
	end
	for i, rarity in Cards.RarityOrder do
		local w = Config.PackWeights[rarity]
		if w then
			local box = Kit.tile({ Parent = row, Size = UDim2.fromOffset(98, 104), Palette = RARITY_PALETTE[rarity], LayoutOrder = i, Border = 3, Streaks = false })
			icon("cardpack", { Parent = box, Size = UDim2.fromOffset(70, 70), Position = UDim2.new(0.5, 0, 0, 14), AnchorPoint = Vector2.new(0.5, 0), Color = Cards.Rarities[rarity].Color, ZIndex = 2 })
			Kit.text({ Parent = box, Text = Odds.text(w / total), Size = UDim2.new(1, -6, 0, 24), Position = UDim2.new(0.5, 0, 0, -10), AnchorPoint = Vector2.new(0.5, 0), Stroke = 2.5, ZIndex = 4 })
			Kit.text({ Parent = box, Text = rarity, Size = UDim2.new(1, -8, 0, 20), Position = UDim2.new(0.5, 0, 1, -4), AnchorPoint = Vector2.new(0.5, 1), Stroke = 2, ZIndex = 3 })
		end
	end
	local _, price = robuxButton({ Parent = card, Size = UDim2.fromOffset(200, 50), Position = UDim2.new(1, -14, 1, -12), AnchorPoint = Vector2.new(1, 1), Palette = "Green", Caption = "1 Pack" }, function()
		send("BuyProduct", "MysteryPack")
	end)
	productPrice(price, "MysteryPack")
	Kit.text({ Parent = card, Text = "Sent to your grading lab", Size = UDim2.fromOffset(300, 22), Position = UDim2.new(1, -228, 1, -24), AnchorPoint = Vector2.new(1, 1), TextXAlignment = Enum.TextXAlignment.Right, Stroke = 2, ZIndex = 2 })
end

-- carte "Starter Pack"
local starterCard
do
	starterCard = Kit.tile({ Parent = shopScroll, Size = UDim2.new(1, -14, 0, 206), Palette = "Candy", LayoutOrder = 2, Border = 4, Rot = 15 })
	icon("gift", { Parent = starterCard, Size = UDim2.fromOffset(150, 150), Position = UDim2.fromOffset(10, 4), Rotation = -8, ZIndex = 2 })
	Kit.text({ Parent = starterCard, Text = "1x Legendary+", Size = UDim2.fromOffset(170, 26), Position = UDim2.fromOffset(14, 152), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Yellow, Stroke = 3 })
	Kit.text({ Parent = starterCard, Text = "card guaranteed", Size = UDim2.fromOffset(170, 22), Position = UDim2.fromOffset(14, 176), TextXAlignment = Enum.TextXAlignment.Left, Stroke = 2.5 })
	Kit.text({ Parent = starterCard, Text = "Limited Starter Pack!", Size = UDim2.new(1, -200, 0, 40), Position = UDim2.fromOffset(186, 8), TextXAlignment = Enum.TextXAlignment.Left, Stroke = 3.5 })
	Kit.text({ Parent = starterCard, Text = "+", Size = UDim2.fromOffset(40, 60), Position = UDim2.fromOffset(160, 70), Stroke = 3.5 })
	local items = Kit.new("Frame", { Parent = starterCard, BackgroundTransparency = 1, Size = UDim2.fromOffset(330, 110), Position = UDim2.fromOffset(200, 68), ZIndex = 2 })
	list(items, 8, true)
	for i, item in { { "cardpack", "Legendary+" }, { "cashpile", "15 min" }, { "bolt", "15 min" } } do
		local box = Kit.well({ Parent = items, Size = UDim2.fromOffset(102, 108), LayoutOrder = i, Color = Color3.fromRGB(40, 20, 70), Transparency = 0.35 })
		Kit.text({ Parent = box, Text = "x1", Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0.5, 0, 0, -12), AnchorPoint = Vector2.new(0.5, 0), Stroke = 2.5, ZIndex = 3 })
		icon(item[1], { Parent = box, Size = UDim2.fromOffset(74, 74), Position = UDim2.new(0.5, 0, 0, 10), AnchorPoint = Vector2.new(0.5, 0), Color = Cards.Rarities.Legendary.Color, ZIndex = 2 })
		Kit.text({ Parent = box, Text = item[2], Size = UDim2.new(1, -8, 0, 22), Position = UDim2.new(0.5, 0, 1, -4), AnchorPoint = Vector2.new(0.5, 1), Stroke = 2, ZIndex = 3 })
	end
	Kit.tag({ Parent = starterCard, Text = "VALUE!", Position = UDim2.new(1, -110, 0, 74), Size = UDim2.fromOffset(150, 40), Rotation = 0 })
	local _, price = robuxButton({ Parent = starterCard, Size = UDim2.fromOffset(200, 60), Position = UDim2.new(1, -14, 1, -14), AnchorPoint = Vector2.new(1, 1), Palette = "Green" }, function()
		send("BuyProduct", "StarterPack")
	end)
	productPrice(price, "StarterPack")
end

-- boosts
Kit.text({ Parent = shopScroll, Text = "Boosts", Size = UDim2.new(1, -14, 0, 34), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 3, Stroke = 3 })
local boostGrid = Kit.new("Frame", { Parent = shopScroll, BackgroundTransparency = 1, Size = UDim2.new(1, -14, 0, 2 * 196 + 12), LayoutOrder = 4 })
grid(boostGrid, Vector2.new(236, 196), 12, 3)
local BOOSTS = {
	{ "FreezeGuards", "snowflake", "Cyan", "Freeze Guards", "30s for everyone" },
	{ "ServerLuck", "clover", "Green", "Server Luck x2", "15 min, whole server" },
	{ "TreadmillUpgrade", "arrowup", "Lime", "Treadmill +1", "One level, right now" },
	{ "InstantGrade", "clock", "Blue", "Grade All Now", "Finish your lab" },
	{ "SpeedSmall", "bolt", "Yellow", "Speed Boost", "10 min of training" },
	{ "SpeedBig", "bolt", "Orange", "Mega Speed", "1 hour of training" },
}
for i, b in BOOSTS do
	local tile = Kit.tile({ Parent = boostGrid, Palette = b[3], LayoutOrder = i, Border = 3 })
	icon(b[2], { Parent = tile, Size = UDim2.fromOffset(92, 92), Position = UDim2.new(0.5, 0, 0, 4), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 2 })
	Kit.text({ Parent = tile, Text = b[4], Size = UDim2.new(1, -12, 0, 26), Position = UDim2.new(0.5, 0, 0, 96), AnchorPoint = Vector2.new(0.5, 0), Stroke = 2.5 })
	Kit.text({ Parent = tile, Text = b[5], Size = UDim2.new(1, -12, 0, 17), Position = UDim2.new(0.5, 0, 0, 122), AnchorPoint = Vector2.new(0.5, 0), Stroke = 2 })
	local _, price = robuxButton({ Parent = tile, Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0.5, 0, 1, -8), AnchorPoint = Vector2.new(0.5, 1), Palette = "Green" }, function()
		send("BuyProduct", b[1])
	end)
	productPrice(price, b[1])
end

-- friend boost
local friendText
do
	local card = Kit.tile({ Parent = shopScroll, Size = UDim2.new(1, -14, 0, 130), Palette = "Blue", LayoutOrder = 5, Border = 4 })
	icon("people", { Parent = card, Size = UDim2.fromOffset(120, 120), Position = UDim2.fromOffset(14, 4), ZIndex = 2 })
	friendText = Kit.text({ Parent = card, Text = "Friend Boost: +0%", Size = UDim2.new(1, -380, 0, 44), Position = UDim2.fromOffset(150, 18), TextXAlignment = Enum.TextXAlignment.Left, Stroke = 3.5 })
	Kit.text({
		Parent = card,
		Text = ("+%d%% cash for each friend in your server, up to +%d%%"):format(Config.FriendBoostPerFriend * 100, Config.FriendBoostMax * 100),
		Size = UDim2.new(1, -380, 0, 44),
		Position = UDim2.fromOffset(150, 66),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Stroke = 2,
	})
	Kit.button({ Parent = card, Size = UDim2.fromOffset(190, 64), Position = UDim2.new(1, -16, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Palette = "Green", Text = "INVITE", TextStroke = 3 }, function()
		pcall(function()
			game:GetService("SocialService"):PromptGameInvite(player)
		end)
	end)
end

-- codes : toujours en bas du shop
do
	local row = Kit.new("Frame", { Parent = shopContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 56), Position = UDim2.new(0, 0, 1, -56) })
	local box = Kit.well({ Parent = row, Size = UDim2.new(1, -196, 1, 0), Color = Color3.fromRGB(245, 246, 250), Transparency = 0, Border = 3 })
	local codeBox = Kit.new("TextBox", {
		Parent = box,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -24, 1, -14),
		Position = UDim2.fromOffset(14, 7),
		Font = Kit.Font,
		TextScaled = true,
		TextColor3 = C.Ink,
		PlaceholderText = "Enter a code...",
		PlaceholderColor3 = Color3.fromRGB(150, 155, 170),
		Text = "",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 2,
	})
	Kit.button({ Parent = row, Size = UDim2.new(0, 184, 1, 0), Position = UDim2.new(1, 0, 0, 0), AnchorPoint = Vector2.new(1, 0), Palette = "Yellow", Text = "REDEEM", TextStroke = 3 }, function()
		if codeBox.Text ~= "" then
			send("Redeem", codeBox.Text)
			codeBox.Text = ""
		end
	end)
end

refreshers.Shop = function()
	refreshCashAmounts()
	if not state then
		return
	end
	friendText.Text = ("Friend Boost: +%d%%"):format(math.floor(state.FriendBoost * 100 + 0.5))
	starterCard.Visible = not state.StarterBought
end

--------------------------------------------------------------------
-- GAME PASSES
--------------------------------------------------------------------
local passContent = makePanel("Passes", "Game Passes", "Yellow", "ticket", Vector2.new(800, 560))
local passScroll = scroller(passContent)
grid(passScroll, Vector2.new(240, 226), 12, 3)
pad(passScroll, 6, 4)
local PASS_LOOK = {
	VIP = { "crown", "Gold" },
	DoubleCash = { "cash", "Green" },
	DoubleSpeed = { "bolt", "Orange" },
	FastGrading = { "clock", "Blue" },
	MoreGrading = { "cards", "Purple" },
	AutoCollect = { "magnet", "Red" },
	Lucky = { "clover", "Candy" },
}
local passButtons: { [string]: { face: Frame, price: TextLabel, owned: TextLabel } } = {}
for i, key in Config.GamePassOrder do
	local pass = Config.GamePasses[key]
	local look = PASS_LOOK[key] or { "ticket", "Yellow" }
	local tile = Kit.tile({ Parent = passScroll, Palette = look[2], LayoutOrder = i, Border = 3, Rot = 20 })
	icon(look[1], { Parent = tile, Size = UDim2.fromOffset(96, 96), Position = UDim2.new(0.5, 0, 0, 2), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 2 })
	Kit.text({ Parent = tile, Text = pass.Name, Size = UDim2.new(1, -16, 0, 30), Position = UDim2.new(0.5, 0, 0, 96), AnchorPoint = Vector2.new(0.5, 0), Stroke = 3 })
	Kit.text({ Parent = tile, Text = pass.Description, Size = UDim2.new(1, -20, 0, 36), Position = UDim2.new(0.5, 0, 0, 126), AnchorPoint = Vector2.new(0.5, 0), TextWrapped = true, Stroke = 2 })
	local face, price = robuxButton({ Parent = tile, Size = UDim2.new(1, -28, 0, 46), Position = UDim2.new(0.5, 0, 1, -10), AnchorPoint = Vector2.new(0.5, 1), Palette = "Green" }, function()
		send("BuyPass", key)
	end)
	passPrice(price, key)
	local owned = Kit.text({ Parent = face, Text = "OWNED", Size = UDim2.new(1, -16, 1, -12), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, Stroke = 3, ZIndex = 5 })
	passButtons[key] = { face = face, price = price, owned = owned }
end

--------------------------------------------------------------------
-- DAILY REWARDS
--------------------------------------------------------------------
local dailyContent, dailyHeader = makePanel("Daily", "Daily Rewards", "Blue", "calendar", Vector2.new(820, 520))
local dailyTimer = Kit.tile({ Parent = dailyHeader, Size = UDim2.fromOffset(240, 52), Position = UDim2.new(1, -82, 0, 10), AnchorPoint = Vector2.new(1, 0), Palette = "Yellow", Radius = 6 })
local dailyTimerText = Kit.text({ Parent = dailyTimer, Text = "", Size = UDim2.new(1, -16, 1, -12), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Stroke = 3 })
local DAY_PALETTE = { "Blue", "Blue", "Blue", "Purple", "Purple", "Yellow", "Rainbow" }
local dayTiles = {}
for i, reward in Config.DailyRewards do
	local big = i == #Config.DailyRewards
	local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
	local tile = Kit.tile({
		Parent = dailyContent,
		Size = big and UDim2.fromOffset(196, 420) or UDim2.fromOffset(176, 204),
		Position = big and UDim2.fromOffset(3 * 188 + 4, 0) or UDim2.fromOffset(col * 188, row * 216),
		Palette = DAY_PALETTE[i] or "Blue",
		Border = 3,
		Rot = big and 35 or 25,
	})
	Kit.text({
		Parent = tile,
		Text = "DAY " .. i,
		Size = big and UDim2.new(1, -20, 0, 56) or UDim2.new(1, -16, 0, 36),
		Position = UDim2.new(0.5, 0, 0, 6),
		AnchorPoint = Vector2.new(0.5, 0),
		TextColor3 = big and C.Yellow or C.White,
		Stroke = big and 4 or 3,
	})
	local iconSize = big and 170 or 92
	icon(reward.Icon, {
		Parent = tile,
		Size = UDim2.fromOffset(iconSize, iconSize),
		Position = UDim2.new(0.5, 0, 0, big and 90 or 40),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = reward.Rarity and Cards.Rarities[reward.Rarity].Color or nil,
		ZIndex = 2,
	})
	local name = Kit.text({
		Parent = tile,
		Text = reward.Name:upper(),
		Size = big and UDim2.new(1, -16, 0, 70) or UDim2.new(1, -12, 0, 26),
		Position = UDim2.new(0.5, 0, 1, big and -84 or -60),
		AnchorPoint = Vector2.new(0.5, 1),
		TextWrapped = true,
		Stroke = 3,
	})
	local btnFace, btnHit, btnLabel = Kit.button({
		Parent = tile,
		Size = UDim2.new(1, -24, 0, big and 56 or 44),
		Position = UDim2.new(0.5, 0, 1, -10),
		AnchorPoint = Vector2.new(0.5, 1),
		Palette = "Red",
		Text = "LOCKED",
		Radius = 5,
		TextStroke = 3,
	}, function()
		send("ClaimDaily")
	end)
	local _ = btnHit
	if big then
		Kit.tag({ Parent = tile, Text = "OP", Position = UDim2.new(1, -22, 0, 84), Size = UDim2.fromOffset(84, 50), Rotation = 24, Color = C.Red, StrokeColor = Color3.new(1, 1, 1), Stroke = 4 })
	end
	dayTiles[i] = { tile = tile, name = name, face = btnFace, label = btnLabel, reward = reward }
end

local function dailyLeft(): number
	return state and (state.DailyWait - (os.clock() - stateAt)) or 0
end

refreshers.Daily = function()
	if not state then
		return
	end
	local ready = state.DailyReady or dailyLeft() <= 0
	local slot = state.DailySlot or 1
	dailyTimerText.Text = ready and "READY!" or ("NEXT IN " .. Kit.formatTime(dailyLeft()))
	Kit.paint(dailyTimer, ready and "Green" or "Yellow")
	for i, d in dayTiles do
		local amount = state.DailyAmounts and state.DailyAmounts[i] or 0
		local r = d.reward
		if r.Kind == "Cash" then
			d.name.Text = bigCash(amount)
		elseif r.Kind == "Speed" then
			d.name.Text = "+" .. Format.short(amount) .. " SPEED"
		elseif amount > 0 then
			d.name.Text = r.Name:upper() .. " + " .. Format.cash(amount)
		else
			d.name.Text = r.Name:upper()
		end
		local text, palette
		if i < slot then
			text, palette = "CLAIMED", "Grey"
		elseif i == slot and ready then
			text, palette = "CLAIM", "Green"
		elseif i == slot then
			text, palette = Kit.formatTime(dailyLeft()), "Grey"
		else
			text, palette = "LOCKED", "Red"
		end
		d.label.Text = text
		Kit.paint(d.face, palette)
	end
end

--------------------------------------------------------------------
-- REBIRTH
--------------------------------------------------------------------
local rebirthContent = makePanel("Rebirth", "Rebirth", "Purple", "rebirth", Vector2.new(720, 520))
local rbFrom, rbTo, rbFromTitle, rbToTitle, rbBonus, rbReqText, rbBarFill, rbBarLeft, rbBtn
do
	local function side(x: number): (TextLabel, TextLabel)
		local title = Kit.text({ Parent = rebirthContent, Text = "Rebirth 1", Size = UDim2.fromOffset(280, 30), Position = UDim2.fromOffset(x, 0), Stroke = 3 })
		local tile = Kit.tile({ Parent = rebirthContent, Size = UDim2.fromOffset(280, 78), Position = UDim2.fromOffset(x, 32), Palette = "Lime", Border = 4 })
		local value = Kit.text({ Parent = tile, Text = "X1 Money", Size = UDim2.new(1, -20, 1, -16), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Stroke = 3.5 })
		return title, value
	end
	rbFromTitle, rbFrom = side(0)
	rbToTitle, rbTo = side(408)
	icon("arrowup", { Parent = rebirthContent, Size = UDim2.fromOffset(90, 90), Position = UDim2.fromOffset(344, 70), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 90, Color = Color3.fromRGB(150, 210, 255), Dir = Vector3.new(0, 0, 1), ZIndex = 2 })
	rbBonus = Kit.text({
		Parent = rebirthContent,
		Text = "",
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.fromOffset(0, 120),
		TextColor3 = C.Yellow,
		Stroke = 2.5,
	})
	local req = Kit.well({ Parent = rebirthContent, Size = UDim2.new(1, 0, 0, 126), Position = UDim2.fromOffset(0, 156), Color = Color3.fromRGB(10, 12, 20), Transparency = 0.35, Border = 3, BorderColor = Color3.fromRGB(70, 75, 95) })
	Kit.text({ Parent = req, Text = "Requirements:", Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0.5, 0, 0, 8), AnchorPoint = Vector2.new(0.5, 0), Stroke = 3 })
	rbReqText = Kit.text({ Parent = req, Text = "", Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0.5, 0, 0, 38), AnchorPoint = Vector2.new(0.5, 0), Stroke = 2.5 })
	local _, fill, left = Kit.bar({ Parent = req, Size = UDim2.new(1, -36, 0, 40), Position = UDim2.new(0.5, 0, 1, -14), AnchorPoint = Vector2.new(0.5, 1), Palette = "Orange" })
	rbBarFill, rbBarLeft = fill, left
	rbBtn = Kit.button({ Parent = rebirthContent, Size = UDim2.fromOffset(280, 84), Position = UDim2.fromOffset(0, 300), Palette = "Lime", Text = "Rebirth", TextStroke = 4, Border = 4 }, function()
		send("Rebirth")
	end)
	Kit.text({ Parent = rebirthContent, Text = "OR", Size = UDim2.fromOffset(100, 44), Position = UDim2.fromOffset(294, 320), Stroke = 3.5 })
	local skip = Kit.button({
		Parent = rebirthContent,
		Size = UDim2.fromOffset(280, 84),
		Position = UDim2.fromOffset(408, 300),
		Palette = "Purple",
		Text = "Skip",
		TextSize = UDim2.new(1, -20, 0, 48),
		TextPosition = UDim2.new(0.5, 0, 0, 30),
		TextStroke = 4,
		Border = 4,
	}, function()
		send("BuyProduct", "RebirthSkip")
	end)
	Kit.text({ Parent = skip, Text = "[keep your stats]", Size = UDim2.new(1, -20, 0, 22), Position = UDim2.new(0.5, 0, 1, -6), AnchorPoint = Vector2.new(0.5, 1), TextColor3 = C.Yellow, StrokeColor = Color3.fromRGB(90, 20, 10), Stroke = 2.5, ZIndex = 3 })
	local _, skipPrice = Kit.price({ Parent = skip, Size = UDim2.fromOffset(90, 34), Position = UDim2.new(1, 10, 0, -14), AnchorPoint = Vector2.new(1, 0), IconSize = 28, TextWidth = 50, ZIndex = 5 })
	productPrice(skipPrice, "RebirthSkip")
	Kit.text({
		Parent = rebirthContent,
		Text = "Rebirth resets your cash, Speed, treadmill and cards. You keep your cases, Index and passes.",
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 1, -4),
		AnchorPoint = Vector2.new(0, 1),
		TextColor3 = Color3.fromRGB(200, 205, 220),
		Stroke = 2,
	})
end

refreshers.Rebirth = function()
	if not state then
		return
	end
	local r = state.Rebirths
	local now = 1 + r * Config.RebirthCashBonus
	local nxt = 1 + (r + 1) * Config.RebirthCashBonus
	rbFromTitle.Text = "Rebirth " .. r
	rbToTitle.Text = "Rebirth " .. (r + 1)
	rbFrom.Text = mult(now) .. " Money"
	rbTo.Text = mult(nxt) .. " Money"
	rbBonus.Text = ("Next rebirth: +%d%% Speed from training and +%d grading slot"):format(Config.RebirthSpeedBonus * 100, Config.GradingSlotsPerRebirth)
	local cash = player:GetAttribute("Cash") or 0
	rbReqText.Text = "Have " .. bigCash(state.RebirthCost) .. " cash"
	local p = math.clamp(cash / state.RebirthCost, 0, 1)
	rbBarFill.Size = UDim2.fromScale(math.max(p, 0.02), 1)
	rbBarLeft.Text = bigCash(math.min(cash, state.RebirthCost)) .. " / " .. bigCash(state.RebirthCost)
	rbBarLeft.Size = UDim2.new(1, -20, 1, -6)
	rbBarLeft.TextXAlignment = Enum.TextXAlignment.Center
	Kit.paint(rbBtn, cash >= state.RebirthCost and "Lime" or "Grey")
end

--------------------------------------------------------------------
-- INDEX
--------------------------------------------------------------------
local indexContent = makePanel("Index", "Index", "Blue", "book", Vector2.new(860, 580))
local indexInfo = Kit.text({ Parent = indexContent, Text = "", Size = UDim2.new(0.42, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, Stroke = 3 })
local filterRow = Kit.new("Frame", { Parent = indexContent, BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 0, 34), Position = UDim2.new(1, 0, 0, 0), AnchorPoint = Vector2.new(1, 0) })
list(filterRow, 5, true, Enum.HorizontalAlignment.Right)
local indexScroll = scroller(indexContent, UDim2.new(1, 0, 1, -44), UDim2.fromOffset(0, 44))
grid(indexScroll, Vector2.new(150, 210), 10, 5)
pad(indexScroll, 6, 4)
local indexFilter = "All"
local indexBuiltKey = ""

local function refreshIndex(force: boolean?)
	if not state then
		return
	end
	local owned = {}
	for _, id in state.Index do
		owned[id] = true
	end
	indexInfo.Text = ("%d / %d found  ·  +%d%% cash"):format(#state.Index, #Cards.List, math.floor(#state.Index * Config.IndexBonusPerCard * 100 + 0.5))
	local key = indexFilter .. ":" .. #state.Index
	if key == indexBuiltKey and not force then
		return
	end
	indexBuiltKey = key
	Kit.clear(indexScroll)
	local sorted = table.clone(Cards.List)
	table.sort(sorted, function(a, b)
		local ra, rb = Cards.Rarities[a.Rarity].Order, Cards.Rarities[b.Rarity].Order
		if ra ~= rb then
			return ra < rb
		end
		return a.Income < b.Income
	end)
	local order = 0
	for _, card in sorted do
		if indexFilter == "All" or card.Rarity == indexFilter then
			order += 1
			local have = owned[card.Id] == true
			local tile = Kit.tile({ Parent = indexScroll, Palette = RARITY_PALETTE[card.Rarity], LayoutOrder = order, Border = 3, Streaks = false })
			Icons3D.entity(card.Id, "Normal", { Parent = tile, Size = UDim2.fromOffset(112, 112), Position = UDim2.new(0.5, 0, 0, 4), AnchorPoint = Vector2.new(0.5, 0), Hidden = not have, ZIndex = 2 })
			Kit.text({ Parent = tile, Text = have and card.Name or "???", Size = UDim2.new(1, -10, 0, 24), Position = UDim2.new(0.5, 0, 0, 114), AnchorPoint = Vector2.new(0.5, 0), Stroke = 2.5 })
			Kit.text({ Parent = tile, Text = Format.cash(card.Income) .. "/s", Size = UDim2.new(1, -10, 0, 20), Position = UDim2.new(0.5, 0, 0, 138), AnchorPoint = Vector2.new(0.5, 0), TextColor3 = C.Money, Stroke = 2.5 })
			local first, best, chance = Odds.where(card.Id)
			local where = Kit.well({ Parent = tile, Size = UDim2.new(1, -12, 0, 40), Position = UDim2.new(0.5, 0, 1, -6), AnchorPoint = Vector2.new(0.5, 1), Color = Color3.fromRGB(0, 0, 0), Transparency = 0.55, Border = false, Radius = 4 })
			local line1, line2
			if card.Season then
				line1 = Cards.Seasons[card.Season].Name:upper()
				line2 = "Event only"
			elseif first then
				line1 = first == best and ("Shop %d"):format(best) or ("Shop %d+, best %d"):format(first, best)
				line2 = Odds.text(chance) .. " per stand"
			else
				line1, line2 = "Packs only", ""
			end
			Kit.text({ Parent = where, Text = line1, Size = UDim2.new(1, -8, 0, 18), Position = UDim2.new(0.5, 0, 0, 2), AnchorPoint = Vector2.new(0.5, 0), TextColor3 = C.Yellow, Stroke = 2 })
			Kit.text({ Parent = where, Text = line2, Size = UDim2.new(1, -8, 0, 16), Position = UDim2.new(0.5, 0, 0, 21), AnchorPoint = Vector2.new(0.5, 0), Stroke = 2 })
		end
	end
end
refreshers.Index = refreshIndex

local filterButtons = {}
for i, name in { "All", table.unpack(Cards.RarityOrder) } do
	local palette = name == "All" and "Dark" or RARITY_PALETTE[name]
	local face = Kit.button({ Parent = filterRow, Size = UDim2.fromOffset(i == 1 and 46 or 40, 34), Palette = palette, Text = name == "All" and "ALL" or name:sub(1, 1), LayoutOrder = i, Radius = 5, TextStroke = 2 }, function()
		indexFilter = name
		for n, f in filterButtons do
			f.Size = UDim2.fromOffset(n == "All" and 46 or 40, n == name and 38 or 34)
		end
		refreshIndex(true)
	end)
	filterButtons[name] = face
end

--------------------------------------------------------------------
-- UPGRADES
--------------------------------------------------------------------
local upContent = makePanel("Upgrades", "Upgrades", "Green", "arrowup", Vector2.new(760, 540))
local upRows = {}
do
	list(upContent, 12)
	local function row(order: number, iconKind: string, palette: string)
		local r = Kit.well({ Parent = upContent, Size = UDim2.new(1, 0, 0, 128), LayoutOrder = order, Color = Color3.fromRGB(10, 12, 20), Transparency = 0.35, Border = 3, BorderColor = Color3.fromRGB(70, 75, 95) })
		local iconTile = Kit.tile({ Parent = r, Size = UDim2.fromOffset(108, 108), Position = UDim2.fromOffset(10, 10), Palette = palette, Border = 3 })
		icon(iconKind, { Parent = iconTile, Size = UDim2.fromScale(1, 1), ZIndex = 2 })
		local title = Kit.text({ Parent = r, Text = "", Size = UDim2.new(1, -480, 0, 36), Position = UDim2.fromOffset(132, 12), TextXAlignment = Enum.TextXAlignment.Left, Stroke = 3 })
		local sub = Kit.text({ Parent = r, Text = "", Size = UDim2.new(1, -480, 0, 22), Position = UDim2.fromOffset(132, 52), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Money, Stroke = 2.5 })
		local sub2 = Kit.text({ Parent = r, Text = "", Size = UDim2.new(1, -480, 0, 20), Position = UDim2.fromOffset(132, 80), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(200, 205, 220), Stroke = 2 })
		return r, title, sub, sub2
	end
	-- tapis
	local r1, t1, s1, s2 = row(1, "treadmill", "Lime")
	local strip = Kit.new("Frame", { Parent = r1, BackgroundTransparency = 1, Size = UDim2.fromOffset(240, 18), Position = UDim2.fromOffset(132, 104) })
	list(strip, 4, true)
	local tierChips = {}
	for i, tier in Config.TreadmillTiers do
		tierChips[i] = Kit.new("Frame", { Parent = strip, Size = UDim2.fromOffset(22, 14), BackgroundColor3 = tier.Color, LayoutOrder = i }, { Kit.corner(3), Kit.stroke(2) })
	end
	local cashBtn, _, cashLabel = Kit.button({ Parent = r1, Size = UDim2.fromOffset(150, 56), Position = UDim2.new(1, -176, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Palette = "Green", Text = "$0", TextStroke = 3 }, function()
		send("UpgradeTreadmill")
	end)
	local _, tPrice = robuxButton({ Parent = r1, Size = UDim2.fromOffset(150, 56), Position = UDim2.new(1, -12, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Palette = "Purple", Caption = "+1 Level" }, function()
		send("BuyProduct", "TreadmillUpgrade")
	end)
	productPrice(tPrice, "TreadmillUpgrade")
	upRows.treadmill = { title = t1, sub = s1, sub2 = s2, btn = cashBtn, label = cashLabel, chips = tierChips }
	-- vitrines
	local r2, t2, s3, s4 = row(2, "cases", "Gold")
	local caseBtn, _, caseLabel = Kit.button({ Parent = r2, Size = UDim2.fromOffset(150, 56), Position = UDim2.new(1, -12, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Palette = "Green", Text = "$0", TextStroke = 3 }, function()
		send("UnlockCase")
	end)
	upRows.cases = { title = t2, sub = s3, sub2 = s4, btn = caseBtn, label = caseLabel }
	-- labo
	local r3, t3, s5, s6 = row(3, "flask", "Cyan")
	local slotFace, slotPrice = robuxButton({ Parent = r3, Size = UDim2.fromOffset(150, 56), Position = UDim2.new(1, -12, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Palette = "Purple", Caption = "+2 Slots" }, function()
		send("BuyPass", "MoreGrading")
	end)
	passPrice(slotPrice, "MoreGrading")
	upRows.lab = { title = t3, sub = s5, sub2 = s6, btn = slotFace }
end

refreshers.Upgrades = function()
	if not state then
		return
	end
	local level = state.Treadmill
	local tier, tierIndex = Config.TreadmillTier(level)
	local t = upRows.treadmill
	t.title.Text = ("%s Treadmill  ·  Lv %d / %d"):format(tier.Name, level, Config.TreadmillMaxLevel)
	t.sub.Text = ("+%s Speed/s while you run"):format(Format.short(state.TreadmillRate))
	local nextTier = Config.TreadmillTiers[tierIndex + 1]
	t.sub2.Text = nextTier and ("Next: %s, +%s Speed/s"):format(nextTier.Name, Format.short(Config.TreadmillRate(level + 1) * state.SpeedMultiplier)) or "Supreme treadmill: the best one!"
	for i, chip in t.chips do
		chip.Size = UDim2.fromOffset(22, i == tierIndex and 18 or 12)
		chip.BackgroundTransparency = i <= tierIndex and 0 or 0.6
	end
	if state.TreadmillCost then
		t.label.Text = bigCash(state.TreadmillCost)
		Kit.paint(t.btn, (player:GetAttribute("Cash") or 0) >= state.TreadmillCost and "Green" or "Grey")
	else
		t.label.Text = "MAX"
		Kit.paint(t.btn, "Grey")
	end
	local c = upRows.cases
	c.title.Text = ("Display Cases  ·  %d / %d"):format(state.Cases, Config.GalleryMaxCases)
	c.sub.Text = "Every case shows one card that makes money"
	c.sub2.Text = "You can also unlock them at your base"
	if state.Cases < Config.GalleryMaxCases then
		local cost = Config.CaseCost(state.Cases)
		c.label.Text = bigCash(cost)
		Kit.paint(c.btn, (player:GetAttribute("Cash") or 0) >= cost and "Green" or "Grey")
	else
		c.label.Text = "MAX"
		Kit.paint(c.btn, "Grey")
	end
	local l = upRows.lab
	l.title.Text = ("Grading Lab  ·  %d slots"):format(state.GradingSlots)
	l.sub.Text = ("+%d slot every rebirth"):format(Config.GradingSlotsPerRebirth)
	l.sub2.Text = state.Passes.MoreGrading and "+2 Grading Slots pass: owned" or "Grade more cards at the same time"
	l.btn.Visible = not state.Passes.MoreGrading
end

--------------------------------------------------------------------
-- VENTE (stand "Sell Cards" au bout de la rue)
--------------------------------------------------------------------
local sellContent, sellHeader = makePanel("Sell", "Sell Cards", "Gold", "cashpile", Vector2.new(880, 590))
local sellFilter = "all"
local sellConfirm = false
local sellFilterButtons = {}
local sellTotal = Kit.text({ Parent = sellContent, Text = "", Size = UDim2.new(0.42, 0, 0, 34), Position = UDim2.fromOffset(0, 2), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Money, Stroke = 3 })
local sellFilterRow = Kit.new("Frame", { Parent = sellContent, BackgroundTransparency = 1, Size = UDim2.fromOffset(380, 38), Position = UDim2.new(1, 0, 0, 0), AnchorPoint = Vector2.new(1, 0) })
list(sellFilterRow, 8, true, Enum.HorizontalAlignment.Right)
local sellScroll = scroller(sellContent, UDim2.new(1, 0, 1, -48), UDim2.fromOffset(0, 48))
local sellEmpty = Kit.text({ Parent = sellContent, Text = "No cards to sell here. Steal some in the shops!", Size = UDim2.new(1, -40, 0, 34), Position = UDim2.new(0.5, 0, 0.45, 0), AnchorPoint = Vector2.new(0.5, 0.5), TextColor3 = Color3.fromRGB(190, 195, 210), Stroke = 2.5, Visible = false })
grid(sellScroll, Vector2.new(150, 284), 12, 5)
pad(sellScroll, 6, 4)
local sellAllFace, sellAllLabel
sellAllFace, _, sellAllLabel = Kit.button({ Parent = sellHeader, Size = UDim2.fromOffset(220, 52), Position = UDim2.new(1, -78, 0, 10), AnchorPoint = Vector2.new(1, 0), Palette = "Red", Text = "SELL ALL", TextStroke = 3 }, function()
	if not sellConfirm then
		-- premier clic : on demande confirmation
		sellConfirm = true
		sellAllLabel.Text = "SURE? CLICK AGAIN"
		Kit.paint(sellAllFace, "Orange")
		task.delay(3, function()
			sellConfirm = false
			sellAllLabel.Text = "SELL ALL"
			Kit.paint(sellAllFace, "Red")
		end)
		return
	end
	sellConfirm = false
	sellAllLabel.Text = "SELL ALL"
	Kit.paint(sellAllFace, "Red")
	send("SellAll", sellFilter)
end)

local function refreshSell()
	if not state then
		return
	end
	Kit.clear(sellScroll)
	local items = {}
	if sellFilter ~= "base" then
		for i, raw in state.Raw do
			table.insert(items, { id = raw.Id, f = raw.F, value = Cards.RawSellValue(raw.Id, raw.F), where = "Waiting in lab", action = "SellRaw", arg = i })
		end
	end
	if sellFilter ~= "raw" then
		for _, c in state.Cards or {} do
			table.insert(items, { id = c.Id, f = c.F, g = c.G, value = Cards.SellValue(c.Id, c.F, c.G), where = "In your base", action = "SellCase", arg = c.S })
		end
	end
	local total = 0
	for i, it in items do
		total += it.value
		local cell = Kit.well({ Parent = sellScroll, LayoutOrder = i, Color = Color3.fromRGB(10, 12, 20), Transparency = 0.35, Border = 2, BorderColor = Color3.fromRGB(70, 75, 95) })
		local art = Kit.new("Frame", { Parent = cell, BackgroundTransparency = 1, Size = UDim2.fromOffset(136, 190), Position = UDim2.new(0.5, 0, 0, 7), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 2 })
		CardArt.build(art, it.id, it.f, { grade = it.g, zIndex = 2, strokeThickness = 3 })
		Kit.text({ Parent = cell, Text = it.where, Size = UDim2.new(1, -10, 0, 16), Position = UDim2.new(0.5, 0, 0, 200), AnchorPoint = Vector2.new(0.5, 0), TextColor3 = Color3.fromRGB(200, 205, 220), Stroke = 2 })
		Kit.button({ Parent = cell, Size = UDim2.new(1, -16, 0, 50), Position = UDim2.new(0.5, 0, 1, -8), AnchorPoint = Vector2.new(0.5, 1), Palette = "Green", Text = "SELL " .. Format.cash(it.value), TextStroke = 2.5 }, function()
			send(it.action, it.arg)
		end)
	end
	sellEmpty.Visible = #items == 0
	sellTotal.Text = ("%d cards  ·  worth %s"):format(#items, Format.cash(total))
end
refreshers.Sell = refreshSell

for i, info in { { "all", "ALL" }, { "raw", "WAITING" }, { "base", "IN BASE" } } do
	local face = Kit.button({ Parent = sellFilterRow, Size = UDim2.fromOffset(i == 1 and 80 or 130, 38), Palette = i == 1 and "Yellow" or "Dark", Text = info[2], LayoutOrder = i, TextStroke = 2.5 }, function()
		sellFilter = info[1]
		for key, f in sellFilterButtons do
			Kit.paint(f, key == sellFilter and "Yellow" or "Dark")
		end
		refreshSell()
	end)
	sellFilterButtons[info[1]] = face
end

--------------------------------------------------------------------
-- GRADING LAB
--------------------------------------------------------------------
local labContent, labHeader = makePanel("Lab", "Grading Lab", "Cyan", "flask", Vector2.new(820, 560))
Kit.button({ Parent = labHeader, Size = UDim2.fromOffset(170, 52), Position = UDim2.new(1, -258, 0, 10), AnchorPoint = Vector2.new(1, 0), Palette = "Green", Text = "COLLECT ALL", TextStroke = 3 }, function()
	send("CollectAll")
end)
do
	local _, p = robuxButton({ Parent = labHeader, Size = UDim2.fromOffset(170, 52), Position = UDim2.new(1, -78, 0, 10), AnchorPoint = Vector2.new(1, 0), Palette = "Yellow", Caption = "Grade All" }, function()
		send("BuyProduct", "InstantGrade")
	end)
	productPrice(p, "InstantGrade")
end
local labInfo = Kit.text({ Parent = labContent, Text = "", Size = UDim2.new(1, 0, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, Stroke = 3 })
local gradingScroll = Kit.new("ScrollingFrame", {
	Parent = labContent,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 262),
	Position = UDim2.fromOffset(0, 34),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.X,
	ScrollingDirection = Enum.ScrollingDirection.X,
	ScrollBarThickness = 8,
})
list(gradingScroll, 12, true)
pad(gradingScroll, 6, 4)
local rawTitle = Kit.text({ Parent = labContent, Text = "", Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 302), TextXAlignment = Enum.TextXAlignment.Left, Stroke = 3 })
local rawScroll = Kit.new("ScrollingFrame", {
	Parent = labContent,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 120),
	Position = UDim2.fromOffset(0, 334),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.X,
	ScrollingDirection = Enum.ScrollingDirection.X,
	ScrollBarThickness = 8,
})
list(rawScroll, 10, true)
pad(rawScroll, 4, 4)

local gradingTimers: { { label: TextLabel, fill: Frame, face: Frame, btnLabel: TextLabel, entry: any } } = {}

local function refreshLab()
	if not state then
		return
	end
	labInfo.Text = ("%d / %d slots in use"):format(#state.Grading, state.GradingSlots)
	Kit.clear(gradingScroll)
	gradingTimers = {}
	for i = 1, state.GradingSlots do
		local entry = state.Grading[i]
		local slot = Kit.tile({ Parent = gradingScroll, Size = UDim2.fromOffset(170, 244), Palette = entry and RARITY_PALETTE[Cards.ById[entry.Id].Rarity] or "Dark", LayoutOrder = i, Border = 3, Streaks = false })
		if entry then
			local art = Kit.new("Frame", { Parent = slot, BackgroundTransparency = 1, Size = UDim2.fromOffset(100, 140), Position = UDim2.new(0.5, 0, 0, 10), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 2 })
			CardArt.build(art, entry.Id, entry.F, { zIndex = 2, strokeThickness = 3 })
			local _, fill, left = Kit.bar({ Parent = slot, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 156), Palette = "Cyan", ZIndex = 2 })
			left.Size = UDim2.new(1, -12, 1, -6)
			left.TextXAlignment = Enum.TextXAlignment.Center
			local face, _, btnLabel = Kit.button({ Parent = slot, Size = UDim2.new(1, -20, 0, 44), Position = UDim2.new(0.5, 0, 1, -10), AnchorPoint = Vector2.new(0.5, 1), Palette = "Grey", Text = "GRADING", TextStroke = 3 }, function()
				send("Collect", i)
			end)
			table.insert(gradingTimers, { label = left, fill = fill, face = face, btnLabel = btnLabel :: TextLabel, entry = entry })
		else
			Kit.text({ Parent = slot, Text = "EMPTY", Size = UDim2.new(1, -20, 0, 34), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), TextColor3 = Color3.fromRGB(150, 155, 175), Stroke = 2.5 })
		end
	end

	Kit.clear(rawScroll)
	rawTitle.Text = ("Waiting in line  %d / %d"):format(#state.Raw, Config.MaxRawCards)
	for i, raw in state.Raw do
		local card = Kit.tile({ Parent = rawScroll, Size = UDim2.fromOffset(230, 104), Palette = RARITY_PALETTE[Cards.ById[raw.Id].Rarity], LayoutOrder = i, Border = 3, Streaks = false })
		local art = Kit.new("Frame", { Parent = card, BackgroundTransparency = 1, Size = UDim2.fromOffset(62, 86), Position = UDim2.fromOffset(9, 9), ZIndex = 2 })
		CardArt.build(art, raw.Id, raw.F, { zIndex = 2, strokeThickness = 2 })
		Kit.text({ Parent = card, Text = Cards.Name(raw.Id), Size = UDim2.new(1, -86, 0, 26), Position = UDim2.fromOffset(78, 8), TextXAlignment = Enum.TextXAlignment.Left, Stroke = 2.5 })
		Kit.button({ Parent = card, Size = UDim2.fromOffset(70, 42), Position = UDim2.fromOffset(78, 50), Palette = "Blue", Text = "GRADE", TextStroke = 2.5 }, function()
			send("StartRaw", i)
		end)
		Kit.button({ Parent = card, Size = UDim2.fromOffset(64, 42), Position = UDim2.fromOffset(154, 50), Palette = "Red", Text = "SELL", TextStroke = 2.5 }, function()
			send("SellRaw", i)
		end)
	end
end
refreshers.Lab = refreshLab

local function tickLab()
	local now = serverNow()
	for _, t in gradingTimers do
		local entry = t.entry
		local total = Cards.Rarities[Cards.ById[entry.Id].Rarity].GradeTime
		if state.Passes.FastGrading then
			total /= 2
		end
		local left = entry.Ends - now
		if left <= 0 then
			t.label.Text = "READY"
			t.fill.Size = UDim2.fromScale(1, 1)
			t.btnLabel.Text = "COLLECT"
			Kit.paint(t.face, "Green")
		else
			t.label.Text = Format.time(left)
			t.fill.Size = UDim2.fromScale(math.clamp(1 - left / total, 0.03, 1), 1)
		end
	end
end

--------------------------------------------------------------------
-- ADMIN (seulement pour toi et les admins de Config)
--------------------------------------------------------------------
local adminContent = makePanel("Admin", "Admin", "Dark", "flask", Vector2.new(680, 460))
do
	local s = scroller(adminContent)
	grid(s, Vector2.new(196, 50), 10, 3)
	pad(s, 4, 4)
	local order = 0
	local function adminButton(text: string, palette: string, fn: () -> ())
		order += 1
		Kit.button({ Parent = s, Palette = palette, Text = text, LayoutOrder = order, TextStroke = 2.5 }, fn)
	end
	for id, event in Config.Events do
		adminButton(event.Name, "Yellow", function()
			Remotes.Admin:FireServer("Event", id)
		end)
	end
	adminButton("SERVER LUCK", "Green", function()
		Remotes.Admin:FireServer("Luck")
	end)
	adminButton("FREEZE GUARDS", "Cyan", function()
		Remotes.Admin:FireServer("Freeze")
	end)
	adminButton("RESTOCK ALL", "Blue", function()
		Remotes.Admin:FireServer("Restock")
	end)
	adminButton("+1B CASH", "Green", function()
		Remotes.Admin:FireServer("Cash", 1e9)
	end)
	adminButton("+1M SPEED", "Blue", function()
		Remotes.Admin:FireServer("Speed", 1e6)
	end)
	for _, rarity in Cards.RarityOrder do
		adminButton("GIVE " .. rarity:upper(), RARITY_PALETTE[rarity], function()
			Remotes.Admin:FireServer("Card", rarity)
		end)
	end
end

--------------------------------------------------------------------
-- HUD : onglets du haut (Shop / My Base / Upgrades)
--------------------------------------------------------------------
local tabs = Kit.new("Frame", { Name = "Tabs", Parent = gui, BackgroundTransparency = 1, Size = UDim2.fromOffset(560, 74), Position = UDim2.new(0.5, 0, 0, 2), AnchorPoint = Vector2.new(0.5, 0) })
local tabList = list(tabs, 8, true, Enum.HorizontalAlignment.Center)
tabList.VerticalAlignment = Enum.VerticalAlignment.Top
Kit.button({ Parent = tabs, Size = UDim2.fromOffset(156, 56), Palette = "Red", Text = "Shop", LayoutOrder = 1, TextStroke = 3.5, Border = 4 }, function()
	togglePanel("Shop")
end)
local baseTab = Kit.button({ Parent = tabs, Size = UDim2.fromOffset(212, 70), Palette = "Blue", Text = "My Base", LayoutOrder = 2, TextStroke = 4, Border = 4 }, function()
	closePanels()
	send("Home")
end)
local baseBadge = Kit.badge(baseTab)
Kit.button({ Parent = tabs, Size = UDim2.fromOffset(170, 56), Palette = "Lime", Text = "Upgrades", LayoutOrder = 3, TextStroke = 3.5, Border = 4 }, function()
	togglePanel("Upgrades")
end)

-- pastille d'event (seulement quand il se passe quelque chose)
local eventPill = Kit.well({ Name = "Event", Parent = gui, Size = UDim2.fromOffset(380, 34), Position = UDim2.new(0.5, 0, 0, 82), AnchorPoint = Vector2.new(0.5, 0), Color = Color3.fromRGB(20, 20, 30), Transparency = 0.25 })
eventPill.Visible = false
local eventText = Kit.text({ Parent = eventPill, Text = "", Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), TextColor3 = C.Yellow, Stroke = 2.5 })

--------------------------------------------------------------------
-- HUD : gauche (Daily + grille 2x2)
--------------------------------------------------------------------
local left = Kit.new("Frame", { Name = "Left", Parent = gui, BackgroundTransparency = 1, Size = UDim2.fromOffset(228, 300), Position = UDim2.fromOffset(14, 150) })
local dailyBanner = Kit.button({ Parent = left, Size = UDim2.fromOffset(226, 60), Palette = "Lime", Text = "Daily Rewards", TextSize = UDim2.new(1, -16, 1, -14), TextStroke = 3, Border = 4 }, function()
	togglePanel("Daily")
end)
local dailyBadge = Kit.badge(dailyBanner)
local tileGrid = Kit.new("Frame", { Parent = left, BackgroundTransparency = 1, Size = UDim2.fromOffset(228, 228), Position = UDim2.fromOffset(0, 72) })
grid(tileGrid, Vector2.new(108, 108), 10, 2)
local function hudTile(order: number, text: string, palette: string, iconKind: string, onClick: () -> ()): Frame
	local face = Kit.button({ Parent = tileGrid, Palette = palette, LayoutOrder = order, Border = 4 }, onClick)
	icon(iconKind, { Parent = face, Size = UDim2.fromOffset(92, 92), Position = UDim2.new(0.5, 0, 0, -4), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 2 })
	Kit.text({ Parent = face, Text = text, Size = UDim2.new(1, 4, 0, 34), Position = UDim2.new(0.5, 0, 1, 4), AnchorPoint = Vector2.new(0.5, 1), Stroke = 3, ZIndex = 4 })
	return face
end
hudTile(1, "Shop", "Red", "basket", function()
	togglePanel("Shop")
end)
hudTile(2, "Pass", "Yellow", "ticket", function()
	togglePanel("Passes")
end)
local rebirthTile = hudTile(3, "Rebirth", "Purple", "rebirth", function()
	togglePanel("Rebirth")
end)
local rebirthBadge = Kit.badge(rebirthTile)
hudTile(4, "Index", "Blue", "book", function()
	togglePanel("Index")
end)
local adminBtn = Kit.button({ Parent = gui, Size = UDim2.fromOffset(110, 38), Position = UDim2.new(1, -14, 0, 8), AnchorPoint = Vector2.new(1, 0), Palette = "Dark", Text = "Admin", TextStroke = 2.5, Visible = false }, function()
	togglePanel("Admin")
end)

--------------------------------------------------------------------
-- HUD : droite (offres)
--------------------------------------------------------------------
local right = Kit.new("Frame", { Name = "Right", Parent = gui, BackgroundTransparency = 1, Size = UDim2.fromOffset(210, 360), Position = UDim2.new(1, -14, 0, 150), AnchorPoint = Vector2.new(1, 0) })
list(right, 10, false, Enum.HorizontalAlignment.Center)
local starterOffer = Kit.new("Frame", { Parent = right, BackgroundTransparency = 1, Size = UDim2.fromOffset(170, 150), LayoutOrder = 1 })
do
	Kit.text({ Parent = starterOffer, Text = "Starter Pack", Size = UDim2.new(1, 0, 0, 26), Stroke = 3 })
	icon("gift", { Parent = starterOffer, Size = UDim2.fromOffset(110, 110), Position = UDim2.new(0.5, 0, 0, 20), AnchorPoint = Vector2.new(0.5, 0) })
	local _, price = Kit.price({ Parent = starterOffer, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0.5, 0, 1, 0), AnchorPoint = Vector2.new(0.5, 1), IconSize = 26, TextWidth = 48, Stroke = 3 })
	productPrice(price, "StarterPack")
	local hit = Kit.new("TextButton", { Parent = starterOffer, BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 10 })
	hit.Activated:Connect(function()
		showPanel("Shop")
	end)
end
local function offer(order: number, text: string, palette: string, passKey: string): Frame
	local holder = Kit.new("Frame", { Parent = right, BackgroundTransparency = 1, Size = UDim2.fromOffset(206, 86), LayoutOrder = order })
	Kit.button({ Parent = holder, Size = UDim2.fromOffset(206, 60), Palette = palette, Text = text, TextStroke = 3.5, Border = 4 }, function()
		send("BuyPass", passKey)
	end)
	local _, price = Kit.price({ Parent = holder, Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0.5, 0, 1, 0), AnchorPoint = Vector2.new(0.5, 1), IconSize = 24, TextWidth = 44, Stroke = 3 })
	passPrice(price, passKey)
	return holder
end
local moneyOffer = offer(2, "X2 Money", "Rainbow", "DoubleCash")
local luckOffer = offer(3, "X2 Luck", "Candy", "Lucky")

--------------------------------------------------------------------
-- HUD : bas gauche (rebirths, speed, cash, friend boost)
--------------------------------------------------------------------
local stats = Kit.new("Frame", { Name = "Stats", Parent = gui, BackgroundTransparency = 1, Size = UDim2.fromOffset(380, 196), Position = UDim2.new(0, 12, 1, -10), AnchorPoint = Vector2.new(0, 1) })
icon("rebirth", { Parent = stats, Size = UDim2.fromOffset(44, 44), Position = UDim2.fromOffset(0, 0) })
local rebirthText = Kit.text({ Parent = stats, Text = "0", Size = UDim2.fromOffset(120, 38), Position = UDim2.fromOffset(50, 3), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 80, 90), Stroke = 3 })
icon("bolt", { Parent = stats, Size = UDim2.fromOffset(44, 44), Position = UDim2.fromOffset(0, 44) })
local speedText = Kit.text({ Parent = stats, Text = "0", Size = UDim2.fromOffset(260, 38), Position = UDim2.fromOffset(50, 47), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Speed, Stroke = 3 })
local cashText = Kit.text({ Parent = stats, Text = "$0", Size = UDim2.fromOffset(260, 56), Position = UDim2.fromOffset(0, 90), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Money, Stroke = 4 })
local cashPlus = Kit.button({ Parent = stats, Size = UDim2.fromOffset(42, 42), Position = UDim2.fromOffset(266, 97), Palette = "Green", Text = "+", Radius = 5, TextStroke = 3 }, function()
	showPanel("Shop")
end)
local incomeText = Kit.text({ Parent = stats, Text = "+$0/s", Size = UDim2.fromOffset(200, 22), Position = UDim2.fromOffset(4, 144), TextXAlignment = Enum.TextXAlignment.Left, Stroke = 2.5 })
local friendLabel = Kit.text({ Parent = stats, Text = "Friend Boost: +0%", Size = UDim2.fromOffset(300, 30), Position = UDim2.fromOffset(2, 166), TextXAlignment = Enum.TextXAlignment.Left, Stroke = 3 })

local function placeCashPlus()
	-- le "+" suit la longueur du montant
	local n = #cashText.Text
	cashPlus.Position = UDim2.fromOffset(math.clamp(n * 31 + 14, 90, 320), 97)
end

--------------------------------------------------------------------
-- HUD : bas centre (barre de vitesse conseillée + boosts)
--------------------------------------------------------------------
local center = Kit.new("Frame", { Name = "SpeedBar", Parent = gui, BackgroundTransparency = 1, Size = UDim2.fromOffset(560, 124), Position = UDim2.new(0.5, 0, 1, -8), AnchorPoint = Vector2.new(0.5, 1) })
local speedMult = Kit.text({ Parent = center, Text = "", Size = UDim2.fromOffset(260, 28), Position = UDim2.new(1, -4, 0, 0), AnchorPoint = Vector2.new(1, 0), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = C.Yellow, StrokeColor = Color3.fromRGB(80, 30, 0), Stroke = 3 })
local _, speedFill, speedLeft, speedRight = Kit.bar({ Parent = center, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 30), Palette = "Orange" })
local boostRow = Kit.new("Frame", { Parent = center, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), Position = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(0, 1) })
list(boostRow, 10, true, Enum.HorizontalAlignment.Center)
for i, b in { { "+10 min Speed", "SpeedSmall", C.Yellow }, { "+1 hour Speed", "SpeedBig", C.Speed }, { "+1 Treadmill", "TreadmillUpgrade", Color3.fromRGB(230, 120, 255) } } do
	local face = Kit.button({ Parent = boostRow, Size = UDim2.fromOffset(180, 46), Palette = "Green", LayoutOrder = i, Text = b[1], TextStroke = 3 }, function()
		send("BuyProduct", b[2])
	end)
	local label = face:FindFirstChild("Label") :: TextLabel
	label.TextColor3 = b[3]
end

--------------------------------------------------------------------
-- HUD : bas droite (multiplicateurs + prochain event)
--------------------------------------------------------------------
local chips = Kit.new("Frame", { Name = "Multipliers", Parent = gui, BackgroundTransparency = 1, Size = UDim2.fromOffset(250, 110), Position = UDim2.new(1, -12, 1, -8), AnchorPoint = Vector2.new(1, 1) })
local forecastText = Kit.text({ Parent = chips, Text = "", Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(220, 225, 240), Stroke = 2.5 })
local chipRow = Kit.new("Frame", { Parent = chips, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 80), Position = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(0, 1) })
list(chipRow, 6, true, Enum.HorizontalAlignment.Right)
local function chip(order: number, iconKind: string, color: Color3): TextLabel
	local f = Kit.new("Frame", { Parent = chipRow, BackgroundTransparency = 1, Size = UDim2.fromOffset(72, 80), LayoutOrder = order })
	icon(iconKind, { Parent = f, Size = UDim2.fromOffset(60, 60), Position = UDim2.new(0.5, 0, 0, 0), AnchorPoint = Vector2.new(0.5, 0) })
	return Kit.text({ Parent = f, Text = "X1", Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0.5, 0, 1, 0), AnchorPoint = Vector2.new(0.5, 1), TextColor3 = color, Stroke = 3 })
end
local cashChip = chip(1, "cash", C.Money)
local speedChip = chip(2, "bolt", C.Speed)
local luckChip = chip(3, "clover", Color3.fromRGB(255, 120, 200))

--------------------------------------------------------------------
-- Bandeau "tu portes une carte"
--------------------------------------------------------------------
local carry = Kit.tile({ Name = "Carry", Parent = gui, Size = UDim2.fromOffset(470, 62), Position = UDim2.new(0.5, 0, 1, -146), AnchorPoint = Vector2.new(0.5, 1), Palette = "Red", Border = 4 })
carry.Visible = false
Kit.new("UIScale", { Parent = carry })
Kit.text({ Parent = carry, Text = "RUN BACK TO YOUR BASE!", Size = UDim2.new(1, -24, 1, -14), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Stroke = 3.5 })

--------------------------------------------------------------------
-- Bannière de zone (quand on entre dans une boutique)
--------------------------------------------------------------------
local zoneBanner = Kit.new("Frame", { Name = "ZoneBanner", Parent = gui, BackgroundTransparency = 1, Size = UDim2.fromOffset(640, 110), Position = UDim2.new(0.5, 0, 0.2, 0), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false })
Kit.new("UIScale", { Parent = zoneBanner })
local zoneTitle = Kit.text({ Parent = zoneBanner, Text = "", Size = UDim2.new(1, 0, 0, 62), Stroke = 4.5 })
local zoneSub = Kit.text({ Parent = zoneBanner, Text = "", Size = UDim2.new(1, 0, 0, 32), Position = UDim2.fromOffset(0, 66), Stroke = 3 })

--------------------------------------------------------------------
-- Messages, annonces, révélation
--------------------------------------------------------------------
local toastHolder = Kit.new("Frame", { Name = "Toasts", Parent = gui, BackgroundTransparency = 1, Size = UDim2.fromOffset(460, 200), Position = UDim2.new(0.5, 0, 1, -160), AnchorPoint = Vector2.new(0.5, 1), ZIndex = 40 })
list(toastHolder, 6, false, Enum.HorizontalAlignment.Center).VerticalAlignment = Enum.VerticalAlignment.Bottom
local toastCount = 0
Remotes.Notify.OnClientEvent:Connect(function(text: string, kind: string)
	toastCount += 1
	local color = (kind == "error" and Color3.fromRGB(255, 90, 90)) or (kind == "reward" and C.Money) or (kind == "cash" and C.Yellow) or C.White
	local toast = Kit.well({ Parent = toastHolder, Size = UDim2.fromOffset(440, 40), Color = Color3.fromRGB(16, 18, 28), Transparency = 0.2, LayoutOrder = toastCount })
	Kit.text({ Parent = toast, Text = text, Size = UDim2.new(1, -20, 1, -10), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), TextColor3 = color, Stroke = 2.5 })
	Kit.pop(toast)
	task.delay(3, function()
		toast:Destroy()
	end)
	local children = {}
	for _, c in toastHolder:GetChildren() do
		if c:IsA("GuiObject") then
			table.insert(children, c)
		end
	end
	if #children > 4 then
		table.sort(children, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		children[1]:Destroy()
	end
end)

local announce = Kit.new("Frame", { Name = "Announce", Parent = gui, BackgroundTransparency = 1, Size = UDim2.fromOffset(700, 100), Position = UDim2.new(0.5, 0, 0.3, 0), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 45 })
Kit.new("UIScale", { Parent = announce })
local announceTitle = Kit.text({ Parent = announce, Text = "", Size = UDim2.new(1, 0, 0, 64), Stroke = 5 })
local announceSub = Kit.text({ Parent = announce, Text = "", Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 68), Stroke = 3 })
local announceToken = 0
Remotes.Announce.OnClientEvent:Connect(function(title: string, sub: string, kind: string)
	announceToken += 1
	local token = announceToken
	local rarity = Cards.Rarities[kind]
	announceTitle.Text = title
	announceTitle.TextColor3 = rarity and (kind == "Secret" and C.White or rarity.Color) or (kind == "event" and C.Yellow) or (kind == "luck" and C.Money) or Color3.fromRGB(255, 90, 90)
	announceSub.Text = sub
	announce.Visible = true
	announce.Rotation = -3
	Kit.pop(announce)
	task.delay(4, function()
		if token == announceToken then
			announce.Visible = false
		end
	end)
end)

-- révélation de la note après gradation
local reveal = Kit.tile({ Name = "Reveal", Parent = gui, Size = UDim2.fromOffset(310, 480), Position = UDim2.fromScale(0.5, 0.52), AnchorPoint = Vector2.new(0.5, 0.5), Palette = "Dark", Border = 5, Radius = 10, ZIndex = 60 })
reveal.Visible = false
Kit.new("UIScale", { Parent = reveal })
local revealArt = Kit.new("Frame", { Parent = reveal, BackgroundTransparency = 1, Size = UDim2.fromOffset(240, 336), Position = UDim2.fromOffset(35, 20), ZIndex = 2 })
local revealGrade = Kit.text({ Parent = reveal, Text = "", Size = UDim2.new(1, -20, 0, 44), Position = UDim2.fromOffset(10, 362), Stroke = 3.5, ZIndex = 3 })
local revealSub = Kit.text({ Parent = reveal, Text = "", Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 410), TextColor3 = C.Money, Stroke = 2.5, ZIndex = 3 })
local revealToken = 0
Remotes.Reveal.OnClientEvent:Connect(function(info)
	revealToken += 1
	local token = revealToken
	Kit.clear(revealArt)
	CardArt.build(revealArt, info.Id, info.F, { grade = info.G, zIndex = 2, strokeThickness = 6 })
	local gradeName = Cards.GradeNames[info.G]
	revealGrade.Text = ("GRADE %d  ·  %s"):format(info.G, gradeName:upper())
	revealGrade.TextColor3 = info.G >= 9 and C.Yellow or (info.G >= 7 and C.Money or C.White)
	Kit.paint(reveal, info.G >= 10 and "Rainbow" or (info.G >= 9 and "Gold" or "Dark"))
	revealSub.Text = "+" .. Format.cash(Cards.IncomeOf(info.Id, info.F, info.G) * (state and state.CashMultiplier or 1)) .. "/s in your base"
	reveal.Visible = true
	reveal.Rotation = 0
	Kit.pop(reveal)
	TweenService:Create(reveal, TweenInfo.new(0.6, Enum.EasingStyle.Back), { Rotation = -3 }):Play()
	task.delay(3.2, function()
		if token == revealToken then
			reveal.Visible = false
		end
	end)
end)

--------------------------------------------------------------------
-- Mise à jour
--------------------------------------------------------------------
local function nextZone(speed: number)
	for i, zone in Config.Zones do
		if speed < zone.Speed then
			return i, zone
		end
	end
	return nil, nil
end

local function renderStats()
	local cash = player:GetAttribute("Cash") or 0
	local income = player:GetAttribute("Income") or 0
	local speed = player:GetAttribute("Speed") or 0
	cashText.Text = bigCash(cash)
	placeCashPlus()
	incomeText.Text = "+" .. Format.cash(income) .. "/s"
	speedText.Text = Format.short(speed) .. " Speed"
	local i, zone = nextZone(speed)
	if zone then
		local prev = Config.Zones[i - 1] and Config.Zones[i - 1].Speed or 0
		speedLeft.Text = "Speed " .. Format.short(speed)
		speedRight.Text = ("%s: %s"):format(zone.Name, Format.short(zone.Speed))
		-- progression en échelle log pour que la barre bouge vraiment
		local a, b = math.log10(1 + prev), math.log10(1 + zone.Speed)
		speedFill.Size = UDim2.fromScale(math.clamp((math.log10(1 + speed) - a) / (b - a), 0.02, 1), 1)
	else
		speedLeft.Text = "Speed " .. Format.short(speed)
		speedRight.Text = "Every shop unlocked"
		speedFill.Size = UDim2.fromScale(1, 1)
	end
end
for _, attr in { "Cash", "Income", "Speed" } do
	player:GetAttributeChangedSignal(attr):Connect(renderStats)
end
renderStats()

player:GetAttributeChangedSignal("Carrying"):Connect(function()
	local id = player:GetAttribute("Carrying")
	carry.Visible = id ~= nil
	if id then
		Kit.pop(carry)
	end
end)

local function render()
	if not state then
		return
	end
	rebirthText.Text = tostring(state.Rebirths)
	friendLabel.Text = ("Friend Boost: +%d%%"):format(math.floor(state.FriendBoost * 100 + 0.5))
	speedMult.Text = state.SpeedMultiplier > 1 and ("x%s Speed Multiplier"):format(tostring(math.floor(state.SpeedMultiplier * 100 + 0.5) / 100)) or ""
	cashChip.Text = mult(state.CashMultiplier)
	speedChip.Text = mult(state.SpeedMultiplier)
	luckChip.Text = state.Passes.Lucky and "X2" or "N/A"
	adminBtn.Visible = state.IsAdmin
	rebirthBadge.Visible = (player:GetAttribute("Cash") or 0) >= state.RebirthCost
	starterOffer.Visible = not state.StarterBought
	moneyOffer.Visible = not state.Passes.DoubleCash
	luckOffer.Visible = not state.Passes.Lucky
	for key, b in passButtons do
		local owned = state.Passes[key] == true
		b.owned.Visible = owned
		b.price.Parent.Visible = not owned
		Kit.paint(b.face, owned and "Grey" or "Green")
	end
	if openPanel and refreshers[openPanel] then
		refreshers[openPanel]()
	end
end

Remotes.State.OnClientEvent:Connect(function(s)
	state = s
	stateAt = os.clock()
	render()
end)
Remotes.EventState.OnClientEvent:Connect(function(e)
	eventState = e
end)
send("Sync")

-- comptoir du labo
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Name == "LabPrompt" then
		showPanel("Lab")
	elseif prompt.Name == "StandUpgrades" then
		showPanel("Upgrades")
	elseif prompt.Name == "StandSell" then
		showPanel("Sell")
	end
end)

-- zone actuelle, timers, pastilles
local currentZone = 0
local zoneToken = 0
local function showZone(index: number)
	zoneToken += 1
	local token = zoneToken
	if index == 0 then
		zoneTitle.Text = "SAFE ZONE"
		zoneTitle.TextColor3 = C.Money
		zoneSub.Text = "Bases, treadmills and grading labs"
	else
		local zone = Config.Zones[index]
		zoneTitle.Text = zone.Name
		zoneTitle.TextColor3 = zone.Accent
		local speed = player:GetAttribute("Speed") or 0
		if zone.Speed > 0 then
			zoneSub.Text = ("Recommended Speed: %s%s"):format(Format.short(zone.Speed), speed < zone.Speed and "  ·  watch out!" or "")
		else
			zoneSub.Text = "Grab a card and run back to your base!"
		end
	end
	zoneBanner.Visible = true
	Kit.pop(zoneBanner)
	task.delay(2.6, function()
		if token == zoneToken then
			zoneBanner.Visible = false
		end
	end)
end

task.spawn(function()
	while true do
		task.wait(0.25)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local z = root.Position.Z
			local index = 0
			if z >= 20 then
				index = math.clamp(math.floor((z - 20) / 200) + 1, 1, #Config.Zones)
			end
			if index ~= currentZone and not (z >= 0 and z < 20) then
				currentZone = index
				showZone(index)
			end
		end

		local now = workspace:GetServerTimeNow()
		local parts = {}
		local frozen = eventState.FrozenUntil and eventState.FrozenUntil > now
		if frozen then
			table.insert(parts, "GUARDS FROZEN " .. Format.time(eventState.FrozenUntil - now))
		end
		if eventState.Event and eventState.EndsAt and eventState.EndsAt > now then
			table.insert(parts, ("%s  %s"):format(Config.Events[eventState.Event].Name, Format.time(eventState.EndsAt - now)))
		end
		if eventState.LuckUntil and eventState.LuckUntil > now then
			table.insert(parts, ("LUCK x%d  %s"):format(Config.ServerLuckMultiplier, Format.time(eventState.LuckUntil - now)))
		end
		eventPill.Visible = #parts > 0
		eventText.Text = table.concat(parts, "   ·   ")
		if eventState.NextEvent and eventState.NextAt and eventState.NextAt > now and eventState.NextAt - now < 86400 then
			local name = Config.Events[eventState.NextEvent].Name
			forecastText.Text = ("Next: %s in %s"):format(name:sub(1, 1) .. name:sub(2):lower(), Format.time(eventState.NextAt - now))
		else
			forecastText.Text = ""
		end

		if state then
			local ready = 0
			for _, entry in state.Grading do
				if entry.Ends <= serverNow() then
					ready += 1
				end
			end
			baseBadge.Visible = ready > 0
			dailyBadge.Visible = state.DailyReady or dailyLeft() <= 0
			if openPanel == "Lab" then
				tickLab()
			elseif openPanel == "Daily" or openPanel == "Rebirth" then
				refreshers[openPanel]()
			end
		end
	end
end)
