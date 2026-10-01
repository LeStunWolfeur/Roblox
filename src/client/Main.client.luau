-- Interface du joueur

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
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Kit = require(script.Parent.UI.Kit)
local Icons = require(script.Parent.UI.Icons)

local C = Kit.Colors
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local state: any = nil
local stateAt = os.clock()
local eventState: any = {}

local function send(action: string, a: any?, b: any?)
	Remotes.Action:FireServer(action, a, b)
end

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
	rootScale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 760), 0.55, 1.15)
end
updateScale()
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

local priceCache: { [string]: string } = {}
local function priceText(id: number, infoType: Enum.InfoType): string
	if id == 0 then
		return "SOON"
	end
	local key = tostring(infoType) .. id
	if not priceCache[key] then
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
		priceCache[key] = (ok and info and info.PriceInRobux) and ("R$ " .. info.PriceInRobux) or "R$"
	end
	return priceCache[key]
end

local function serverNow(): number
	if not state then
		return os.time()
	end
	return state.Now + (os.clock() - stateAt)
end

--------------------------------------------------------------------
-- HUD : vitesse, cash, friend boost (bas gauche)
--------------------------------------------------------------------
local stats = Kit.new("Frame", {
	Parent = gui,
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(360, 200),
	Position = UDim2.new(0, 16, 1, -16),
	AnchorPoint = Vector2.new(0, 1),
})
local function iconBox(parent: Instance, kind: string, color: Color3, pos: UDim2, size: number)
	local f = Kit.new("Frame", { Parent = parent, BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Position = pos, ZIndex = 5 })
	Icons.draw(kind, f, color, 5)
	return f
end
local function bigText(parent: Instance, pos: UDim2, size: UDim2, color: Color3, text: string)
	local l = Kit.label({ Parent = parent, Position = pos, Size = size, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = color, Text = text, ZIndex = 6 })
	Kit.textStroke(3.5).Parent = l
	return l
end
-- prochaine zone
local nextZoneLabel = Kit.label({
	Parent = stats,
	Size = UDim2.fromOffset(300, 18),
	Position = UDim2.fromOffset(4, 0),
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Kit.Body,
	TextColor3 = C.White,
	Text = "",
	ZIndex = 6,
})
Kit.textStroke(2).Parent = nextZoneLabel
local zoneBarBack = Kit.new("Frame", {
	Parent = stats,
	BackgroundColor3 = C.Ink2,
	Size = UDim2.fromOffset(250, 10),
	Position = UDim2.fromOffset(4, 22),
	ZIndex = 5,
}, { Kit.corner(5), Kit.stroke(2) })
local zoneBarFill = Kit.new("Frame", { Parent = zoneBarBack, BackgroundColor3 = C.Blue, Size = UDim2.fromScale(0, 1), ZIndex = 6 }, { Kit.corner(5) })
-- vitesse
iconBox(stats, "shoe", C.Blue, UDim2.fromOffset(0, 40), 46)
local speedLabel = bigText(stats, UDim2.fromOffset(54, 40), UDim2.fromOffset(170, 46), Color3.fromRGB(120, 170, 255), "0")
local multLabel = bigText(stats, UDim2.fromOffset(226, 48), UDim2.fromOffset(110, 32), C.Green, "")
-- cash
iconBox(stats, "cash", C.Green, UDim2.fromOffset(0, 92), 46)
local cashLabel = bigText(stats, UDim2.fromOffset(54, 90), UDim2.fromOffset(220, 52), C.Green, "$0")
local incomeLabel = bigText(stats, UDim2.fromOffset(56, 140), UDim2.fromOffset(200, 20), C.White, "+$0/s")
-- friend boost
local friendLabel = bigText(stats, UDim2.fromOffset(4, 168), UDim2.fromOffset(220, 28), C.White, "Friend Boost: +0%")
Kit.button({
	Parent = stats,
	Size = UDim2.fromOffset(34, 30),
	Position = UDim2.fromOffset(232, 166),
	Color = C.Green,
	Text = "+",
	TextColor = C.White,
	TextStroke = true,
	Shadow = 3,
}, function()
	pcall(function()
		game:GetService("SocialService"):PromptGameInvite(player)
	end)
end)

--------------------------------------------------------------------
-- HUD : lieu actuel + event (haut centre)
--------------------------------------------------------------------
local _, placeFace = Kit.sticker({
	Parent = gui,
	Size = UDim2.fromOffset(340, 56),
	Position = UDim2.new(0.5, 0, 0, 10),
	AnchorPoint = Vector2.new(0.5, 0),
	Color = C.Ink2,
})
local placeLabel = Kit.label({
	Parent = placeFace,
	Size = UDim2.new(1, -20, 0, 30),
	Position = UDim2.fromOffset(10, 4),
	Text = "SAFE ZONE",
	ZIndex = 5,
})
Kit.textStroke(3).Parent = placeLabel
local placeSub = Kit.label({
	Parent = placeFace,
	Size = UDim2.new(1, -20, 0, 14),
	Position = UDim2.fromOffset(10, 36),
	Font = Kit.Body,
	TextColor3 = C.Green,
	Text = "Your gallery, the lab and the track are here",
	ZIndex = 5,
})

local eventHolder, eventFace = Kit.sticker({
	Parent = gui,
	Size = UDim2.fromOffset(300, 40),
	Position = UDim2.new(0.5, 0, 0, 76),
	AnchorPoint = Vector2.new(0.5, 0),
	Color = C.Yellow,
}, 4)
eventHolder.Visible = false
local eventLabel = Kit.label({
	Parent = eventFace,
	Size = UDim2.new(1, -16, 1, -10),
	Position = UDim2.fromOffset(8, 5),
	TextColor3 = C.Ink,
	Text = "",
	ZIndex = 5,
})

--------------------------------------------------------------------
-- Bandeau "tu portes une carte"
--------------------------------------------------------------------
local carryHolder, carryFace = Kit.sticker({
	Parent = gui,
	Size = UDim2.fromOffset(460, 58),
	Position = UDim2.new(0.5, 0, 1, -110),
	AnchorPoint = Vector2.new(0.5, 1),
	Color = C.Pink,
}, 5)
carryHolder.Visible = false
local carryLabel = Kit.label({
	Parent = carryFace,
	Size = UDim2.new(1, -20, 1, -12),
	Position = UDim2.fromOffset(10, 6),
	Text = "",
	ZIndex = 5,
})
Kit.textStroke(3).Parent = carryLabel

--------------------------------------------------------------------
-- Panneaux
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
	openPanel = name
	if refreshers[name] then
		refreshers[name]()
	end
end

local function togglePanel(name: string)
	if openPanel == name then
		closePanels()
	else
		showPanel(name)
	end
end

local function makePanel(name: string, title: string, accent: Color3, size: Vector2?): Frame
	local s = size or Vector2.new(660, 460)
	local holder, face = Kit.sticker({
		Name = name .. "Panel",
		Parent = gui,
		Size = UDim2.fromOffset(s.X, s.Y),
		Position = UDim2.fromScale(0.5, 0.53),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = C.Paper,
		ZIndex = 20,
		Radius = 10,
	}, 8)
	holder.Visible = false
	Kit.new("UIScale", { Parent = holder })
	local tagHolder, tag = Kit.sticker({
		Parent = face,
		Size = UDim2.fromOffset(250, 52),
		Position = UDim2.fromOffset(-14, -26),
		Color = accent,
		ZIndex = 30,
	}, 4)
	tagHolder.Rotation = -3
	local t = Kit.label({ Parent = tag, Size = UDim2.fromScale(1, 1), Text = title, ZIndex = 32 })
	Kit.padding(8).Parent = t
	Kit.textStroke(3).Parent = t
	Kit.button({
		Parent = face,
		Size = UDim2.fromOffset(46, 46),
		Position = UDim2.new(1, -30, 0, -16),
		Color = C.Pink,
		Text = "X",
		TextColor = C.White,
		TextStroke = true,
		ZIndex = 30,
	}, closePanels)
	local content = Kit.new("Frame", {
		Name = "Content",
		Parent = face,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -40, 1, -60),
		Position = UDim2.fromOffset(20, 42),
		ZIndex = 22,
	})
	panels[name] = holder
	return content
end

local function scrollGrid(parent: Instance, cell: UDim2, cols: number, size: UDim2?, position: UDim2?): ScrollingFrame
	local scroll = Kit.new("ScrollingFrame", {
		Parent = parent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = size or UDim2.fromScale(1, 1),
		Position = position or UDim2.new(),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = C.Ink,
		ZIndex = 23,
	})
	Kit.new("UIGridLayout", {
		Parent = scroll,
		CellSize = cell,
		CellPadding = UDim2.fromOffset(14, 14),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirectionMaxCells = cols,
	})
	Kit.new("UIPadding", {
		Parent = scroll,
		PaddingTop = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 10),
	})
	return scroll
end

local function clearChildren(frame: Instance)
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function smallText(parent: Instance, text: string, props: { [string]: any }?)
	local p = {
		Parent = parent,
		Font = Kit.Body,
		TextColor3 = C.Ink,
		Text = text,
		ZIndex = 26,
	}
	for k, v in props or {} do
		p[k] = v
	end
	return Kit.label(p)
end

--------------------------------------------------------------------
-- GRADING LAB
--------------------------------------------------------------------
local labContent = makePanel("Lab", "GRADING LAB", C.Blue, Vector2.new(720, 480))
local labTop = Kit.new("Frame", { Parent = labContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), ZIndex = 23 })
local labInfo = smallText(labTop, "", {
	Size = UDim2.new(0.5, 0, 1, 0),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = C.Grey,
})
Kit.button({
	Parent = labTop,
	Size = UDim2.fromOffset(150, 36),
	Position = UDim2.new(1, -312, 0, 0),
	Color = C.Green,
	Text = "COLLECT ALL",
	ZIndex = 24,
}, function()
	send("CollectAll")
end)
local _, gradeNowBtn = Kit.button({
	Parent = labTop,
	Size = UDim2.fromOffset(150, 36),
	Position = UDim2.new(1, -150, 0, 0),
	Color = C.Yellow,
	Text = "GRADE ALL NOW",
	ZIndex = 24,
}, function()
	send("BuyProduct", "InstantGrade")
end)
gradeNowBtn.Parent.Parent.Visible = Config.Products.InstantGrade.Id ~= 0

local gradingGrid = scrollGrid(labContent, UDim2.fromOffset(150, 230), 4, UDim2.new(1, 0, 0, 250), UDim2.fromOffset(0, 50))
local rawTitle = smallText(labContent, "WAITING IN LINE", {
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.fromOffset(0, 306),
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Kit.Title,
})
local rawList = Kit.new("ScrollingFrame", {
	Parent = labContent,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 90),
	Position = UDim2.fromOffset(0, 330),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.X,
	ScrollingDirection = Enum.ScrollingDirection.X,
	ScrollBarThickness = 6,
	ZIndex = 23,
})
Kit.new("UIListLayout", { Parent = rawList, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10) })

local gradingTimers: { { label: TextLabel, bar: Frame, btn: TextButton, entry: any } } = {}

local function refreshLab()
	if not state then
		return
	end
	labInfo.Text = ("%d / %d slots in use"):format(#state.Grading, state.GradingSlots)
	clearChildren(gradingGrid)
	gradingTimers = {}
	for i = 1, state.GradingSlots do
		local entry = state.Grading[i]
		local _, face = Kit.sticker({ Parent = gradingGrid, Color = C.White, LayoutOrder = i, ZIndex = 24 }, 4)
		if entry then
			local art = Kit.new("Frame", {
				Parent = face,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(100, 140),
				Position = UDim2.new(0.5, -50, 0, 10),
				ZIndex = 25,
			})
			CardArt.build(art, entry.Id, entry.F, { zIndex = 25, strokeThickness = 3 })
			local barBack = Kit.new("Frame", {
				Parent = face,
				BackgroundColor3 = C.Ink2,
				Size = UDim2.new(1, -20, 0, 10),
				Position = UDim2.fromOffset(10, 158),
				ZIndex = 25,
			}, { Kit.corner(5) })
			local bar = Kit.new("Frame", { Parent = barBack, BackgroundColor3 = C.Blue, Size = UDim2.fromScale(0, 1), ZIndex = 26 }, { Kit.corner(5) })
			local label = smallText(face, "", { Size = UDim2.new(1, -20, 0, 14), Position = UDim2.fromOffset(10, 172) })
			local _, btn = Kit.button({
				Parent = face,
				Size = UDim2.new(1, -24, 0, 30),
				Position = UDim2.new(0, 12, 1, -40),
				Color = C.Grey,
				Text = "GRADING...",
				ZIndex = 26,
			}, function()
				send("Collect", i)
			end)
			table.insert(gradingTimers, { label = label, bar = bar, btn = btn, entry = entry })
		else
			smallText(face, "EMPTY SLOT", { Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0.5, -10), TextColor3 = C.Grey })
		end
	end

	clearChildren(rawList)
	rawTitle.Text = ("WAITING IN LINE  %d / %d"):format(#state.Raw, Config.MaxRawCards)
	for i, raw in state.Raw do
		local _, face = Kit.sticker({ Parent = rawList, Size = UDim2.fromOffset(190, 80), Color = C.White, LayoutOrder = i, ZIndex = 24 }, 3)
		local art = Kit.new("Frame", { Parent = face, BackgroundTransparency = 1, Size = UDim2.fromOffset(46, 64), Position = UDim2.fromOffset(8, 8), ZIndex = 25 })
		CardArt.build(art, raw.Id, raw.F, { zIndex = 25, strokeThickness = 2 })
		smallText(face, Cards.Name(raw.Id), { Size = UDim2.new(1, -66, 0, 18), Position = UDim2.fromOffset(60, 8), TextXAlignment = Enum.TextXAlignment.Left })
		Kit.button({ Parent = face, Size = UDim2.fromOffset(56, 28), Position = UDim2.fromOffset(60, 42), Color = C.Blue, Text = "GRADE", ZIndex = 26 }, function()
			send("StartRaw", i)
		end)
		Kit.button({ Parent = face, Size = UDim2.fromOffset(56, 28), Position = UDim2.fromOffset(124, 42), Color = C.Pink, Text = "SELL", ZIndex = 26 }, function()
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
			t.bar.Size = UDim2.fromScale(1, 1)
			t.btn.Text = "COLLECT"
			t.btn.Parent.BackgroundColor3 = C.Green
		else
			t.label.Text = Format.time(left)
			t.bar.Size = UDim2.fromScale(math.clamp(1 - left / total, 0, 1), 1)
		end
	end
end

--------------------------------------------------------------------
-- BOUTIQUE ROBUX
--------------------------------------------------------------------
local shopContent = makePanel("Shop", "SHOP", C.Pink, Vector2.new(720, 520))
local shopTabs = Kit.new("Frame", { Parent = shopContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), ZIndex = 23 })
Kit.new("UIListLayout", {
	Parent = shopTabs,
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 12),
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
})
local shopPages = Kit.new("Frame", {
	Parent = shopContent,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, -120),
	Position = UDim2.fromOffset(0, 52),
	ZIndex = 23,
})
local pages: { [string]: ScrollingFrame } = {}
local passButtons: { [string]: TextButton } = {}

local function shopCard(parent: Instance, order: number, title: string, desc: string, accent: Color3, onBuy: () -> ())
	local holder, face = Kit.sticker({ Parent = parent, Color = C.White, LayoutOrder = order, ZIndex = 24 }, 4)
	Kit.new("Frame", { Parent = face, BackgroundColor3 = accent, Size = UDim2.new(0, 10, 1, 0), ZIndex = 25 }, { Kit.corner(6) })
	Kit.label({
		Parent = face,
		Size = UDim2.new(1, -30, 0, 26),
		Position = UDim2.fromOffset(20, 8),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = C.Ink,
		Text = title,
		ZIndex = 26,
	})
	Kit.label({
		Parent = face,
		Size = UDim2.new(1, -30, 0, 44),
		Position = UDim2.fromOffset(20, 36),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		TextScaled = false,
		TextSize = 14,
		Font = Kit.Body,
		TextColor3 = C.Grey,
		Text = desc,
		ZIndex = 26,
	})
	local _, btn = Kit.button({
		Parent = face,
		Size = UDim2.new(1, -36, 0, 36),
		Position = UDim2.new(0, 20, 1, -46),
		Color = C.Green,
		Text = "...",
		ZIndex = 26,
	}, onBuy)
	return holder, btn
end

for i, tab in { { "Passes", "PASSES", C.Yellow }, { "Boosts", "BOOSTS", C.Green }, { "Friends", "FRIENDS", C.Blue } } do
	local page = scrollGrid(shopPages, UDim2.fromOffset(310, 136), 2)
	page.Visible = i == 1
	pages[tab[1]] = page
	Kit.button({ Parent = shopTabs, Size = UDim2.fromOffset(120, 36), Color = tab[3], Text = tab[2], LayoutOrder = i, ZIndex = 24 }, function()
		for key, p in pages do
			p.Visible = key == tab[1]
		end
	end)
end
for i, key in Config.GamePassOrder do
	local pass = Config.GamePasses[key]
	local holder, btn = shopCard(pages.Passes, i, pass.Name, pass.Description, pass.Color, function()
		send("BuyPass", key)
	end)
	holder.Visible = pass.Id ~= 0
	passButtons[key] = btn
	task.spawn(function()
		local text = priceText(pass.Id, Enum.InfoType.GamePass)
		if not (state and state.Passes[key]) then
			btn.Text = text
		end
	end)
end
-- onglet Friends : Friend Boost + invitation
local friendInfo = Kit.label({
	Parent = pages.Friends,
	Text = "",
	Font = Kit.Body,
	TextScaled = false,
	TextSize = 18,
	TextWrapped = true,
	TextColor3 = C.Ink,
	LayoutOrder = 1,
	ZIndex = 25,
})
local _, inviteFace = Kit.sticker({ Parent = pages.Friends, Color = C.White, LayoutOrder = 2, ZIndex = 24 }, 4)
local inviteTitle = Kit.label({ Parent = inviteFace, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 10), TextColor3 = C.Ink, Text = "INVITE FRIENDS", ZIndex = 26 })
local _ = inviteTitle
Kit.button({
	Parent = inviteFace,
	Size = UDim2.new(1, -36, 0, 44),
	Position = UDim2.new(0, 18, 1, -56),
	Color = C.Green,
	Text = "INVITE",
	ZIndex = 26,
}, function()
	pcall(function()
		game:GetService("SocialService"):PromptGameInvite(player)
	end)
end)
refreshers.Shop = function()
	if not state then
		return
	end
	friendInfo.Text = ("FRIEND BOOST\n+%d%% cash right now\n\n+%d%% for each friend in this server, up to +%d%%."):format(
		math.floor(state.FriendBoost * 100 + 0.5),
		math.floor(Config.FriendBoostPerFriend * 100),
		math.floor(Config.FriendBoostMax * 100)
	)
end

-- codes, tout en bas du shop
local codeRow = Kit.new("Frame", {
	Parent = shopContent,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 52),
	Position = UDim2.new(0, 0, 1, -56),
	ZIndex = 23,
})
local _, codeFace = Kit.sticker({ Parent = codeRow, Size = UDim2.new(1, -170, 1, 0), Color = C.White, ZIndex = 24 }, 4)
local codeBox = Kit.new("TextBox", {
	Parent = codeFace,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -24, 1, -10),
	Position = UDim2.fromOffset(12, 5),
	Font = Kit.Title,
	TextScaled = true,
	TextColor3 = C.Ink,
	PlaceholderText = "Enter a code...",
	PlaceholderColor3 = C.Grey,
	Text = "",
	ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 26,
})
Kit.button({
	Parent = codeRow,
	Size = UDim2.fromOffset(150, 52),
	Position = UDim2.new(1, -150, 0, 0),
	Color = C.Yellow,
	Text = "REDEEM",
	ZIndex = 24,
}, function()
	if codeBox.Text ~= "" then
		send("Redeem", codeBox.Text)
		codeBox.Text = ""
	end
end)

for i, key in Config.ProductOrder do
	local product = Config.Products[key]
	local holder, btn = shopCard(pages.Boosts, i, product.Name, product.Description, C.Green, function()
		send("BuyProduct", key)
	end)
	holder.Visible = product.Id ~= 0
	task.spawn(function()
		btn.Text = priceText(product.Id, Enum.InfoType.Product)
	end)
end

--------------------------------------------------------------------
-- INDEX (collection)
--------------------------------------------------------------------
local indexContent = makePanel("Index", "INDEX", C.Purple, Vector2.new(740, 500))
local indexInfo = smallText(indexContent, "", {
	Size = UDim2.new(1, 0, 0, 24),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = C.Grey,
})
local indexGrid = scrollGrid(indexContent, UDim2.fromOffset(100, 140), 6, UDim2.new(1, 0, 1, -34), UDim2.fromOffset(0, 34))
local indexBuiltFor = -1

local function refreshIndex()
	if not state then
		return
	end
	local owned = {}
	for _, id in state.Index do
		owned[id] = true
	end
	indexInfo.Text = ("%d / %d discovered  ·  +%d%% cash"):format(#state.Index, #Cards.List, math.floor(#state.Index * Config.IndexBonusPerCard * 100 + 0.5))
	if indexBuiltFor == #state.Index then
		return
	end
	indexBuiltFor = #state.Index
	clearChildren(indexGrid)
	local sorted = table.clone(Cards.List)
	table.sort(sorted, function(a, b)
		local ra, rb = Cards.Rarities[a.Rarity].Order, Cards.Rarities[b.Rarity].Order
		if ra ~= rb then
			return ra < rb
		end
		return a.Income < b.Income
	end)
	for i, card in sorted do
		local holder = Kit.new("Frame", { Parent = indexGrid, BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 24 })
		CardArt.build(holder, card.Id, "Normal", { hidden = not owned[card.Id], zIndex = 24, strokeThickness = 3 })
		if card.Season then
			smallText(holder, Cards.Seasons[card.Season].Name:upper(), {
				Size = UDim2.new(1, 0, 0, 14),
				Position = UDim2.new(0, 0, 1, -2),
				TextColor3 = C.Pink,
				ZIndex = 40,
			})
		end
	end
end
refreshers.Index = refreshIndex

--------------------------------------------------------------------
-- REBIRTH
--------------------------------------------------------------------
local rebirthContent = makePanel("Rebirth", "REBIRTH", C.Yellow)
local rebirthInfo = smallText(rebirthContent, "", {
	Size = UDim2.new(1, 0, 0, 170),
	Position = UDim2.fromOffset(0, 10),
	TextScaled = false,
	TextSize = 20,
	TextWrapped = true,
})
local _, rebirthBtn = Kit.button({
	Parent = rebirthContent,
	Size = UDim2.fromOffset(320, 64),
	Position = UDim2.new(0.5, 0, 1, -76),
	AnchorPoint = Vector2.new(0.5, 0),
	Color = C.Yellow,
	Text = "REBIRTH",
	ZIndex = 24,
}, function()
	send("Rebirth")
end)
refreshers.Rebirth = function()
	if not state then
		return
	end
	local cash = player:GetAttribute("Cash") or 0
	rebirthInfo.Text = table.concat({
		("Rebirths: %d"):format(state.Rebirths),
		"",
		"You lose: cash, Speed, treadmills, cards in the lab and in your gallery.",
		"You keep: display cases, your index, your Game Passes.",
		"",
		("You get forever: +%d%% cash, +%d%% Speed from training, +1 grading slot."):format(
			Config.RebirthCashBonus * 100,
			Config.RebirthSpeedBonus * 100
		),
	}, "\n")
	local can = cash >= state.RebirthCost
	rebirthBtn.Text = can and ("REBIRTH  " .. Format.cash(state.RebirthCost)) or ("NEED " .. Format.cash(state.RebirthCost))
	rebirthBtn.Parent.BackgroundColor3 = can and C.Yellow or C.Grey
end

--------------------------------------------------------------------
-- DAILY
--------------------------------------------------------------------
local dailyContent = makePanel("Daily", "DAILY", C.Green)
local dayRow = Kit.new("Frame", { Parent = dailyContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 120), Position = UDim2.fromOffset(0, 30), ZIndex = 23 })
Kit.new("UIListLayout", { Parent = dayRow, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center })
local dayFaces = {}
for i = 1, #Config.DailyMinutes do
	local _, face = Kit.sticker({ Parent = dayRow, Size = UDim2.fromOffset(72, 100), Color = C.White, LayoutOrder = i, ZIndex = 24 }, 4)
	Kit.label({ Parent = face, Size = UDim2.new(1, -8, 0, 24), Position = UDim2.fromOffset(4, 10), TextColor3 = C.Ink, Text = "DAY " .. i, ZIndex = 25 })
	smallText(face, i == #Config.DailyMinutes and "BIG" or (Config.DailyMinutes[i] .. " min"), {
		Size = UDim2.new(1, -8, 0, 20),
		Position = UDim2.fromOffset(4, 52),
		TextColor3 = C.Pink,
	})
	dayFaces[i] = face
end
smallText(dailyContent, "Rewards are minutes of your income. Miss two days and the streak resets.", {
	Size = UDim2.new(1, 0, 0, 24),
	Position = UDim2.fromOffset(0, 170),
	TextColor3 = C.Grey,
})
local _, dailyBtn = Kit.button({
	Parent = dailyContent,
	Size = UDim2.fromOffset(320, 64),
	Position = UDim2.new(0.5, 0, 1, -76),
	AnchorPoint = Vector2.new(0.5, 0),
	Color = C.Green,
	Text = "CLAIM",
	ZIndex = 24,
}, function()
	send("ClaimDaily")
end)
local function dailyLeft(): number
	return state and (state.DailyWait - (os.clock() - stateAt)) or 0
end
refreshers.Daily = function()
	if not state then
		return
	end
	local current = math.min(state.DailyDay, #Config.DailyMinutes)
	for i, face in dayFaces do
		face.BackgroundColor3 = i < current and C.Green or (i == current and C.Yellow or C.White)
	end
	local ready = state.DailyReady or dailyLeft() <= 0
	dailyBtn.Text = ready and ("CLAIM  +" .. Format.cash(state.DailyReward)) or ("NEXT IN " .. Format.time(dailyLeft()))
	dailyBtn.Parent.BackgroundColor3 = ready and C.Green or C.Grey
end

--------------------------------------------------------------------
-- ADMIN
--------------------------------------------------------------------
local adminContent = makePanel("Admin", "ADMIN", C.Ink2, Vector2.new(640, 420))
local adminGrid = scrollGrid(adminContent, UDim2.fromOffset(180, 44), 3)
local function adminButton(order: number, text: string, color: Color3, fn: () -> ())
	Kit.button({ Parent = adminGrid, Color = color, Text = text, LayoutOrder = order, ZIndex = 24 }, fn)
end
local order = 0
for id, event in Config.Events do
	order += 1
	adminButton(order, event.Name, C.Yellow, function()
		Remotes.Admin:FireServer("Event", id)
	end)
end
adminButton(50, "SERVER LUCK", C.Green, function()
	Remotes.Admin:FireServer("Luck")
end)
adminButton(51, "RESTOCK ALL", C.Blue, function()
	Remotes.Admin:FireServer("Restock")
end)
adminButton(52, "+1B CASH", C.Green, function()
	Remotes.Admin:FireServer("Cash", 1e9)
end)
adminButton(53, "+1M SPEED", C.Blue, function()
	Remotes.Admin:FireServer("Speed", 1e6)
end)
for i, rarity in Cards.RarityOrder do
	adminButton(60 + i, "GIVE " .. rarity:upper(), Cards.Rarities[rarity].Color, function()
		Remotes.Admin:FireServer("Card", rarity)
	end)
end

--------------------------------------------------------------------
-- Gros boutons à gauche (avec icônes)
--------------------------------------------------------------------
local side = Kit.new("Frame", {
	Parent = gui,
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(200, 360),
	Position = UDim2.new(0, 16, 0.5, -215),
})
Kit.new("UIListLayout", { Parent = side, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
local badges: { [string]: Frame } = {}
local adminButtonHolder: Frame

local function iconButton(parent: Instance, order: number, text: string, color: Color3, icon: string, size: Vector2, onClick: () -> ())
	local holder, btn = Kit.button({
		Parent = parent,
		Size = UDim2.fromOffset(size.X, size.Y),
		Color = color,
		Text = "",
		LayoutOrder = order,
		Shadow = 4,
	}, onClick)
	local face = btn.Parent
	local iconFrame = Kit.new("Frame", {
		Parent = face,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size.Y - 16, size.Y - 16),
		Position = UDim2.fromOffset(8, 8),
		ZIndex = 4,
	})
	Icons.draw(icon, iconFrame, C.White, 4)
	local label = Kit.label({
		Parent = face,
		Size = UDim2.new(1, -(size.Y + 4), 1, -14),
		Position = UDim2.fromOffset(size.Y, 7),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
		ZIndex = 4,
	})
	Kit.textStroke(3).Parent = label
	return holder, label
end

for i, info in {
	{ "Shop", "Shop", C.Pink, "cart" },
	{ "Index", "Index", C.Blue, "book" },
	{ "Rebirth", "Rebirth", C.Yellow, "star" },
	{ "Lab", "Lab", Color3.fromRGB(0, 200, 210), "flask" },
	{ "Daily", "Daily", C.Green, "gift" },
	{ "Admin", "Admin", C.Ink2, "gear" },
} do
	local holder = iconButton(side, i, info[2], info[3], info[4], Vector2.new(186, 54), function()
		togglePanel(info[1])
	end)
	badges[info[1]] = Kit.new("Frame", {
		Parent = holder,
		BackgroundColor3 = C.Pink,
		Size = UDim2.fromOffset(22, 22),
		Position = UDim2.new(1, -12, 0, -8),
		ZIndex = 10,
		Visible = false,
	}, { Kit.corner(11), Kit.stroke(3) })
	if info[1] == "Admin" then
		adminButtonHolder = holder
		holder.Visible = false
	end
end

--------------------------------------------------------------------
-- Colonne de droite : Plot, Freeze Guards, Lab, Train
--------------------------------------------------------------------
local right = Kit.new("Frame", {
	Parent = gui,
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(160, 340),
	Position = UDim2.new(1, -176, 0.5, -215),
})
Kit.new("UIListLayout", { Parent = right, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right })

-- Freeze Guards : tuile mise en avant (produit Robux)
local freezeHolder, freezeFace = Kit.sticker({
	Parent = right,
	Size = UDim2.fromOffset(160, 132),
	Color = Color3.fromRGB(120, 200, 255),
	LayoutOrder = 1,
}, 5)
freezeHolder.Visible = Config.Products.FreezeGuards.Id ~= 0
local freezeIcon = Kit.new("Frame", { Parent = freezeFace, BackgroundTransparency = 1, Size = UDim2.fromOffset(56, 56), Position = UDim2.new(0.5, -28, 0, 30), ZIndex = 4 })
Icons.draw("ice", freezeIcon, Color3.fromRGB(200, 240, 255), 4)
local freezeTitle = Kit.label({ Parent = freezeFace, Size = UDim2.new(1, -12, 0, 26), Position = UDim2.fromOffset(6, 4), Text = "Freeze Guards", ZIndex = 5 })
Kit.textStroke(3).Parent = freezeTitle
local freezePrice = Kit.label({ Parent = freezeFace, Size = UDim2.new(1, -12, 0, 30), Position = UDim2.new(0, 6, 1, -36), Text = "...", ZIndex = 5 })
Kit.textStroke(3).Parent = freezePrice
local freezeHit = Kit.new("TextButton", { Parent = freezeFace, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "", ZIndex = 8 })
freezeHit.Activated:Connect(function()
	send("BuyProduct", "FreezeGuards")
end)
task.spawn(function()
	freezePrice.Text = "ONLY " .. priceText(Config.Products.FreezeGuards.Id, Enum.InfoType.Product)
end)

iconButton(right, 2, "Plot", C.Paper, "house", Vector2.new(160, 58), function()
	send("Home")
end)
iconButton(right, 3, "Lab", Color3.fromRGB(0, 200, 210), "flask", Vector2.new(160, 50), function()
	send("GoLab")
end)
iconButton(right, 4, "Train", C.Blue, "shoe", Vector2.new(160, 50), function()
	send("GoTraining")
end)

--------------------------------------------------------------------
-- Prévision des events (bas droite)
--------------------------------------------------------------------
local forecastHolder, forecastFace = Kit.sticker({
	Parent = gui,
	Size = UDim2.fromOffset(250, 70),
	Position = UDim2.new(1, -16, 1, -16),
	AnchorPoint = Vector2.new(1, 1),
	Color = C.Ink2,
}, 4)
local forecastIcon = Kit.new("Frame", { Parent = forecastFace, BackgroundTransparency = 1, Size = UDim2.fromOffset(44, 44), Position = UDim2.fromOffset(10, 13), ZIndex = 4 })
Icons.draw("clock", forecastIcon, C.Yellow, 4)
Kit.label({ Parent = forecastFace, Size = UDim2.new(1, -70, 0, 16), Position = UDim2.fromOffset(62, 8), Font = Kit.Body, TextColor3 = C.Grey, TextXAlignment = Enum.TextXAlignment.Left, Text = "FORECAST", ZIndex = 4 })
local forecastLabel = Kit.label({ Parent = forecastFace, Size = UDim2.new(1, -70, 0, 34), Position = UDim2.fromOffset(62, 26), TextXAlignment = Enum.TextXAlignment.Left, Text = "", ZIndex = 4 })
Kit.textStroke(2.5).Parent = forecastLabel
local _ = forecastHolder

--------------------------------------------------------------------
-- Messages, annonces, révélation
--------------------------------------------------------------------
local toastHolder = Kit.new("Frame", {
	Parent = gui,
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(420, 240),
	Position = UDim2.new(0.5, 0, 0, 126),
	AnchorPoint = Vector2.new(0.5, 0),
})
Kit.new("UIListLayout", { Parent = toastHolder, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder })
local toastCount = 0
Remotes.Notify.OnClientEvent:Connect(function(text: string, kind: string)
	toastCount += 1
	local color = (kind == "error" and C.Pink) or (kind == "reward" and C.Green) or (kind == "cash" and C.Yellow) or C.Paper
	local holder, face = Kit.sticker({ Parent = toastHolder, Size = UDim2.fromOffset(380, 38), Color = color, LayoutOrder = toastCount }, 4)
	smallText(face, text, { Size = UDim2.new(1, -20, 1, -12), Position = UDim2.fromOffset(10, 6), ZIndex = 5 })
	Kit.pop(holder)
	task.delay(3, function()
		holder:Destroy()
	end)
	-- on garde au maximum 5 messages
	local children = {}
	for _, c in toastHolder:GetChildren() do
		if c:IsA("Frame") then
			table.insert(children, c)
		end
	end
	if #children > 5 then
		table.sort(children, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		children[1]:Destroy()
	end
end)

local announceHolder, announceFace = Kit.sticker({
	Parent = gui,
	Size = UDim2.fromOffset(560, 86),
	Position = UDim2.new(0.5, 0, 0.24, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Color = C.Ink2,
	ZIndex = 45,
}, 6)
announceHolder.Visible = false
Kit.new("UIScale", { Parent = announceHolder })
local announceTitle = Kit.label({ Parent = announceFace, Size = UDim2.new(1, -20, 0, 44), Position = UDim2.fromOffset(10, 6), Text = "", ZIndex = 47 })
Kit.textStroke(3).Parent = announceTitle
local announceSub = smallText(announceFace, "", { Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 54), TextColor3 = C.White, ZIndex = 47 })
local announceToken = 0
Remotes.Announce.OnClientEvent:Connect(function(title: string, sub: string, kind: string)
	announceToken += 1
	local token = announceToken
	local rarity = Cards.Rarities[kind]
	announceTitle.Text = title
	announceTitle.TextColor3 = rarity and rarity.Color or (kind == "event" and C.Yellow) or (kind == "luck" and C.Green) or C.Pink
	announceSub.Text = sub
	announceHolder.Visible = true
	announceHolder.Rotation = -2
	Kit.pop(announceHolder)
	task.delay(4, function()
		if token == announceToken then
			announceHolder.Visible = false
		end
	end)
end)

-- révélation de la note après gradation
local revealHolder, revealFace = Kit.sticker({
	Parent = gui,
	Size = UDim2.fromOffset(300, 470),
	Position = UDim2.fromScale(0.5, 0.52),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Color = C.Ink2,
	ZIndex = 60,
	Radius = 12,
}, 8)
revealHolder.Visible = false
Kit.new("UIScale", { Parent = revealHolder })
local revealArt = Kit.new("Frame", {
	Parent = revealFace,
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(240, 336),
	Position = UDim2.fromOffset(30, 20),
	ZIndex = 61,
})
local revealGrade = Kit.label({ Parent = revealFace, Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 364), Text = "", ZIndex = 62 })
Kit.textStroke(3).Parent = revealGrade
local revealSub = smallText(revealFace, "", { Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 406), TextColor3 = C.White, ZIndex = 62 })
local revealToken = 0
Remotes.Reveal.OnClientEvent:Connect(function(info)
	revealToken += 1
	local token = revealToken
	clearChildren(revealArt)
	CardArt.build(revealArt, info.Id, info.F, { grade = info.G, zIndex = 61, strokeThickness = 6 })
	local gradeName = Cards.GradeNames[info.G]
	revealGrade.Text = ("GRADE %d  ·  %s"):format(info.G, gradeName:upper())
	revealGrade.TextColor3 = info.G >= 9 and C.Yellow or (info.G >= 7 and C.Green or C.White)
	revealSub.Text = "+" .. Format.cash(Cards.IncomeOf(info.Id, info.F, info.G) * (state and state.CashMultiplier or 1)) .. "/s in your gallery"
	revealHolder.Visible = true
	revealHolder.Rotation = 0
	Kit.pop(revealHolder)
	TweenService:Create(revealHolder, TweenInfo.new(0.6, Enum.EasingStyle.Back), { Rotation = -3 }):Play()
	task.delay(3.2, function()
		if token == revealToken then
			revealHolder.Visible = false
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
	cashLabel.Text = Format.cash(cash)
	incomeLabel.Text = "+" .. Format.cash(income) .. "/s"
	speedLabel.Text = Format.short(speed)
	local i, zone = nextZone(speed)
	if zone then
		local prev = Config.Zones[i - 1] and Config.Zones[i - 1].Speed or 0
		nextZoneLabel.Text = ("Next: %s at %s"):format(zone.Name, Format.short(zone.Speed))
		-- progression en échelle log pour que la barre bouge vraiment
		local a, b = math.log10(1 + prev), math.log10(1 + zone.Speed)
		zoneBarFill.Size = UDim2.fromScale(math.clamp((math.log10(1 + speed) - a) / (b - a), 0, 1), 1)
	else
		nextZoneLabel.Text = "Every shop is open to you"
		zoneBarFill.Size = UDim2.fromScale(1, 1)
	end
end
for _, attr in { "Cash", "Income", "Speed" } do
	player:GetAttributeChangedSignal(attr):Connect(renderStats)
end
renderStats()

local function renderCarry()
	local id = player:GetAttribute("Carrying")
	carryHolder.Visible = id ~= nil
	if id then
		carryLabel.Text = "RUN TO THE SAFE ZONE!"
		Kit.pop(carryHolder)
	end
end
player:GetAttributeChangedSignal("Carrying"):Connect(renderCarry)

local function render()
	if not state then
		return
	end
	multLabel.Text = state.SpeedMultiplier > 1 and ("(x%s)"):format(tostring(math.floor(state.SpeedMultiplier * 100 + 0.5) / 100)) or ""
	friendLabel.Text = ("Friend Boost: +%d%%"):format(math.floor(state.FriendBoost * 100 + 0.5))
	adminButtonHolder.Visible = state.IsAdmin
	for key, btn in passButtons do
		if state.Passes[key] then
			btn.Text = "OWNED"
			btn.Parent.BackgroundColor3 = C.Grey
		end
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
	end
end)

-- lieu actuel, timers, pastilles
task.spawn(function()
	while true do
		task.wait(0.25)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local z = root.Position.Z
			if z < 100 then
				placeLabel.Text = "SAFE ZONE"
				placeSub.Text = "Gallery, lab and treadmills are here"
				placeSub.TextColor3 = C.Green
			else
				local index = math.clamp(math.floor((z - 120) / 200) + 1, 1, #Config.Zones)
				if z < 120 then
					placeLabel.Text = "THE STRIP"
					placeSub.Text = "Shops ahead. Guardians chase thieves!"
					placeSub.TextColor3 = C.Yellow
				else
					local zone = Config.Zones[index]
					placeLabel.Text = ("SHOP %d  ·  %s"):format(index, zone.Name:upper())
					placeSub.Text = "Guardian: " .. zone.Guardian
					placeSub.TextColor3 = zone.Accent
				end
			end
		end

		local now = workspace:GetServerTimeNow()
		local parts = {}
		if eventState.Event and eventState.EndsAt and eventState.EndsAt > now then
			table.insert(parts, ("%s  %s"):format(Config.Events[eventState.Event].Name, Format.time(eventState.EndsAt - now)))
		end
		if eventState.LuckUntil and eventState.LuckUntil > now then
			table.insert(parts, ("LUCK x%d  %s"):format(Config.ServerLuckMultiplier, Format.time(eventState.LuckUntil - now)))
		end
		if eventState.Season then
			table.insert(parts, Cards.Seasons[eventState.Season].Name:upper())
		end
		local frozen = eventState.FrozenUntil and eventState.FrozenUntil > now
		if frozen then
			table.insert(parts, 1, "GUARDS FROZEN " .. Format.time(eventState.FrozenUntil - now))
		end
		eventHolder.Visible = #parts > 0
		eventLabel.Text = table.concat(parts, "   ·   ")
		if eventState.NextEvent and eventState.NextAt and eventState.NextAt > now and eventState.NextAt - now < 86400 then
			forecastLabel.Text = ("%s in %s"):format(Config.Events[eventState.NextEvent].Name, Format.time(eventState.NextAt - now))
		else
			forecastLabel.Text = "Calm skies"
		end

		if state then
			local ready = 0
			for _, entry in state.Grading do
				if entry.Ends <= serverNow() then
					ready += 1
				end
			end
			badges.Lab.Visible = ready > 0
			badges.Daily.Visible = state.DailyReady or dailyLeft() <= 0
			if openPanel == "Lab" then
				tickLab()
			elseif openPanel == "Daily" or openPanel == "Rebirth" then
				refreshers[openPanel]()
			end
		end
	end
end)
