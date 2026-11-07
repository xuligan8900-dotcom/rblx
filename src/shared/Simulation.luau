--!nocheck
-- Pure authoritative state transitions. No yields, network, instances or client time.
local S = {}
function S.new(catalog, genetics, random, uuid)
	local api = {}
	local species = {}
	for _, c in catalog.plants do
		species[c.id] = c
	end
	local function count(t)
		local n = 0
		for _ in t do
			n += 1
		end
		return n
	end
	function api.profile()
		return {
			version = 1,
			coins = 100,
			rp = 0,
			xp = 0,
			seeds = { p01 = 6, p02 = 4 },
			plants = {},
			harvest = {},
			research = {},
			collection = {},
			quest = 0,
			questClaim = 0,
			expansion = 1,
			lastExperiment = 0,
			tutorial = 1,
			settings = { language = "auto", effects = true },
			savedAt = 0,
			stats = { planted = 0, watered = 0, harvested = 0, sold = 0 },
		}
	end
	function api.validate(p)
		if type(p) ~= "table" or p.version ~= 1 then
			return false
		end
		for _, k in { "coins", "rp", "xp", "quest", "questClaim", "expansion", "lastExperiment", "tutorial", "savedAt" } do
			if type(p[k]) ~= "number" or p[k] ~= p[k] or p[k] < 0 or p[k] == math.huge then
				return false
			end
		end
		if p.expansion % 1 ~= 0 or p.expansion < 1 or p.expansion > 5 then
			return false
		end
		for _, k in { "seeds", "plants", "harvest", "research", "collection", "settings" } do
			if type(p[k]) ~= "table" then
				return false
			end
		end
		if
			p.settings.language ~= nil
			and p.settings.language ~= "en"
			and p.settings.language ~= "ru"
			and p.settings.language ~= "auto"
		then
			return false
		end
		if p.settings.effects ~= nil and type(p.settings.effects) ~= "boolean" then
			return false
		end
		for id, n in p.seeds do
			if not species[id] or type(n) ~= "number" or n < 0 or n % 1 ~= 0 or n > 10000 then
				return false
			end
		end
		for _, group in { p.plants, p.harvest } do
			if count(group) > catalog.inventoryCap then
				return false
			end
			for id, plant in group do
				if
					type(id) ~= "string"
					or type(plant) ~= "table"
					or not species[plant.species]
					or type(plant.genome) ~= "table"
				then
					return false
				end
				for _, g in genetics.genes do
					local pair = plant.genome[g]
					if type(pair) ~= "table" then
						return false
					end
					for i = 1, 2 do
						local v = pair[i]
						if type(v) ~= "number" or v % 1 ~= 0 or v < 0 or v > 3 then
							return false
						end
					end
				end
				for _, k in { "progress", "updated", "waterUntil", "cell", "seed" } do
					local v = plant[k]
					if type(v) ~= "number" or v ~= v or v < 0 or v == math.huge then
						return false
					end
				end
				if plant.id ~= id or plant.progress > 1 or plant.cell % 1 ~= 0 or plant.cell > 96 then
					return false
				end
				if
					group == p.harvest
					and (
						type(plant.amount) ~= "number"
						or plant.amount % 1 ~= 0
						or plant.amount < 1
						or plant.amount > 100
					)
				then
					return false
				end
				if type(plant.mutations) ~= "table" then
					return false
				end
				local seen = {}
				for _, m in plant.mutations do
					local known = false
					for _, cfg in catalog.mutations do
						if cfg.id == m then
							known = true
						end
					end
					if not known or seen[m] then
						return false
					end
					seen[m] = true
				end
				if #plant.mutations > 3 or (seen.Giant and seen.Miniature) then
					return false
				end
			end
		end
		if p.stats ~= nil then
			if type(p.stats) ~= "table" then
				return false
			end
			for _, k in { "planted", "watered", "harvested", "sold" } do
				local v = p.stats[k]
				if type(v) ~= "number" or v < 0 or v % 1 ~= 0 or v == math.huge then
					return false
				end
			end
		end
		for _, plant in p.plants do
			if
				plant.baseSeconds ~= nil
				and (
					type(plant.baseSeconds) ~= "number"
					or plant.baseSeconds <= 0
					or plant.baseSeconds > species[plant.species].seconds
					or plant.baseSeconds ~= plant.baseSeconds
				)
			then
				return false
			end
		end
		local cells = {}
		for _, plant in p.plants do
			if plant.cell < 1 or plant.cell > catalog.expansions[p.expansion] or cells[plant.cell] then
				return false
			end
			cells[plant.cell] = true
		end
		return true
	end
	function api.level(p)
		return 1 + math.floor(p.xp / 50)
	end
	function api.biome(p)
		local n = 1
		for i = 1, 5 do
			if p.research["Botany" .. i] then
				n = i + 1
			end
		end
		return n
	end
	function api.advance(p, now, offline)
		for _, plant in p.plants do
			local c = species[plant.species]
			local ph = genetics.phenotype(plant.genome)
			local dt = math.max(0, now - plant.updated)
			if offline then
				dt = math.min(dt, catalog.offlineCap)
			end
			local wet = math.clamp(plant.waterUntil - plant.updated, 0, dt)
			-- Each automation tier improves a specific part of unattended care.
			if p.research.Automation1 then
				wet = dt * 0.25
			end
			if p.research.Automation2 then
				wet = dt * 0.5
			end
			if p.research.Automation3 then
				wet = dt * 0.75
			end
			if p.research.Automation4 then
				wet = dt
			end
			local bonus = 0
			for i = 1, 6 do
				if p.research["Cultivation" .. i] then
					bonus += 0.06
				end
			end
			local speed = 1
				+ ph.speed * 0.1
				+ bonus
				+ (if p.research.Automation5 then 0.1 else 0)
				+ (if p.research.Automation6 then 0.15 else 0)
			for _, m in plant.mutations do
				for _, cfg in catalog.mutations do
					if cfg.id == m then
						speed *= cfg.growth
					end
				end
			end
			plant.progress = math.min(1, plant.progress + (dt + wet * 0.4) * speed / (plant.baseSeconds or c.seconds))
			plant.updated = math.max(plant.updated, now)
		end
	end
	function api.price(plant)
		local bonus = 1
		for _, m in plant.mutations do
			for _, cfg in catalog.mutations do
				if cfg.id == m then
					bonus += cfg.value
				end
			end
		end
		local c = species[plant.species]
		local ph = genetics.phenotype(plant.genome)
		return math.floor(c.value * plant.amount * math.min(4, bonus) * (1 + ph.size * 0.05))
	end
	function api.probability(m, plant, p, weather)
		if m.biome ~= 0 and m.biome ~= species[plant.species].biome then
			return 0
		end
		local ph = genetics.phenotype(plant.genome)
		local research = 1
		for i = 1, 6 do
			if p.research["Genetics" .. i] then
				research += 0.15
			end
		end
		return math.clamp(
			m.probability
				* (1 + ph.affinity * 0.1)
				* (1 - ph.resistance * 0.08)
				* (if weather == "Aurora" then 1.5 else 1)
				* research,
			0,
			0.15
		)
	end
	function api.act(p, action, args, now, weather)
		api.advance(p, now, false)
		p.stats = p.stats or { planted = 0, watered = 0, harvested = 0, sold = 0 }
		if action == "Buy" then
			local c = species[args.id]
			if not c or c.biome > api.biome(p) or c.level > api.level(p) then
				return false, "error_species_locked"
			end
			if p.coins < c.price or (p.seeds[c.id] or 0) >= 10000 then
				return false, "error_coins_stack"
			end
			p.coins -= c.price
			p.seeds[c.id] = (p.seeds[c.id] or 0) + 1
		elseif action == "Plant" then
			local c = species[args.id]
			local cell = args.cell
			if
				not c
				or type(cell) ~= "number"
				or cell % 1 ~= 0
				or cell < 1
				or cell > catalog.expansions[p.expansion]
				or c.biome > api.biome(p)
			then
				return false, "error_planting"
			end
			if (p.seeds[c.id] or 0) < 1 then
				return false, "error_no_seed"
			end
			for _, v in p.plants do
				if v.cell == cell then
					return false, "error_cell_occupied"
				end
			end
			local id = uuid()
			p.seeds[c.id] -= 1
			p.plants[id] = {
				id = id,
				species = c.id,
				cell = cell,
				genome = genetics.create(random),
				mutations = {},
				seed = math.floor(random() * 1000000),
				baseSeconds = if p.stats.planted < 3 then math.min(12, c.seconds) else c.seconds,
				progress = 0,
				updated = now,
				waterUntil = 0,
			}
			p.stats.planted += 1
			p.tutorial = math.max(p.tutorial, 2)
		elseif action == "Replant" then
			local plant = p.harvest[args.id]
			local cell = args.cell
			if
				not plant
				or plant.favorite
				or type(cell) ~= "number"
				or cell % 1 ~= 0
				or cell < 1
				or cell > catalog.expansions[p.expansion]
			then
				return false, "error_specimen_cell"
			end
			for _, v in p.plants do
				if v.cell == cell then
					return false, "error_cell_occupied"
				end
			end
			p.harvest[args.id] = nil
			p.plants[args.id] = plant
			plant.cell = cell
			plant.progress = 0
			plant.updated = math.max(plant.updated, now)
			plant.waterUntil = 0
			plant.baseSeconds = species[plant.species].seconds
			plant.watered = nil
			plant.amount = nil
		elseif action == "Water" then
			local plant = p.plants[args.id]
			if not plant then
				return false, "error_plant_missing"
			end
			if not plant.watered then
				p.stats.watered += 1
				plant.watered = true
			end
			plant.waterUntil = now + 120
			p.tutorial = math.max(p.tutorial, 3)
		elseif action == "Harvest" then
			local plant = p.plants[args.id]
			if not plant or plant.progress < 1 or count(p.harvest) >= catalog.inventoryCap then
				return false, "error_harvest"
			end
			local selected = table.clone(plant.mutations)
			local total = 0
			for _, m in catalog.mutations do
				total += api.probability(m, plant, p, weather)
			end
			local roll = random() * math.max(1, total)
			for _, m in catalog.mutations do
				roll -= api.probability(m, plant, p, weather)
				if roll < 0 then
					if
						#selected < 3
						and not table.find(selected, m.id)
						and not (
							(m.id == "Giant" and table.find(selected, "Miniature"))
							or (m.id == "Miniature" and table.find(selected, "Giant"))
						)
					then
						table.insert(selected, m.id)
					end
					break
				end
			end
			plant.mutations = selected
			plant.amount = species[plant.species].yieldCount
				+ math.floor(genetics.phenotype(plant.genome)["yield"] * 0.5)
			if table.find(selected, "Giant") then
				plant.amount += 2
			end
			p.plants[args.id] = nil
			p.harvest[args.id] = plant
			p.stats.harvested += 1
			p.xp += 10
			p.quest += 1
			if not p.collection[plant.species] then
				p.collection[plant.species] = true
				p.rp += (if p.research.Botany6 then 8 else 5)
			end
			p.rp += 1
			p.tutorial = math.max(p.tutorial, 4)
		elseif action == "Sell" then
			local plant = p.harvest[args.id]
			if not plant or plant.favorite then
				return false, "error_protected"
			end
			local bonus = 0
			for i = 1, 6 do
				if p.research["Economy" .. i] then
					bonus += 0.04
				end
			end
			p.coins = math.min(1e9, p.coins + math.floor(api.price(plant) * (1 + bonus)))
			p.harvest[args.id] = nil
			p.stats.sold += 1
			p.tutorial = math.max(p.tutorial, 5)
		elseif action == "SellAll" then
			local bonus = 0
			for i = 1, 6 do
				if p.research["Economy" .. i] then
					bonus += 0.04
				end
			end
			local countSold = 0
			local total = 0
			for id, plant in p.harvest do
				if not plant.favorite then
					total += math.floor(api.price(plant) * (1 + bonus))
					p.harvest[id] = nil
					countSold += 1
				end
			end
			if countSold == 0 then
				return false, "error_nothing_sell"
			end
			p.coins = math.min(1e9, p.coins + total)
			p.stats.sold += countSold
			p.tutorial = math.max(p.tutorial, 5)
			return true, "sold_all"
		elseif action == "Favorite" then
			local plant = p.harvest[args.id]
			if not plant then
				return false, "error_plant_missing"
			end
			plant.favorite = not plant.favorite
		elseif action == "Cross" then
			local a, b = p.harvest[args.id], p.harvest[args.other]
			if not a or not b or a == b or a.favorite or b.favorite or p.coins < 30 or now - p.lastExperiment < 15 then
				return false, "error_cross_requirements"
			end
			if species[a.species].archetype ~= species[b.species].archetype then
				return false, "error_incompatible"
			end
			local id = uuid()
			local child = {
				id = id,
				species = if random() < 0.5 then a.species else b.species,
				genome = genetics.cross(a.genome, b.genome, random),
				mutations = {},
				seed = math.floor(random() * 1000000),
				progress = 1,
				updated = now,
				waterUntil = 0,
				cell = 0,
				amount = 1,
			}
			p.harvest[a.id] = nil
			p.harvest[b.id] = nil
			p.harvest[id] = child
			p.coins -= 30
			p.rp += 3
			p.lastExperiment = now
			p.tutorial = 6
		elseif action == "Research" then
			local cfg = nil
			for _, r in catalog.research do
				if r.id == args.id then
					cfg = r
				end
			end
			if
				not cfg
				or p.research[cfg.id]
				or p.rp < cfg.cost
				or (cfg.requires ~= "" and not p.research[cfg.requires])
			then
				return false, "error_research"
			end
			p.rp -= cfg.cost
			p.research[cfg.id] = true
		elseif action == "Expand" then
			local cost = p.expansion * 250
			if p.expansion >= 5 or p.coins < cost then
				return false, "error_expansion"
			end
			p.coins -= cost
			p.expansion += 1
		elseif action == "Settings" then
			if args.id == "language" and (args.value == "ru" or args.value == "en") then
				p.settings.language = args.value
				p.settings.languageChosen = true
			elseif args.id == "effects" and (args.value == "on" or args.value == "off") then
				p.settings.effects = args.value == "on"
			else
				return false, "error_settings"
			end
		elseif action == "Quest" then
			local goal = (p.questClaim + 1) * 5
			if p.quest < goal then
				return false, "error_quest"
			end
			p.questClaim += 1
			p.coins += 75
			p.rp += 5
		else
			return false, "error_action"
		end
		return true, "done"
	end
	return api
end
return S
