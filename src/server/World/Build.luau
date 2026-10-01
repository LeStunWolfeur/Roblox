-- Petites fonctions pour construire la map et animer les pièces mobiles

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Build = {}

function Build.part(props: { [string]: any }, parent: Instance?): BasePart
	local className = props.ClassName or "Part"
	local p = Instance.new(className) :: BasePart
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		if key ~= "ClassName" then
			(p :: any)[key] = value
		end
	end
	p.Parent = parent
	return p
end

-- Pièce mortelle : rouge néon, tue au contact
function Build.kill(props: { [string]: any }, parent: Instance?): BasePart
	props.Color = props.Color or Config.KillColor
	props.Material = props.Material or Enum.Material.Neon
	local p = Build.part(props, parent)
	CollectionService:AddTag(p, "Kill")
	return p
end

--------------------------------------------------------------------
-- Animations (tournants, balayeurs)
--------------------------------------------------------------------
type Mover = {
	part: BasePart,
	base: CFrame,
	kind: string,
	speed: number,
	amplitude: Vector3?,
	phase: number,
}

local movers: { Mover } = {}

-- Fait tourner une pièce autour de son axe Y
function Build.spin(part: BasePart, speed: number, phase: number?)
	table.insert(movers, { part = part, base = part.CFrame, kind = "spin", speed = speed, phase = phase or 0 })
end

-- Fait aller-retour une pièce (sinus) selon un vecteur
function Build.slide(part: BasePart, amplitude: Vector3, speed: number, phase: number?)
	table.insert(movers, {
		part = part,
		base = part.CFrame,
		kind = "slide",
		speed = speed,
		amplitude = amplitude,
		phase = phase or 0,
	})
end

-- Plateforme qui disparaît après qu'on a marché dessus
local function setupVanish(part: BasePart)
	local busy = false
	local baseTransparency = part.Transparency
	part.Touched:Connect(function(hit)
		if busy then
			return
		end
		local model = hit:FindFirstAncestorOfClass("Model")
		if not model or not model:FindFirstChildOfClass("Humanoid") then
			return
		end
		busy = true
		local blink = TweenService:Create(part, TweenInfo.new(0.12, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 3, true), { Transparency = 0.6 })
		blink:Play()
		task.wait(0.75)
		part.Transparency = 0.85
		part.CanCollide = false
		part.CanTouch = false
		task.wait(2.5)
		part.CanCollide = true
		part.CanTouch = true
		part.Transparency = baseTransparency
		busy = false
	end)
end

function Build.vanish(part: BasePart)
	CollectionService:AddTag(part, "Vanish")
	setupVanish(part)
end

function Build.jumpPad(part: BasePart, power: number)
	part:SetAttribute("Power", power)
	CollectionService:AddTag(part, "JumpPad")
end

local function killCharacter(hit: BasePart)
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end
end

function Build.Start()
	local function hookKill(part: Instance)
		if part:IsA("BasePart") then
			part.Touched:Connect(killCharacter)
		end
	end
	for _, part in CollectionService:GetTagged("Kill") do
		hookKill(part)
	end
	CollectionService:GetInstanceAddedSignal("Kill"):Connect(hookKill)

	RunService.Heartbeat:Connect(function()
		local t = workspace:GetServerTimeNow()
		for _, m in movers do
			if m.kind == "spin" then
				m.part.CFrame = m.base * CFrame.Angles(0, (t * m.speed + m.phase) % (math.pi * 2), 0)
			elseif m.kind == "slide" then
				local offset = (m.amplitude :: Vector3) * math.sin(t * m.speed + m.phase)
				m.part.CFrame = m.base + offset
			end
		end
	end)
end

return Build
