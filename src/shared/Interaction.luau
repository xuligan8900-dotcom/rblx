--!strict
-- Presentation decisions only. The server independently validates every action.
local Interaction = {}
function Interaction.resolve(profile: any, cell: number, seed: string, now: number): (string?, any, string)
	for id, plant in profile.plants do
		if plant.cell == cell then
			if plant.progress >= 1 then
				return "Harvest", { id = id }, "harvest"
			end
			if plant.waterUntil > now then
				return nil, {}, "growing_hint"
			end
			return "Water", { id = id }, "water"
		end
	end
	if (profile.seeds[seed] or 0) < 1 then
		return nil, {}, "error_no_seed"
	end
	return "Plant", { id = seed, cell = cell }, "plant"
end
function Interaction.mission(profile: any): string
	local stats = profile.stats or {}
	if (stats.planted or 0) == 0 then
		return "mission_plant"
	end
	if (stats.watered or 0) == 0 then
		return "mission_water"
	end
	if (stats.harvested or 0) == 0 then
		return "mission_harvest"
	end
	if (stats.sold or 0) == 0 then
		return "mission_sell"
	end
	return "mission_experiment"
end
return Interaction
