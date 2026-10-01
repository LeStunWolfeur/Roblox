--[[
	Tapis de course côté joueur.
	Le serveur met l'attribut "Training" quand on monte sur un tapis.
	- Le personnage est placé sur le tapis et bloqué.
	- Tant qu'on reste appuyé (Espace, W, flèche haut, clic, gâchette, ou le bouton RUN),
	  il court (animation de course du personnage) et la Speed monte.
	- X, Retour arrière ou le bouton LEAVE pour descendre.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Kit = require(script.Parent.UI.Kit)

local C = Kit.Colors
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HOLD_KEYS = {
	[Enum.KeyCode.Space] = true,
	[Enum.KeyCode.W] = true,
	[Enum.KeyCode.Up] = true,
	[Enum.KeyCode.ButtonA] = true,
	[Enum.KeyCode.ButtonR2] = true,
}
local LEAVE_KEYS = { [Enum.KeyCode.X] = true, [Enum.KeyCode.Backspace] = true, [Enum.KeyCode.ButtonB] = true }

local active: number? = nil
local holdSources: { [any]: boolean } = {}
local holding = false
local runTrack: AnimationTrack? = nil
local passes: { [string]: boolean } = {}
local multiplier = 1

--------------------------------------------------------------------
-- Interface d'entraînement
--------------------------------------------------------------------
local gui = Kit.new("ScreenGui", { Name = "TrainingUI", ResetOnSpawn = false, Enabled = false, Parent = playerGui })
local scale = Kit.new("UIScale", { Parent = gui })
local function updateScale()
	local size = workspace.CurrentCamera.ViewportSize
	scale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 760), 0.55, 1.15)
end
updateScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

local _, panel = Kit.sticker({
	Parent = gui,
	Size = UDim2.fromOffset(460, 150),
	Position = UDim2.new(0.5, 0, 1, -30),
	AnchorPoint = Vector2.new(0.5, 1),
	Color = C.Ink2,
}, 6)
local title = Kit.label({ Parent = panel, Size = UDim2.new(1, -24, 0, 34), Position = UDim2.fromOffset(12, 8), Text = "HOLD SPACE TO RUN", ZIndex = 5 })
Kit.textStroke(3).Parent = title
local rateLabel = Kit.label({ Parent = panel, Size = UDim2.new(1, -24, 0, 20), Position = UDim2.fromOffset(12, 44), Font = Kit.Body, TextColor3 = C.Green, Text = "", ZIndex = 5 })
local _, runBtn = Kit.button({
	Parent = panel,
	Size = UDim2.fromOffset(250, 58),
	Position = UDim2.fromOffset(16, 78),
	Color = C.Green,
	Text = "HOLD TO RUN",
	ZIndex = 5,
}, function() end)
Kit.button({
	Parent = panel,
	Size = UDim2.fromOffset(160, 58),
	Position = UDim2.new(1, -176, 0, 78),
	Color = C.Pink,
	Text = "LEAVE (X)",
	TextColor = C.White,
	TextStroke = true,
	ZIndex = 5,
}, function()
	Remotes.Action:FireServer("TrainStop")
end)

local function autoTrain(): boolean
	return passes.AutoTrain == true
end

local function refreshUI()
	if not active then
		return
	end
	local tier = Config.Treadmills[active]
	local rate = tier.Rate * multiplier
	if autoTrain() then
		title.Text = "AUTO TRAINING"
	else
		title.Text = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and "HOLD THE BUTTON TO RUN" or "HOLD SPACE / CLICK TO RUN"
	end
	rateLabel.Text = ("%s treadmill  ·  +%s Speed/s"):format(tier.Name, Format.short(rate))
	runBtn.Parent.BackgroundColor3 = (holding or autoTrain()) and C.Yellow or C.Green
	runBtn.Text = (holding or autoTrain()) and "RUNNING!" or "HOLD TO RUN"
end

--------------------------------------------------------------------
-- Animation de course (on réutilise celle du personnage)
--------------------------------------------------------------------
local function getRunTrack(): AnimationTrack?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	local animate = character and character:FindFirstChild("Animate")
	local run = animate and animate:FindFirstChild("run")
	local anim = run and run:FindFirstChildOfClass("Animation")
	if not animator or not anim then
		return nil
	end
	local track = animator:LoadAnimation(anim)
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Action
	return track
end

local function updateRunning()
	local running = active ~= nil and (holding or autoTrain())
	if running then
		if not runTrack then
			runTrack = getRunTrack()
		end
		if runTrack and not runTrack.IsPlaying then
			runTrack:Play(0.15)
		end
		if runTrack then
			runTrack:AdjustSpeed(1.6)
		end
	elseif runTrack and runTrack.IsPlaying then
		runTrack:Stop(0.2)
	end
	refreshUI()
end

local function setHolding(value: boolean)
	if value == holding then
		return
	end
	holding = value
	if active then
		Remotes.Action:FireServer("TrainHold", value)
	end
	updateRunning()
end

local function recomputeHold()
	local any = false
	for _, v in holdSources do
		if v then
			any = true
		end
	end
	setHolding(any)
end

--------------------------------------------------------------------
-- Monter / descendre du tapis
--------------------------------------------------------------------
local function consoleFor(index: number): BasePart?
	for _, c in CollectionService:GetTagged("Treadmill") do
		if c:GetAttribute("TreadmillIndex") == index then
			return c :: BasePart
		end
	end
	return nil
end

local function enter(index: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local console = consoleFor(index)
	if not root or not humanoid or not console then
		return
	end
	active = index
	local spot = console:GetAttribute("Spot") :: CFrame
	local beltTop = console:GetAttribute("BeltTop") or 2
	local y = beltTop + humanoid.HipHeight + root.Size.Y / 2
	root.Anchored = true
	character:PivotTo(CFrame.new(spot.Position.X, y, spot.Position.Z) * (spot - spot.Position))
	holdSources = {}
	holding = false
	gui.Enabled = true
	updateRunning()
end

local function leave()
	active = nil
	holdSources = {}
	holding = false
	gui.Enabled = false
	if runTrack then
		runTrack:Stop(0.2)
		runTrack = nil
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.Anchored = false
	end
end

player:GetAttributeChangedSignal("Training"):Connect(function()
	local index = player:GetAttribute("Training")
	if index then
		enter(index)
	else
		leave()
	end
end)
player.CharacterAdded:Connect(function()
	runTrack = nil
	if active then
		leave()
	end
end)

--------------------------------------------------------------------
-- Entrées
--------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, processed)
	if not active then
		return
	end
	if LEAVE_KEYS[input.KeyCode] and not processed then
		Remotes.Action:FireServer("TrainStop")
		return
	end
	if HOLD_KEYS[input.KeyCode] then
		holdSources[input.KeyCode] = true
		recomputeHold()
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 and not processed then
		holdSources.Mouse = true
		recomputeHold()
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if HOLD_KEYS[input.KeyCode] then
		holdSources[input.KeyCode] = nil
		recomputeHold()
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		holdSources.Mouse = nil
		recomputeHold()
	end
end)
runBtn.MouseButton1Down:Connect(function()
	holdSources.Button = true
	recomputeHold()
end)
runBtn.MouseButton1Up:Connect(function()
	holdSources.Button = nil
	recomputeHold()
end)
runBtn.MouseLeave:Connect(function()
	holdSources.Button = nil
	recomputeHold()
end)

Remotes.State.OnClientEvent:Connect(function(state)
	passes = state.Passes or {}
	multiplier = state.SpeedMultiplier or 1
	updateRunning()
end)
