--!nocheck
local C = require("../src/shared/Catalog")
local G = require("../src/shared/Genetics")
local I = require("../src/shared/Interaction")
local n = 0
local sim = require("../src/shared/Simulation").new(C, G, function()
	return 0.5
end, function()
	n += 1
	return "id" .. n
end)
local p = sim.profile()
assert(I.mission(p) == "mission_plant")
local action, args = I.resolve(p, 1, "p01", 100)
assert(action == "Plant" and sim.act(p, action, args, 100, "Sunny"))
assert(I.mission(p) == "mission_water")
local id = next(p.plants)
assert(p.plants[id].baseSeconds == 12)
action, args = I.resolve(p, 1, "p01", 100)
assert(action == "Water" and sim.act(p, action, args, 100, "Sunny"))
assert(I.mission(p) == "mission_harvest")
assert(I.resolve(p, 1, "p01", 101) == nil)
assert(p.stats.watered == 1)
assert(sim.act(p, "Water", { id = id }, 102, "Sunny"))
assert(p.stats.watered == 1, "Repeated watering must not fake onboarding progress")
sim.advance(p, 113, false)
action, args = I.resolve(p, 1, "p01", 113)
assert(action == "Harvest" and sim.act(p, action, args, 113, "Sunny"))
assert(I.mission(p) == "mission_sell")
local before = p.coins
assert(sim.act(p, "SellAll", {}, 114, "Sunny"))
assert(p.coins > before and p.stats.sold == 1 and I.mission(p) == "mission_experiment")
local after = p.coins
assert(not sim.act(p, "SellAll", {}, 114, "Sunny"))
assert(p.coins == after and p.stats.sold == 1)
print("PASS first session: contextual planting, one-time water goal, early harvest, bulk sale and next goal")
-- Favorite specimens survive the bulk operation and every specimen is counted once.
for i = 1, 3 do
	assert(sim.act(p, "Plant", { id = "p01", cell = i }, 120, "Sunny"))
end
local protected
for key, plant in p.plants do
	if not protected then
		protected = key
		assert(sim.act(p, "Water", { id = key }, 120, "Sunny"))
	end
end
sim.advance(p, 300, false)
local ids = {}
for key in p.plants do
	table.insert(ids, key)
end
for _, key in ids do
	assert(sim.act(p, "Harvest", { id = key }, 300, "Sunny"))
end
assert(sim.act(p, "Favorite", { id = protected }, 300, "Sunny"))
local expected = 0
for key, plant in p.harvest do
	if key ~= protected then
		expected += sim.price(plant)
	end
end
before = p.coins
assert(sim.act(p, "SellAll", {}, 300, "Sunny"))
assert(p.coins == before + expected and p.harvest[protected] and p.stats.sold == 3)
assert(not sim.act(p, "SellAll", {}, 300, "Sunny"))
assert(sim.validate(p))
print("PASS bulk sale preserves favorites, exact pricing and no duplicate payouts")
local legacy = sim.profile()
legacy.stats = nil
assert(sim.validate(legacy))
assert(sim.act(legacy, "Plant", { id = "p01", cell = 1 }, 100, "Sunny"))
assert(legacy.stats.planted == 1)
legacy.stats.sold = -1
assert(not sim.validate(legacy))
print("PASS older profiles acquire onboarding stats; invalid counters rejected")
