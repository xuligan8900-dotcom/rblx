--!nocheck
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local Catalog = require(RS:WaitForChild("Shared").Catalog)
local Languages = require(RS.Shared.Localization)
local Interaction = require(RS.Shared.Interaction)
local remote = RS:WaitForChild("GardenRequest")
local language = Languages.language(player.LocaleId)
local function tr(key, ...)
	return Languages.text(language, key, ...)
end
local lastWeather = "Sunny"
local temporary = false
local lastNotice = "ready"
local refreshChrome
local toolButtons, tabButtons = {}, {}
local menuButton, home, hint, languageButton, toast, mission, seedButton, sellButton
local feedback
local currentSlot
local localizationLoaded = false
local page = "garden"
local tool = "Auto"
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
local accent = Color3.fromRGB(181, 197, 170)
local panel = create("Frame", gui, {
	Size = UDim2.new(0.34, 0, 0.65, 0),
	AnchorPoint = Vector2.new(1, 0),
	Visible = false,
	Position = UDim2.new(0.98, 0, 0.12, 0),
	BackgroundColor3 = green,
	BackgroundTransparency = 0.04,
})
create("UICorner", panel, { CornerRadius = UDim.new(0, 14) })
create("UIStroke", panel, { Color = Color3.fromRGB(157, 174, 149), Transparency = 0.45, Thickness = 1 })
local limit = create("UISizeConstraint", panel, { MaxSize = Vector2.new(420, 650), MinSize = Vector2.new(285, 170) })
local title = create("TextLabel", gui, {
	Position = UDim2.fromOffset(20, 8),
	Size = UDim2.new(0.7, 0, 0, 35),
	BackgroundTransparency = 1,
	Text = tr("title"),
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
	Text = tr("loading"),
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
	create("UIStroke", b, { Color = Color3.fromRGB(85, 110, 87), Transparency = 0.6, Thickness = 1 })
	b.Activated:Connect(fn)
	return b
end
local function name(id)
	return tr(id)
end
local function mutations(list)
	local names = {}
	for _, id in list do
		table.insert(names, tr(id))
	end
	return table.concat(names, ", ")
end
request = function(action, args)
	if busy then
		return
	end
	busy = true
	local priorPlant = profile and args and args.id and profile.plants[args.id]
	local feedbackCell = if args and args.cell then args.cell elseif priorPlant then priorPlant.cell else nil
	local ok, result = pcall(function()
		return remote:InvokeServer(action, args or {})
	end)
	busy = false
	if not ok then
		lastNotice = "network_error"
		notice.Text = tr(lastNotice)
		return
	end
	if action ~= "Sync" or not result.ok then
		lastNotice = result.message
	end
	if result.profile then
		profile = result.profile
		if not localizationLoaded then
			localizationLoaded = true
			if
				profile.settings.languageChosen
				and (profile.settings.language == "ru" or profile.settings.language == "en")
			then
				language = profile.settings.language
			end
		end
		effects = profile.settings.effects ~= false
		temporary = result.temporary
		lastWeather = result.weather
		currentSlot = result.slot or currentSlot
		if action == "Sync" and panel.Visible then
			if refreshChrome then
				refreshChrome()
			end
		else
			render()
		end
		if result.ok and feedback then
			feedback(action, feedbackCell)
		end
	end
	notice.Text = tr(lastNotice)
	if toast and action ~= "Sync" then
		local message = tr(lastNotice)
		toast.Text = message
		task.delay(5, function()
			if toast.Text == message then
				toast.Text = ""
			end
		end)
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
local function switchLanguage()
	if busy then
		return
	end
	language = if language == "en" then "ru" else "en"
	render()
	request("Settings", { id = "language", value = language })
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
	if refreshChrome then
		refreshChrome()
	end
	if page == "garden" then
		text(tr("tutorial" .. math.clamp(profile.tutorial, 1, 6)))
		for _, id in sorted(profile.seeds) do
			if profile.seeds[id] > 0 then
				local seed = id
				button(
					content,
					(if selectedSeed == id then "✓ " else "") .. name(id) .. " ×" .. profile.seeds[id],
					function()
						selectedSeed = seed
						tool = "Auto"
						panel.Visible = false
						render()
					end
				)
			end
		end
		text(tr("garden_help"))
	elseif page == "shop" then
		for _, cfg in Catalog.plants do
			local c = cfg
			button(content, tr("shop_item", name(c.id), tr(c.rarity), c.price, c.seconds, c.level), function()
				request("Buy", { id = c.id })
			end)
		end
	elseif page == "inventory" then
		text(tr("inventory_help"))
		button(content, tr("cross_cost", L.cross, #parents), function()
			if #parents == 2 then
				local a, b = parents[1], parents[2]
				parents = {}
				request("Cross", { id = a, other = b })
			else
				notice.Text = tr("select_parents")
			end
		end)
		if next(profile.harvest) == nil then
			text(tr("inventory_empty"))
		end
		for _, id in sorted(profile.harvest) do
			local key = id
			local plant = profile.harvest[id]
			button(
				content,
				(if table.find(parents, id) then "✓ " else "")
					.. name(plant.species)
					.. " · "
					.. mutations(plant.mutations),
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
			button(content, (if plant.favorite then "★ " else "☆ ") .. tr("protect"), function()
				request("Favorite", { id = key })
			end)
			button(content, tr("replant"), function()
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
				notice.Text = tr("no_cell")
			end)
			local confirm = false
			local b
			b = button(content, L.sell, function()
				if not confirm then
					confirm = true
					b.Text = tr("confirm_sale")
				else
					request("Sell", { id = key })
				end
			end)
		end
	elseif page == "research" then
		text(tr("research_help"))
		for _, cfg in Catalog.research do
			local r = cfg
			button(
				content,
				(if profile.research[r.id] then "✓ " else "")
					.. tr("research_item", tr(r.id), r.cost, if r.requires == "" then tr("none") else tr(r.requires)),
				function()
					request("Research", { id = r.id })
				end
			)
		end
	elseif page == "collection" then
		for _, c in Catalog.plants do
			text(
				if profile.collection[c.id]
					then name(c.id) .. " · " .. tr(c.rarity) .. " · " .. tr(Catalog.biomes[c.biome])
					else "??? · " .. tr(Catalog.biomes[c.biome])
			)
		end
	elseif page == "quests" then
		text(tr("quest_progress", profile.quest, (profile.questClaim + 1) * 5))
		button(content, L.claim, function()
			request("Quest", {})
		end)
	elseif page == "settings" then
		button(content, tr("language"), switchLanguage)
		button(content, tr("animations", tr(if effects then "on" else "off")), function()
			request("Settings", { id = "effects", value = if effects then "off" else "on" })
		end)
		button(content, tr("expand_cost", L.expand, profile.expansion * 250), function()
			request("Expand", {})
		end)
		text(tr("visit_help"))
	end
end
for i, key in { "garden", "shop", "inventory", "research", "collection", "quests", "settings" } do
	local k = key
	local b = button(tabs, tr(key), function()
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
	tabButtons[key] = b
end
menuButton = button(gui, tr("menu"), function()
	panel.Visible = not panel.Visible
end, 70)
menuButton.Position = UDim2.new(1, -90, 0, 8)
languageButton = button(gui, "RU", switchLanguage, 60)
languageButton.Position = UDim2.new(1, -158, 0, 8)
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local actionbar = create("Frame", gui, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -68),
	Size = UDim2.new(0.95, 0, 0, 44),
	BackgroundTransparency = 1,
})
create("UIListLayout", actionbar, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) })

create("UISizeConstraint", actionbar, { MaxSize = Vector2.new(380, 44) })
toolButtons.Auto = button(actionbar, tr("auto"), function()
	tool = "Auto"
	panel.Visible = false
end, 98)
seedButton = button(actionbar, tr("choose_seed"), function()
	page = "garden"
	panel.Visible = true
	render()
end, 130)
sellButton = button(actionbar, tr("sell_all"), function()
	request("SellAll", {})
end, 135)
mission = create("TextLabel", gui, {
	Position = UDim2.fromOffset(20, 85),
	Size = UDim2.fromOffset(320, 78),
	Text = tr("mission_plant"),
	TextColor3 = cream,
	BackgroundColor3 = green,
	BackgroundTransparency = 0.1,
	Font = Enum.Font.GothamMedium,
	TextSize = 15,
	TextWrapped = true,
})
create("UICorner", mission, { CornerRadius = UDim.new(0, 10) })

hint = create("TextLabel", gui, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -121),
	Size = UDim2.new(0.85, 0, 0, 32),
	BackgroundTransparency = 1,
	Text = tr("tool_hint"),
	TextColor3 = cream,
	TextStrokeTransparency = 0.25,
	Font = Enum.Font.GothamMedium,
	TextSize = 15,
})
toast = create("TextLabel", gui, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 84),
	Size = UDim2.new(0.8, 0, 0, 42),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = cream,
	TextStrokeTransparency = 0.2,
	TextWrapped = true,
	TextSize = 16,
	Font = Enum.Font.GothamMedium,
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
	local action, args, key = Interaction.resolve(profile, cell, selectedSeed, os.time())
	if action then
		request(action, args)
	else
		hint.Text = tr(key)
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
home = button(gui, tr("home"), function()
	request("Home", {})
	panel.Visible = false
end, 110)
home.Position = UDim2.new(1, -130, 0, 62)
local function localizeWorldObject(obj)
	if obj:IsA("TextLabel") and obj:GetAttribute("LocaleKey") then
		local arg = obj:GetAttribute("LocaleArg")
		obj.Text = if arg then tr(obj:GetAttribute("LocaleKey"), arg) else tr(obj:GetAttribute("LocaleKey"))
	elseif obj:IsA("ProximityPrompt") and obj:GetAttribute("GardenScreen") then
		obj.ObjectText = tr("station_" .. obj:GetAttribute("GardenScreen"))
		obj.ActionText = tr("open")
	end
end
local function refreshWorld()
	local world = workspace:FindFirstChild("MutationGarden")
	if world then
		for _, obj in world:GetDescendants() do
			localizeWorldObject(obj)
		end
	end
end
local worldLanguage = nil
refreshChrome = function()
	title.Text = tr("title") .. (if temporary then " · " .. tr("local_test") else "")
	status.Text = tr("status", profile.coins, profile.rp, 1 + math.floor(profile.xp / 50), tr(lastWeather))
	notice.Text = tr(lastNotice)
	menuButton.Text = tr("menu")
	languageButton.Text = if language == "ru" then "EN" else "RU"
	home.Text = tr("home")
	for key, b in tabButtons do
		b.Text = tr(key)
	end
	for mode, b in toolButtons do
		b.Text = tr(string.lower(mode))
	end
	hint.Text = tr("tool_hint")
	mission.Text = tr(Interaction.mission(profile))
	seedButton.Text = tr("choose_seed")
	sellButton.Text = tr("sell_all")
	if worldLanguage ~= language then
		worldLanguage = language
		refreshWorld()
	end
end
local function watchWorld(obj)
	if obj:IsA("TextLabel") then
		obj:GetAttributeChangedSignal("LocaleKey"):Connect(function()
			localizeWorldObject(obj)
		end)
		obj:GetAttributeChangedSignal("LocaleArg"):Connect(function()
			localizeWorldObject(obj)
		end)
	end
	task.defer(localizeWorldObject, obj)
end
local world = workspace:WaitForChild("MutationGarden")
for _, obj in world:GetDescendants() do
	watchWorld(obj)
end
world.DescendantAdded:Connect(watchWorld)
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
				local _, _, actionKey =
					Interaction.resolve(profile, targetCell:GetAttribute("Cell"), selectedSeed, os.time())
				hint.Text = if plant
					then tr("hover_growing", name(plant.species), math.floor(plant.progress * 100), tr(actionKey))
					else tr("hover_plant", name(selectedSeed))
			end
		else
			highlight.Adornee = nil
		end
	end
end)
feedback = function(action, cell)
	if
		not effects
		or not cell
		or not currentSlot
		or (action ~= "Plant" and action ~= "Water" and action ~= "Harvest")
	then
		return
	end
	local plot = world:FindFirstChild("Garden" .. currentSlot)
	local soil = plot and plot:FindFirstChild("Soil" .. cell)
	if not soil then
		return
	end
	local origin = soil.Position
	for i = 1, 6 do
		local p = Instance.new("Part")
		p.Name = "GardenFeedback"
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(0.16, 0.25, 0.16)
		p.Color = if action == "Water"
			then Color3.fromRGB(116, 195, 225)
			elseif action == "Harvest" then Color3.fromRGB(232, 203, 123)
			else Color3.fromRGB(151, 185, 120)
		local angle = i * math.pi / 3
		p.Position = origin
			+ Vector3.new(math.cos(angle) * 0.8, if action == "Water" then 2.5 else 0.7, math.sin(angle) * 0.8)
		p.Parent = workspace
		TweenService:Create(
			p,
			TweenInfo.new(0.6),
			{ Position = p.Position + Vector3.new(0, if action == "Water" then -2 else 1.8, 0), Transparency = 1 }
		):Play()
		game:GetService("Debris"):AddItem(p, 0.7)
	end
end
request("Sync", {})
task.spawn(function()
	while gui.Parent do
		task.wait(1)
		if not busy then
			request("Sync", {})
		end
	end
end)
