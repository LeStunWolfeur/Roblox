-- Côté client : boutons des supports, prompt du tapis, portails de vitesse,
-- claques reçues, animations des cartes, tags dans le chat

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Cards = require(ReplicatedStorage.Shared.Cards)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Kit = require(script.Parent.UI.Kit)

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
-- Supports de MA base : boutons cliquables qui apparaissent quand on s'approche
--   carte posée : VENDRE (avec confirmation) / RAMASSER
--   support vide : POSER ICI (si on tient une carte)
--   support suivant : DÉBLOQUER $X
--------------------------------------------------------------------
local playerGui = player:WaitForChild("PlayerGui")
local caseGuis: { [BasePart]: any } = {}
local SHOW_DISTANCE = 13

local function caseButton(parent: Instance, text: string, palette: string, order: number, onClick: () -> ()): (Frame, TextLabel?)
	local face, _, label = Kit.button({ Parent = parent, Size = UDim2.fromOffset(118, 46), Palette = palette, Text = text, LayoutOrder = order, TextStroke = 2.5 }, onClick)
	return face, label
end

local function buildCaseGui(plinth: BasePart)
	local info = caseGuis[plinth]
	if info then
		info.gui:Destroy()
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "CaseButtons"
	gui.Adornee = plinth
	gui.Size = UDim2.fromOffset(260, 56)
	gui.StudsOffset = Vector3.new(0, 2.4, 0)
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Active = true
	gui.LightInfluence = 0
	gui.Parent = playerGui
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 1)
	row.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row
	info = { gui = gui, row = row, key = "" }
	caseGuis[plinth] = info
	return info
end

local function refreshCase(plinth: BasePart)
	local mine = plinth:GetAttribute("GalleryIndex") == player:GetAttribute("GalleryIndex")
	local stateName = plinth:GetAttribute("State")
	local holding = player:GetAttribute("Carrying") ~= nil
	local key = table.concat({ tostring(mine), tostring(stateName), tostring(holding), tostring(plinth:GetAttribute("Value")), tostring(plinth:GetAttribute("Cost")) }, "|")
	local info = caseGuis[plinth] or buildCaseGui(plinth)
	if info.key == key then
		return
	end
	info.key = key
	for _, c in info.row:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	info.active = false
	if not mine then
		return
	end
	local index = plinth:GetAttribute("CaseIndex")
	if stateName == "card" then
		info.active = true
		local confirm = false
		local sellFace, sellLabel
		sellFace, sellLabel = caseButton(info.row, "SELL " .. Format.cash(plinth:GetAttribute("Value") or 0), "Red", 1, function()
			if not confirm then
				confirm = true
				if sellLabel then
					sellLabel.Text = "SURE?"
				end
				Kit.paint(sellFace, "Orange")
				task.delay(2.5, function()
					confirm = false
					if sellLabel and sellLabel.Parent then
						sellLabel.Text = "SELL " .. Format.cash(plinth:GetAttribute("Value") or 0)
						Kit.paint(sellFace, "Red")
					end
				end)
				return
			end
			Remotes.Action:FireServer("SellCase", index)
		end)
		if not holding then
			caseButton(info.row, "PICK UP", "Blue", 2, function()
				Remotes.Action:FireServer("PickUp", index)
			end)
		end
	elseif stateName == "empty" and holding and player:GetAttribute("CarryFromBase") then
		info.active = true
		caseButton(info.row, "PLACE HERE", "Green", 1, function()
			Remotes.Action:FireServer("Place", index)
		end)
	elseif stateName == "buy" then
		info.active = true
		caseButton(info.row, "UNLOCK " .. Format.cash(plinth:GetAttribute("Cost") or 0), "Yellow", 1, function()
			Remotes.Action:FireServer("UnlockCase")
		end)
	end
end

local function hookCase(plinth: Instance)
	if not plinth:IsA("BasePart") or caseGuis[plinth] then
		return
	end
	buildCaseGui(plinth)
	plinth.AttributeChanged:Connect(function()
		refreshCase(plinth)
	end)
	refreshCase(plinth)
end
for _, p in CollectionService:GetTagged("Case") do
	hookCase(p)
end
CollectionService:GetInstanceAddedSignal("Case"):Connect(hookCase)
local function refreshAllCases()
	for plinth in caseGuis do
		refreshCase(plinth)
	end
end
player:GetAttributeChangedSignal("GalleryIndex"):Connect(refreshAllCases)
player:GetAttributeChangedSignal("Carrying"):Connect(refreshAllCases)
player:GetAttributeChangedSignal("CarryFromBase"):Connect(refreshAllCases)
-- les boutons ne s'affichent que près du support
task.spawn(function()
	while true do
		task.wait(0.2)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		for plinth, info in caseGuis do
			local near = root ~= nil and (root.Position - plinth.Position).Magnitude < SHOW_DISTANCE and plinth.Transparency < 1
			info.gui.Enabled = info.active == true and near
		end
	end
end)

--------------------------------------------------------------------
-- Tapis de course : débloquer le suivant
--------------------------------------------------------------------
local treadmillPrompts: { [BasePart]: { train: ProximityPrompt } } = {}
local treadmillLevel, treadmillCost = 1, nil

local function updateTreadmill(console: BasePart)
	local prompts = treadmillPrompts[console]
	local mine = console:GetAttribute("BaseIndex") == player:GetAttribute("GalleryIndex")
	local training = player:GetAttribute("Training") ~= nil
	prompts.train.Enabled = mine and not training
	prompts.train.ActionText = "Train"
	prompts.train.ObjectText = "Treadmill · Level " .. treadmillLevel
	-- l'amélioration se fait uniquement en cliquant sur le gros bouton à côté du tapis
end

local function hookTreadmill(console: Instance)
	if not console:IsA("BasePart") or treadmillPrompts[console] then
		return
	end
	local train = makePrompt(console, "TrainPrompt")
	train.MaxActivationDistance = 14
	train.KeyboardKeyCode = Enum.KeyCode.E
	treadmillPrompts[console] = { train = train }
	train.Triggered:Connect(function()
		Remotes.Action:FireServer("TrainStart")
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
		displayBase[part] = part:GetAttribute("BaseCFrame") or part.CFrame
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
			-- la carte flotte et tourne lentement sur elle-même
			part.CFrame = base * CFrame.new(0, math.sin(t * 1.6) * 0.25, 0) * CFrame.Angles(0, t * 0.9, 0)
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
