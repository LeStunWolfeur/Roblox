-- Game Passes et Developer Products (achats Robux)

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local MonetizationService = {}

local owned: { [Player]: { [string]: boolean } } = {}
local passChanged = Instance.new("BindableEvent")
MonetizationService.PassChanged = passChanged.Event -- (player, key)

-- handlers[kind] = function(player, product) -> boolean (true = livré)
local handlers: { [string]: (Player, any) -> boolean } = {}

function MonetizationService.RegisterHandler(kind: string, fn: (Player, any) -> boolean)
	handlers[kind] = fn
end

local function passKeyFromId(id: number): string?
	if id == 0 then
		return nil
	end
	for key, pass in Config.GamePasses do
		if pass.Id == id then
			return key
		end
	end
	return nil
end

local function productFromId(id: number)
	if id == 0 then
		return nil, nil
	end
	for key, product in Config.Products do
		if product.Id == id then
			return key, product
		end
	end
	return nil, nil
end

function MonetizationService.Owns(player: Player, key: string): boolean
	local list = owned[player]
	return list ~= nil and list[key] == true
end

function MonetizationService.OwnedList(player: Player): { [string]: boolean }
	local result = {}
	for key in Config.GamePasses do
		result[key] = MonetizationService.Owns(player, key)
	end
	return result
end

local function loadPasses(player: Player)
	local list = {}
	owned[player] = list
	local grantAll = Config.StudioGrantAllPasses and RunService:IsStudio()
	for key, pass in Config.GamePasses do
		if grantAll then
			list[key] = true
		elseif pass.Id ~= 0 then
			local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			list[key] = ok and result == true
		end
	end
end

function MonetizationService.PromptPass(player: Player, key: string)
	local pass = Config.GamePasses[key]
	if not pass or MonetizationService.Owns(player, key) then
		return
	end
	if pass.Id == 0 then
		Remotes.Notify:FireClient(player, pass.Name .. " is not on sale yet", "error")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, pass.Id)
end

function MonetizationService.PromptProduct(player: Player, key: string)
	local product = Config.Products[key]
	if not product then
		return
	end
	if product.Id == 0 then
		Remotes.Notify:FireClient(player, product.Name .. " is not on sale yet", "error")
		return
	end
	MarketplaceService:PromptProductPurchase(player, product.Id)
end

-- Traitement des achats de Developer Products.
-- On ne renvoie PurchaseGranted que si l'achat est livré ET sauvegardé,
-- sinon Roblox réessaiera plus tard (et le joueur ne perd jamais son achat).
local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = DataService.WaitFor(player, 20)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseId = tostring(receipt.PurchaseId)
	if DataService.HasReceipt(player, purchaseId) then
		if DataService.CommitReceipt(player, purchaseId) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local _, product = productFromId(receipt.ProductId)
	if not product then
		warn("[Monetization] Unknown product id", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local handler = handlers[product.Kind]
	if not handler then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, delivered = pcall(handler, player, product)
	if not ok or not delivered then
		warn("[Monetization] Handler failed", product.Name, delivered)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if DataService.CommitReceipt(player, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationService.Start()
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local key = passKeyFromId(passId)
		if key and owned[player] then
			owned[player][key] = true
			passChanged:Fire(player, key)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
	end)
end

-- Appelé à l'arrivée du joueur, avant d'appliquer les bonus
function MonetizationService.LoadPlayer(player: Player)
	loadPasses(player)
end

return MonetizationService
