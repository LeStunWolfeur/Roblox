-- Classements mondiaux affichés dans le lobby (niveaux et dons)

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local Format = require(ReplicatedStorage.Shared.Format)

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

local function buildBoardGui(board: BasePart, title: string)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
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
			rows[i].Text = ("  #%d  %s  ·  %s%s"):format(i, name, Format.short(entry.value), suffix)
		else
			rows[i].Text = ("  #%d  ---"):format(i)
		end
	end
end

local function submitMax(store: OrderedDataStore, userId: number, value: number): boolean
	return (pcall(function()
		store:UpdateAsync(tostring(userId), function(old)
			return math.max(tonumber(old) or 0, value)
		end)
	end))
end

-- getIncome(player) renvoie le revenu par seconde actuel du joueur
function LeaderboardService.Start(boards, getIncome: (Player) -> number)
	local okIncome, incomeStore = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, Config.IncomeBoardStore)
	local okSpeed, speedStore = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, Config.SpeedBoardStore)
	if not okIncome or not okSpeed then
		warn("[Leaderboard] OrderedDataStore unavailable")
		return
	end

	local incomeRows = buildBoardGui(boards.TopIncome.part, boards.TopIncome.title)
	local speedRows = buildBoardGui(boards.TopSpeed.part, boards.TopSpeed.title)

	-- on garde le meilleur score atteint (il baisse après un rebirth)
	local best: { [number]: { income: number, speed: number } } = {}

	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				local data = DataService.Get(player)
				if data then
					local prev = best[player.UserId] or { income = 0, speed = 0 }
					local income = math.floor(getIncome(player))
					if income > prev.income and submitMax(incomeStore, player.UserId, income) then
						prev.income = income
					end
					local speed = math.floor(data.Speed)
					if speed > prev.speed and submitMax(speedStore, player.UserId, speed) then
						prev.speed = speed
					end
					best[player.UserId] = prev
				end
			end
			refreshBoard(incomeStore, incomeRows, "/s")
			refreshBoard(speedStore, speedRows, "")
			task.wait(Config.LeaderboardRefresh)
		end
	end)
end

return LeaderboardService
