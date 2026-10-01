-- Gameplay côté client : double saut, trampolines, tags dans le chat, ambiance par monde

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer

--------------------------------------------------------------------
-- Double saut (Game Pass)
--------------------------------------------------------------------
local humanoid: Humanoid? = nil
local canDouble = false
local usedDouble = false

local function onCharacter(character: Model)
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	canDouble, usedDouble = false, false
	;(humanoid :: Humanoid).StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			canDouble, usedDouble = false, false
		elseif new == Enum.HumanoidStateType.Freefall then
			task.delay(0.12, function()
				canDouble = true
			end)
		end
	end)
end

if player.Character then
	task.spawn(onCharacter, player.Character)
end
player.CharacterAdded:Connect(onCharacter)

UserInputService.JumpRequest:Connect(function()
	local h = humanoid
	if not h or not player:GetAttribute("DoubleJump") then
		return
	end
	if canDouble and not usedDouble and h:GetState() == Enum.HumanoidStateType.Freefall then
		usedDouble = true
		h:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

--------------------------------------------------------------------
-- Trampolines
--------------------------------------------------------------------
local padCooldown = 0

local function hookPad(pad: Instance)
	if not pad:IsA("BasePart") then
		return
	end
	pad.Touched:Connect(function(hit)
		local character = player.Character
		if not character or not hit:IsDescendantOf(character) then
			return
		end
		if os.clock() < padCooldown then
			return
		end
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			return
		end
		padCooldown = os.clock() + 0.4
		local power = pad:GetAttribute("Power") or 80
		local v = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(v.X, power, v.Z)
		-- petit écrasement visuel du trampoline
		local original = pad.Size
		local squash = TweenService:Create(pad, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
			Size = original * Vector3.new(1.1, 0.5, 1.1),
		})
		squash:Play()
	end)
end

for _, pad in CollectionService:GetTagged("JumpPad") do
	hookPad(pad)
end
CollectionService:GetInstanceAddedSignal("JumpPad"):Connect(hookPad)

--------------------------------------------------------------------
-- Tags dans le chat : [VIP] et niveau
--------------------------------------------------------------------
TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local props = Instance.new("TextChatMessageProperties")
	local source = message.TextSource
	if not source then
		return props
	end
	local speaker = Players:GetPlayerByUserId(source.UserId)
	if not speaker then
		return props
	end
	local prefix = ""
	local level = speaker:GetAttribute("Level")
	if level then
		prefix ..= ("<font color='#50E68C'>[Lv %d]</font> "):format(level)
	end
	if speaker:GetAttribute("VIP") then
		prefix ..= "<font color='#FFC828'>[VIP]</font> "
	end
	props.PrefixText = prefix .. message.PrefixText
	return props
end

--------------------------------------------------------------------
-- Ambiance : la brume prend la couleur du monde où l'on est
--------------------------------------------------------------------
local currentWorld = 0
Remotes.State.OnClientEvent:Connect(function(state)
	local _, index = Config.WorldForStage(math.max(state.Stage, 1))
	if index == currentWorld then
		return
	end
	currentWorld = index
	local world = Config.Worlds[index]
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		local tint = world.Main:Lerp(Color3.new(1, 1, 1), 0.55)
		TweenService:Create(atmosphere, TweenInfo.new(2), { Color = tint, Decay = world.Alt:Lerp(Color3.new(0, 0, 0), 0.4) }):Play()
	end
	-- les derniers mondes passent en soirée puis en nuit
	local clock = index <= 3 and 14.5 or (index == 4 and 18 or 0)
	TweenService:Create(Lighting, TweenInfo.new(3), { ClockTime = clock }):Play()
end)
