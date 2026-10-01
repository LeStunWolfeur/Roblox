-- Applique les bonus sur le personnage : vitesse, saut, trail, étiquette au-dessus de la tête

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)

local CharacterService = {}

-- Trails liés à un Game Pass (en plus des trails achetables en coins)
local PASS_TRAILS = {
	Rainbow = { Pass = "RainbowTrail", Name = "Rainbow" },
	Gold = { Pass = "VIP", Name = "VIP Gold" },
}
CharacterService.PassTrails = PASS_TRAILS

local function rainbowSequence(): ColorSequence
	local keys = {}
	for i = 0, 6 do
		table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.85, 1)))
	end
	return ColorSequence.new(keys)
end

local function trailColor(id: string): ColorSequence?
	if id == "Rainbow" then
		return rainbowSequence()
	elseif id == "Gold" then
		return ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 160, 0))
	end
	local trail = Config.GetTrail(id)
	if trail then
		return ColorSequence.new(trail.Colors[1], trail.Colors[2])
	end
	return nil
end

function CharacterService.CanUseTrail(player: Player, id: string): boolean
	local pass = PASS_TRAILS[id]
	if pass then
		return MonetizationService.Owns(player, pass.Pass)
	end
	local data = DataService.Get(player)
	return data ~= nil and table.find(data.Trails, id) ~= nil
end

local function applyTrail(player: Player, character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local old = root:FindFirstChild("PlayerTrail")
	if old then
		old:Destroy()
	end
	for _, name in { "TrailTop", "TrailBottom" } do
		local a = root:FindFirstChild(name)
		if a then
			a:Destroy()
		end
	end

	local data = DataService.Get(player)
	local id = data and data.EquippedTrail
	if not id or id == "None" or not CharacterService.CanUseTrail(player, id) then
		return
	end
	local colors = trailColor(id)
	if not colors then
		return
	end

	local top = Instance.new("Attachment")
	top.Name = "TrailTop"
	top.Position = Vector3.new(0, 0.8, 0)
	top.Parent = root
	local bottom = Instance.new("Attachment")
	bottom.Name = "TrailBottom"
	bottom.Position = Vector3.new(0, -0.8, 0)
	bottom.Parent = root

	local trail = Instance.new("Trail")
	trail.Name = "PlayerTrail"
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Color = colors
	trail.Lifetime = 0.45
	trail.LightEmission = 0.6
	trail.Transparency = NumberSequence.new(0.1, 1)
	trail.WidthScale = NumberSequence.new(1, 0.2)
	trail.FaceCamera = true
	trail.Parent = root
end

local function applyOverhead(player: Player, character: Model)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild("Overhead")
	if old then
		old:Destroy()
	end
	local data = DataService.Get(player)
	if not data then
		return
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "Overhead"
	gui.Size = UDim2.fromOffset(200, 50)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = 80
	gui.AlwaysOnTop = false
	gui.Parent = head

	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gui

	local function line(text: string, color: Color3, order: number, height: number)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, height)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Text = text
		label.TextColor3 = color
		label.LayoutOrder = order
		label.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(20, 20, 30)
		stroke.Parent = label
		return label
	end

	if MonetizationService.Owns(player, "VIP") then
		line("VIP", Config.GamePasses.VIP.Color, 1, 18)
	end
	local tag = ("Lv %d"):format(data.Level)
	if data.Rebirths > 0 then
		tag ..= ("  ·  R%d"):format(data.Rebirths)
	end
	line(tag, Color3.fromRGB(255, 255, 255), 2, 20)
end

function CharacterService.Apply(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local speed = MonetizationService.Owns(player, "Speed") and Config.SpeedPassWalkSpeed or Config.BaseWalkSpeed
		if MonetizationService.Owns(player, "VIP") then
			speed *= Config.VipSpeedMultiplier
		end
		humanoid.WalkSpeed = speed
		humanoid.UseJumpPower = false
		humanoid.JumpHeight = MonetizationService.Owns(player, "Gravity") and Config.GravityPassJumpHeight or Config.BaseJumpHeight
	end

	player:SetAttribute("DoubleJump", MonetizationService.Owns(player, "DoubleJump"))
	player:SetAttribute("VIP", MonetizationService.Owns(player, "VIP"))

	applyTrail(player, character)
	applyOverhead(player, character)
end

-- Rafraîchit juste l'étiquette (après un level up ou un rebirth)
function CharacterService.RefreshOverhead(player: Player)
	if player.Character then
		applyOverhead(player, player.Character)
	end
end

function CharacterService.RefreshTrail(player: Player)
	if player.Character then
		applyTrail(player, player.Character)
	end
end

return CharacterService
