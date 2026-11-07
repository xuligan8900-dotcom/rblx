--!nocheck
local L = require("../src/shared/Localization")
local C = require("../src/shared/Catalog")
local sim = require("../src/shared/Simulation").new(C, require("../src/shared/Genetics"), function()
	return 0.5
end, function()
	return "id"
end)
local P = require("../src/shared/Protocol")
local count = 0
for key, value in L.en do
	assert(type(value) == "string" and #value > 0)
	assert(type(L.ru[key]) == "string" and #L.ru[key] > 0, "Missing Russian translation: " .. key)
	local a, b = {}, {}
	for token in string.gmatch(value, "%%[ds]") do
		table.insert(a, token)
	end
	for token in string.gmatch(L.ru[key], "%%[ds]") do
		table.insert(b, token)
	end
	assert(table.concat(a) == table.concat(b), "Placeholder mismatch: " .. key)
	count += 1
end
for key in L.ru do
	assert(L.en[key], "Missing English translation: " .. key)
end
assert(L.language("ru-RU") == "ru" and L.language("RU-ru") == "ru" and L.language("en-us") == "en")
assert(L.text("ru", "plant") == "Посадить")
assert(L.text("ru", "owner_garden", "Иван") == "Сад игрока Иван")
for _, c in C.plants do
	assert(L.ru[c.id] and L.en[c.id])
end
for _, c in C.mutations do
	assert(L.ru[c.id] and L.en[c.id])
end
for _, c in C.research do
	assert(L.ru[c.id] and L.en[c.id])
end
for _, c in C.biomes do
	assert(L.ru[c] and L.en[c])
end
for _, c in C.weather do
	assert(L.ru[c] and L.en[c])
end
print("PASS language key parity, placeholders, locale detection and every catalog entry (" .. count .. " keys)")
local p = sim.profile()
local coins = p.coins
assert(P.valid("Settings", { id = "language", value = "ru" }))
assert(sim.act(p, "Settings", { id = "language", value = "ru" }, 100, "Sunny"))
assert(p.settings.language == "ru" and p.settings.languageChosen and sim.validate(p))
assert(sim.act(p, "Settings", { id = "effects", value = "off" }, 100, "Sunny"))
assert(not p.settings.effects and p.coins == coins)
assert(not sim.act(p, "Settings", { id = "language", value = "bad" }, 100, "Sunny"))
assert(not sim.act(p, "Settings", { id = "coins", value = "999" }, 100, "Sunny"))
assert(not P.valid("Settings", { id = "language", value = {} }))
assert(p.settings.language == "ru" and p.coins == coins)
print("PASS language/effect preferences persist in the profile; invalid values and currency edits rejected")
