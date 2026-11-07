# Game design

Cozy, decision-driven farming and a small diploid genetics sandbox. English is primary; Russian core UI keys are centralized. Original primitive geometry and generated colors avoid dependencies on third party models.

The first loop starts with 100 Coins, six Sunny Daisy and four Mint Sprout seeds. Grow (25 seconds base for the first species), water for +40% speed during the wet interval, harvest a unique specimen, sell it or preserve it for experimentation. First discoveries grant 5 RP, every harvest 1 RP. Each five harvests unlocks the next contract reward. XP unlocks higher-level shop stock.

Each genome contains eight paired integer alleles in [0,3]. Allele 3 dominates; others express their mean. Each offspring inherits one allele from each parent with a 2.5% per-gene random edit. Parents require matching procedural archetypes and are consumed. This is a game model, not a biology simulation.

Research has five linear six-tier branches. Cultivation adds 6% growth per tier, Economy 4% sale value per tier, Genetics adds 15% relative mutation odds per tier. Botany I–V unlock biome stock and VI raises discovery RP from 5 to 8. Automation I–IV grant 25/50/75/100% wet coverage; V–VI add 10/15% growth. These are the initial effects, not all equipment from the full specification.

Species have nine visual archetypes. Progression expands 12 → 24 → 48 → 72 → 96 cells. Gardens support eight owners. Growth does not kill plants and offline progress is capped at eight hours.

Mutation candidates have biome eligibility and bounded, normalized selection. Maximum three retained mutations; Giant and Miniature conflict. A harvest rolls at most one new mutation. Bonus values add and cap at 4×. Giant adds yield and size; Miniature reduces size; Frozen slows growth and Solar speeds it. Other mutations currently share a neon visual treatment and differ in odds/value/biome; bespoke effects are pending.
