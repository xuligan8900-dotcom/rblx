--!strict
local Protocol = {}
local fields: { [string]: { string } } = {
	Buy = { "id" },
	Plant = { "id", "cell" },
	Water = { "id" },
	Replant = { "id", "cell" },
	Harvest = { "id" },
	Sell = { "id" },
	SellAll = {},
	Favorite = { "id" },
	Cross = { "id", "other" },
	Research = { "id" },
	Expand = {},
	Quest = {},
	Sync = {},
	Home = {},
	Settings = { "id", "value" },
}
function Protocol.valid(action: any, args: any): boolean
	if type(action) ~= "string" or type(args) ~= "table" then
		return false
	end
	local allowed = fields[action]
	if not allowed then
		return false
	end
	local seen = 0
	for k, v in args do
		seen += 1
		if seen > 2 or type(k) ~= "string" or not table.find(allowed, k) then
			return false
		end
		if k == "cell" then
			if type(v) ~= "number" or v ~= v or v % 1 ~= 0 or v < 1 or v > 96 then
				return false
			end
		elseif type(v) ~= "string" or #v < 1 or #v > 64 then
			return false
		end
	end
	for _, k in allowed do
		if args[k] == nil then
			return false
		end
	end
	return true
end
return Protocol
