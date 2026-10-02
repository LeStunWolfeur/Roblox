-- Étiquette flottante au-dessus d'une carte/créature : rareté, nom, revenu.
-- Style des jeux du genre : gros texte blanc, contour épais, rareté en couleur.

local Cards = require(script.Parent.Cards)
local Format = require(script.Parent.Format)

local Nameplate = {}

local INK = Color3.fromRGB(20, 20, 28)

local function line(parent: Instance, text: string, color: Color3, height: number, order: number, stroke: number?)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, 0, 0, height)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = color
	l.LayoutOrder = order
	l.Parent = parent
	local s = Instance.new("UIStroke")
	s.Thickness = stroke or 3
	s.Color = INK
	s.Parent = l
	return l
end

-- extra : texte en plus (ex. prix, note) affiché en dernier
function Nameplate.attach(adornee: BasePart, id: string, finish: string?, grade: number?, offset: Vector3?, extra: string?): BillboardGui
	local card = Cards.ById[id]
	local rarity = Cards.Rarities[card.Rarity]
	local f = Cards.Finishes[finish or "Normal"] or Cards.Finishes.Normal
	local gui = Instance.new("BillboardGui")
	gui.Name = "Nameplate"
	gui.Size = UDim2.fromOffset(240, 110)
	gui.StudsOffsetWorldSpace = offset or Vector3.new(0, 9, 0)
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	gui.Adornee = adornee
	gui.Parent = adornee
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = gui

	if f.Name ~= "" then
		local fl = line(gui, f.Name:upper(), f.Color or Color3.new(1, 1, 1), 20, 1)
		if finish == "Rainbow" then
			local g = Instance.new("UIGradient")
			local keys = {}
			for i = 0, 6 do
				table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.8, 1)))
			end
			g.Color = ColorSequence.new(keys)
			g.Parent = fl
			fl.TextColor3 = Color3.new(1, 1, 1)
		end
	end
	line(gui, card.Name, Color3.new(1, 1, 1), 30, 2, 3.5)
	local rl = line(gui, rarity.Name:upper() .. (grade and ("  ·  G" .. grade) or ""), rarity.Color, 22, 3)
	if card.Rarity == "Secret" then
		rl.TextColor3 = Color3.new(1, 1, 1)
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(Color3.fromRGB(40, 40, 40), Color3.fromRGB(255, 255, 255))
		g.Parent = rl
	end
	line(gui, "$" .. Format.short(Cards.IncomeOf(id, finish, grade or 6)) .. "/s", Color3.fromRGB(110, 255, 120), 24, 4)
	if extra then
		line(gui, extra, Color3.fromRGB(255, 220, 80), 20, 5)
	end
	return gui
end

return Nameplate
