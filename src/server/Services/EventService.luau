-- Events du serveur (météo), saison en cours, boost de chance acheté

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Cards = require(ReplicatedStorage.Shared.Cards)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local EventService = {}

local current: string? = nil
local endsAt = 0
local luckUntil = 0
local season: string? = nil
local nextId: string? = nil
local nextAt = 0
local rng = Random.new()

local function now(): number
	return workspace:GetServerTimeNow()
end

function EventService.Season(): string?
	return season
end

function EventService.Current(): string?
	if current and endsAt > now() then
		return current
	end
	return nil
end

function EventService.Luck(): number
	local luck = 1
	local id = EventService.Current()
	if id and Config.Events[id].Luck then
		luck *= Config.Events[id].Luck
	end
	if luckUntil > now() then
		luck *= Config.ServerLuckMultiplier
	end
	return luck
end

function EventService.FinishBoosts(): { [string]: number }
	local id = EventService.Current()
	return (id and Config.Events[id].FinishBoost) or {}
end

function EventService.RestockSpeed(): number
	local id = EventService.Current()
	return (id and Config.Events[id].RestockSpeed) or 1
end

function EventService.GuardianSpeedFactor(): number
	local id = EventService.Current()
	return (id and Config.Events[id].GuardianSlow) or 1
end

function EventService.Broadcast(player: Player?)
	local payload = {
		Event = EventService.Current(),
		EndsAt = endsAt,
		Season = season,
		LuckUntil = luckUntil,
		NextEvent = nextId,
		NextAt = nextAt,
		FrozenUntil = workspace:GetAttribute("GuardsFrozenUntil") or 0,
	}
	if player then
		Remotes.EventState:FireClient(player, payload)
	else
		Remotes.EventState:FireAllClients(payload)
	end
end

function EventService.StartEvent(id: string, duration: number?)
	local event = Config.Events[id]
	if not event then
		return
	end
	current = id
	endsAt = now() + (duration or Config.EventDuration)
	Remotes.Announce:FireAllClients(event.Name, event.Description, "event")
	EventService.Broadcast()
end

function EventService.AddServerLuck(seconds: number, byName: string?)
	luckUntil = math.max(luckUntil, now()) + seconds
	Remotes.Announce:FireAllClients(
		"SERVER LUCK x" .. Config.ServerLuckMultiplier,
		byName and ("Thanks to " .. byName .. "!") or "Rare cards boosted",
		"luck"
	)
	EventService.Broadcast()
end

local function applySeasonLighting()
	local s = season and Cards.Seasons[season]
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if s and s.Lighting then
		Lighting.ClockTime = s.Lighting.ClockTime
		if atmosphere then
			atmosphere.Color = s.Lighting.Atmosphere
		end
	else
		Lighting.ClockTime = 14
		if atmosphere then
			atmosphere.Color = Color3.fromRGB(200, 215, 255)
		end
	end
end

local function refreshSeason()
	local date = os.date("!*t")
	local new = Cards.ActiveSeason({ month = date.month, day = date.day })
	if new ~= season then
		season = new
		applySeasonLighting()
		EventService.Broadcast()
	end
end

function EventService.Start()
	refreshSeason()
	task.spawn(function()
		while true do
			task.wait(600)
			refreshSeason()
		end
	end)

	task.spawn(function()
		while true do
			-- on choisit le prochain event à l'avance pour l'afficher dans la prévision
			local pool = {}
			for id, event in Config.Events do
				if not event.Season or event.Season == season then
					table.insert(pool, id)
				end
			end
			table.sort(pool)
			nextId = pool[rng:NextInteger(1, #pool)]
			nextAt = now() + rng:NextInteger(Config.EventEvery[1], Config.EventEvery[2])
			EventService.Broadcast()
			while now() < nextAt do
				task.wait(1)
			end
			if not EventService.Current() then
				EventService.StartEvent(nextId)
			end
		end
	end)
end

return EventService
