-- Interface du joueur : HUD, boutique, trails, rebirth, récompense quotidienne, messages

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Kit = require(script.Parent.UI.Kit)

local C = Kit.Colors
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local state: any = nil
local stateReceivedAt = os.clock()

local function send(action: string, arg: any?)
	Remotes.Action:FireServer(action, arg)
end

--------------------------------------------------------------------
-- Racine + mise à l'échelle (PC, tablette, téléphone)
--------------------------------------------------------------------
local gui = Kit.new("ScreenGui", {
	Name = "SkyRushUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})
local rootScale = Kit.new("UIScale", { Parent = gui })
local function updateScale()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local size = camera.ViewportSize
	rootScale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 760), 0.55, 1.15)
end
updateScale()
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

-- Infos Robux des articles (prix) mises en cache
local priceCache: { [string]: string } = {}
local function priceText(id: number, infoType: Enum.InfoType): string
	if id == 0 then
		return "SOON"
	end
	local key = tostring(infoType) .. id
	if priceCache[key] then
		return priceCache[key]
	end
	local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
	local text = (ok and info and info.PriceInRobux) and ("R$ " .. info.PriceInRobux) or "R$"
	priceCache[key] = text
	return text
end

--------------------------------------------------------------------
-- HUD : stage en haut
--------------------------------------------------------------------
local _, stageFace = Kit.sticker({
	Name = "StagePill",
	Parent = gui,
	Size = UDim2.fromOffset(300, 74),
	Position = UDim2.new(0.5, 0, 0, 10),
	AnchorPoint = Vector2.new(0.5, 0),
	Color = C.Ink2,
})
local stageLabel = Kit.label({
	Parent = stageFace,
	Size = UDim2.new(1, -20, 0, 38),
	Position = UDim2.fromOffset(10, 4),
	Text = "STAGE 0",
	ZIndex = 5,
})
Kit.textStroke(3).Parent = stageLabel
local worldLabel = Kit.label({
	Parent = stageFace,
	Size = UDim2.new(1, -20, 0, 14),
	Position = UDim2.fromOffset(10, 42),
	Font = Kit.Body,
	TextColor3 = C.Yellow,
	Text = "WORLD 1",
	ZIndex = 5,
})
local barBack = Kit.new("Frame", {
	Parent = stageFace,
	BackgroundColor3 = C.Ink,
	Size = UDim2.new(1, -24, 0, 7),
	Position = UDim2.new(0, 12, 1, -12),
	ZIndex = 5,
}, { Kit.corner(4) })
local barFill = Kit.new("Frame", {
	Parent = barBack,
	BackgroundColor3 = C.Pink,
	Size = UDim2.fromScale(0, 1),
	ZIndex = 6,
}, { Kit.corner(4) })

--------------------------------------------------------------------
-- HUD : coins + niveau (en haut à gauche, sous les boutons Roblox)
--------------------------------------------------------------------
local statsHolder = Kit.new("Frame", {
	Name = "Stats",
	Parent = gui,
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(230, 120),
	Position = UDim2.fromOffset(14, 14),
})

local _, coinFace = Kit.sticker({ Parent = statsHolder, Size = UDim2.fromOffset(210, 46), Color = C.Yellow })
Kit.new("Frame", {
	Parent = coinFace,
	BackgroundColor3 = Color3.fromRGB(255, 180, 0),
	Size = UDim2.fromOffset(28, 28),
	Position = UDim2.fromOffset(10, 9),
	ZIndex = 5,
}, { Kit.corner(14), Kit.stroke(3) })
local coinLabel = Kit.label({
	Parent = coinFace,
	Size = UDim2.new(1, -56, 0, 30),
	Position = UDim2.fromOffset(46, 8),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = C.Ink,
	Text = "0",
	ZIndex = 5,
})

local _, levelFace = Kit.sticker({
	Parent = statsHolder,
	Size = UDim2.fromOffset(210, 52),
	Position = UDim2.fromOffset(0, 58),
	Color = C.Paper,
})
local levelLabel = Kit.label({
	Parent = levelFace,
	Size = UDim2.new(1, -20, 0, 22),
	Position = UDim2.fromOffset(10, 5),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = C.Ink,
	Text = "LEVEL 1",
	ZIndex = 5,
})
local multLabel = Kit.label({
	Parent = levelFace,
	Size = UDim2.new(0, 70, 0, 18),
	Position = UDim2.new(1, -78, 0, 7),
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = C.Pink,
	Text = "x1",
	ZIndex = 5,
})
local xpBack = Kit.new("Frame", {
	Parent = levelFace,
	BackgroundColor3 = C.Ink2,
	Size = UDim2.new(1, -20, 0, 12),
	Position = UDim2.fromOffset(10, 32),
	ZIndex = 5,
}, { Kit.corner(6) })
local xpFill = Kit.new("Frame", {
	Parent = xpBack,
	BackgroundColor3 = C.Green,
	Size = UDim2.fromScale(0, 1),
	ZIndex = 6,
}, { Kit.corner(6) })

--------------------------------------------------------------------
-- Panneaux (un seul ouvert à la fois)
--------------------------------------------------------------------
local panels: { [string]: Frame } = {}
local openPanel: string? = nil

local function closePanels()
	for _, panel in panels do
		panel.Visible = false
	end
	openPanel = nil
end

local function togglePanel(name: string)
	local wasOpen = openPanel == name
	closePanels()
	if not wasOpen then
		local panel = panels[name]
		panel.Visible = true
		Kit.pop(panel)
		openPanel = name
	end
end

local function makePanel(name: string, title: string, accent: Color3): Frame
	local holder, face = Kit.sticker({
		Name = name .. "Panel",
		Parent = gui,
		Size = UDim2.fromOffset(620, 440),
		Position = UDim2.fromScale(0.5, 0.52),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = C.Paper,
		ZIndex = 20,
		Radius = 10,
	}, 8)
	holder.Visible = false
	Kit.new("UIScale", { Parent = holder })

	-- bandeau de titre penché, façon étiquette
	local _, tag = Kit.sticker({
		Parent = face,
		Size = UDim2.fromOffset(240, 52),
		Position = UDim2.fromOffset(-14, -26),
		Color = accent,
		ZIndex = 30,
	}, 4)
	tag.Parent.Rotation = -4
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

local function scrollList(parent: Instance, cellSize: UDim2, cols: number?): ScrollingFrame
	local scroll = Kit.new("ScrollingFrame", {
		Parent = parent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = C.Ink,
		ZIndex = 23,
	})
	Kit.new("UIGridLayout", {
		Parent = scroll,
		CellSize = cellSize,
		CellPadding = UDim2.fromOffset(16, 16),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirectionMaxCells = cols or 0,
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

--------------------------------------------------------------------
-- Boutique Robux : passes, coins, dons
--------------------------------------------------------------------
local shopContent = makePanel("Shop", "SHOP", C.Pink)
local shopTabs = Kit.new("Frame", {
	Parent = shopContent,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 40),
	ZIndex = 23,
})
Kit.new("UIListLayout", {
	Parent = shopTabs,
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 12),
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
})
local shopPages = Kit.new("Frame", {
	Parent = shopContent,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, -52),
	Position = UDim2.fromOffset(0, 52),
	ZIndex = 23,
})

local shopPageFrames: { [string]: ScrollingFrame } = {}
local function showShopPage(name: string)
	for key, frame in shopPageFrames do
		frame.Visible = key == name
	end
end

local passCards: { [string]: { status: TextButton, holder: Frame } } = {}

local function shopCard(parent: Instance, order: number, title: string, desc: string, accent: Color3, price: string, onBuy: () -> ())
	local holder, face = Kit.sticker({ Parent = parent, Color = C.White, LayoutOrder = order, ZIndex = 24 }, 4)
	Kit.new("Frame", {
		Parent = face,
		BackgroundColor3 = accent,
		Size = UDim2.new(0, 10, 1, 0),
		ZIndex = 25,
	}, { Kit.corner(6) })
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
		Size = UDim2.new(1, -36, 0, 38),
		Position = UDim2.new(0, 20, 1, -48),
		Color = C.Green,
		Text = price,
		ZIndex = 26,
	}, onBuy)
	return holder, btn
end

local function buildShop()
	local tabs = {
		{ "Passes", "PASSES", C.Yellow },
		{ "Coins", "EXTRAS", C.Green },
		{ "Donate", "DONATE", C.Blue },
	}
	for i, tab in tabs do
		local page = scrollList(shopPages, UDim2.fromOffset(268, 140), 2)
		page.Visible = i == 1
		shopPageFrames[tab[1]] = page
		Kit.button({
			Parent = shopTabs,
			Size = UDim2.fromOffset(120, 36),
			Color = tab[3],
			Text = tab[2],
			LayoutOrder = i,
			ZIndex = 24,
		}, function()
			showShopPage(tab[1])
		end)
	end

	for i, key in Config.GamePassOrder do
		local pass = Config.GamePasses[key]
		local holder, btn = shopCard(shopPageFrames.Passes, i, pass.Name, pass.Description, pass.Color, "...", function()
			send("BuyPass", key)
		end)
		passCards[key] = { status = btn, holder = holder }
		task.spawn(function()
			local text = priceText(pass.Id, Enum.InfoType.GamePass)
			if not (state and state.Passes and state.Passes[key]) then
				btn.Text = text
			end
		end)
		if pass.Id == 0 then
			holder.Visible = false
		end
	end

	local skipCards = { { "SkipStage", "Skip 1 stage. Stuck? Jump straight to the next checkpoint." }, { "Skip5", "Jump 5 stages ahead in one go." } }
	for i, info in skipCards do
		local product = Config.Products[info[1]]
		local holder, btn = shopCard(shopPageFrames.Coins, i, product.Name, info[2], C.Yellow, "...", function()
			send(info[1] == "SkipStage" and "Skip" or "Skip5")
		end)
		holder.Visible = product.Id ~= 0
		task.spawn(function()
			btn.Text = priceText(product.Id, Enum.InfoType.Product)
		end)
	end
	for i, key in Config.CoinPackOrder do
		local product = Config.Products[key]
		local holder, btn = shopCard(shopPageFrames.Coins, 10 + i, product.Name, "Spend them on trails in the Trails menu.", C.Green, "...", function()
			send("BuyProduct", key)
		end)
		holder.Visible = product.Id ~= 0
		task.spawn(function()
			btn.Text = priceText(product.Id, Enum.InfoType.Product)
		end)
	end
	for i, key in Config.DonationOrder do
		local product = Config.Products[key]
		local holder, btn = shopCard(shopPageFrames.Donate, i, product.Name, "Support the game and get on the Top Donors board.", C.Blue, "...", function()
			send("BuyProduct", key)
		end)
		holder.Visible = product.Id ~= 0
		task.spawn(function()
			btn.Text = priceText(product.Id, Enum.InfoType.Product)
		end)
	end
end
buildShop()

--------------------------------------------------------------------
-- Trails
--------------------------------------------------------------------
local trailsContent = makePanel("Trails", "TRAILS", C.Purple)
local trailsList = scrollList(trailsContent, UDim2.fromOffset(170, 170), 3)
local trailCards: { [string]: any } = {}

local function trailCard(order: number, id: string, name: string, colors: { Color3 })
	local _, face = Kit.sticker({ Parent = trailsList, Color = C.White, LayoutOrder = order, ZIndex = 24 }, 4)
	local swatch = Kit.new("Frame", {
		Parent = face,
		BackgroundColor3 = C.White,
		Size = UDim2.new(1, -24, 0, 50),
		Position = UDim2.fromOffset(12, 12),
		ZIndex = 25,
	}, { Kit.corner(6), Kit.stroke(2) })
	Kit.new("UIGradient", {
		Parent = swatch,
		Color = #colors > 2 and ColorSequence.new((function()
			local keys = {}
			for i, c in colors do
				table.insert(keys, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), c))
			end
			return keys
		end)()) or ColorSequence.new(colors[1], colors[2]),
	})
	Kit.label({
		Parent = face,
		Size = UDim2.new(1, -24, 0, 22),
		Position = UDim2.fromOffset(12, 68),
		TextColor3 = C.Ink,
		Text = name,
		ZIndex = 25,
	})
	local req = Kit.label({
		Parent = face,
		Size = UDim2.new(1, -24, 0, 16),
		Position = UDim2.fromOffset(12, 92),
		Font = Kit.Body,
		TextColor3 = C.Grey,
		Text = "",
		ZIndex = 25,
	})
	local _, btn = Kit.button({
		Parent = face,
		Size = UDim2.new(1, -28, 0, 36),
		Position = UDim2.new(0, 12, 1, -46),
		Color = C.Green,
		Text = "",
		ZIndex = 25,
	}, function()
		local owned = state and table.find(state.Trails, id)
		local passTrail = id == "Rainbow" or id == "Gold"
		if owned or passTrail then
			send("EquipTrail", (state and state.EquippedTrail == id) and "None" or id)
		else
			send("BuyTrail", id)
		end
	end)
	trailCards[id] = { req = req, btn = btn, face = face }
end

local rainbow = {}
for i = 0, 5 do
	table.insert(rainbow, Color3.fromHSV(i / 6, 0.85, 1))
end
trailCard(0, "Gold", "VIP Gold", { Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 160, 0) })
trailCard(1, "Rainbow", "Rainbow", rainbow)
for i, trail in Config.Trails do
	trailCard(1 + i, trail.Id, trail.Name, trail.Colors)
end

local function refreshTrails()
	if not state then
		return
	end
	for id, card in trailCards do
		local equipped = state.EquippedTrail == id
		local passKey = (id == "Rainbow" and "RainbowTrail") or (id == "Gold" and "VIP") or nil
		if passKey then
			local has = state.Passes[passKey]
			card.req.Text = has and "Game Pass" or (passKey == "VIP" and "Needs VIP pass" or "Needs Rainbow pass")
			card.btn.Text = equipped and "EQUIPPED" or (has and "EQUIP" or "GET PASS")
			card.face.Parent.Visible = Config.GamePasses[passKey].Id ~= 0 or has
		else
			local trail = Config.GetTrail(id)
			local owned = table.find(state.Trails, id) ~= nil
			if owned then
				card.req.Text = "Owned"
				card.btn.Text = equipped and "EQUIPPED" or "EQUIP"
			else
				local locks = {}
				if state.Level < trail.Level then
					table.insert(locks, "Lv " .. trail.Level)
				end
				if state.Rebirths < trail.Rebirths then
					table.insert(locks, "R" .. trail.Rebirths)
				end
				card.req.Text = #locks > 0 and ("Needs " .. table.concat(locks, " + ")) or "Unlocked"
				card.btn.Text = Kit.formatNumber(trail.Price) .. " C"
			end
		end
		card.btn.Parent.BackgroundColor3 = equipped and C.Yellow or C.Green
	end
end

--------------------------------------------------------------------
-- Rebirth
--------------------------------------------------------------------
local rebirthContent = makePanel("Rebirth", "REBIRTH", C.Yellow)
local rebirthInfo = Kit.label({
	Parent = rebirthContent,
	Size = UDim2.new(1, 0, 0, 140),
	Position = UDim2.fromOffset(0, 20),
	Font = Kit.Body,
	TextScaled = false,
	TextSize = 22,
	TextWrapped = true,
	TextColor3 = C.Ink,
	Text = "",
	ZIndex = 24,
})
local rebirthBig = Kit.label({
	Parent = rebirthContent,
	Size = UDim2.new(1, 0, 0, 70),
	Position = UDim2.fromOffset(0, 170),
	TextColor3 = C.Pink,
	Text = "x1  >  x1.5",
	ZIndex = 24,
})
Kit.textStroke(3).Parent = rebirthBig
local _, rebirthBtn = Kit.button({
	Parent = rebirthContent,
	Size = UDim2.fromOffset(300, 64),
	Position = UDim2.new(0.5, 0, 1, -76),
	AnchorPoint = Vector2.new(0.5, 0),
	Color = C.Yellow,
	Text = "REBIRTH",
	ZIndex = 24,
}, function()
	send("Rebirth")
end)

local function refreshRebirth()
	if not state then
		return
	end
	rebirthInfo.Text = ("Finish all %d stages, then rebirth.\nYou go back to stage 0, keep your level, coins and trails, and earn more forever.\n\nRebirths: %d"):format(
		state.Total,
		state.Rebirths
	)
	rebirthBig.Text = ("x%s  >  x%s"):format(tostring(state.Multiplier), tostring(state.NextMultiplier))
	rebirthBtn.Text = state.CanRebirth and "REBIRTH NOW" or ("LOCKED  %d/%d"):format(state.BestStage, state.Total)
	rebirthBtn.Parent.BackgroundColor3 = state.CanRebirth and C.Yellow or C.Grey
end

--------------------------------------------------------------------
-- Récompense quotidienne
--------------------------------------------------------------------
local dailyContent = makePanel("Daily", "DAILY", C.Green)
local dayRow = Kit.new("Frame", {
	Parent = dailyContent,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 120),
	Position = UDim2.fromOffset(0, 30),
	ZIndex = 23,
})
Kit.new("UIListLayout", {
	Parent = dayRow,
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 10),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
})
local dayFaces = {}
for i, amount in Config.DailyRewards do
	local _, face = Kit.sticker({
		Parent = dayRow,
		Size = UDim2.fromOffset(70, 100),
		Color = C.White,
		LayoutOrder = i,
		ZIndex = 24,
	}, 4)
	Kit.label({ Parent = face, Size = UDim2.new(1, -8, 0, 24), Position = UDim2.fromOffset(4, 8), TextColor3 = C.Ink, Text = "DAY " .. i, ZIndex = 25 })
	Kit.label({
		Parent = face,
		Size = UDim2.new(1, -8, 0, 30),
		Position = UDim2.fromOffset(4, 46),
		TextColor3 = C.Pink,
		Text = tostring(amount),
		ZIndex = 25,
	})
	dayFaces[i] = face
end
local dailyNote = Kit.label({
	Parent = dailyContent,
	Size = UDim2.new(1, 0, 0, 30),
	Position = UDim2.fromOffset(0, 170),
	Font = Kit.Body,
	TextColor3 = C.Grey,
	Text = "Come back every day. Miss two days and the streak resets.",
	ZIndex = 24,
})
local _, dailyBtn = Kit.button({
	Parent = dailyContent,
	Size = UDim2.fromOffset(300, 64),
	Position = UDim2.new(0.5, 0, 1, -76),
	AnchorPoint = Vector2.new(0.5, 0),
	Color = C.Green,
	Text = "CLAIM",
	ZIndex = 24,
}, function()
	send("ClaimDaily")
end)

local function dailyRemaining(): number
	if not state then
		return 0
	end
	return state.DailyWait - (os.clock() - stateReceivedAt)
end

local function refreshDaily()
	if not state then
		return
	end
	local current = math.min(state.DailyStreak, #Config.DailyRewards)
	for i, face in dayFaces do
		face.BackgroundColor3 = (i < current) and C.Green or (i == current and C.Yellow or C.White)
	end
	local remaining = dailyRemaining()
	local ready = state.DailyReady or remaining <= 0
	dailyBtn.Text = ready and ("CLAIM  +" .. state.DailyReward) or ("NEXT IN " .. Kit.formatTime(remaining))
	dailyBtn.Parent.BackgroundColor3 = ready and C.Green or C.Grey
	dailyNote.Text = "Come back every day. Miss two days and the streak resets."
end

--------------------------------------------------------------------
-- Boutons de gauche
--------------------------------------------------------------------
local sideHolder = Kit.new("Frame", {
	Name = "Side",
	Parent = gui,
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(110, 330),
	Position = UDim2.new(0, 14, 0.5, -120),
})
Kit.new("UIListLayout", { Parent = sideHolder, Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder })

local dailyDot: Frame
for i, info in {
	{ "Shop", "SHOP", C.Pink },
	{ "Trails", "TRAILS", C.Purple },
	{ "Rebirth", "REBIRTH", C.Yellow },
	{ "Daily", "DAILY", C.Green },
} do
	local holder = Kit.button({
		Parent = sideHolder,
		Size = UDim2.fromOffset(104, 52),
		Color = info[3],
		Text = info[2],
		TextColor = C.White,
		TextStroke = true,
		LayoutOrder = i,
	}, function()
		togglePanel(info[1])
	end)
	if info[1] == "Daily" then
		dailyDot = Kit.new("Frame", {
			Parent = holder,
			BackgroundColor3 = C.Pink,
			Size = UDim2.fromOffset(20, 20),
			Position = UDim2.new(1, -10, 0, -8),
			ZIndex = 10,
			Visible = false,
		}, { Kit.corner(10), Kit.stroke(3) })
	end
end

--------------------------------------------------------------------
-- Skip + respawn (à droite)
--------------------------------------------------------------------
local skipHolder = Kit.button({
	Name = "Skip",
	Parent = gui,
	Size = UDim2.fromOffset(150, 64),
	Position = UDim2.new(1, -16, 0.5, -60),
	AnchorPoint = Vector2.new(1, 0.5),
	Color = C.Yellow,
	Text = "SKIP STAGE",
	Shadow = 5,
}, function()
	send("Skip")
end)
skipHolder.Rotation = 3
skipHolder.Visible = Config.Products.SkipStage.Id ~= 0

Kit.button({
	Name = "Respawn",
	Parent = gui,
	Size = UDim2.fromOffset(110, 40),
	Position = UDim2.new(1, -16, 0.5, 6),
	AnchorPoint = Vector2.new(1, 0),
	Color = C.Paper,
	Text = "RESPAWN",
}, function()
	send("Respawn")
end)

--------------------------------------------------------------------
-- Messages (toasts) et célébrations
--------------------------------------------------------------------
local toastHolder = Kit.new("Frame", {
	Parent = gui,
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(420, 200),
	Position = UDim2.new(0.5, 0, 0, 96),
	AnchorPoint = Vector2.new(0.5, 0),
})
Kit.new("UIListLayout", {
	Parent = toastHolder,
	Padding = UDim.new(0, 8),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
})
local toastCount = 0

local function toast(text: string, kind: string)
	toastCount += 1
	local color = kind == "error" and C.Pink or (kind == "reward" and C.Green or C.Paper)
	local holder, face = Kit.sticker({
		Parent = toastHolder,
		Size = UDim2.fromOffset(360, 40),
		Color = color,
		LayoutOrder = toastCount,
	}, 4)
	Kit.label({
		Parent = face,
		Size = UDim2.new(1, -20, 1, -12),
		Position = UDim2.fromOffset(10, 6),
		Font = Kit.Body,
		TextColor3 = C.Ink,
		Text = text,
		ZIndex = 5,
	})
	Kit.pop(holder)
	task.delay(3, function()
		holder:Destroy()
	end)
end

local bigText = Kit.label({
	Parent = gui,
	Size = UDim2.fromOffset(700, 110),
	Position = UDim2.fromScale(0.5, 0.33),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Text = "",
	TextColor3 = C.Yellow,
	Visible = false,
	ZIndex = 50,
})
Kit.textStroke(5).Parent = bigText
local bigScale = Kit.new("UIScale", { Parent = bigText })
local bigSub = Kit.label({
	Parent = bigText,
	Size = UDim2.new(1, 0, 0, 34),
	Position = UDim2.new(0, 0, 1, 0),
	Font = Kit.Body,
	Text = "",
	ZIndex = 50,
})
Kit.textStroke(3).Parent = bigSub
local celebrateToken = 0

local function celebrate(title: string, sub: string, color: Color3)
	celebrateToken += 1
	local token = celebrateToken
	bigText.Text = title
	bigText.TextColor3 = color
	bigSub.Text = sub
	bigText.Visible = true
	bigText.Rotation = -6
	Kit.pop(bigText, bigScale)
	TweenService:Create(bigText, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Rotation = -2 }):Play()
	task.delay(2.6, function()
		if token == celebrateToken then
			bigText.Visible = false
		end
	end)
end

Remotes.Notify.OnClientEvent:Connect(toast)

Remotes.Celebrate.OnClientEvent:Connect(function(kind: string, value: any)
	if kind == "Level" then
		celebrate("LEVEL " .. value, "Level up!", C.Green)
	elseif kind == "Finish" then
		celebrate("OBBY COMPLETE", ("+%s coins  ·  Rebirth is unlocked"):format(Kit.formatNumber(value)), C.Yellow)
	elseif kind == "Rebirth" then
		celebrate("REBIRTH " .. value, "Your multiplier went up. Go again!", C.Pink)
	elseif kind == "Donate" then
		celebrate("THANK YOU", ("%d Robux donated"):format(value), C.Blue)
	end
end)

--------------------------------------------------------------------
-- Proposition de skip quand on meurt trop souvent
--------------------------------------------------------------------
local stuckHolder, stuckFace = Kit.sticker({
	Name = "Stuck",
	Parent = gui,
	Size = UDim2.fromOffset(380, 150),
	Position = UDim2.new(0.5, 0, 1, -40),
	AnchorPoint = Vector2.new(0.5, 1),
	Color = C.Ink2,
	ZIndex = 40,
}, 6)
stuckHolder.Visible = false
local stuckLabel = Kit.label({
	Parent = stuckFace,
	Size = UDim2.new(1, -30, 0, 40),
	Position = UDim2.fromOffset(15, 14),
	Text = "STUCK ON STAGE 1?",
	ZIndex = 42,
})
Kit.textStroke(3).Parent = stuckLabel
local _, stuckBuy = Kit.button({
	Parent = stuckFace,
	Size = UDim2.fromOffset(200, 54),
	Position = UDim2.fromOffset(18, 76),
	Color = C.Yellow,
	Text = "SKIP IT",
	ZIndex = 42,
}, function()
	stuckHolder.Visible = false
	send("Skip")
end)
Kit.button({
	Parent = stuckFace,
	Size = UDim2.fromOffset(130, 54),
	Position = UDim2.new(1, -148, 0, 76),
	Color = C.Paper,
	Text = "NOPE",
	ZIndex = 42,
}, function()
	stuckHolder.Visible = false
end)

Remotes.StuckOffer.OnClientEvent:Connect(function(stage: number)
	stuckLabel.Text = ("STUCK ON STAGE %d?"):format(stage)
	stuckBuy.Text = "SKIP  " .. priceText(Config.Products.SkipStage.Id, Enum.InfoType.Product)
	stuckHolder.Visible = true
	Kit.pop(stuckHolder)
	task.delay(8, function()
		stuckHolder.Visible = false
	end)
end)

--------------------------------------------------------------------
-- Mise à jour de l'affichage
--------------------------------------------------------------------
local shownCoins = 0
local function tweenCoins(target: number)
	local start = shownCoins
	local t0 = os.clock()
	task.spawn(function()
		while os.clock() - t0 < 0.5 do
			local a = (os.clock() - t0) / 0.5
			coinLabel.Text = Kit.formatNumber(start + (target - start) * a)
			task.wait()
		end
		coinLabel.Text = Kit.formatNumber(target)
	end)
	shownCoins = target
end

local function render()
	if not state then
		return
	end
	local stage = state.Stage
	stageLabel.Text = stage >= state.Total and "FINISHED!" or ("STAGE %d / %d"):format(stage, state.Total)
	local world, index = Config.WorldForStage(math.max(stage, 1))
	if stage >= state.Total then
		world, index = Config.Worlds[#Config.Worlds], #Config.Worlds
	elseif stage > 0 and stage % Config.StagesPerWorld == 0 then
		world, index = Config.WorldForStage(stage + 1)
	end
	worldLabel.Text = ("WORLD %d  ·  %s"):format(index, world.Name:upper())
	worldLabel.TextColor3 = world.Alt
	TweenService:Create(barFill, TweenInfo.new(0.4), { Size = UDim2.fromScale(stage / state.Total, 1) }):Play()

	tweenCoins(state.Coins)
	levelLabel.Text = ("LEVEL %d"):format(state.Level)
	multLabel.Text = "x" .. tostring(state.Multiplier)
	TweenService:Create(xpFill, TweenInfo.new(0.4), { Size = UDim2.fromScale(math.clamp(state.XP / state.XPNext, 0, 1), 1) }):Play()

	skipHolder.Visible = Config.Products.SkipStage.Id ~= 0 and stage < state.Total

	for key, card in passCards do
		if state.Passes[key] then
			card.status.Text = "OWNED"
			card.status.Parent.BackgroundColor3 = C.Grey
		end
	end

	refreshTrails()
	refreshRebirth()
	refreshDaily()
end

Remotes.State.OnClientEvent:Connect(function(newState)
	state = newState
	stateReceivedAt = os.clock()
	render()
end)
send("Sync")

-- petit tick pour le compte à rebours et la pastille "daily"
task.spawn(function()
	while true do
		task.wait(1)
		if state then
			local ready = state.DailyReady or dailyRemaining() <= 0
			dailyDot.Visible = ready
			if openPanel == "Daily" then
				refreshDaily()
			end
		end
	end
end)
