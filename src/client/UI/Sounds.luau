-- Petits sons de l'interface et musique de fond (réglages dans Config.Sounds / Config.Music)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)

local Sounds = {}

local cache: { [string]: Sound } = {}

local function get(name: string): Sound?
	local id = Config.Sounds[name]
	if not id or id == "" then
		return nil
	end
	if not cache[name] then
		local s = Instance.new("Sound")
		s.Name = "UI_" .. name
		s.SoundId = id
		s.Volume = Config.SoundVolume
		s.Parent = SoundService
		cache[name] = s
	end
	return cache[name]
end

function Sounds.play(name: string, pitch: number?)
	local s = get(name)
	if s then
		s.PlaybackSpeed = pitch or 1
		pcall(function()
			SoundService:PlayLocalSound(s)
		end)
	end
end

-- musique de fond en boucle (si Config.Music contient des musiques)
function Sounds.startMusic()
	if #Config.Music == 0 then
		return
	end
	task.spawn(function()
		local music = Instance.new("Sound")
		music.Name = "Music"
		music.Volume = Config.MusicVolume
		music.Parent = SoundService
		local i = 1
		while true do
			music.SoundId = Config.Music[i]
			music:Play()
			music.Ended:Wait()
			i = i % #Config.Music + 1
		end
	end)
end

return Sounds
