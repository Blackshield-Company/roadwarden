# Changelog

All notable changes to this project are documented here. Versions follow [Semantic Versioning](https://semver.org/).

## [0.1.2] - 2026-10-29

Still early beta and still not playtested in game.

### Fixed
- An ambush could fire on the College of Winterhold grounds (by the statue) and in other populated places whose location is not tagged City, Town, Settlement or Dwelling. These are now excluded explicitly, together with every location inside them.
- Markers dropped before the update (or before you walked into an excluded place) are checked again when a spot is picked, so an old marker in a town or by the College can no longer be used.

### Added
- `RWD_AvoidLocations` form list (Skyrim.esm): College of Winterhold, Winterhold, Dawnstar, Morthal, Falkreath, Riverwood, Solitude (and the Solitude docks, sawmill, Katla's Farm and stables), Windhelm, Whiterun, Markarth and Riften (and their stables), Sky Haven Temple, High Hrothgar, Ivarstead, Rorikstead, Dragon Bridge, Karthwasten, Shor's Stone, Kynesgrove and Old Hroldan.
- Fort Dawnguard (Dawnguard.esm) and Raven Rock, Thirsk Mead Hall, Skaal Village and Tel Mithryn (Dragonborn.esm), looked up by FormID at runtime, so the plugin still has Skyrim.esm as its only master.
- `RWD_TownRadius` (default 2500 units): no encounters this close to the map markers outside Whiterun, Solitude, Windhelm, Markarth, Riften, Winterhold and the College. `set RWD_TownRadius to 0` turns it off.
- With `RWD_Debug 1`, a location reject now names the rule: `keyword`, `location list` or `near town`.

## [0.1.1] - 2026-10-10

Still early beta and still not playtested in game; this release targets reports of "installed, never saw an event".

### Fixed
- Riding a horse no longer blocks encounters. The sit check now ignores being mounted (`IsOnMount`), so mounted travel counts.
- Encounters were filtered out of large stretches of road. Locations tagged Habitation, Dungeon, Bandit Camp or Military Fort are no longer excluded (their outdoor areas cover much of the road network); interiors are still always excluded, as are cities, towns, settlements, dwellings and player houses.

### Changed
- More frequent: one check every 45 seconds (was 60) with a 15% chance (was 10%), and 4 game hours between encounters (was 8). If an existing save still shows the old values (`show RWD_ChancePct`), set `RWD_CheckSeconds 45`, `RWD_ChancePct 15`, `RWD_CooldownHours 4` to match.
- Description: spawn distance is about 20 to 50 m (10 to 25 m for deserters and the courier); fast travel and carriages never trigger encounters.

### Added
- "Roadwarden active" notification and a Papyrus log line when the controller starts and on every save load, with the current settings.
- `RWD_Debug` (default 0): set to 1 to log every check and why it was skipped (combat, sitting, location, controls, Helgen, level, quiet period, cooldown, failed roll, no marker in range).

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
