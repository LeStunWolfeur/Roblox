-- Icônes dessinées avec des formes (pas d'images externes à charger)

local Icons = {}

local INK = Color3.fromRGB(28, 28, 38)
local WHITE = Color3.new(1, 1, 1)

local function box(parent: Instance, size: UDim2, pos: UDim2, color: Color3, radius: number?, rotation: number?, z: number)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = color
	f.Rotation = rotation or 0
	f.ZIndex = z
	f.BorderSizePixel = 0
	f.Parent = parent
	if radius then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(radius, 0)
		c.Parent = f
	end
	local s = Instance.new("UIStroke")
	s.Thickness = 2.5
	s.Color = INK
	s.Parent = f
	return f
end

local function s(x, y)
	return UDim2.fromScale(x, y)
end

-- kind : cart, book, star, flask, gift, house, ice, shoe, cash, crown, people, gear
function Icons.draw(kind: string, parent: Instance, color: Color3, z: number)
	if kind == "cart" then
		box(parent, s(0.7, 0.4), s(0.52, 0.42), color, 0.15, nil, z)
		box(parent, s(0.18, 0.18), s(0.32, 0.8), INK, 0.5, nil, z)
		box(parent, s(0.18, 0.18), s(0.72, 0.8), INK, 0.5, nil, z)
		box(parent, s(0.25, 0.08), s(0.12, 0.18), INK, nil, nil, z)
	elseif kind == "book" then
		box(parent, s(0.66, 0.8), s(0.5, 0.5), color, 0.1, -8, z)
		box(parent, s(0.12, 0.8), s(0.22, 0.5), INK, nil, -8, z + 1)
		box(parent, s(0.36, 0.08), s(0.56, 0.36), WHITE, nil, -8, z + 1)
	elseif kind == "star" then
		box(parent, s(0.6, 0.6), s(0.5, 0.5), color, 0.15, 0, z)
		box(parent, s(0.6, 0.6), s(0.5, 0.5), color, 0.15, 45, z)
		box(parent, s(0.26, 0.26), s(0.5, 0.5), WHITE, 0.5, nil, z + 1)
	elseif kind == "flask" then
		box(parent, s(0.66, 0.5), s(0.5, 0.66), color, 0.5, nil, z)
		box(parent, s(0.24, 0.36), s(0.5, 0.28), WHITE, 0.2, nil, z)
		box(parent, s(0.14, 0.14), s(0.4, 0.66), WHITE, 0.5, nil, z + 1)
	elseif kind == "gift" then
		box(parent, s(0.72, 0.5), s(0.5, 0.64), color, 0.1, nil, z)
		box(parent, s(0.82, 0.2), s(0.5, 0.36), color, 0.1, nil, z)
		box(parent, s(0.14, 0.7), s(0.5, 0.56), WHITE, nil, nil, z + 1)
		box(parent, s(0.24, 0.2), s(0.38, 0.18), WHITE, 0.5, -30, z)
		box(parent, s(0.24, 0.2), s(0.62, 0.18), WHITE, 0.5, 30, z)
	elseif kind == "house" then
		box(parent, s(0.6, 0.44), s(0.5, 0.68), color, 0.08, nil, z)
		box(parent, s(0.52, 0.52), s(0.5, 0.42), color, 0.08, 45, z)
		box(parent, s(0.2, 0.28), s(0.5, 0.76), INK, nil, nil, z + 1)
	elseif kind == "ice" then
		box(parent, s(0.7, 0.7), s(0.5, 0.5), color, 0.18, 10, z)
		box(parent, s(0.18, 0.4), s(0.38, 0.42), WHITE, 0.3, 10, z + 1)
	elseif kind == "shoe" then
		box(parent, s(0.8, 0.32), s(0.5, 0.66), color, 0.4, nil, z)
		box(parent, s(0.36, 0.42), s(0.34, 0.42), color, 0.3, nil, z)
		box(parent, s(0.8, 0.1), s(0.5, 0.84), WHITE, 0.4, nil, z + 1)
	elseif kind == "cash" then
		box(parent, s(0.84, 0.5), s(0.5, 0.5), color, 0.1, -10, z)
		box(parent, s(0.26, 0.26), s(0.5, 0.5), WHITE, 0.5, nil, z + 1)
	elseif kind == "people" then
		box(parent, s(0.3, 0.3), s(0.34, 0.32), color, 0.5, nil, z)
		box(parent, s(0.42, 0.34), s(0.34, 0.7), color, 0.4, nil, z)
		box(parent, s(0.3, 0.3), s(0.68, 0.32), WHITE, 0.5, nil, z)
		box(parent, s(0.42, 0.34), s(0.68, 0.7), WHITE, 0.4, nil, z)
	elseif kind == "gear" then
		for i = 0, 3 do
			box(parent, s(0.2, 0.84), s(0.5, 0.5), color, 0.2, i * 45, z)
		end
		box(parent, s(0.5, 0.5), s(0.5, 0.5), color, 0.5, nil, z + 1)
		box(parent, s(0.2, 0.2), s(0.5, 0.5), INK, 0.5, nil, z + 2)
	elseif kind == "ticket" then
		box(parent, s(0.84, 0.52), s(0.5, 0.5), color, 0.15, -14, z)
		box(parent, s(0.16, 0.16), s(0.13, 0.55), INK, 0.5, nil, z + 1)
		box(parent, s(0.16, 0.16), s(0.87, 0.45), INK, 0.5, nil, z + 1)
		box(parent, s(0.4, 0.1), s(0.5, 0.5), WHITE, nil, -14, z + 1)
	elseif kind == "clock" then
		box(parent, s(0.76, 0.76), s(0.5, 0.5), color, 0.5, nil, z)
		box(parent, s(0.08, 0.3), s(0.5, 0.38), INK, nil, nil, z + 1)
		box(parent, s(0.24, 0.08), s(0.6, 0.5), INK, nil, nil, z + 1)
	end
end

return Icons
