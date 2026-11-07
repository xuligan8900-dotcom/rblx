--!nocheck
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Profiles = {}
Profiles.__index = Profiles
function Profiles.new(sim)
	local temporary = game:GetService("RunService"):IsStudio() and game.GameId == 0
	local store = nil
	if temporary then
		warn("LOCAL STUDIO TEST: unpublished place; progress is temporary and resets when testing stops.")
	else
		store = DataStoreService:GetDataStore("MutationGarden_v1")
	end
	return setmetatable({
		store = store,
		temporary = temporary,
		sim = sim,
		loaded = {},
		token = game.JobId .. HttpService:GenerateGUID(false),
		busy = {},
	}, Profiles)
end
function Profiles:load(player)
	if self.temporary then
		local p = self.sim.profile()
		self.loaded[player] = p
		return p
	end
	local key = tostring(player.UserId)
	local now = os.time()
	local accepted = false
	local ok, record = pcall(function()
		return self.store:UpdateAsync(key, function(old)
			accepted = false
			if old and old.lock and old.lock.token ~= self.token and old.lock.expires > now then
				return nil
			end
			local data = if old then old.data else self.sim.profile()
			if not self.sim.validate(data) then
				return nil
			end
			accepted = true
			return { data = data, lock = { token = self.token, expires = now + 180 } }
		end)
	end)
	if not ok or not accepted or not record then
		return nil
	end
	local p = record.data
	self.sim.advance(p, now, true)
	self.loaded[player] = p
	return p
end
function Profiles:save(player, release)
	if self.temporary then
		if not self.loaded[player] then
			return false
		end
		if release then
			self.loaded[player] = nil
		end
		-- Successful temporary-state lifecycle, not a durable save.
		return true
	end
	if self.busy[player] then
		return false
	end
	local p = self.loaded[player]
	if not p then
		return false
	end
	self.busy[player] = true
	local snapshot = HttpService:JSONDecode(HttpService:JSONEncode(p))
	snapshot.savedAt = os.time()
	local wrote = false
	local ok = pcall(function()
		self.store:UpdateAsync(tostring(player.UserId), function(old)
			wrote = false
			if not old or not old.lock or old.lock.token ~= self.token then
				return nil
			end
			wrote = true
			return { data = snapshot, lock = if release then nil else { token = self.token, expires = os.time() + 180 } }
		end)
	end)
	self.busy[player] = nil
	if release and ok and wrote then
		self.loaded[player] = nil
	end
	return ok and wrote
end
return Profiles
