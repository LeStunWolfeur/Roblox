-- Sauvegarde des joueurs (stage, victoires, dons, reçus d'achat)

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}

local MAX_RECEIPTS = 60
local RETRIES = 4

local store: DataStore? = nil
local storeOk = pcall(function()
	store = DataStoreService:GetDataStore(Config.DataStoreName)
end)

local profiles: { [Player]: any } = {}
local canSave: { [Player]: boolean } = {}
local loadedSignal = Instance.new("BindableEvent")

local function defaultData()
	return {
		Cash = Config.StartCash,
		Speed = 0,
		Treadmill = 1, -- niveau du tapis de course de la base
		Raw = {}, -- cartes volées pas encore gradées : { Id, F }
		Grading = {}, -- cartes au labo : { Id, F, Ends = os.time() de fin }
		Cards = {}, -- cartes gradées exposées : { S = vitrine, Id, F, G }
		Cases = Config.GalleryStartCases, -- vitrines débloquées
		Rebirths = 0,
		Index = {}, -- [idCarte] = true pour chaque carte déjà possédée
		BestZone = 1,
		TotalEarned = 0,
		Steals = 0,
		DailyStreak = 0,
		StarterBought = false,
		LastDaily = 0,
		Codes = {}, -- [CODE] = true pour chaque code utilisé
		Receipts = {},
	}
end

local function retry<T>(fn: () -> T): (boolean, T?)
	local ok, result
	for attempt = 1, RETRIES do
		ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn(("[DataService] attempt %d failed: %s"):format(attempt, tostring(result)))
		task.wait(attempt * 1.5)
	end
	return false, nil
end

local function keyFor(player: Player): string
	return "u_" .. player.UserId
end

function DataService.Load(player: Player)
	local data = defaultData()
	local ok = false

	if storeOk and store then
		local success, saved = retry(function()
			return (store :: DataStore):GetAsync(keyFor(player))
		end)
		ok = success
		if success and type(saved) == "table" then
			for k, v in saved do
				data[k] = v
			end
		end
	end

	if not player.Parent then
		return
	end

	if not ok then
		if RunService:IsStudio() then
			warn("[DataService] DataStore unavailable in Studio. Enable 'Studio Access to API Services' to test saving.")
		else
			player:Kick("Your progress could not be loaded. Please rejoin in a moment.")
			return
		end
	end

	data.Cash = tonumber(data.Cash) or Config.StartCash
	profiles[player] = data
	canSave[player] = ok
	loadedSignal:Fire(player)
end

function DataService.Get(player: Player)
	return profiles[player]
end

-- Attend que les données d'un joueur soient chargées (ou qu'il parte)
function DataService.WaitFor(player: Player, timeout: number?)
	local deadline = os.clock() + (timeout or 30)
	while not profiles[player] and player.Parent and os.clock() < deadline do
		task.wait(0.1)
	end
	return profiles[player]
end

function DataService.Save(player: Player): boolean
	local data = profiles[player]
	if not data or not canSave[player] or not store then
		return false
	end
	local ok = retry(function()
		return (store :: DataStore):UpdateAsync(keyFor(player), function(old)
			-- on garde les reçus déjà connus pour ne jamais redonner un achat
			if type(old) == "table" and type(old.Receipts) == "table" then
				local known = {}
				for _, id in data.Receipts do
					known[id] = true
				end
				for _, id in old.Receipts do
					if not known[id] then
						table.insert(data.Receipts, id)
					end
				end
			end
			while #data.Receipts > MAX_RECEIPTS do
				table.remove(data.Receipts, 1)
			end
			return data
		end)
	end)
	return ok
end

function DataService.HasReceipt(player: Player, purchaseId: string): boolean
	local data = profiles[player]
	return data ~= nil and table.find(data.Receipts, purchaseId) ~= nil
end

-- Enregistre un reçu et sauvegarde tout de suite. Renvoie true si c'est bien écrit.
function DataService.CommitReceipt(player: Player, purchaseId: string): boolean
	local data = profiles[player]
	if not data then
		return false
	end
	if not table.find(data.Receipts, purchaseId) then
		table.insert(data.Receipts, purchaseId)
	end
	if not canSave[player] then
		-- en Studio sans API, on accepte pour pouvoir tester
		return RunService:IsStudio()
	end
	return DataService.Save(player)
end

function DataService.Release(player: Player)
	DataService.Save(player)
	profiles[player] = nil
	canSave[player] = nil
end

DataService.Loaded = loadedSignal.Event

function DataService.Start()
	Players.PlayerRemoving:Connect(DataService.Release)

	task.spawn(function()
		while true do
			task.wait(Config.AutosaveInterval)
			for _, player in Players:GetPlayers() do
				task.spawn(DataService.Save, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for _, player in Players:GetPlayers() do
			pending += 1
			task.spawn(function()
				DataService.Save(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.2)
		end
	end)
end

return DataService
