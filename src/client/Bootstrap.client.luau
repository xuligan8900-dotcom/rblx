--!nocheck
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local Catalog = require(RS:WaitForChild("Shared").Catalog)
local Languages = require(RS.Shared.Localization)
local remote = RS:WaitForChild("GardenRequest")
local language = "en"
local page = "garden"
local profile = nil
local selectedSeed = "p01"
local parents = {}
local busy = false
local effects = true
local gui = Instance.new("ScreenGui")
gui.Name = "MutationGarden"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
local function create(class, parent, props)
	local o = Instance.new(class)
	for k, v in props do
		o[k] = v
	end
	o.Parent = parent
	return o
end
local cream = Color3.fromRGB(244, 238, 214)
local green = Color3.fromRGB(28, 53, 47)
local accent = Color3.fromRGB(183, 221, 144)
local panel = create("Frame", gui, {
	Size = UDim2.new(0.92, 0, 0.72, 0),
	Position = UDim2.fromScale(0.04, 0.24),
	BackgroundColor3 = green,
	BackgroundTransparency = 0.04,
})
create("UICorner", panel, { CornerRadius = UDim.new(0, 18) })
local limit = create("UISizeConstraint", panel, { MaxSize = Vector2.new(1000, 700), MinSize = Vector2.new(260, 180) })
local title = create("TextLabel", gui, {
	Position = UDim2.fromScale(0.04, 0.02),
	Size = UDim2.new(0.7, 0, 0, 35),
	BackgroundTransparency = 1,
	Text = "MUTATION GARDEN",
	TextColor3 = cream,
	TextStrokeTransparency = 0.4,
	Font = Enum.Font.GothamBold,
	TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local status = create("TextLabel", gui, {
	Position = UDim2.fromScale(0.04, 0.09),
	Size = UDim2.new(0.92, 0, 0, 40),
	BackgroundColor3 = green,
	TextColor3 = cream,
	Font = Enum.Font.Gotham,
	TextSize = 15,
	TextWrapped = true,
	Text = Languages.en.loading,
})
local notice = create("TextLabel", panel, {
	Size = UDim2.new(1, -24, 0, 46),
	Position = UDim2.fromOffset(12, 5),
	BackgroundTransparency = 1,
	TextColor3 = accent,
	TextSize = 15,
	TextWrapped = true,
	Font = Enum.Font.Gotham,
	Text = "",
})
local tabs = create("ScrollingFrame", gui, {
	Position = UDim2.fromScale(0.04, 0.17),
	Size = UDim2.new(0.92, 0, 0, 44),
	BackgroundTransparency = 1,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.X,
	ScrollingDirection = Enum.ScrollingDirection.X,
	ScrollBarThickness = 2,
})
create(
	"UIListLayout",
	tabs,
	{ FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }
)
local content = create("ScrollingFrame", panel, {
	Position = UDim2.fromOffset(12, 55),
	Size = UDim2.new(1, -24, 1, -68),
	BackgroundTransparency = 1,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 5,
})
local layout = create("UIListLayout", content, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
local render, request
local function text(s)
	return create("TextLabel", content, {
		Size = UDim2.new(1, -8, 0, 48),
		BackgroundTransparency = 1,
		Text = s,
		TextColor3 = cream,
		Font = Enum.Font.Gotham,
		TextSize = 15,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
end
local function button(parent, s, fn, width)
	local b = create("TextButton", parent, {
		Size = UDim2.new(if width then 0 else 1, if width then width else -8, 0, 44),
		BackgroundColor3 = accent,
		TextColor3 = green,
		Text = s,
		TextSize = 15,
		TextWrapped = true,
		Font = Enum.Font.GothamMedium,
		AutoButtonColor = true,
	})
	create("UICorner", b, { CornerRadius = UDim.new(0, 9) })
	b.Activated:Connect(fn)
	return b
end
local function name(id)
	for _, c in Catalog.plants do
		if c.id == id then
			return c.name
		end
	end
	return id
end
request = function(action, args)
	if busy then
		return
	end
	busy = true
	local ok, result = pcall(function()
		return remote:InvokeServer(action, args or {})
	end)
	busy = false
	if not ok then
		notice.Text = "Connection interrupted. Try again."
		return
	end
	notice.Text = result.message
	if result.profile then
		profile = result.profile
		status.Text = string.format(
			"%d Coins  •  %d RP  •  Level %d  •  %s",
			profile.coins,
			profile.rp,
			1 + math.floor(profile.xp / 50),
			result.weather
		)
		render()
	end
end
local function sorted(t)
	local keys = {}
	for k in t do
		table.insert(keys, k)
	end
	table.sort(keys)
	return keys
end
render = function()
	for _, c in content:GetChildren() do
		if c ~= layout then
			c:Destroy()
		end
	end
	if not profile then
		text(Languages[language].loading)
		return
	end
	local L = Languages[language]
	if page == "garden" then
		local hints = {
			"Choose a seed, then an empty garden cell.",
			"Water your first plant.",
			"Watch it grow, then harvest.",
			"Sell a specimen or keep two matching architectures for the lab.",
			"Cross two specimens in the lab.",
			"Experiment, research and discover all 40 species.",
		}
		text(hints[math.min(6, profile.tutorial)])
		for _, id in sorted(profile.seeds) do
			if profile.seeds[id] > 0 then
				local seed = id
				button(
					content,
					(if selectedSeed == id then "✓ " else "") .. name(id) .. " ×" .. profile.seeds[id],
					function()
						selectedSeed = seed
						render()
					end
				)
			end
		end
		local occupied = {}
		for id, p in profile.plants do
			occupied[p.cell] = id
		end
		for cell = 1, Catalog.expansions[profile.expansion] do
			local index = cell
			local id = occupied[cell]
			if id then
				local plant = profile.plants[id]
				local ready = plant.progress >= 1
				button(
					content,
					string.format(
						"%02d · %s · %d%% · %s",
						cell,
						name(plant.species),
						math.floor(plant.progress * 100),
						if ready then L.harvest else L.water
					),
					function()
						request(if ready then "Harvest" else "Water", { id = id })
					end
				)
			else
				button(content, string.format("%02d · %s %s", cell, L.plant, name(selectedSeed)), function()
					request("Plant", { id = selectedSeed, cell = index })
				end)
			end
		end
	elseif page == "shop" then
		for _, cfg in Catalog.plants do
			local c = cfg
			button(
				content,
				string.format("%s · %s · %d coins · %ds · Lv%d", c.name, c.rarity, c.price, c.seconds, c.level),
				function()
					request("Buy", { id = c.id })
				end
			)
		end
	elseif page == "inventory" then
		text("Tap to select parents. ★ protects from sale and crossing. Sale needs a second tap.")
		button(content, L.cross .. " (" .. #parents .. "/2) · 30 Coins", function()
			if #parents == 2 then
				local a, b = parents[1], parents[2]
				parents = {}
				request("Cross", { id = a, other = b })
			else
				notice.Text = "Select two specimens first"
			end
		end)
		if next(profile.harvest) == nil then
			text("No specimens yet. Harvest your first plant.")
		end
		for _, id in sorted(profile.harvest) do
			local key = id
			local plant = profile.harvest[id]
			button(
				content,
				(if table.find(parents, id) then "✓ " else "")
					.. name(plant.species)
					.. " · "
					.. table.concat(plant.mutations, ", "),
				function()
					local i = table.find(parents, key)
					if i then
						table.remove(parents, i)
					elseif #parents < 2 then
						table.insert(parents, key)
					end
					render()
				end
			)
			button(content, (if plant.favorite then "★ " else "☆ ") .. "Protect / unprotect", function()
				request("Favorite", { id = key })
			end)
			button(content, "Replant in first free cell", function()
				local occupied = {}
				for _, v in profile.plants do
					occupied[v.cell] = true
				end
				for cell = 1, Catalog.expansions[profile.expansion] do
					if not occupied[cell] then
						request("Replant", { id = key, cell = cell })
						return
					end
				end
				notice.Text = "No free cell"
			end)
			local confirm = false
			local b
			b = button(content, L.sell, function()
				if not confirm then
					confirm = true
					b.Text = "Confirm sale"
				else
					request("Sell", { id = key })
				end
			end)
		end
	elseif page == "research" then
		text(
			"Branches: mutation odds, growth, biome unlocks, automated care and sale bonuses. Research each branch in order."
		)
		for _, cfg in Catalog.research do
			local r = cfg
			button(
				content,
				(if profile.research[r.id] then "✓ " else "")
					.. r.id
					.. " · "
					.. r.cost
					.. " RP · requires "
					.. r.requires,
				function()
					request("Research", { id = r.id })
				end
			)
		end
	elseif page == "collection" then
		for _, c in Catalog.plants do
			text(
				if profile.collection[c.id]
					then c.name .. " · " .. c.rarity .. " · " .. Catalog.biomes[c.biome]
					else "??? · " .. Catalog.biomes[c.biome]
			)
		end
	elseif page == "quests" then
		text(
			string.format(
				"Harvest contract: %d / %d. Reward: 75 Coins + 5 RP",
				profile.quest,
				(profile.questClaim + 1) * 5
			)
		)
		button(content, L.claim, function()
			request("Quest", {})
		end)
	elseif page == "settings" then
		button(content, "English / Русский", function()
			language = if language == "en" then "ru" else "en"
			render()
		end)
		button(content, "UI animations: " .. tostring(effects), function()
			effects = not effects
			render()
		end)
		button(content, L.expand .. " · " .. tostring(profile.expansion * 250) .. " Coins", function()
			request("Expand", {})
		end)
		text(
			"Walk around to visit other gardens. Only owners can manage them. Purchases and trading are not enabled in this build."
		)
	end
end
for i, key in { "garden", "shop", "inventory", "research", "collection", "quests", "settings" } do
	local k = key
	local b = button(tabs, Languages.en[key] or "Settings", function()
		page = k
		render()
		if effects then
			panel.BackgroundTransparency = 0.25
			TweenService:Create(panel, TweenInfo.new(0.15), { BackgroundTransparency = 0.04 }):Play()
		end
	end, 110)
	b.LayoutOrder = i
end
button(gui, "☰", function()
	panel.Visible = not panel.Visible
end, 44).Position = UDim2.new(1, -60, 0, 10)
request("Sync", {})
task.spawn(function()
	while gui.Parent do
		task.wait(4)
		if not busy then
			request("Sync", {})
		end
	end
end)
