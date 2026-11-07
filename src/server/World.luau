--!nocheck
local World = {}
World.__index = World
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
	p.Parent = parent
	return p
end
local function label(p, text)
	local g = Instance.new("BillboardGui")
	g.Size = UDim2.fromOffset(220, 45)
	g.StudsOffset = Vector3.new(0, 4, 0)
	g.MaxDistance = 110
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = Color3.fromRGB(250, 247, 222)
	t.TextStrokeTransparency = 0.4
	t.TextScaled = true
	t.Font = Enum.Font.GothamBold
	t.Parent = g
end
function World.new(catalog)
	local self = setmetatable({ catalog = catalog, plots = {}, visuals = {}, stages = {} }, World)
	local folder = Instance.new("Folder")
	folder.Name = "MutationGarden"
	folder.Parent = workspace
	self.root = folder
	part(folder, "Island", Vector3.new(480, 12, 480), Vector3.new(0, -7, 0), Color3.fromRGB(107, 155, 119))
	part(folder, "Plaza", Vector3.new(70, 1, 70), Vector3.new(0, 0, 0), Color3.fromRGB(215, 200, 171))
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 2, 0)
	spawn.Neutral = true
	spawn.Parent = folder
	for i, name in
		{ "Seed Shop", "Genetics Lab", "Research Center", "Quest Lodge", "Trade Pavilion", "Botanical Museum" }
	do
		local a = i * math.pi / 3
		local pos = Vector3.new(math.cos(a) * 48, 5, math.sin(a) * 48)
		part(folder, name, Vector3.new(16, 10, 13), pos, Color3.fromHSV(i / 6, 0.25, 0.85))
		local roof =
			part(folder, "Roof", Vector3.new(19, 3, 16), pos + Vector3.new(0, 7, 0), Color3.fromRGB(88, 123, 112))
		label(roof, name)
	end
	for i, name in catalog.biomes do
		local a = (i - 1) * math.pi / 3
		local pos = Vector3.new(math.cos(a) * 190, 0, math.sin(a) * 190)
		part(folder, name, Vector3.new(60, 1, 60), pos, Color3.fromHSV(i / 6, 0.25, 0.65))
		local sign = part(
			folder,
			"Biome marker",
			Vector3.new(2, 10, 2),
			pos + Vector3.new(0, 5, 0),
			Color3.fromHSV(i / 6, 0.5, 0.9)
		)
		label(sign, name)
		for j = 1, 9 do
			local x = pos + Vector3.new((j % 3 - 1) * 15, 4, (math.floor(j / 3) - 1) * 14)
			local deco = part(
				folder,
				"Biome flora",
				Vector3.new(4, 8 + j % 3, 4),
				x,
				Color3.fromHSV(i / 6, 0.4, 0.8),
				if i == 2 then Enum.PartType.Ball else Enum.PartType.Block
			)
			if i == 3 or i == 6 then
				deco.Material = Enum.Material.Neon
			end
		end
	end
	for i = 1, catalog.maxPlayers do
		local a = (i - 1) * math.pi / 4
		local center = Vector3.new(math.cos(a) * 110, 1, math.sin(a) * 110)
		local model = Instance.new("Model")
		model.Name = "Garden" .. i
		model.Parent = folder
		part(model, "Lawn", Vector3.new(50, 1, 65), center, Color3.fromRGB(138, 178, 125))
		local marker = part(
			model,
			"Mailbox",
			Vector3.new(3, 3, 2),
			center + Vector3.new(-22, 3, -28),
			Color3.fromRGB(208, 177, 150)
		)
		label(marker, "Available garden")
		part(model, "Storage", Vector3.new(7, 5, 6), center + Vector3.new(17, 3, -27), Color3.fromRGB(156, 116, 81))
		local glass = part(
			model,
			"Greenhouse",
			Vector3.new(13, 8, 8),
			center + Vector3.new(0, 5, -27),
			Color3.fromRGB(175, 226, 222)
		)
		glass.Transparency = 0.65
		glass.CanCollide = false
		self.plots[i] = { model = model, center = center, marker = marker, cells = {} }
	end
	return self
end
function World:claim(player)
	for i, p in self.plots do
		if not p.owner then
			p.owner = player
			p.model:SetAttribute("Owner", player.UserId)
			p.marker:FindFirstChildOfClass("BillboardGui").TextLabel.Text = player.DisplayName .. "'s garden"
			return i
		end
	end
	return nil
end
function World:cell(plot, index)
	return plot.center + Vector3.new(((index - 1) % 8 - 3.5) * 5, 1, (math.floor((index - 1) / 8) - 5) * 4.5)
end
function World:release(index)
	local p = self.plots[index]
	p.owner = nil
	p.model:SetAttribute("Owner", nil)
	p.marker:FindFirstChildOfClass("BillboardGui").TextLabel.Text = "Available garden"
	for _, c in p.cells do
		c:Destroy()
	end
	p.cells = {}
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
			local cell =
				part(plot.model, "Soil" .. i, Vector3.new(4.4, 0.3, 4), self:cell(plot, i), Color3.fromRGB(105, 78, 59))
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
			self.stages[id] = stage
		end
	end
end
return World
