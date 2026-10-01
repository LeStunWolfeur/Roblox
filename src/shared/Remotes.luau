-- Récupère (ou crée côté serveur) les RemoteEvents du jeu

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	"State", -- serveur -> client : état complet du joueur
	"Notify", -- serveur -> client : petit message (texte, type)
	"Celebrate", -- serveur -> client : level up, fin, rebirth...
	"StuckOffer", -- serveur -> client : propose le skip après plusieurs morts
	"Action", -- client -> serveur : action demandée (skip, rebirth, acheter un trail...)
}

local Remotes = {}

local folder: Folder
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("Remotes") :: Folder
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in NAMES do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

for _, name in NAMES do
	Remotes[name] = folder:WaitForChild(name) :: RemoteEvent
end

return Remotes
