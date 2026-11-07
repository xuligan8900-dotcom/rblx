--!strict
local G = {}
G.genes = { "color", "size", "speed", "yield", "resistance", "affinity", "light", "stability" }
export type Genome = { [string]: { number } }
function G.create(random: () -> number): Genome
	local genome = {}
	for _, key in G.genes do
		genome[key] = { math.floor(random() * 4), math.floor(random() * 4) }
	end
	return genome
end
function G.phenotype(genome: Genome): { [string]: number }
	local result = {}
	for _, key in G.genes do
		local pair = genome[key]
		-- Allele 3 dominates; other combinations express their mean.
		result[key] = if pair[1] == 3 or pair[2] == 3 then 3 else (pair[1] + pair[2]) / 2
	end
	return result
end
function G.cross(a: Genome, b: Genome, random: () -> number): Genome
	local result = {}
	for _, key in G.genes do
		local pair = { a[key][if random() < 0.5 then 1 else 2], b[key][if random() < 0.5 then 1 else 2] }
		if random() < 0.025 then
			pair[if random() < 0.5 then 1 else 2] = math.floor(random() * 4)
		end
		result[key] = pair
	end
	return result
end
return G
