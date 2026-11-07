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
local tool = "Plant"
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
	Size = UDim2.new(0.34, 0, 0.65, 0),
	AnchorPoint = Vector2.new(1, 0),
	Visible = false,
	Position = UDim2.new(0.98, 0, 0.12, 0),
	BackgroundColor3 = green,
	BackgroundTransparency = 0.04,
})
create("UICorner", panel, { CornerRadius = UDim.new(0, 18) })
local limit = create("UISizeConstraint", panel, { MaxSize = Vector2.new(420, 650), MinSize = Vector2.new(285, 170) })
local title = create("TextLabel", gui, {
	Position = UDim2.fromOffset(20, 8),
	Size = UDim2.new(0.7, 0, 0, 35),
	BackgroundTransparency = 1,
	Text = "MUTATION GARDEN",
	TextColor3 = cream,
	TextStrokeTransparency = 0.4,
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local status = create("TextLabel", gui, {
	Position = UDim2.fromOffset(20, 43),
	Size = UDim2.new(0.86, 0, 0, 34),
	BackgroundColor3 = green,
	TextColor3 = cream,
	Font = Enum.Font.Gotham,
	TextSize = 13,
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
	Position = UDim2.new(0.5, 0, 1, -58),
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.new(0.94, 0, 0, 44),
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
create("UISizeConstraint", tabs, { MaxSize = Vector2.new(710, 44) })
create("UISizeConstraint", status, { MaxSize = Vector2.new(360, 34) })
create("UICorner", status, { CornerRadius = UDim.new(0, 10) })
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
	if action ~= "Sync" then
		notice.Text = result.message
	end
	if result.profile then
		if result.temporary then
			title.Text = "MUTATION GARDEN · LOCAL TEST (NO SAVES)"
		end
		profile = result.profile
		status.Text = (if result.temporary then "Test · " else "")
			.. string.format(
				"%d Coins  ·  %d RP  ·  Lv %d  ·  %s",
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
			"Choose a seed, then click a soil square in the world.",
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
						tool = "Plant"
						panel.Visible = false
						render()
					end
				)
			end
		end
		text(
			"Close this panel and click a soil square in your garden. Use Water while growing, then Harvest when ready."
		)
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
		local same = page == k
		page = k
		panel.Visible = not (same and panel.Visible)
		render()
		if effects then
			panel.BackgroundTransparency = 0.25
			TweenService:Create(panel, TweenInfo.new(0.15), { BackgroundTransparency = 0.04 }):Play()
		end
	end, 95)
	b.LayoutOrder = i
end
button(gui, "Menu", function()
	panel.Visible = not panel.Visible
end, 70).Position = UDim2.new(1, -90, 0, 8)
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local actionbar = create("Frame", gui, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -68),
	Size = UDim2.fromOffset(306, 44),
	BackgroundTransparency = 1,
})
create("UIListLayout", actionbar, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) })
local toolButtons = {}
for _, mode in { "Plant", "Water", "Harvest" } do
	local m = mode
	toolButtons[m] = button(actionbar, m, function()
		tool = m
		panel.Visible = false
	end, 98)
end
local hint = create("TextLabel", gui, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -121),
	Size = UDim2.new(0.85, 0, 0, 32),
	BackgroundTransparency = 1,
	Text = "Choose a tool, then click your garden soil",
	TextColor3 = cream,
	TextStrokeTransparency = 0.25,
	Font = Enum.Font.GothamMedium,
	TextSize = 15,
})
local highlight = Instance.new("Highlight")
highlight.FillTransparency = 0.65
highlight.OutlineColor = accent
highlight.DepthMode = Enum.HighlightDepthMode.Occluded
highlight.Parent = gui
local targetCell = nil
local function targetAt(position)
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end
	local ray = camera:ScreenPointToRay(position.X, position.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = if player.Character then { player.Character } else {}
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 180, params)
	local obj = hit and hit.Instance
	while obj and obj ~= workspace do
		if obj:GetAttribute("Cell") then
			return obj
		end
		obj = obj.Parent
	end
	return nil
end
local function actAt(position)
	if not profile then
		return
	end
	local target = targetAt(position)
	if not target or target:GetAttribute("Owner") ~= player.UserId then
		return
	end
	local cell = target:GetAttribute("Cell")
	local id = nil
	for key, p in profile.plants do
		if p.cell == cell then
			id = key
			break
		end
	end
	if tool == "Plant" and not id then
		request("Plant", { id = selectedSeed, cell = cell })
	elseif id and tool ~= "Plant" then
		request(tool, { id = id })
	else
		hint.Text = if id
			then "This square is occupied. Choose Water or Harvest."
			else "Choose Plant for an empty square."
	end
end
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
		actAt(UserInputService:GetMouseLocation())
	end
end)
UserInputService.TouchTapInWorld:Connect(function(position, processed)
	if not processed then
		actAt(position)
	end
end)
ProximityPromptService.PromptTriggered:Connect(function(pr, who)
	if who ~= player then
		return
	end
	local screen = pr:GetAttribute("GardenScreen")
	if screen then
		page = screen
		panel.Visible = true
		render()
	end
end)
local home = button(gui, "My garden", function()
	request("Home", {})
	panel.Visible = false
end, 110)
home.Position = UDim2.new(1, -130, 0, 62)
task.spawn(function()
	while gui.Parent do
		task.wait(0.12)
		for mode, b in toolButtons do
			b.BackgroundColor3 = if tool == mode then cream else accent
		end
		if not panel.Visible and not UserInputService.TouchEnabled then
			targetCell = targetAt(UserInputService:GetMouseLocation())
			highlight.Adornee = targetCell
			local own = targetCell and targetCell:GetAttribute("Owner") == player.UserId
			highlight.FillColor = if own then accent else Color3.fromRGB(210, 110, 100)
			if targetCell and own and profile then
				local plant = nil
				for _, v in profile.plants do
					if v.cell == targetCell:GetAttribute("Cell") then
						plant = v
						break
					end
				end
				hint.Text = if plant
					then string.format("%s · %d%% · %s", name(plant.species), math.floor(plant.progress * 100), tool)
					else "Plant " .. name(selectedSeed) .. " · Click soil"
			end
		else
			highlight.Adornee = nil
		end
	end
end)
request("Sync", {})
task.spawn(function()
	while gui.Parent do
		task.wait(4)
		if not busy then
			request("Sync", {})
		end
	end
end)
