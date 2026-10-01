-- Petite boîte à outils d'interface : couleurs, création d'objets, boutons "sticker"

local TweenService = game:GetService("TweenService")

local Kit = {}

Kit.Colors = {
	Ink = Color3.fromRGB(20, 20, 30),
	Ink2 = Color3.fromRGB(38, 38, 54),
	Paper = Color3.fromRGB(250, 247, 240),
	Pink = Color3.fromRGB(255, 70, 110),
	Yellow = Color3.fromRGB(255, 210, 60),
	Green = Color3.fromRGB(80, 230, 140),
	Blue = Color3.fromRGB(70, 160, 255),
	Purple = Color3.fromRGB(160, 110, 255),
	Grey = Color3.fromRGB(140, 140, 155),
	White = Color3.new(1, 1, 1),
}

Kit.Title = Enum.Font.FredokaOne
Kit.Body = Enum.Font.GothamBold

function Kit.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	if props then
		local parent = props.Parent
		for k, v in props do
			if k ~= "Parent" then
				(inst :: any)[k] = v
			end
		end
		if children then
			for _, child in children do
				child.Parent = inst
			end
		end
		if parent then
			inst.Parent = parent
		end
	end
	return inst
end

function Kit.corner(radius: number?): UICorner
	return Kit.new("UICorner", { CornerRadius = UDim.new(0, radius or 6) })
end

function Kit.stroke(thickness: number?, color: Color3?): UIStroke
	return Kit.new("UIStroke", {
		Thickness = thickness or 3,
		Color = color or Kit.Colors.Ink,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Kit.textStroke(thickness: number?): UIStroke
	return Kit.new("UIStroke", { Thickness = thickness or 2, Color = Kit.Colors.Ink })
end

function Kit.padding(px: number): UIPadding
	local u = UDim.new(0, px)
	return Kit.new("UIPadding", { PaddingTop = u, PaddingBottom = u, PaddingLeft = u, PaddingRight = u })
end

function Kit.label(props: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = Kit.Title,
		TextColor3 = Kit.Colors.White,
		TextScaled = true,
	}
	for k, v in props do
		defaults[k] = v
	end
	return Kit.new("TextLabel", defaults)
end

-- Bloc avec une ombre dure décalée : la signature visuelle du jeu
function Kit.sticker(props: { [string]: any }, shadowOffset: number?): (Frame, Frame)
	local offset = shadowOffset or 5
	local holder = Kit.new("Frame", {
		Name = props.Name or "Sticker",
		BackgroundTransparency = 1,
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	})
	Kit.new("Frame", {
		Name = "Shadow",
		BackgroundColor3 = Kit.Colors.Ink,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(offset, offset),
		ZIndex = (props.ZIndex or 1),
		Parent = holder,
	}, { Kit.corner(props.Radius) })
	local face = Kit.new("Frame", {
		Name = "Face",
		BackgroundColor3 = props.Color or Kit.Colors.Paper,
		Size = UDim2.fromScale(1, 1),
		ZIndex = (props.ZIndex or 1) + 1,
		Parent = holder,
	}, { Kit.corner(props.Radius), Kit.stroke(3) })
	return holder, face
end

-- Bouton sticker qui s'enfonce quand on clique
function Kit.button(props: { [string]: any }, onClick: () -> ()): (Frame, TextButton)
	local holder, face = Kit.sticker(props, props.Shadow or 4)
	face.Name = "Face"
	local btn = Kit.new("TextButton", {
		Name = "Hit",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = props.Text or "",
		Font = props.Font or Kit.Title,
		TextScaled = true,
		TextColor3 = props.TextColor or Kit.Colors.Ink,
		ZIndex = face.ZIndex + 1,
		AutoButtonColor = false,
		Parent = face,
	}, { Kit.padding(props.TextPadding or 6) })
	if props.TextStroke then
		Kit.textStroke(2).Parent = btn
	end

	local offset = props.Shadow or 4
	local down = TweenInfo.new(0.06)
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(face, down, { Position = UDim2.fromOffset(offset, offset) }):Play()
	end)
	local function release()
		TweenService:Create(face, down, { Position = UDim2.fromOffset(0, 0) }):Play()
	end
	btn.MouseButton1Up:Connect(release)
	btn.MouseLeave:Connect(release)
	btn.Activated:Connect(onClick)
	return holder, btn
end

function Kit.pop(gui: GuiObject, scale: UIScale?)
	local s = scale or gui:FindFirstChildOfClass("UIScale") or Kit.new("UIScale", { Parent = gui })
	s.Scale = 0.6
	TweenService:Create(s, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

function Kit.formatNumber(n: number): string
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end
	return formatted
end

function Kit.formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then
		return ("%dh %02dm"):format(h, m)
	end
	return ("%dm %02ds"):format(m, s)
end

return Kit
