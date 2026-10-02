-- Côté client : prompts personnels (vitrines, tapis), portails de vitesse,
-- claques reçues, animations des cartes, tags dans le chat

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Config = require(ReplicatedStorage.Shared.Config)
local Cards = require(ReplicatedStorage.Shared.Cards)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer

local function makePrompt(parent: Instance, name: string): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.Name = name
	p.RequiresLineOfSight = false
	p.MaxActivationDistance = 9
	p.Enabled = false
	p.Parent = parent
	return p
end

--------------------------------------------------------------------
-- Vitrines de MA galerie : vendre / débloquer
--------------------------------------------------------------------
local casePrompts: { [BasePart]: ProximityPrompt } = {}

local function updateCase(plinth: BasePart)
	local prompt = casePrompts[plinth]
	if not prompt then
		return
	end
	local mine = plinth:GetAttribute("GalleryIndex") == player:GetAttribute("GalleryIndex")
	local cardId = plinth:GetAttribute("CardId")
	local cost = plinth:GetAttribute("Cost")
	if mine and cardId then
		prompt.ActionText = "Sell " .. Format.cash(plinth:GetAttribute("Value") or 0)
		prompt.ObjectText = Cards.DisplayName(cardId, plinth:GetAttribute("Finish")) .. "  G" .. tostring(plinth:GetAttribute("Grade"))
		prompt.HoldDuration = 1.2
		prompt.Enabled = true
	elseif mine and cost then
		prompt.ActionText = "Unlock " .. Format.cash(cost)
		prompt.ObjectText = "Display case"
		prompt.HoldDuration = 0.3
		prompt.Enabled = true
	else
		prompt.Enabled = false
	end
end

local function hookCase(plinth: Instance)
	if not plinth:IsA("BasePart") or casePrompts[plinth] then
		return
	end
	local prompt = makePrompt(plinth, "CasePrompt")
	casePrompts[plinth] = prompt
	prompt.Triggered:Connect(function()
		if plinth:GetAttribute("CardId") then
			Remotes.Action:FireServer("SellCase", plinth:GetAttribute("CaseIndex"))
		elseif plinth:GetAttribute("Cost") then
			Remotes.Action:FireServer("UnlockCase")
		end
	end)
	plinth.AttributeChanged:Connect(function()
		updateCase(plinth)
	end)
	updateCase(plinth)
end
for _, p in CollectionService:GetTagged("Case") do
	hookCase(p)
end
CollectionService:GetInstanceAddedSignal("Case"):Connect(hookCase)
player:GetAttributeChangedSignal("GalleryIndex"):Connect(function()
	for plinth in casePrompts do
		updateCase(plinth)
	end
end)

--------------------------------------------------------------------
-- Tapis de course : débloquer le suivant
--------------------------------------------------------------------
local treadmillPrompts: { [BasePart]: { train: ProximityPrompt, upgrade: ProximityPrompt } } = {}
local treadmillLevel, treadmillCost = 1, nil

local function updateTreadmill(console: BasePart)
	local prompts = treadmillPrompts[console]
	local mine = console:GetAttribute("BaseIndex") == player:GetAttribute("GalleryIndex")
	local training = player:GetAttribute("Training") ~= nil
	prompts.train.Enabled = mine and not training
	prompts.train.ActionText = "Train"
	prompts.train.ObjectText = "Treadmill · Level " .. treadmillLevel
	prompts.upgrade.Enabled = mine and treadmillCost ~= nil
	prompts.upgrade.ActionText = treadmillCost and ("Upgrade " .. Format.cash(treadmillCost)) or "Max level"
	prompts.upgrade.ObjectText = ("Level %d > %d"):format(treadmillLevel, treadmillLevel + 1)
end

local function hookTreadmill(console: Instance)
	if not console:IsA("BasePart") or treadmillPrompts[console] then
		return
	end
	local train = makePrompt(console, "TrainPrompt")
	train.MaxActivationDistance = 14
	train.KeyboardKeyCode = Enum.KeyCode.E
	local upgrade = makePrompt(console, "UpgradePrompt")
	upgrade.MaxActivationDistance = 14
	upgrade.KeyboardKeyCode = Enum.KeyCode.F
	upgrade.HoldDuration = 0.3
	upgrade.UIOffset = Vector2.new(0, 80)
	treadmillPrompts[console] = { train = train, upgrade = upgrade }
	train.Triggered:Connect(function()
		Remotes.Action:FireServer("TrainStart")
	end)
	upgrade.Triggered:Connect(function()
		Remotes.Action:FireServer("UpgradeTreadmill")
	end)
	updateTreadmill(console)
end
for _, c in CollectionService:GetTagged("Treadmill") do
	hookTreadmill(c)
end
CollectionService:GetInstanceAddedSignal("Treadmill"):Connect(hookTreadmill)

local function refreshTreadmills()
	for console in treadmillPrompts do
		updateTreadmill(console)
	end
end
Remotes.State.OnClientEvent:Connect(function(state)
	treadmillLevel = state.Treadmill
	treadmillCost = state.TreadmillCost
	refreshTreadmills()
end)
player:GetAttributeChangedSignal("GalleryIndex"):Connect(refreshTreadmills)
player:GetAttributeChangedSignal("Training"):Connect(refreshTreadmills)

--------------------------------------------------------------------
-- Portails de vitesse : on se cogne dedans si on n'est pas assez rapide
-- (changement local : la physique du personnage est calculée chez le joueur)
--------------------------------------------------------------------
local gates: { BasePart } = {}
local function updateGates()
	local speed = player:GetAttribute("Speed") or 0
	for _, gate in gates do
		local need = gate:GetAttribute("Speed") or 0
		local blocked = speed < need
		gate.CanCollide = blocked
		if need > 0 then
			gate.Transparency = blocked and 0.35 or 0.85
		end
	end
end
local function hookGate(gate: Instance)
	if gate:IsA("BasePart") then
		table.insert(gates, gate)
		updateGates()
	end
end
for _, g in CollectionService:GetTagged("SpeedGate") do
	hookGate(g)
end
CollectionService:GetInstanceAddedSignal("SpeedGate"):Connect(hookGate)
player:GetAttributeChangedSignal("Speed"):Connect(updateGates)

--------------------------------------------------------------------
-- Claque / gardien : projection
--------------------------------------------------------------------
Remotes.Knockback.OnClientEvent:Connect(function(velocity: Vector3)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end
	humanoid.PlatformStand = true
	root.AssemblyLinearVelocity = velocity
	root.AssemblyAngularVelocity = Vector3.new(math.random(-8, 8), math.random(-8, 8), math.random(-8, 8))
	task.delay(1.1, function()
		if humanoid.Parent then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end)

--------------------------------------------------------------------
-- Animations : cartes exposées qui oscillent, reflets des finitions
--------------------------------------------------------------------
local displayBase: { [BasePart]: CFrame } = {}
local function hookDisplay(part: Instance)
	if part:IsA("BasePart") then
		displayBase[part] = part.CFrame
		part.Destroying:Connect(function()
			displayBase[part] = nil
		end)
	end
end
for _, p in CollectionService:GetTagged("DisplayCard") do
	hookDisplay(p)
end
CollectionService:GetInstanceAddedSignal("DisplayCard"):Connect(hookDisplay)
CollectionService:GetInstanceRemovedSignal("DisplayCard"):Connect(function(p)
	displayBase[p :: BasePart] = nil
end)

local shines: { [UIGradient]: boolean } = {}
local function hookShine(g: Instance)
	if g:IsA("UIGradient") then
		shines[g] = true
	end
end
for _, g in CollectionService:GetTagged("CardShine") do
	hookShine(g)
end
CollectionService:GetInstanceAddedSignal("CardShine"):Connect(hookShine)
CollectionService:GetInstanceRemovedSignal("CardShine"):Connect(function(g)
	shines[g :: UIGradient] = nil
end)

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for part, base in displayBase do
		if part.Parent then
			part.CFrame = base * CFrame.new(0, math.sin(t * 1.6) * 0.15, 0) * CFrame.Angles(0, math.sin(t * 0.8) * 0.35, 0)
		end
	end
	local offset = ((t * 0.6) % 2) - 1
	for g in shines do
		if g.Parent then
			g.Offset = Vector2.new(offset * 1.5, 0)
		else
			shines[g] = nil
		end
	end
end)

--------------------------------------------------------------------
-- Chat : [VIP] [R3]
--------------------------------------------------------------------
TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local props = Instance.new("TextChatMessageProperties")
	local source = message.TextSource
	local speaker = source and Players:GetPlayerByUserId(source.UserId)
	if not speaker then
		return props
	end
	local prefix = ""
	local rebirths = speaker:GetAttribute("Rebirths")
	if rebirths and rebirths > 0 then
		prefix ..= ("<font color='#FF4670'>[R%d]</font> "):format(rebirths)
	end
	if speaker:GetAttribute("VIP") then
		prefix ..= "<font color='#FFC828'>[VIP]</font> "
	end
	props.PrefixText = prefix .. message.PrefixText
	return props
end
