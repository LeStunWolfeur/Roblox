--[[
	Tapis de course côté joueur.
	Le serveur met l'attribut "Training" quand on monte sur un tapis (touche E).
	- Le personnage est placé sur le tapis et court tout seul : plus le tapis est
	  amélioré, plus il court vite et plus la Speed monte.
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
local Icons3D = require(script.Parent.UI.Icons3D)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local LEAVE_KEYS = { [Enum.KeyCode.X] = true, [Enum.KeyCode.Backspace] = true, [Enum.KeyCode.ButtonB] = true }

local active: number? = nil
local runTrack: AnimationTrack? = nil
local rate = 5
local level = 1
local cost: number? = nil

--------------------------------------------------------------------
-- Interface d'entraînement (au-dessus de la barre de vitesse)
--------------------------------------------------------------------
local gui = Kit.new("ScreenGui", { Name = "TrainingUI", ResetOnSpawn = false, Enabled = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui })
local scale = Kit.new("UIScale", { Parent = gui })
local function updateScale()
	local size = workspace.CurrentCamera.ViewportSize
	scale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 760), 0.5, 1.2)
end
updateScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

local panel = Kit.well({
	Parent = gui,
	Size = UDim2.fromOffset(560, 150),
	Position = UDim2.new(0.5, 0, 1, -146),
	AnchorPoint = Vector2.new(0.5, 1),
	Color = Color3.fromRGB(18, 22, 32),
	Transparency = 0.15,
	Border = 4,
	Radius = 8,
})
local head = Kit.tile({ Parent = panel, Size = UDim2.new(1, 0, 0, 56), Palette = "Lime", Border = 4, Radius = 8 })
Icons3D.view("treadmill", { Parent = panel, Size = UDim2.fromOffset(120, 120), Position = UDim2.fromOffset(-40, -52), Rotation = -6, ZIndex = 4 })
local title = Kit.text({ Parent = head, Text = "TRAINING!", Size = UDim2.new(1, -100, 0, 40), Position = UDim2.fromOffset(80, 8), TextXAlignment = Enum.TextXAlignment.Left, Stroke = 3.5 })
local rateLabel = Kit.text({ Parent = panel, Text = "", Size = UDim2.new(0.44, -10, 0, 30), Position = UDim2.fromOffset(16, 66), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Kit.Colors.Speed, Stroke = 3 })
local nextLabel = Kit.text({ Parent = panel, Text = "", Size = UDim2.new(0.44, -10, 0, 22), Position = UDim2.fromOffset(16, 100), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(210, 215, 230), Stroke = 2.5 })
local upFace, _, upLabel = Kit.button({
	Parent = panel,
	Size = UDim2.fromOffset(150, 64),
	Position = UDim2.new(1, -150, 0, 70),
	AnchorPoint = Vector2.new(1, 0),
	Palette = "Green",
	Text = "UPGRADE",
	TextSize = UDim2.new(1, -14, 0, 30),
	TextPosition = UDim2.new(0.5, 0, 0, 20),
	TextStroke = 3,
}, function()
	Remotes.Action:FireServer("UpgradeTreadmill")
end)
local costLabel = Kit.text({ Parent = upFace, Text = "", Size = UDim2.new(1, -14, 0, 24), Position = UDim2.new(0.5, 0, 1, -4), AnchorPoint = Vector2.new(0.5, 1), Stroke = 2.5, ZIndex = 3 })
Kit.button({
	Parent = panel,
	Size = UDim2.fromOffset(120, 64),
	Position = UDim2.new(1, -16, 0, 70),
	AnchorPoint = Vector2.new(1, 0),
	Palette = "Red",
	Text = "LEAVE (X)",
	TextStroke = 3,
}, function()
	Remotes.Action:FireServer("TrainStop")
end)

local function refreshUI()
	if not active then
		return
	end
	local tier, tierIndex = Config.TreadmillTier(level)
	title.Text = ("%s Treadmill  ·  Lv %d / %d"):format(tier.Name, level, Config.TreadmillMaxLevel)
	Kit.paint(head, ({ "Grey", "Green", "Blue", "Purple", "Gold", "Red", "Cyan", "Candy", "Rainbow" })[tierIndex] or "Lime")
	rateLabel.Text = ("+%s Speed/s"):format(Format.short(rate))
	-- temps restant avant la vitesse conseillée de la prochaine boutique (on peut rester AFK)
	local speed = player:GetAttribute("Speed") or 0
	local target
	for _, zone in Config.Zones do
		if speed < zone.Speed then
			target = zone
			break
		end
	end
	if target and rate > 0 then
		nextLabel.Text = ("%s in %s (AFK is fine!)"):format(target.Name, Format.time((target.Speed - speed) / rate))
	else
		nextLabel.Text = "Fast enough for every shop!"
	end
	if cost then
		upLabel.Text = "UPGRADE"
		costLabel.Text = Format.cash(cost)
		Kit.paint(upFace, (player:GetAttribute("Cash") or 0) >= cost and "Green" or "Grey")
	else
		upLabel.Text = "MAX"
		costLabel.Text = ""
		Kit.paint(upFace, "Grey")
	end
end
player:GetAttributeChangedSignal("Cash"):Connect(refreshUI)
player:GetAttributeChangedSignal("Speed"):Connect(refreshUI)

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
	local running = active ~= nil
	if running then
		if not runTrack then
			runTrack = getRunTrack()
		end
		if runTrack and not runTrack.IsPlaying then
			runTrack:Play(0.15)
		end
		if runTrack then
			-- plus le tapis est amélioré, plus on court vite
			runTrack:AdjustSpeed(1.2 + level * 0.06)
		end
	elseif runTrack and runTrack.IsPlaying then
		runTrack:Stop(0.2)
	end
	refreshUI()
end


--------------------------------------------------------------------
-- Monter / descendre du tapis
--------------------------------------------------------------------
local function consoleFor(index: number): BasePart?
	for _, c in CollectionService:GetTagged("Treadmill") do
		if c:GetAttribute("BaseIndex") == index then
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
	gui.Enabled = true
	updateRunning()
end

local function leave()
	active = nil
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
	if active and LEAVE_KEYS[input.KeyCode] and not processed then
		Remotes.Action:FireServer("TrainStop")
	end
end)

--------------------------------------------------------------------
-- Anti-AFK : Roblox déconnecte au bout de 20 minutes sans rien toucher.
-- Si on est sur le tapis, on demande au serveur de nous faire revenir dans
-- ce même serveur juste avant (on se retrouve remis sur son tapis).
--------------------------------------------------------------------
local lastInput = os.clock()
UserInputService.InputBegan:Connect(function()
	lastInput = os.clock()
end)
local AFK_LIMIT = 17 * 60
player.Idled:Connect(function(idleTime: number)
	if active and idleTime >= AFK_LIMIT then
		Remotes.Action:FireServer("AfkRejoin")
	end
end)
task.spawn(function()
	while true do
		task.wait(30)
		if active and os.clock() - lastInput >= AFK_LIMIT then
			Remotes.Action:FireServer("AfkRejoin")
		end
	end
end)

--------------------------------------------------------------------
-- "+X" qui s'envolent au-dessus du joueur quand la Speed monte
--------------------------------------------------------------------
local TweenService = game:GetService("TweenService")
local lastSpeed = player:GetAttribute("Speed") or 0
local pending = 0
player:GetAttributeChangedSignal("Speed"):Connect(function()
	local now = player:GetAttribute("Speed") or 0
	if active and now > lastSpeed then
		pending += now - lastSpeed
	end
	lastSpeed = now
end)
task.spawn(function()
	local rng = Random.new()
	while true do
		task.wait(0.45)
		local headPart = player.Character and player.Character:FindFirstChild("Head")
		if pending > 0 and headPart and active then
			local amount = pending
			pending = 0
			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.fromOffset(160, 44)
			bb.StudsOffset = Vector3.new(rng:NextNumber(-2.5, 2.5), 2.5, 0)
			bb.AlwaysOnTop = true
			bb.Adornee = headPart
			bb.Parent = playerGui
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 1)
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.TextColor3 = Color3.fromRGB(255, 80, 140)
			label.Text = "+" .. Format.short(amount)
			label.Parent = bb
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 3
			stroke.Color = Color3.fromRGB(255, 255, 255)
			stroke.Parent = label
			TweenService:Create(bb, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = bb.StudsOffset + Vector3.new(0, 4, 0) }):Play()
			TweenService:Create(label, TweenInfo.new(1.1), { TextTransparency = 1 }):Play()
			TweenService:Create(stroke, TweenInfo.new(1.1), { Transparency = 1 }):Play()
			task.delay(1.2, function()
				bb:Destroy()
			end)
		end
	end
end)

Remotes.State.OnClientEvent:Connect(function(state)
	rate = state.TreadmillRate or rate
	level = state.Treadmill or level
	cost = state.TreadmillCost
	updateRunning()
end)
