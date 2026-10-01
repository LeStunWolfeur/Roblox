-- Récupère (ou crée côté serveur) les RemoteEvents du jeu

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	"State", -- serveur -> client : état du joueur (cash, cartes, rebirths...)
	"Notify", -- serveur -> client : petit message (texte, type)
	"Announce", -- serveur -> tous : grosse annonce (carte rare, event...)
	"Reveal", -- serveur -> client : révélation d'une carte achetée (note, finition)
	"StealAlert", -- serveur -> client : quelqu'un vole ta carte
	"Knockback", -- serveur -> client : tu t'es pris une claque
	"EventState", -- serveur -> tous : event en cours, saison, boost de chance
	"Action", -- client -> serveur : actions de l'interface
	"Admin", -- client -> serveur : commandes du panneau admin
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
