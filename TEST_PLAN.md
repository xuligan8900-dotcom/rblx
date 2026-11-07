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
