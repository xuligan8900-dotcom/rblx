--!nocheck
local World = {}
World.__index = World
local C = {
	grass = Color3.fromRGB(104, 153, 103),
	leaf = Color3.fromRGB(77, 125, 88),
	wood = Color3.fromRGB(124, 86, 63),
	cream = Color3.fromRGB(235, 220, 184),
	roof = Color3.fromRGB(60, 102, 95),
	soil = Color3.fromRGB(94, 65, 46),
}
local function part(parent, name, size, position, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
local function label(p, text)
	local g = Instance.new("BillboardGui")
	g.Size = UDim2.fromOffset(160, 28)
	g.StudsOffset = Vector3.new(0, 2.5, 0)
	g.MaxDistance = 42
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundColor3 = C.roof
	t.BackgroundTransparency = 0.08
	t.Text = text
	t.TextColor3 = C.cream
	t.TextSize = 13
	t.Font = Enum.Font.GothamMedium
	t.Parent = g
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = t
end
local function beam(parent, a, b, width, color)
	local p = part(parent, "Beam", Vector3.new(width, width, (b - a).Magnitude), (a + b) / 2, color)
	p.CFrame = CFrame.lookAt((a + b) / 2, b)
	return p
end
local function tree(parent, pos, scale, hue)
	local trunk = part(parent, "Trunk", Vector3.new(1, 7, 1) * scale, pos + Vector3.new(0, 3.5, 0) * scale, C.wood)
	trunk.Material = Enum.Material.Wood
	for j = 1, 3 do
		local leaf = part(
			parent,
			"Canopy",
			Vector3.new(8, 6, 8) * scale,
			pos + Vector3.new((j - 2) * 2, 7 + j, math.sin(j) * 1.5) * scale,
			Color3.fromHSV(hue, 0.36, 0.53 + j * 0.035),
			Enum.PartType.Ball
		)
		leaf.CanCollide = false
	end
end
local function flower(parent, pos, color)
	local p = part(parent, "Wildflower", Vector3.new(0.15, 0.9, 0.15), pos + Vector3.new(0, 0.45, 0), C.leaf)
	p.CanCollide = false
	local head =
		part(parent, "Flower", Vector3.new(0.9, 0.35, 0.9), pos + Vector3.new(0, 1, 0), color, Enum.PartType.Ball)
	head.CanCollide = false
end
local function fence(parent, origin, width)
	for x = -width / 2, width / 2, 6 do
		part(parent, "Fence post", Vector3.new(0.5, 3, 0.5), origin + Vector3.new(x, 1.5, 0), C.cream)
	end
	for _, y in { 1, 2.2 } do
		part(parent, "Fence rail", Vector3.new(width, 0.3, 0.25), origin + Vector3.new(0, y, 0), C.cream)
	end
end
local function prompt(p, screen, caption)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = caption
	pr.ObjectText = screen
	pr.HoldDuration = 0
	pr.MaxActivationDistance = 12
	pr.RequiresLineOfSight = false
	pr:SetAttribute("GardenScreen", screen)
	pr.Parent = p
end
local function building(parent, name, pos, tint, screen)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	part(m, "Foundation", Vector3.new(21, 0.6, 18), pos + Vector3.new(0, 0.3, 0), C.cream).Material =
		Enum.Material.Cobblestone
	part(m, "Back wall", Vector3.new(19, 9, 0.6), pos + Vector3.new(0, 5, -7), tint)
	for _, x in { -9, 9 } do
		part(m, "Side wall", Vector3.new(0.6, 9, 14), pos + Vector3.new(x, 5, 0), tint)
	end
	for _, x in { -6, 6 } do
		part(m, "Front wall", Vector3.new(6, 9, 0.6), pos + Vector3.new(x, 5, 7), tint)
		local glass =
			part(m, "Window", Vector3.new(3.6, 3, 0.15), pos + Vector3.new(x, 5.5, 7.35), Color3.fromRGB(155, 209, 199))
		glass.Material = Enum.Material.Glass
		glass.Transparency = 0.2
		for _, dy in { -1.6, 1.6 } do
			part(m, "Window trim", Vector3.new(4, 0.25, 0.3), pos + Vector3.new(x, 5.5 + dy, 7.45), C.cream)
		end
		part(m, "Window mullion", Vector3.new(0.2, 3.4, 0.3), pos + Vector3.new(x, 5.5, 7.45), C.cream)
	end
	for _, x in { -5, 5 } do
		local r = part(m, "Pitched roof", Vector3.new(12, 0.7, 19), pos + Vector3.new(x, 11, 0), C.roof)
		r.CFrame *= CFrame.Angles(0, 0, if x < 0 then math.rad(25) else math.rad(-25))
	end
	part(m, "Roof ridge", Vector3.new(0.7, 0.7, 19), pos + Vector3.new(0, 13.2, 0), C.roof)
	local sign = part(m, "Shop sign", Vector3.new(6, 1.2, 0.4), pos + Vector3.new(0, 7.8, 7.5), C.wood)
	label(sign, name)
	local counter = part(m, "Counter", Vector3.new(7, 3, 2), pos + Vector3.new(0, 1.8, 3), C.wood)
	prompt(counter, screen, "Open")
	for j = -1, 1 do
		local pot = part(
			m,
			"Display pot",
			Vector3.new(1.5, 1.4, 1.5),
			pos + Vector3.new(j * 2.5, 3.8, 3),
			Color3.fromRGB(178, 109, 78)
		)
		flower(m, pot.Position + Vector3.new(0, 0.7, 0), Color3.fromRGB(234, 181, 123))
	end
end
function World.new(catalog)
	local self = setmetatable({ catalog = catalog, plots = {}, visuals = {}, stages = {} }, World)
	local folder = Instance.new("Folder")
	folder.Name = "MutationGarden"
	folder.Parent = workspace
	self.root = folder
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 15.4
	lighting.Brightness = 2
	lighting.Ambient = Color3.fromRGB(122, 135, 143)
	lighting.OutdoorAmbient = Color3.fromRGB(153, 166, 153)
	lighting.GlobalShadows = true
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.25
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(210, 227, 219)
	atmosphere.Decay = Color3.fromRGB(143, 162, 149)
	atmosphere.Parent = lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Saturation = -0.08
	grade.Contrast = 0.07
	grade.TintColor = Color3.fromRGB(255, 247, 229)
	grade.Parent = lighting
	local base = part(folder, "Meadow", Vector3.new(640, 18, 640), Vector3.new(0, -10, 0), C.grass)
	base.Material = Enum.Material.Grass
	part(folder, "Plaza", Vector3.new(80, 0.35, 80), Vector3.new(0, -0.7, 0), Color3.fromRGB(194, 183, 157)).Material =
		Enum.Material.Cobblestone
	for i = 0, 7 do
		local a = i * math.pi / 4
		local path = part(
			folder,
			"Garden path",
			Vector3.new(10, 0.25, 110),
			Vector3.new(math.cos(a) * 85, -0.55, math.sin(a) * 85),
			Color3.fromRGB(204, 190, 159)
		)
		path.CFrame = CFrame.new(path.Position) * CFrame.Angles(0, math.pi / 2 - a, 0)
		path.Material = Enum.Material.Pebble
	end
	-- A low fountain gives the square a focal point without hiding the buildings.
	local basin =
		part(folder, "Fountain basin", Vector3.new(16, 1.2, 16), Vector3.new(0, 0, 0), C.cream, Enum.PartType.Cylinder)
	basin.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	basin.Size = Vector3.new(1.2, 16, 16)
	local water = part(
		folder,
		"Fountain water",
		Vector3.new(0.3, 13, 13),
		Vector3.new(0, 0.7, 0),
		Color3.fromRGB(100, 180, 185),
		Enum.PartType.Cylinder
	)
	water.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	water.Material = Enum.Material.Glass
	water.Transparency = 0.2
	water.CanCollide = false
	part(folder, "Fountain pillar", Vector3.new(2, 4, 2), Vector3.new(0, 2, 0), C.cream)
	part(
		folder,
		"Fountain bloom",
		Vector3.new(6, 1.4, 6),
		Vector3.new(0, 4.5, 0),
		Color3.fromRGB(211, 169, 179),
		Enum.PartType.Ball
	)
	local shopNames = { "Willow Seeds", "Genetics Atelier", "Research Library", "Garden Contracts", "Botanical Museum" }
	local screens = { "shop", "inventory", "research", "quests", "collection" }
	for i, name in shopNames do
		local a = (i - 1) * math.pi * 2 / 5
		building(
			folder,
			name,
			Vector3.new(math.cos(a) * 57, -0.4, math.sin(a) * 57),
			Color3.fromHSV(0.08 + i * 0.025, 0.14, 0.82),
			screens[i]
		)
	end
	local rng = Random.new(4107)
	for j = 1, 68 do
		local a = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(192, 295)
		local pos = Vector3.new(math.cos(a) * radius, -1, math.sin(a) * radius)
		tree(folder, pos, rng:NextNumber(0.7, 1.5), rng:NextNumber(0.24, 0.36))
	end
	for i, name in catalog.biomes do
		local a = (i - 1) * math.pi / 3
		local pos = Vector3.new(math.cos(a) * 245, -0.5, math.sin(a) * 245)
		part(folder, name, Vector3.new(44, 0.6, 44), pos, Color3.fromHSV(i / 6, 0.17, 0.65)).Material =
			Enum.Material.Grass
		local sign = part(folder, "Biome sign", Vector3.new(2, 4, 1), pos + Vector3.new(0, 2, 20), C.wood)
		label(sign, name)
		for j = 1, 5 do
			local x = pos + Vector3.new((j % 3 - 1) * 11, 2, (math.floor(j / 3) - 1) * 12)
			if i == 2 then
				part(folder, "Mushroom stem", Vector3.new(1, 5, 1), x, C.cream)
				part(
					folder,
					"Mushroom cap",
					Vector3.new(7, 2, 7),
					x + Vector3.new(0, 3, 0),
					Color3.fromRGB(171, 126, 183),
					Enum.PartType.Ball
				)
			elseif i == 3 or i == 6 then
				local shard = part(folder, "Crystal", Vector3.new(2, 7 + j, 2), x, Color3.fromHSV(i / 6, 0.3, 0.85))
				shard.CFrame *= CFrame.Angles(0.2, 0, 0.2)
				shard.Material = Enum.Material.Glass
			else
				tree(folder, x - Vector3.new(0, 2, 0), 0.7, if i == 4 then 0.08 elseif i == 5 then 0.5 else 0.29)
			end
		end
	end
	for i = 1, catalog.maxPlayers do
		local a = (i - 1) * math.pi / 4
		local center = Vector3.new(math.cos(a) * 132, -0.5, math.sin(a) * 132)
		local model = Instance.new("Model")
		model.Name = "Garden" .. i
		model.Parent = folder
		part(model, "Garden lawn", Vector3.new(62, 0.4, 82), center, C.grass).Material = Enum.Material.Grass
		fence(model, center + Vector3.new(0, 0, -40), 60)
		fence(model, center + Vector3.new(-20, 0, 40), 20)
		fence(model, center + Vector3.new(20, 0, 40), 20)
		for _, x in { -30, 30 } do
			for z = -36, 36, 12 do
				part(model, "Hedge", Vector3.new(2.5, 2, 11), center + Vector3.new(x, 1, z), C.leaf, Enum.PartType.Ball).CanCollide =
					false
			end
			tree(model, center + Vector3.new(x * 0.8, 0, -33), 0.7, 0.3)
		end
		local marker = part(
			model,
			"Mailbox",
			Vector3.new(2.5, 1.8, 2.5),
			center + Vector3.new(-8, 3, 36),
			Color3.fromRGB(167, 106, 81)
		)
		part(model, "Mailbox post", Vector3.new(0.5, 2, 0.5), center + Vector3.new(-8, 1, 36), C.wood)
		label(marker, "Unclaimed garden")
		local chest = part(model, "Storage chest", Vector3.new(5, 2.8, 3), center + Vector3.new(22, 1.6, 30), C.wood)
		prompt(chest, "inventory", "Inspect specimens")
		part(model, "Chest lid", Vector3.new(5.3, 0.5, 3.3), chest.Position + Vector3.new(0, 1.6, 0), C.cream)
		-- Glasshouse is an open frame rather than a solid transparent cube.
		local gh = center + Vector3.new(-17, 0, 29)
		for _, x in { -5, 5 } do
			for _, z in { -4, 4 } do
				part(model, "Greenhouse frame", Vector3.new(0.25, 6, 0.25), gh + Vector3.new(x, 3, z), C.cream)
			end
		end
		for _, x in { -5, 5 } do
			local glass = part(
				model,
				"Greenhouse glass",
				Vector3.new(0.15, 5.5, 8),
				gh + Vector3.new(x, 3, 0),
				Color3.fromRGB(173, 213, 203)
			)
			glass.Material = Enum.Material.Glass
			glass.Transparency = 0.75
			glass.CanCollide = false
		end
		for _, z in { -4, 4 } do
			beam(model, gh + Vector3.new(-5, 6, z), gh + Vector3.new(0, 8, z), 0.25, C.cream)
			beam(model, gh + Vector3.new(5, 6, z), gh + Vector3.new(0, 8, z), 0.25, C.cream)
		end
		beam(model, gh + Vector3.new(0, 8, -4), gh + Vector3.new(0, 8, 4), 0.25, C.cream)
		for j = 1, 12 do
			flower(
				model,
				center + Vector3.new(rng:NextNumber(-26, 26), 0.3, rng:NextNumber(-38, -33)),
				Color3.fromHSV(rng:NextNumber(), 0.3, 0.95)
			)
		end
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "Garden spawn"
		spawn.Size = Vector3.new(4, 0.2, 4)
		spawn.Position = center + Vector3.new(0, 0.6, 33)
		spawn.Anchored = true
		spawn.Transparency = 1
		spawn.CanCollide = false
		spawn.Neutral = true
		spawn.Duration = 0
		spawn.Enabled = false
		spawn.Parent = model
		self.plots[i] = { model = model, center = center, marker = marker, cells = {}, spawn = spawn }
	end
	return self
end
function World:claim(player)
	for i, p in self.plots do
		if not p.owner then
			p.owner = player
			p.model:SetAttribute("Owner", player.UserId)
			p.marker:FindFirstChildOfClass("BillboardGui").TextLabel.Text = player.DisplayName .. "'s garden"
			p.spawn.Enabled = true
			player.RespawnLocation = p.spawn
			return i
		end
	end
	return nil
end
function World:cell(plot, index)
	local block = math.floor((index - 1) / 12)
	local within = (index - 1) % 12
	return plot.center
		+ Vector3.new(
			(block % 2) * 25 - 19 + (within % 4) * 4.6,
			0.9,
			math.floor(block / 2) * 16 - 27 + math.floor(within / 4) * 4.6
		)
end
function World:release(index)
	local p = self.plots[index]
	if p.owner then
		p.owner.RespawnLocation = nil
	end
	p.owner = nil
	p.spawn.Enabled = false
	p.model:SetAttribute("Owner", nil)
	p.marker:FindFirstChildOfClass("BillboardGui").TextLabel.Text = "Unclaimed garden"
	for _, c in p.cells do
		c:Destroy()
	end
	p.cells = {}
	for _, c in p.model:GetChildren() do
		if c.Name == "Bed trim" then
			c:Destroy()
		end
	end
	for id, model in self.visuals do
		if model.Parent == p.model then
			model:Destroy()
			self.visuals[id] = nil
			self.stages[id] = nil
		end
	end
end
function World:model(plant, cfg, position, stage, parent, phenotype)
	local m = Instance.new("Model")
	m.Name = plant.id
	m.Parent = parent
	local rng = Random.new(plant.seed)
	local scale = (0.3 + stage * 0.19) * (0.8 + phenotype.size * 0.15)
	local color = Color3.fromHSV((cfg.hue + phenotype.color * 0.025) % 1, 0.55, 0.92)
	for _, mutation in plant.mutations do
		if mutation == "Giant" then
			scale *= 1.8
		elseif mutation == "Miniature" then
			scale *= 0.55
		end
	end
	local function add(name, size, offset, c, shape)
		local p = part(m, name, size * scale, position + offset * scale, c, shape)
		p.CanCollide = false
		p.CanTouch = false
		if phenotype.light >= 3 or #plant.mutations > 0 then
			p.Material = Enum.Material.Neon
		end
		return p
	end
	local green = Color3.fromRGB(66, 123, 87)
	local arch = cfg.archetype
	if stage == 0 then
		add("Seed", Vector3.new(0.6, 0.4, 0.6), Vector3.new(0, 0.2, 0), color, Enum.PartType.Ball)
		return m
	end
	add("Stem", Vector3.new(0.35, 3, 0.35), Vector3.new(0, 1.5, 0), green)
	if arch == "Tree" then
		for j = 1, 3 do
			add(
				"Canopy",
				Vector3.new(3.6, 2.2, 3),
				Vector3.new((j - 2) * 1.1, 3 + j * 0.5, 0),
				color,
				Enum.PartType.Ball
			)
		end
	elseif arch == "Mushroom" then
		add("Cap", Vector3.new(4, 1, 4), Vector3.new(0, 3, 0), color, Enum.PartType.Ball)
	elseif arch == "Cactus" then
		add("Column", Vector3.new(1.3, 4, 1.3), Vector3.new(0, 2, 0), color)
		for j = -1, 1, 2 do
			add("Arm", Vector3.new(1, 1, 1), Vector3.new(j * 1.2, 2.2, 0), green)
			add("Finger", Vector3.new(0.6, 2, 0.6), Vector3.new(j * 1.5, 3, 0), color)
		end
	elseif arch == "Crystal" then
		for j = 1, 4 do
			local p = add("Shard", Vector3.new(0.8, 2 + j * 0.5, 0.8), Vector3.new((j - 2) * 0.6, 1.8, 0), color)
			p.CFrame *= CFrame.Angles(0, 0, (j - 2) * 0.2)
		end
	elseif arch == "Vine" then
		for j = 1, 6 do
			add(
				"Leaf",
				Vector3.new(1, 0.3, 1.6),
				Vector3.new(math.sin(j) * 1.1, j * 0.5, math.cos(j)),
				color,
				Enum.PartType.Ball
			)
		end
	elseif arch == "Bush" then
		for j = 1, 5 do
			add(
				"Foliage",
				Vector3.new(2, 1.7, 2),
				Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(1, 2.5), rng:NextNumber(-1, 1)),
				color,
				Enum.PartType.Ball
			)
		end
	elseif arch == "Aquatic" then
		add("Pad", Vector3.new(3, 0.15, 3), Vector3.new(0, 0.2, 0), green, Enum.PartType.Cylinder)
		for j = 1, 4 do
			add(
				"Bloom",
				Vector3.new(0.6, 1.4, 0.6),
				Vector3.new(math.cos(j) * 0.6, 2.5, math.sin(j) * 0.6),
				color,
				Enum.PartType.Ball
			)
		end
	elseif arch == "Exotic" then
		for j = 1, 5 do
			add(
				"Orbit",
				Vector3.new(0.8, 0.8, 0.8),
				Vector3.new(math.cos(j) * 1.4, 1 + j * 0.5, math.sin(j) * 1.4),
				color,
				Enum.PartType.Ball
			)
		end
	else
		for j = 1, 5 do
			local a = j * math.pi * 2 / 5
			add(
				"Petal",
				Vector3.new(1.5, 0.5, 1.5),
				Vector3.new(math.cos(a), 3, math.sin(a)),
				color,
				Enum.PartType.Ball
			)
		end
		add(
			"Heart",
			Vector3.new(0.9, 0.6, 0.9),
			Vector3.new(0, 3.2, 0),
			Color3.fromRGB(255, 220, 120),
			Enum.PartType.Ball
		)
	end
	return m
end
function World:render(index, profile, sim, genetics)
	local plot = self.plots[index]
	for i = 1, self.catalog.expansions[profile.expansion] do
		if not plot.cells[i] then
			local cell = part(
				plot.model,
				"Soil" .. i,
				Vector3.new(4.2, 0.5, 4.2),
				self:cell(plot, i),
				Color3.fromRGB(105, 78, 59)
			)
			cell.Material = Enum.Material.Ground
			if (i - 1) % 12 == 0 then
				local c = self:cell(plot, i) + Vector3.new(6.9, -0.15, 4.6)
				for _, x in { -9.4, 9.4 } do
					part(plot.model, "Bed trim", Vector3.new(0.3, 0.7, 14.1), c + Vector3.new(x, 0, 0), C.wood).Material =
						Enum.Material.Wood
				end
				for _, z in { -7, 7 } do
					part(plot.model, "Bed trim", Vector3.new(19, 0.7, 0.3), c + Vector3.new(0, 0, z), C.wood).Material =
						Enum.Material.Wood
				end
			end
			cell:SetAttribute("Cell", i)
			cell:SetAttribute("Owner", plot.owner.UserId)
			plot.cells[i] = cell
		end
	end
	for id, m in self.visuals do
		if m.Parent == plot.model and not profile.plants[id] then
			m:Destroy()
			self.visuals[id] = nil
			self.stages[id] = nil
		end
	end
	for id, plant in profile.plants do
		local stage = math.min(4, math.floor(plant.progress * 4))
		if self.stages[id] ~= stage then
			if self.visuals[id] then
				self.visuals[id]:Destroy()
			end
			local cfg
			for _, c in self.catalog.plants do
				if c.id == plant.species then
					cfg = c
				end
			end
			self.visuals[id] = self:model(
				plant,
				cfg,
				self:cell(plot, plant.cell) + Vector3.new(0, 0.3, 0),
				stage,
				plot.model,
				genetics.phenotype(plant.genome)
			)
			self.visuals[id]:SetAttribute("PlantId", id)
			self.visuals[id]:SetAttribute("Cell", plant.cell)
			self.visuals[id]:SetAttribute("Owner", plot.owner.UserId)
			self.stages[id] = stage
		end
	end
end
return World
