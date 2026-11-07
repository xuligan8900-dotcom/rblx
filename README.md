# Mutation Garden: Genetic Paradise

An initial playable Roblox/Rojo source project. This is an implementation increment, not the complete production release described in SPECIFICATION.md. Roblox runtime QA has not been executed.

## Tools and build

Linux x86_64, Python 3, curl. Pinned Rojo 7.6.1, Luau 0.699 and StyLua 2.1.0. No runtime third party packages. Archive SHA-256 hashes are pinned in tools/bootstrap.py. Downloads retain TLS verification.

```sh
cd /workspace/rblx
python3 tools/bootstrap.py
python3 tools/check.py
.tools/bin/rojo serve default.project.json
```

Open `build/MutationGarden.rbxlx` in Roblox Studio, or install the official matching Rojo Studio plugin and connect to Rojo on port 34872. No Roblox asset IDs are required. On other operating systems install the same vendor tool versions for that platform; bootstrap.py targets Linux only.

**Quick local play:** open the built place and press Play. In an unpublished place running inside Studio only, progress is temporary and the HUD displays `LOCAL TEST · NO SAVES`. No publication or API access is needed for that mode. Stopping the session resets the garden. Published places and live servers never fall back to temporary profiles.

For DataStore testing publish a **private test experience** and enable Game Settings → Security → Enable Studio Access to API Services. Use a test universe, never production data. Set maximum server size to 8 in experience settings. API failure intentionally prevents loading rather than silently issuing a replacement profile. Start a server with two clients from Studio's Test controls. See TEST_PLAN.md.

Use the Garden tab to choose seeds, plant into numbered cells, water and harvest. Buy seeds in Seeds. Sell or protect specimens in Specimens; select two with matching architecture to cross for 30 Coins. Parents are consumed. Replant a specimen to grow its inherited genome. Research spends RP; quests reward accumulated harvest milestones. Settings expands the garden. Close the panel to walk around. Other gardens are visible but cannot be modified through this API.

## Layout

- `src/shared`: catalog, diploid genetics, pure state transitions, request schemas, localization keys.
- `src/server`: profile leases, procedural world/plant factory, lifecycle and network boundary.
- `src/client`: adaptive scrolling UI, menu input and state presentation.
- `tests/run.luau`: executable Luau tests without a Roblox dependency.
- `tools`: verified tool bootstrap, full check runner, catalog authoring mirror.
- `build/MutationGarden.rbxlx`: generated place (ignored in Git).

No external secrets or runtime backend is needed. No paid purchases are offered. See DEVELOPMENT_PROGRESS.md for missing features. Only local Git commits are created; no push or publication is performed.

## Garden interaction update

The HUD now opens with the world visible. Select Plant/Water/Harvest in the bottom toolbar, walk to your own raised bed and click a soil square. Plant uses the seed selected in Garden. Hover shows a cell highlight and growth progress. Touch taps are wired to the same action, but mobile runtime QA is pending. Menu tabs open a compact right drawer. Store counters open menus with Roblox ProximityPrompts. My garden returns your character to its assigned plot; respawns are also assigned there. Farming requests check distance on the server; shop and research menus remain usable around the hub.

The world now has framed greenhouses, garden fences/hedges, raised-bed edges, trees, flowers, pathways, a fountain and walk-in shop buildings. This is procedural primitive art, not a Studio-verified final art pass.

The latest art revision is in downloads/MutationGarden-v3.zip (open MutationGarden-v3.rbxlx). It uses built-in Roblox limestone/sandstone/plaster/wood/glass/fabric materials, softer foliage and a consistent botanical-garden palette. Source rebuilds still produce build/MutationGarden.rbxlx. Review the actual rendering in Studio; automated tests are not visual acceptance.
