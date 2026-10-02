--[[
	Sensation de vitesse (côté joueur) :
	- le champ de vision s'élargit quand on court vite ;
	- des traits de vitesse défilent sur les bords de l'écran ;
	- une traînée colorée suit le personnage, sa couleur change avec la Speed ;
	- un gros message quand on atteint la vitesse conseillée d'une nouvelle boutique ;
	- sur le tapis, les flèches de la bande défilent (plus vite à chaque niveau) ;
	- les cristaux et planètes des tapis Divine et Ancient tournent.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local BASE_FOV = 70
local MAX_EXTRA_FOV = 22

--------------------------------------------------------------------
-- Traits de vitesse
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SpeedFX"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = -1
gui.Parent = playerGui

local LINES = 22
local lines = {}
local rng = Random.new()
local function resetLine(l)
	l.angle = rng:NextNumber(0, math.pi * 2)
	l.dist = rng:NextNumber(0.55, 0.75)
	l.speed = rng:NextNumber(0.9, 1.6)
	l.len = rng:NextNumber(0.08, 0.18)
end
for i = 1, LINES do
	local f = Instance.new("Frame")
	f.Name = "Line"
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	f.BorderSizePixel = 0
	f.BackgroundTransparency = 1
	f.Parent = gui
	local l = { frame = f }
	resetLine(l)
	l.dist = rng:NextNumber(0.5, 1.1)
	lines[i] = l
end

--------------------------------------------------------------------
-- Traînée derrière le personnage
--------------------------------------------------------------------
local trail: Trail? = nil
local function makeTrail(character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not root then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailTop"
	a0.Position = Vector3.new(0, 1.2, 0.4)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailBottom"
	a1.Position = Vector3.new(0, -1.6, 0.4)
	a1.Parent = root
	local t = Instance.new("Trail")
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Lifetime = 0.35
	t.LightEmission = 0.6
	t.Transparency = NumberSequence.new(0.35, 1)
	t.WidthScale = NumberSequence.new(1, 0.2)
	t.Enabled = false
	t.Parent = root
	trail = t
end
if player.Character then
	task.spawn(makeTrail, player.Character)
end
player.CharacterAdded:Connect(makeTrail)

-- couleur de la traînée selon la boutique qu'on peut viser
local TRAIL_COLORS = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(120, 255, 120),
	Color3.fromRGB(80, 180, 255),
	Color3.fromRGB(180, 90, 255),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(80, 240, 255),
	Color3.fromRGB(220, 110, 255),
	Color3.fromRGB(255, 230, 120),
	Color3.fromRGB(255, 120, 220),
}

local function zoneReached(speed: number): number
	local reached = 1
	for i, zone in Config.Zones do
		if speed >= zone.Speed then
			reached = i
		end
	end
	return reached
end

--------------------------------------------------------------------
-- Message "nouvelle boutique débloquée"
--------------------------------------------------------------------
local banner = Instance.new("Frame")
banner.Name = "SpeedUnlock"
banner.BackgroundTransparency = 1
banner.Size = UDim2.fromOffset(760, 120)
banner.Position = UDim2.fromScale(0.5, 0.36)
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Visible = false
banner.Parent = gui
local bannerScale = Instance.new("UIScale")
bannerScale.Parent = banner
local function bannerText(y: number, h: number, color: Color3, stroke: number): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, 0, 0, h)
	l.Position = UDim2.fromOffset(0, y)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = color
	l.Text = ""
	l.Parent = banner
	local s = Instance.new("UIStroke")
	s.Thickness = stroke
	s.Color = Color3.fromRGB(20, 20, 28)
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = l
	return l
end
local bannerTitle = bannerText(0, 66, Color3.fromRGB(255, 220, 60), 5)
local bannerSub = bannerText(70, 36, Color3.new(1, 1, 1), 3)
local bannerToken = 0
local lastZone = zoneReached(player:GetAttribute("Speed") or 0)
player:GetAttributeChangedSignal("Speed"):Connect(function()
	local z = zoneReached(player:GetAttribute("Speed") or 0)
	if z > lastZone then
		lastZone = z
		bannerToken += 1
		local token = bannerToken
		bannerTitle.Text = "SPEED " .. Format.short(Config.Zones[z].Speed) .. " REACHED!"
		bannerSub.Text = ("You can now outrun the guard of %s"):format(Config.Zones[z].Name)
		bannerTitle.TextColor3 = TRAIL_COLORS[z] or Color3.new(1, 1, 1)
		banner.Visible = true
		bannerScale.Scale = 0.4
		TweenService:Create(bannerScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		task.delay(3, function()
			if token == bannerToken then
				banner.Visible = false
			end
		end)
	elseif z < lastZone then
		lastZone = z
	end
end)

--------------------------------------------------------------------
-- Bande du tapis et objets en orbite
--------------------------------------------------------------------
local function myTreadmillModel(): Model?
	local index = player:GetAttribute("GalleryIndex")
	if not index then
		return nil
	end
	for _, console in CollectionService:GetTagged("Treadmill") do
		if console:GetAttribute("BaseIndex") == index and console.Parent then
			return console.Parent:FindFirstChild("TreadmillModel") :: Model?
		end
	end
	return nil
end

local beltOffset = 0
local function animateBelt(dt: number, level: number)
	local model = myTreadmillModel()
	local frame = model and model:GetAttribute("Frame") :: CFrame?
	if not model or not frame then
		return
	end
	beltOffset = (beltOffset + dt * (5 + level * 2.2)) % 12
	local top = 1.65 + 0.03
	for _, bar in model:GetChildren() do
		if bar.Name == "Chevron" and bar:IsA("BasePart") then
			local z0 = bar:GetAttribute("Z0") or 0
			local side = bar:GetAttribute("Side") or 1
			local z = -6 + ((z0 + 6 + beltOffset) % 12)
			bar.CFrame = frame * CFrame.new(side * 0.58, top, z + 0.52) * CFrame.Angles(0, math.rad(side * -42), 0)
		end
	end
end

local function animateOrbits(now: number)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	for _, p in CollectionService:GetTagged("Orbit") do
		if p:IsA("BasePart") then
			local center = p:GetAttribute("Center") :: Vector3?
			if center and (not root or (root.Position - center).Magnitude < 160) then
				local a = (p:GetAttribute("Phase") or 0) + now * (p:GetAttribute("Speed") or 0.3)
				local r = p:GetAttribute("Radius") or 5
				local h = (p:GetAttribute("Height") or 5) + math.sin(now * 1.5 + a) * 0.4
				p.CFrame = CFrame.new(center + Vector3.new(math.cos(a) * r, h, math.sin(a) * r)) * CFrame.Angles(0, -a * 2, math.rad(15))
			end
		end
	end
end

--------------------------------------------------------------------
-- Boucle
--------------------------------------------------------------------
local level = 1
local intensity = 0
local clock = 0
RunService.RenderStepped:Connect(function(dt)
	clock += dt
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local training = player:GetAttribute("Training") ~= nil
	local walk = humanoid and humanoid.WalkSpeed or 16
	local moveDir = humanoid and humanoid.MoveDirection
	local moving = moveDir ~= nil and moveDir.Magnitude > 0.1
	-- 0 à 1 selon la vitesse de marche (16 au départ, ~90 à la fin)
	local speedFactor = math.clamp((walk - 16) / 74, 0, 1)
	local target = 0
	if moving then
		target = speedFactor
	elseif training then
		target = math.clamp(level / 9, 0.15, 1) * 0.8
	end
	intensity += (target - intensity) * math.min(dt * 4, 1)

	camera.FieldOfView = BASE_FOV + MAX_EXTRA_FOV * intensity

	-- traits de vitesse (seulement quand ça va vraiment vite)
	local lineAlpha = math.clamp((intensity - 0.15) / 0.6, 0, 1)
	local size = camera.ViewportSize
	for _, l in lines do
		local f = l.frame
		if lineAlpha <= 0 then
			f.BackgroundTransparency = 1
		else
			l.dist += dt * l.speed * (0.6 + intensity)
			if l.dist > 1.15 then
				resetLine(l)
			end
			local x = 0.5 + math.cos(l.angle) * l.dist * 0.75
			local y = 0.5 + math.sin(l.angle) * l.dist * 0.75
			f.Position = UDim2.fromScale(x, y)
			f.Size = UDim2.fromOffset(math.max(size.X, size.Y) * l.len * (0.5 + intensity), 2 + intensity * 2)
			f.Rotation = math.deg(l.angle)
			f.BackgroundTransparency = 1 - lineAlpha * 0.45 * math.clamp((l.dist - 0.5) * 3, 0, 1)
		end
	end

	-- traînée
	if trail then
		local speed = player:GetAttribute("Speed") or 0
		local z = zoneReached(speed)
		trail.Color = ColorSequence.new(TRAIL_COLORS[z] or Color3.new(1, 1, 1))
		-- une traînée achetée (visible par tous) remplace celle-ci
		trail.Enabled = moving and walk > 26 and (player:GetAttribute("Trail") or 0) == 0
	end

	if training then
		animateBelt(dt, level)
	end
	animateOrbits(clock)
end)

local Remotes = require(ReplicatedStorage.Shared.Remotes)
Remotes.State.OnClientEvent:Connect(function(state)
	level = state.Treadmill or level
end)
