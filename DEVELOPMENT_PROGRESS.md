# Development progress

## Implemented increment

Rojo project; pinned downloadable tools; executable test runner; eight procedural gardens with 12–96 soil cells; plaza and six stylized biome areas; nine seeded plant architectures; five growth stages; seeds, shop locks, watering, bounded offline growth, unique harvested specimens, protected favorites, sales; eight diploid genes, consuming hybridization and replanting; 40 species, 24 mutation rolls, 30 research entries with effects; harvest contracts, XP, discovery book; server-validated requests and throttling; DataStore leases/autosave/shutdown; English UI and a partial Russian key set.

## Verified

20 pure Luau tests PASS, source syntax compilation PASS, StyLua PASS, Rojo place build PASS. Tool installation executed with pinned checksums. Roblox Studio runtime, DataStore, multiplayer, mobile layout and actual performance NOT RUN.

## Remaining against SPECIFICATION.md

This is **not** a completed implementation of all twelve phases. Missing: safe durable player trading, paid cosmetics and receipt ledger, decorations placement/move/delete, garden permission controls, grid ghost preview and raycast planting, biome portals/access barriers and unlock rewards, full climate/soil/fertilizer/pest systems and visible automation equipment, six live events, meaningful effects for every weather type, hybrid recipes, special effects for each mutation, mutation collection history, daily/weekly quests/achievements/expeditions, full research graph UI, specimen previews/search/filter/bulk inventory operations, persistent settings/tutorial skip, sound assets and sound controller, full localization, analytics, custom LOD and device profiling, migration fixtures, Roblox runtime integration/security/save failure tests. All 40 species currently use nine archetypes rather than bespoke art per species. UI consolidates the laboratory in Specimens rather than 18 complete screens.

Next: Studio smoke test and persistence/failure tests first; then small reviewed increments for remaining mechanics. Do not enable trading or payments until their failure recovery is implemented and tested.
