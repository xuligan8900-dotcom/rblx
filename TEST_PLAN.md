# Test plan and actual report

## PASS — executed in Linux

`python3 tools/check.py` runs Luau compilation for every source file, StyLua check, 20 domain tests, and Rojo place build. Test names are printed by the runner. Coverage includes catalog counts/references, research reachability, dominance/inheritance, plant–water–grow–harvest–sell, duplicate harvest/sale, foreign IDs, bounds, offline cap, old-interval settling, locked stock, consuming hybrid parents, preserving offspring for replanting, favorites, research, quest claims, malformed schemas, corrupted profiles, deterministic genetics, and 768 plants across eight logical profiles. The workload test verifies results, not frame rate.

## NOT RUN — Roblox Studio required

1. Open the built place, use Start Server with two clients, inspect Output for errors. Confirm spawning, all six zones, buildings and garden ownership. Verify 40 shop entries and all tabs at mobile and desktop sizes.
2. Plant, water, wait, harvest, sell; cross two Flower specimens and replant the child. Confirm same IDs and genome survive a private-universe save/rejoin.
3. Attempt to send the other player's plant ID, edit currency locally, send nil/nested/NaN fields, and flood the remote. Confirm no foreign mutation or extra rewards.
4. Stop/rejoin normally; simulate API outage during load/save, overlap sessions, force a hard server stop and wait for lease expiry. Check no default profile overwrite. Test BindToClose with eight profiles.
5. Fill 8×96 cells, profile on real low-end phones and PC. Measure replication, instance count, frame time and UI response. No FPS claim is made.
6. Grow in all five stages; check nine archetypes, no collision traps, streaming re-entry, touch/gamepad menu controls and readable Russian strings.

## NOT IMPLEMENTED / NOT RUN

Trade reservation/commit and crash recovery, receipt idempotency, product grants, historical migrations, daily/weekly rotation, full tutorial skipping and persistent preferences. Do not treat absent tests as passing or publish monetization/trading without those systems.

## Local Studio mode regression

Three additional mocked-service checks execute the real Profiles source: unpublished Studio makes zero DataStore calls and resets on rejoin; published Studio and live servers select DataStore; published API failures do not fall back to temporary profiles. These are not Roblox integration tests. Actual Studio mode and HUD remain NOT RUN here.

## World interaction redesign checks

PASS: four mocked-world checks for all 96 cell positions inside plot bounds, ownership attributes and stage-only rebuilds, construction of all 40 species at five stages, and plot release cleanup. Existing 20 domain and 3 profile mode checks still pass (27 total).

NOT RUN: rendered appearance, actual raycast coordinates at different GUI insets, mouse/touch interaction and Highlight display, proximity prompts, garden spawn/camera, and mobile drawer layout. In Studio, open the new file, Play, confirm spawn at owned plot, choose Plant then click nearby soil, switch to Water and finally Harvest. Verify another player's beds cannot be changed and long-distance farming fails. Confirm My garden works from the hub and respawn returns to the assigned plot. Check each shop counter and all old menus.

## Localization regression

PASS: EN/RU key parity for 203 entries, matching format arguments, coverage of all current catalogs and locale detection; validated server-side preference updates; actual client script callbacks under UI/service mocks update tabs, controls, shop, world labels and prompts in both directions. These are not visual Studio tests. Total current test groups: 30.

NOT RUN: open v4 in Studio, press RU, verify every menu and world prompt, return to EN, test two clients with different languages, check narrow-screen wrapping, then verify manual selection survives a real DataStore save/rejoin. Local unpublished sessions intentionally reset settings. Review Future lighting, detailed-leaf trees, Terrain perimeter hills and runtime costs on actual devices. No graphical acceptance is claimed.
