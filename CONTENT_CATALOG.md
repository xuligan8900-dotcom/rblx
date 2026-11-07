# Content catalog

Canonical runtime source: `src/shared/Catalog.luau`. `tools/catalog.json` is an authoring mirror, not a runtime dependency. Keep both synchronized when editing; regenerate the balance table deliberately. The catalog contains 40 species, 24 mutations, six biome labels, eight weather labels and 30 sequential research records.

Species records define identity, price, base duration, yield, value, palette, required level, biome and one of nine model architectures. Species IDs remain stable across saves. Mutation IDs are stable English names; each includes probability, biome, value and size/growth/yield metadata. Runtime supports a subset of bespoke visual modifiers; see DEVELOPMENT_PROGRESS.md. The six biome environments currently differ in primitive decoration/palette; audio and custom ambience remain pending.

To add content: assign a unique permanent ID, define positive finite economy values, connect unlocks, extend Catalog if needed, test its reference graph, add model support if introducing an archetype, rebuild, then run Studio tests. Never reuse an old species ID for different content in existing player saves. No external asset IDs are used.
