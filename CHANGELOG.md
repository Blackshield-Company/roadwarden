# Changelog

All notable changes to this project are documented here. Versions follow [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-10-06

Early beta. First public release. It passes every automated check in the build (Papyrus compile, plugin validation, round trip, SEQ check, FOMOD schema, cross-mod compatibility check) but has not been playtested in game yet. Please report problems on the Nexus page or on GitHub.

### Added
- Four road encounters. Each one spawns on the stretch of road you just traveled, outdoors, outside cities, towns, homes, camps, dungeons and forts, and never while you are in combat:
  - **Ambush:** highwaymen come up the road behind you.
  - **Merchant in trouble:** a traveling merchant is attacked by highwaymen or wolves. Save them and they pay you.
  - **Deserters:** a band of Imperial or Stormcloak deserters demands a toll. Pay, intimidate them (Speech 50), or fight.
  - **Wounded courier:** heal them with a potion or a healing spell for a reward. Sometimes the attackers come back.
- Encounters scale with your level: leveled bandit, soldier and wolf templates, plus 2 to 4 attackers depending on your level.
- Encounters are rare (one check a minute while you travel, 10% chance, 8 game hours of cooldown) and wait 2 minutes after any fight.
- About 26 console globals for frequency, distances, rewards, difficulty and a debug trigger (`RWD_ForceNext`).
- `SEQ/Roadwarden.seq` for the Start Game Enabled controller quest.
- FOMOD installer with optional Papyrus sources.
