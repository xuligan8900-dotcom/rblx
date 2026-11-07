--!nocheck
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Shared = RS:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Genetics = require(Shared.Genetics)
local Protocol = require(Shared.Protocol)
local Localization = require(Shared.Localization)
local rng = Random.new()
local sim = require(Shared.Simulation).new(Catalog, Genetics, function()
	return rng:NextNumber()
end, function()
	return HttpService:GenerateGUID(false)
end)
local profiles = require(script.Parent.Profiles).new(sim)
local function playerText(player, key)
	local p = profiles.loaded[player]
	local language = if p and p.settings.languageChosen
		then p.settings.language
		else Localization.language(player.LocaleId)
	return Localization.text(language, key)
end
local world = require(script.Parent.World).new(Catalog)
local remote = Instance.new("RemoteFunction")
remote.Name = "GardenRequest"
remote.Parent = RS
local slots = {}
local rates = {}
local safe = {}
local closing = false
local weather = "Sunny"
local weatherUntil = os.time() + 300
local function teleport(player, character)
	local slot = slots[player]
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root and slot then
		local center = world.plots[slot].center
		character:PivotTo(CFrame.lookAt(center + Vector3.new(0, 5, 18), center + Vector3.new(-10, 3, -12)))
	end
end
local function join(player)
	if closing then
		player:Kick(playerText(player, "kick_closing"))
		return
	end
	local p = profiles:load(player)
	if not p then
		player:Kick(playerText(player, "kick_load"))
		return
	end
	if player.Parent ~= Players then
		profiles:save(player, true)
		return
	end
	local slot = world:claim(player)
	if not slot then
		profiles:save(player, true)
		player:Kick(playerText(player, "kick_full"))
		return
	end
	slots[player] = slot
	safe[player] = true
	player.CharacterAdded:Connect(function(c)
		teleport(player, c)
	end)
	if player.Character then
		task.spawn(teleport, player, player.Character)
	end
	world:render(slot, p, sim, Genetics)
end
local function leave(player)
	safe[player] = nil
	-- Wait for an in-flight autosave before final save; only our own bounded operation.
	local deadline = os.clock() + 20
	while profiles.busy[player] and os.clock() < deadline do
		task.wait(0.1)
	end
	local saved = false
	for _ = 1, 3 do
		if profiles:save(player, true) then
			saved = true
			break
		end
		task.wait(1)
	end
	if not saved then
		warn("Garden save failed; session lease will expire", player.UserId)
	end
	if slots[player] then
		world:release(slots[player])
		slots[player] = nil
	end
	profiles.loaded[player] = nil
	rates[player] = nil
end
remote.OnServerInvoke = function(player, action, args)
	local t = os.clock()
	local rate = rates[player] or { tokens = 12, time = t }
	rates[player] = rate
	rate.tokens = math.min(12, rate.tokens + (t - rate.time) * 4)
	rate.time = t
	if rate.tokens < 1 then
		return { ok = false, message = "error_rate" }
	end
	rate.tokens -= 1
	if not Protocol.valid(action, args) then
		return { ok = false, message = "error_request" }
	end
	local p = profiles.loaded[player]
	if closing or not p or not safe[player] or not slots[player] then
		return { ok = false, message = "error_unavailable" }
	end
	local farming = action == "Plant" or action == "Replant" or action == "Water" or action == "Harvest"
	if farming then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local cell = args.cell
		if not cell then
			local plant = p.plants[args.id]
			cell = plant and plant.cell
		end
		if not root or (cell and (root.Position - world:cell(world.plots[slots[player]], cell)).Magnitude > 25) then
			return { ok = false, message = "error_distance" }
		end
	end
	local ok, message = true, "ready"
	if action == "Home" then
		if player.Character then
			teleport(player, player.Character)
		end
	elseif action ~= "Sync" then
		local success, a, b = pcall(sim.act, p, action, args, os.time(), weather)
		if not success then
			warn("Garden action failed", action, a)
			safe[player] = nil
			return { ok = false, message = "error_paused" }
		end
		ok, message = a, b
	else
		sim.advance(p, os.time(), false)
	end
	world:render(slots[player], p, sim, Genetics)
	return {
		ok = ok,
		message = message,
		profile = p,
		slot = slots[player],
		weather = weather,
		weatherUntil = weatherUntil,
		temporary = profiles.temporary,
	}
end
Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(leave)
for _, p in Players:GetPlayers() do
	task.spawn(join, p)
end
-- One scheduler per server; growth is analytical, models rebuild only on stage changes.
task.spawn(function()
	local nextSave = os.time() + 60
	while not closing do
		task.wait(2)
		local now = os.time()
		if now >= weatherUntil then
			weather = Catalog.weather[rng:NextInteger(1, #Catalog.weather)]
			weatherUntil = now + 300
		end
		for player, p in profiles.loaded do
			if slots[player] and safe[player] then
				sim.advance(p, now, false)
				if weather == "Rain" then
					for _, plant in p.plants do
						plant.waterUntil = now + 4
					end
				end
				world:render(slots[player], p, sim, Genetics)
				if now >= nextSave then
					task.spawn(function()
						if not profiles:save(player, false) then
							safe[player] = nil
							player:Kick(playerText(player, "kick_save"))
						end
					end)
				end
			end
		end
		if now >= nextSave then
			nextSave = now + 60
		end
	end
end)
game:BindToClose(function()
	closing = true
	local pending = 0
	for _, player in Players:GetPlayers() do
		pending += 1
		task.spawn(function()
			leave(player)
			pending -= 1
		end)
	end
	local deadline = os.clock() + 28
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)
