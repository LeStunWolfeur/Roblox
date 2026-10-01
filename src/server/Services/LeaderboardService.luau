-- Classements mondiaux affichés dans le lobby (niveaux et dons)

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)

local LeaderboardService = {}

local names: { [number]: string } = {}

local function nameFor(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	names[userId] = ok and name or "???"
	return names[userId]
end

local function shortNumber(n: number): string
	if n >= 1e6 then
		return ("%.1fM"):format(n / 1e6)
	elseif n >= 1e4 then
		return ("%.1fK"):format(n / 1e3)
	end
	return tostring(n)
end

local function buildBoardGui(board: BasePart, title: string)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = board

	local header = Instance.new("TextLabel")
	header.BackgroundColor3 = Color3.fromRGB(255, 70, 110)
	header.BorderSizePixel = 0
	header.Size = UDim2.fromScale(1, 0.13)
	header.Font = Enum.Font.FredokaOne
	header.TextScaled = true
	header.TextColor3 = Color3.new(1, 1, 1)
	header.Text = title
	header.Parent = gui
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.15, 0)
	pad.PaddingBottom = UDim.new(0.15, 0)
	pad.Parent = header

	local list = Instance.new("Frame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromScale(0.05, 0.16)
	list.Size = UDim2.fromScale(0.9, 0.82)
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.01, 0)
	layout.Parent = list

	local rows = {}
	for i = 1, 10 do
		local row = Instance.new("TextLabel")
		row.BackgroundTransparency = i % 2 == 0 and 1 or 0.92
		row.BackgroundColor3 = Color3.new(1, 1, 1)
		row.BorderSizePixel = 0
		row.Size = UDim2.fromScale(1, 0.09)
		row.Font = Enum.Font.GothamBold
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = i == 1 and Color3.fromRGB(255, 210, 60)
			or i == 2 and Color3.fromRGB(210, 220, 235)
			or i == 3 and Color3.fromRGB(230, 150, 90)
			or Color3.fromRGB(230, 230, 240)
		row.Text = ""
		row.LayoutOrder = i
		row.Parent = list
		rows[i] = row
	end
	return rows
end

local function refreshBoard(store: OrderedDataStore, rows, suffix: string)
	local ok, pages = pcall(store.GetSortedAsync, store, false, 10)
	if not ok then
		return
	end
	local entries = pages:GetCurrentPage()
	for i = 1, 10 do
		local entry = entries[i]
		if entry and entry.value > 0 then
			local userId = tonumber(entry.key)
			local name = userId and nameFor(userId) or "???"
			rows[i].Text = ("  #%d  %s  ·  %s%s"):format(i, name, shortNumber(entry.value), suffix)
		else
			rows[i].Text = ("  #%d  ---"):format(i)
		end
	end
end

function LeaderboardService.Start(boards)
	local okLevel, levelStore = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, Config.StageBoardStore)
	local okDonate, donateStore = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, Config.DonationBoardStore)
	if not okLevel or not okDonate then
		warn("[Leaderboard] OrderedDataStore unavailable")
		return
	end

	local levelRows = buildBoardGui(boards.TopLevels.part, boards.TopLevels.title)
	local donateRows = buildBoardGui(boards.TopDonors.part, boards.TopDonors.title)

	local lastSent: { [number]: { level: number, donated: number } } = {}

	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				local data = DataService.Get(player)
				if data then
					local prev = lastSent[player.UserId] or { level = -1, donated = -1 }
					local levelScore = data.Level
					if levelScore ~= prev.level then
						pcall(levelStore.SetAsync, levelStore, tostring(player.UserId), levelScore)
						prev.level = levelScore
					end
					if data.Donated > 0 and data.Donated ~= prev.donated then
						pcall(donateStore.SetAsync, donateStore, tostring(player.UserId), data.Donated)
						prev.donated = data.Donated
					end
					lastSent[player.UserId] = prev
				end
			end
			refreshBoard(levelStore, levelRows, " lvl")
			refreshBoard(donateStore, donateRows, " R$")
			task.wait(Config.LeaderboardRefresh)
		end
	end)
end

return LeaderboardService
