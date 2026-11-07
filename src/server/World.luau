--!nocheck
local World = {}
World.__index = World
local C = {
	grass = Color3.fromRGB(112, 137, 91),
	leaf = Color3.fromRGB(65, 98, 74),
	wood = Color3.fromRGB(117, 87, 65),
	cream = Color3.fromRGB(224, 211, 178),
	roof = Color3.fromRGB(48, 82, 73),
	soil = Color3.fromRGB(94, 65, 46),
}
local function part(parent, name, size, position, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.Position = position
	p.Color = color
	local wood = string.find(name, "[Tt]rim")
		or string.find(name, "[Ff]ence")
		or string.find(name, "[Ff]rame")
		or string.find(name, "[Cc]hest")
		or string.find(name, "[Bb]eam")
		or string.find(name, "[Ss]ign")
		or string.find(name, "[Cc]ounter")
	p.Material = if wood then Enum.Material.Wood else Enum.Material.SmoothPlastic
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
local function verticalCylinder(parent, name, radius, height, pos, color, material)
	local p = part(parent, name, Vector3.new(height, radius * 2, radius * 2), pos, color, Enum.PartType.Cylinder)
	p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2)
	p.Material = material or Enum.Material.SmoothPlastic
	return p
end
local function rock(parent, pos, size, tint)
	local p = Instance.new("WedgePart")
	p.Name = "Weathered stone"
	p.Anchored = true
	p.Size = size
	p.CFrame = CFrame.new(pos) * CFrame.Angles(0, (pos.X + pos.Z) * 0.23, 0.12)
	p.Color = tint or Color3.fromRGB(139, 144, 133)
	p.Material = Enum.Material.Slate
	p.Parent = parent
	return p
end
local function tree(parent, pos, scale, hue)
	local treeModel = Instance.new("Model")
	treeModel.Name = "Meadow tree"
	treeModel.Parent = parent
	local trunk = verticalCylinder(
		treeModel,
		"Bark trunk",
		0.55 * scale,
		8 * scale,
		pos + Vector3.new(0, 4, 0) * scale,
		C.wood,
		Enum.Material.Wood
	)
	for j = 1, 3 do
		local a = j * 2.399
		local endPoint = pos + Vector3.new(math.cos(a) * 3, 7 + j * 0.7, math.sin(a) * 3) * scale
		beam(treeModel, pos + Vector3.new(0, 4 + j * 0.4, 0) * scale, endPoint, 0.45 * scale, C.wood)
		local crown = part(
			treeModel,
			"Foliage cluster",
			Vector3.new(6.8, 4.6, 6.1) * scale,
			endPoint + Vector3.new(0, 1.5, 0) * scale,
			Color3.fromHSV(hue, 0.28, 0.42 + j * 0.045),
			Enum.PartType.Ball
		)
		crown.CFrame *= CFrame.Angles(j * 0.25, a, j * 0.13)
		crown.CanCollide = false
		local tip = part(
			treeModel,
			"Foliage highlight",
			Vector3.new(4.2, 2.8, 4) * scale,
			endPoint + Vector3.new(-1, 3, -0.5) * scale,
			Color3.fromHSV(hue, 0.26, 0.57 + j * 0.02),
			Enum.PartType.Ball
		)
		tip.CanCollide = false
	end
	-- Buttress roots visually anchor trees instead of floating balloon canopies.
	for j = 1, 3 do
		local a = j * math.pi * 2 / 3
		beam(
			treeModel,
			pos + Vector3.new(0, 0.6, 0) * scale,
			pos + Vector3.new(math.cos(a) * 1.7, 0.1, math.sin(a) * 1.7) * scale,
			0.5 * scale,
			C.wood
		)
	end
end
local function flower(parent, pos, color)
	local stem = part(parent, "Flower stem", Vector3.new(0.1, 0.85, 0.1), pos + Vector3.new(0, 0.42, 0), C.leaf)
	stem.CanCollide = false
	for j = 1, 4 do
		local a = j * math.pi / 2
		local petal = part(
			parent,
			"Silk petal",
			Vector3.new(0.48, 0.15, 0.7),
			pos + Vector3.new(math.cos(a) * 0.29, 0.9, math.sin(a) * 0.29),
			color,
			Enum.PartType.Ball
		)
		petal.CFrame *= CFrame.Angles(0, -a + 0.5, 0.12)
		petal.CanCollide = false
		petal.CanTouch = false
	end
	local center = part(
		parent,
		"Pollen center",
		Vector3.new(0.3, 0.2, 0.3),
		pos + Vector3.new(0, 0.97, 0),
		Color3.fromRGB(223, 181, 91),
		Enum.PartType.Ball
	)
	center.CanCollide = false
	local leaf = part(
		parent,
		"Flower leaf",
		Vector3.new(0.48, 0.1, 0.22),
		pos + Vector3.new(0.15, 0.35, 0),
		C.leaf,
		Enum.PartType.Ball
	)
	leaf.CFrame *= CFrame.Angles(0, 0, 0.4)
	leaf.CanCollide = false
end
local function lantern(parent, pos)
	local housing = part(parent, "Lantern frame", Vector3.new(0.75, 1.2, 0.75), pos, C.roof)
	local glass = part(parent, "Warm lantern", Vector3.new(0.65, 0.8, 0.79), pos, Color3.fromRGB(247, 208, 130))
	glass.Material = Enum.Material.Neon
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 218, 161)
	light.Brightness = 0.6
	light.Range = 10
	light.Shadows = false
	light.Parent = glass
	for _, y in { -0.6, 0.6 } do
		part(parent, "Lantern cap", Vector3.new(0.95, 0.15, 0.95), pos + Vector3.new(0, y, 0), C.roof)
	end
end
local function bench(parent, pos)
	for j = 1, 3 do
		part(parent, "Bench slat", Vector3.new(5, 0.18, 0.6), pos + Vector3.new(0, 1.5, (j - 2) * 0.68), C.wood)
	end
	for _, x in { -1.8, 1.8 } do
		part(parent, "Bench leg", Vector3.new(0.25, 1.6, 1.8), pos + Vector3.new(x, 0.8, 0), C.roof)
	end
	for j = 1, 2 do
		part(parent, "Bench back", Vector3.new(5, 0.5, 0.18), pos + Vector3.new(0, 2 + j * 0.6, -1), C.wood)
	end
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
		Enum.Material.Limestone
	part(m, "Back wall", Vector3.new(19, 9, 0.6), pos + Vector3.new(0, 5, -7), tint).Material = Enum.Material.Plaster
	for _, x in { -9, 9 } do
		part(m, "Side wall", Vector3.new(0.6, 9, 14), pos + Vector3.new(x, 5, 0), tint).Material = Enum.Material.Plaster
	end
	for _, x in { -6, 6 } do
		part(m, "Front wall", Vector3.new(6, 9, 0.6), pos + Vector3.new(x, 5, 7), tint).Material = Enum.Material.Plaster
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
	-- Exposed timber frame, lower cladding and restrained clay roof strips.
	for _, x in { -9, -3, 3, 9 } do
		part(m, "Timber frame", Vector3.new(0.25, 8.7, 0.2), pos + Vector3.new(x, 4.8, 7.4), C.wood)
	end
	for j = 1, 3 do
		for _, x in { -6, 6 } do
			part(m, "Cladding plank", Vector3.new(5.9, 0.55, 0.22), pos + Vector3.new(x, 0.8 + j * 0.55, 7.4), C.wood).Material =
				Enum.Material.WoodPlanks
		end
	end
	for _, x in { -5, 5 } do
		for j = -4, 4 do
			local slat = part(
				m,
				"Roof seam",
				Vector3.new(12, 0.12, 0.13),
				pos + Vector3.new(x, 11.4, j * 2),
				Color3.fromRGB(68, 104, 92)
			)
			slat.CFrame *= CFrame.Angles(0, 0, if x < 0 then math.rad(25) else math.rad(-25))
		end
	end
	for _, x in { -7, 7 } do
		local planter = part(m, "Window planter", Vector3.new(4, 0.9, 1.6), pos + Vector3.new(x, 3.6, 8), C.wood)
		for j = -1, 1 do
			flower(m, planter.Position + Vector3.new(j * 1.15, 0.5, 0), Color3.fromRGB(211, 155, 151))
		end
	end
	local awning = part(m, "Canvas awning", Vector3.new(7, 0.18, 3.5), pos + Vector3.new(0, 7, 8.6), C.roof)
	awning.Material = Enum.Material.Fabric
	awning.CFrame *= CFrame.Angles(0.12, 0, 0)
	for _, x in { -3.6, 3.6 } do
		part(m, "Porch post", Vector3.new(0.22, 6.8, 0.22), pos + Vector3.new(x, 3.4, 10), C.wood)
	end
	lantern(m, pos + Vector3.new(4.3, 6, 7.8))
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
	lighting.ClockTime = 16.6
	lighting.Brightness = 2
	lighting.Ambient = Color3.fromRGB(66, 76, 91)
	lighting.OutdoorAmbient = Color3.fromRGB(127, 139, 128)
	lighting.EnvironmentDiffuseScale = 0.65
	lighting.EnvironmentSpecularScale = 0.35
	lighting.ExposureCompensation = -0.1
	lighting.ShadowSoftness = 0.4
	lighting.GlobalShadows = true
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.19
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(210, 227, 219)
	atmosphere.Decay = Color3.fromRGB(143, 162, 149)
	atmosphere.Parent = lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Saturation = -0.04
	grade.Contrast = 0.07
	grade.TintColor = Color3.fromRGB(255, 247, 229)
	grade.Parent = lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.12
	bloom.Size = 18
	bloom.Threshold = 1.8
	bloom.Parent = lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.025
	rays.Spread = 0.75
	rays.Parent = lighting
	local base = part(folder, "Meadow", Vector3.new(640, 18, 640), Vector3.new(0, -10, 0), C.grass)
	base.Material = Enum.Material.Grass
	part(folder, "Plaza", Vector3.new(80, 0.35, 80), Vector3.new(0, -0.7, 0), Color3.fromRGB(194, 183, 157)).Material =
		Enum.Material.Limestone
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
		path.Material = Enum.Material.Sandstone
	end
	-- Muted limestone pavers and seams give a readable, human-scale ground surface.
	for x = -36, 36, 6 do
		for z = -36, 36, 6 do
			local tile = part(
				folder,
				"Limestone paving",
				Vector3.new(5.85, 0.16, 5.85),
				Vector3.new(x, -0.45, z),
				Color3.fromRGB(188 + ((x + z) % 3) * 3, 183, 164)
			)
			tile.Material = Enum.Material.Limestone
		end
	end
	for _, pos in { Vector3.new(-25, 0, 22), Vector3.new(25, 0, -22) } do
		bench(folder, pos)
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
			Color3.fromRGB(222 - i * 3, 214 - i * 2, 193 + i),
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
	for j = 1, 28 do
		local a = j * 2.399
		local radius = 270 + (j % 3) * 12
		local pos = Vector3.new(math.cos(a) * radius, -1, math.sin(a) * radius)
		local mound = part(
			folder,
			"Distant meadow hill",
			Vector3.new(70, 22 + (j % 4) * 5, 65),
			pos - Vector3.new(0, 9, 0),
			Color3.fromRGB(104 + j % 3 * 5, 129, 93),
			Enum.PartType.Ball
		)
		mound.Material = Enum.Material.Grass
		rock(folder, pos + Vector3.new(12, 1, 5), Vector3.new(5, 4, 6))
	end
	for i, name in catalog.biomes do
		local a = (i - 1) * math.pi / 3
		local pos = Vector3.new(math.cos(a) * 245, -0.5, math.sin(a) * 245)
		part(folder, name, Vector3.new(44, 0.6, 44), pos, Color3.fromRGB(117 + i * 2, 137 - i * 2, 112 + i * 3)).Material =
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
		local path = part(
			model,
			"Garden flagstone walk",
			Vector3.new(5, 0.16, 68),
			center + Vector3.new(2, 0.32, 0),
			Color3.fromRGB(181, 178, 155)
		)
		path.Material = Enum.Material.Limestone
		for j = 1, 7 do
			local stone = part(
				model,
				"Entrance stepping stone",
				Vector3.new(3.3, 0.18, 1.8),
				center + Vector3.new((j % 2) * 0.8, 0.35, 18 + j * 2.5),
				Color3.fromRGB(194, 188, 164)
			)
			stone.CFrame *= CFrame.Angles(0, (j % 3 - 1) * 0.1, 0)
			stone.Material = Enum.Material.Limestone
		end
		bench(model, center + Vector3.new(19, 0.3, 35))
		for _, z in { -36, -24 } do
			rock(model, center + Vector3.new(26, 0.9, z), Vector3.new(2.8, 2, 3.5))
		end
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
		lantern(model, center + Vector3.new(7, 4.5, 36))
		part(model, "Garden lantern post", Vector3.new(0.25, 4, 0.25), center + Vector3.new(7, 2, 36), C.roof)
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
		for _, z in { -4, -2, 0, 2, 4 } do
			beam(model, gh + Vector3.new(-5, 6, z), gh + Vector3.new(0, 8, z), 0.25, C.cream)
			beam(model, gh + Vector3.new(5, 6, z), gh + Vector3.new(0, 8, z), 0.25, C.cream)
		end
		beam(model, gh + Vector3.new(0, 8, -4), gh + Vector3.new(0, 8, 4), 0.25, C.cream)
		for _, x in { -2.5, 2.5 } do
			local roof = part(
				model,
				"Greenhouse roof glass",
				Vector3.new(5.4, 0.1, 8),
				gh + Vector3.new(x, 7, 0),
				Color3.fromRGB(188, 214, 199)
			)
			roof.CFrame *= CFrame.Angles(0, 0, if x < 0 then math.rad(22) else math.rad(-22))
			roof.Material = Enum.Material.Glass
			roof.Transparency = 0.82
			roof.CanCollide = false
		end
		for _, x in { -5, 5 } do
			for _, z in { -2, 0, 2 } do
				part(model, "Glass mullion", Vector3.new(0.12, 5.5, 0.12), gh + Vector3.new(x, 3, z), C.cream)
			end
		end
		for j = 1, 12 do
			flower(
				model,
				center + Vector3.new(rng:NextNumber(-26, 26), 0.3, rng:NextNumber(-38, -33)),
				Color3.fromRGB(210 + (j % 3) * 10, 155 + (j % 4) * 12, 150 + (j % 3) * 15)
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
	-- Curated display planters provide a glimpse of the collectible plants on arrival.
	for i = 1, 6 do
		local a = i * math.pi / 3
		local pos = Vector3.new(math.cos(a) * 23, -0.2, math.sin(a) * 23)
		verticalCylinder(
			folder,
			"Terracotta display pot",
			2.2,
			1.5,
			pos + Vector3.new(0, 0.7, 0),
			Color3.fromRGB(154, 106, 81),
			Enum.Material.Brick
		)
		verticalCylinder(
			folder,
			"Pot rim",
			2.4,
			0.25,
			pos + Vector3.new(0, 1.5, 0),
			Color3.fromRGB(174, 125, 94),
			Enum.Material.Brick
		)
		self:model(
			{ id = "Display" .. i, seed = i * 771, mutations = {} },
			catalog.plants[({ 1, 7, 11, 15, 19, 25 })[i]],
			pos + Vector3.new(0, 1.7, 0),
			4,
			folder,
			{ size = 2, color = 0, light = 0 }
		)
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
			7 - math.floor(block / 2) * 15 + math.floor(within / 4) * 4.6
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
	local color = Color3.fromHSV((cfg.hue + phenotype.color * 0.025) % 1, 0.38, 0.84)
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
		if
			name == "Heart"
			and (phenotype.light >= 3 or table.find(plant.mutations, "Glowing") or table.find(plant.mutations, "Neon"))
		then
			p.Material = Enum.Material.Neon
		end
		if table.find(plant.mutations, "Golden") and (name == "Petal" or name == "Bloom") then
			p.Color = Color3.fromRGB(218, 181, 91)
			p.Material = Enum.Material.Metal
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
