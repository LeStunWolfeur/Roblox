-- Codes promo (onglet Codes du shop). Les codes se règlent dans Config.Codes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local Hub = require(script.Parent.Parent.Hub)

local CodeService = {}

local function expired(code): boolean
	if not code.Expires then
		return false
	end
	local y, m, d = code.Expires[1], code.Expires[2], code.Expires[3]
	local limit = os.time({ year = y, month = m, day = d, hour = 23, min = 59, sec = 59 })
	return os.time() > limit
end

function CodeService.Redeem(player: Player, text: any)
	local data = DataService.Get(player)
	if not data or type(text) ~= "string" then
		return
	end
	local key = text:upper():gsub("%s", "")
	if #key == 0 or #key > 30 then
		return
	end
	local code = Config.Codes[key]
	if not code then
		Remotes.Notify:FireClient(player, "Invalid code", "error")
		return
	end
	if data.Codes[key] then
		Remotes.Notify:FireClient(player, "Code already used", "error")
		return
	end
	if expired(code) then
		Remotes.Notify:FireClient(player, "This code has expired", "error")
		return
	end
	data.Codes[key] = true
	local parts = {}
	if code.Cash then
		data.Cash += code.Cash
		player:SetAttribute("Cash", data.Cash)
		table.insert(parts, Format.cash(code.Cash))
	end
	if code.Speed then
		Hub.Training.AddSpeed(player, code.Speed)
		table.insert(parts, Format.short(code.Speed) .. " Speed")
	end
	if code.Card then
		Hub.Grading.Deliver(player, Hub.Loot.RollCard(code.Card), Hub.Loot.RollFinish())
		table.insert(parts, "a " .. code.Card .. " card")
	end
	Remotes.Notify:FireClient(player, "Code redeemed: " .. table.concat(parts, " + "), "reward")
	Hub.Players.SendState(player)
end

return CodeService
