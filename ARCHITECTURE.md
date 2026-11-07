# Architecture

Dependency direction: Catalog/Genetics/Protocol → injected Simulation → server lifecycle or client presentation. World and Profiles are explicitly constructed by Bootstrap; no circular requires.

The client sends only action names and identifiers. Protocol rejects unexpected keys, nested values, oversized strings and nonfinite/out-of-grid cells. A server token bucket permits 4 requests/second with a burst of 12, including polling. Only the player's server-loaded profile is exposed to operations; client currency, genomes, owners, timestamps and random outcomes are never accepted. Mutating requests additionally require presence near the owner's garden.

Simulation transitions do not yield: validation, debits, inventory moves, rewards and unique ID allocation occur in one server turn. Repeated harvest/sell requests fail because the source item is gone. Buy is intentionally repeatable: each accepted request purchases and charges one seed. A failed internal transition pauses the profile pending reconnect; transactional rollback on unexpected code defects is not implemented.

Profiles use DataStore UpdateAsync, a unique session token and a 180-second lease. The 60-second autosave renews it. A new server cannot acquire a live lease. Saves reject a changed token. Shutdown and departure save/release with bounded retries. Snapshot cloning occurs before the yielding save. Failed loads and unsupported/corrupt versions fail closed. v1 is the only schema: no historical migration is claimed. Current last-unsaved progress can be lost on a hard crash; this is not a transaction journal.

One 2-second scheduler advances all plants analytically. Water changes settle previous growth first. Model reconstruction happens only on stage changes. Seeded Random drives model layout. Anchored parts avoid physics simulation. Workspace streaming is enabled. No custom LOD, pooling or per-device effects budget is implemented yet.

All RemoteFunction data is server-generated. No outbound analytics, payment handling or third party services exist in this increment. Runtime logic is mostly marked nocheck pending Roblox-aware static type analysis; Genetics and Protocol use strict mode. Compilation is syntax validation, not full type checking.
