--!nocheck
local Catalog = require("../src/shared/Catalog")
local Genetics = require("../src/shared/Genetics")
local Simulation = require("../src/shared/Simulation")
local Protocol = require("../src/shared/Protocol")
local n = 0
local function test(name, fn)
	fn()
	n += 1
	print("PASS", name)
end
local serial = 0
local function make(roll)
	return Simulation.new(Catalog, Genetics, function()
		return roll or 0.49
	end, function()
		serial += 1
		return "specimen-" .. serial
	end)
end
local sim = make()
local function planted()
	local p = sim.profile()
	assert(sim.act(p, "Plant", { id = "p01", cell = 1 }, 100, "Sunny"))
	return p, next(p.plants)
end
test("40 unique plant records and positive finite economy", function()
	assert(#Catalog.plants == 40)
	local ids = {}
	for _, c in Catalog.plants do
		assert(not ids[c.id])
		ids[c.id] = true
		assert(Catalog.biomes[c.biome])
		for _, k in { "price", "seconds", "value", "yieldCount" } do
			assert(c[k] > 0 and c[k] < math.huge)
		end
	end
end)
test("24 mutation probabilities and bounds", function()
	assert(#Catalog.mutations == 24)
	local p, id = planted()
	local seen = {}
	for _, m in Catalog.mutations do
		assert(not seen[m.id])
		seen[m.id] = true
		local v = sim.probability(m, p.plants[id], p, "Aurora")
		assert(v >= 0 and v <= 0.15)
	end
end)
test("research graph reachable and acyclic", function()
	assert(#Catalog.research == 30)
	local seen = {}
	for _, r in Catalog.research do
		assert(not seen[r.id])
		assert(r.requires == "" or seen[r.requires])
		seen[r.id] = true
	end
end)
test("diploid phenotype dominant allele", function()
	local genome = Genetics.create(function()
		return 0
	end)
	genome.size = { 0, 3 }
	assert(Genetics.phenotype(genome).size == 3)
end)
test("inheritance uses parental alleles without mutation", function()
	local a = Genetics.create(function()
		return 0.26
	end)
	local b = Genetics.create(function()
		return 0.76
	end)
	local child = Genetics.cross(a, b, function()
		return 0.49
	end)
	for _, g in Genetics.genes do
		assert(child[g][1] == 1 and child[g][2] == 3)
	end
end)
test("full plant water grow harvest sell cycle", function()
	local p, id = planted()
	assert(p.seeds.p01 == 5)
	assert(sim.act(p, "Water", { id = id }, 101, "Sunny"))
	sim.advance(p, 200, false)
	assert(p.plants[id].progress == 1)
	assert(sim.act(p, "Harvest", { id = id }, 200, "Sunny"))
	assert(p.harvest[id] and not p.plants[id])
	local coins = p.coins
	assert(sim.act(p, "Sell", { id = id }, 201, "Sunny"))
	assert(p.coins > coins and p.rp == 6 and p.collection.p01)
end)
test("repeated harvest and sale cannot duplicate", function()
	local p, id = planted()
	assert(sim.act(p, "Harvest", { id = id }, 200, "Sunny"))
	assert(not sim.act(p, "Harvest", { id = id }, 201, "Sunny"))
	assert(sim.act(p, "Sell", { id = id }, 202, "Sunny"))
	local coins = p.coins
	assert(not sim.act(p, "Sell", { id = id }, 203, "Sunny"))
	assert(p.coins == coins)
end)
test("foreign or nonexistent plant IDs rejected", function()
	local p = sim.profile()
	assert(not sim.act(p, "Water", { id = "foreign" }, 100, "Sunny"))
	assert(not sim.act(p, "Harvest", { id = "foreign" }, 100, "Sunny"))
end)
test("placement bounds and occupancy", function()
	local p = planted()
	assert(not sim.act(p, "Plant", { id = "p01", cell = 1 }, 101, "Sunny"))
	assert(not sim.act(p, "Plant", { id = "p01", cell = 13 }, 101, "Sunny"))
	assert(not sim.act(p, "Plant", { id = "p01", cell = 0 / 0 }, 101, "Sunny"))
end)
test("offline cap and clock rollback", function()
	local c = table.clone(Catalog)
	c.offlineCap = 1
	local s = Simulation.new(c, Genetics, function()
		return 0
	end, function()
		return "id"
	end)
	local p = s.profile()
	s.act(p, "Plant", { id = "p01", cell = 1 }, 100, "Sunny")
	s.advance(p, 100000, true)
	assert(p.plants.id.progress < 0.1)
	local progress = p.plants.id.progress
	s.advance(p, 1, false)
	assert(p.plants.id.progress == progress)
end)
test("water settles old interval before changing conditions", function()
	local p, id = planted()
	sim.act(p, "Water", { id = id }, 110, "Sunny")
	local progress = p.plants[id].progress
	assert(progress > 0 and progress < 1)
	sim.advance(p, 115, false)
	assert(p.plants[id].progress > progress)
end)
test("purchase and unlock guards", function()
	local p = sim.profile()
	assert(sim.act(p, "Buy", { id = "p01" }, 100, "Sunny"))
	assert(p.seeds.p01 == 7 and p.coins == 92)
	assert(not sim.act(p, "Buy", { id = "p26" }, 100, "Sunny"))
	p.coins = 0
	assert(not sim.act(p, "Buy", { id = "p01" }, 100, "Sunny"))
end)
test("cross consumes parents once; child genome can be replanted", function()
	local p, a = planted()
	sim.act(p, "Plant", { id = "p01", cell = 2 }, 100, "Sunny")
	local b
	for id in p.plants do
		if id ~= a then
			b = id
		end
	end
	sim.act(p, "Harvest", { id = a }, 200, "Sunny")
	sim.act(p, "Harvest", { id = b }, 200, "Sunny")
	assert(sim.act(p, "Cross", { id = a, other = b }, 201, "Sunny"))
	assert(not p.harvest[a] and not p.harvest[b])
	local child = next(p.harvest)
	assert(child)
	assert(not sim.act(p, "Cross", { id = a, other = b }, 202, "Sunny"))
	assert(sim.act(p, "Replant", { id = child, cell = 1 }, 202, "Sunny"))
	assert(p.plants[child].progress == 0)
end)
test("favorites protect unique specimens", function()
	local p, id = planted()
	sim.act(p, "Harvest", { id = id }, 200, "Sunny")
	sim.act(p, "Favorite", { id = id }, 200, "Sunny")
	assert(not sim.act(p, "Sell", { id = id }, 200, "Sunny"))
	assert(not sim.act(p, "Replant", { id = id, cell = 1 }, 200, "Sunny"))
end)
test("all research can be bought once in order", function()
	local p = sim.profile()
	p.rp = 10000
	for _, r in Catalog.research do
		assert(sim.act(p, "Research", { id = r.id }, 100, "Sunny"))
		assert(not sim.act(p, "Research", { id = r.id }, 100, "Sunny"))
	end
	assert(sim.biome(p) == 6)
end)
test("quest repeated claims require new progress", function()
	local p = sim.profile()
	assert(not sim.act(p, "Quest", {}, 100, "Sunny"))
	p.quest = 5
	assert(sim.act(p, "Quest", {}, 100, "Sunny"))
	assert(not sim.act(p, "Quest", {}, 100, "Sunny"))
end)
test("request schema rejects NaN infinity extras oversized and nested input", function()
	for _, cell in { 0 / 0, math.huge, -1, 0, 97, 1.5 } do
		assert(not Protocol.valid("Plant", { id = "p01", cell = cell }))
	end
	assert(not Protocol.valid("Buy", { id = "p01", coins = 100 }))
	assert(not Protocol.valid("Buy", { id = {} }))
	assert(not Protocol.valid("Buy", { id = string.rep("x", 65) }))
	assert(not Protocol.valid("InventCoins", {}))
	assert(Protocol.valid("Plant", { id = "p01", cell = 1 }))
end)
test("profile rejects corrupted values and unsupported versions", function()
	local p = sim.profile()
	assert(sim.validate(p))
	p.coins = 0 / 0
	assert(not sim.validate(p))
	p.coins = 100
	p.version = 999
	assert(not sim.validate(p))
	local q, id = planted()
	q.plants[id].genome.size = { 99, 1 }
	assert(not sim.validate(q))
end)
test("seeded pure results repeat", function()
	local a = Genetics.create(function()
		return 0.4
	end)
	local b = Genetics.create(function()
		return 0.4
	end)
	for _, g in Genetics.genes do
		assert(a[g][1] == b[g][1] and a[g][2] == b[g][2])
	end
end)
test("768 plant analytical workload", function()
	for _ = 1, 8 do
		local p = sim.profile()
		p.expansion = 5
		p.seeds.p01 = 96
		for i = 1, 96 do
			assert(sim.act(p, "Plant", { id = "p01", cell = i }, 100, "Sunny"))
		end
		sim.advance(p, 200, false)
		for _, plant in p.plants do
			assert(plant.progress == 1)
		end
	end
end)
print(string.format("%d tests passed", n))
