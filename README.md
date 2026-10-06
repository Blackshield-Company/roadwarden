# Roadwarden

The roads of Skyrim get a little less empty. Roadwarden is a small Skyrim Special Edition mod that adds four rare, level-scaled road encounters: a highwaymen ambush, a merchant in trouble, deserters demanding a toll, and a wounded courier. All four are script-driven and use no world edits.

**Status: v0.1.0, early beta.** It passes every automated check in the build (Papyrus compile, plugin validation, byte-exact round trip, SEQ check, FOMOD schema, cross-mod compatibility check), but nobody has playtested it in game yet. Expect rough edges and please report what you find. See [docs/TESTING.md](docs/TESTING.md).

- Game: Skyrim Special Edition / Anniversary Edition 1.6.x (1.5.97 also works). Runs on Windows, and on Linux through Proton.
- Requirements: just the base game. No SKSE, SkyUI, DLC or Creation Club content.
- Plugin: `Roadwarden.esp`, ESL-flagged, with Skyrim.esm as its only master. **It edits no vanilla records and places nothing in the world.** Encounters are spawned by script and cleaned up after you move on.
- Works with the rest of the series ([Blackshield Company](https://github.com/synthalorian/blackshield-company), [Bounties of Oblivion](https://github.com/synthalorian/bounties-of-oblivion), [Contract Hunter](https://github.com/synthalorian/contract-hunter), [Steel Oath](https://github.com/synthalorian/steel-oath), [Ember Smithing](https://github.com/synthalorian/ember-smithing), [The Gray-Mane Debt](https://github.com/synthalorian/the-gray-mane-debt), [Blackshield Codex](https://github.com/synthalorian/blackshield-codex), [War Banners](https://github.com/synthalorian/war-banners)). It has its own prefix (`RWD_`), records, globals and files, and it is checked by loading all the plugins together (see [tools/modkit](tools/modkit/README.md)).

## The encounters

| Encounter | What happens | Outcome |
|---|---|---|
| **Ambush** | "Footsteps on the road behind you." 2 to 4 highwaymen (leveled bandits, every third one an archer) come up the road after you. | Fight. Loot. |
| **Merchant in trouble** | Someone shouts for help behind you. A traveling merchant is being attacked by highwaymen or a wolf pack. | Kill the attackers and go to the merchant for a reward (`(50 + 10 x level) x 1.5` gold). The merchant can't be killed by the attackers, only by you. |
| **Deserters** | "Hold there, traveler!" A band of Imperial or Stormcloak deserters waits on the road and demands a toll (`50 + 5 x level` gold) when you get close. | **Pay** (they leave), **intimidate** (they leave if your Speech is 50+, otherwise they attack), or **fight**. Attack them first and there is no talk. |
| **Wounded courier** | A faint cry for help. A courier with an arrow wound sits behind you on the road. | Give a healing potion or use a healing spell you know for a reward (`50 + 10 x level` gold), or leave. 40% of the time the attackers come back after you help. |

How many attackers depends on your level: 2 below level 12, 3 from 12, and 4 from 25 (`RWD_MaxHostiles` sets the cap). The actors come from vanilla leveled templates (bandits, Imperial and Stormcloak soldiers, wolves, the world-encounter merchants and road couriers), so they scale with you the same way vanilla encounters do.

## When and where

- **Where:** on the stretch of road you **just traveled**. While you travel outdoors, the mod quietly drops a marker about every 400 units behind you and keeps the last eight. Encounters spawn at one of those markers. Ambushes and merchants start 1500 to 3500 units behind you. Deserters and couriers call out and wait 700 to 1800 units behind you. Every marker is a spot you walked through, so it's reachable ground, out of your line of sight, and not inside a rock.
- **Never** in interiors, cities, towns, settlements, homes, inns, player houses, bandit camps, dungeons or forts. Never during the Helgen opening or while you're in combat, sitting, or have your controls locked by a scene.
- **Rare:** one check a minute while you travel, with a 10% chance per check. There are at least 8 game hours between encounters, and no encounter for 2 minutes after any fight. That works out to roughly one encounter per half hour of travel.
- **Cleanup:** once you're more than 6000 units away (or 4 game hours have passed and you're out of sight), living encounter actors are removed and bodies are flagged so they disappear when their cell unloads.

### With Contract Hunter

Contract Hunter's Blood-Sworn Avengers also appear outdoors, outside towns, and only when you're not in combat. To keep the two from piling up:

- Roadwarden waits `RWD_QuietSeconds` (2 minutes) after **any** fight before it tries an encounter, so it won't fire right after the avengers.
- Roadwarden's hostile encounters put you in combat quickly, and Contract Hunter holds its avengers while you're in combat.
- The two mods don't share any records or globals.

The one case that can still overlap: an hourly avenger check lands while you walk back toward a deserter band or a courier you haven't reached yet. Both encounters then run at the same time. It's survivable, just busy.

### Settings (console)

```
set RWD_Enabled to 0            ; pause new encounters (a running one finishes)
set RWD_ChancePct to 10         ; % chance per check
set RWD_CheckSeconds to 60      ; real seconds between checks (minimum 10)
set RWD_CooldownHours to 8      ; game hours between encounters
set RWD_QuietSeconds to 120     ; real seconds to wait after any fight
set RWD_MinLevel to 3           ; no encounters below this level
set RWD_WeightAmbush to 35      ; relative weights; set one to 0 to turn it off
set RWD_WeightMerchant to 25
set RWD_WeightDeserters to 20
set RWD_WeightCourier to 20
set RWD_MaxHostiles to 4        ; cap on attackers (1-6)
set RWD_LevelMod to 1           ; 0 easy, 1 medium, 2 hard, 3 very hard (vanilla leveled-actor modifier)
set RWD_RewardBase to 50        ; base reward gold (plus 10 per level)
set RWD_TollBase to 50          ; base deserter toll (plus 5 per level)
set RWD_IntimidateSpeech to 50  ; Speech needed to cow the deserters
set RWD_PursuitPct to 40        ; % chance the courier's attackers come back
set RWD_Notify to 1             ; 0 hides the "behind you" hints
set RWD_SpawnMinDist to 1500    ; distances in units
set RWD_SpawnMaxDist to 3500
set RWD_CallMinDist to 700
set RWD_CallMaxDist to 1800
set RWD_TalkDistance to 500
set RWD_CleanupDist to 6000
set RWD_ExpireHours to 4
set RWD_ForceNext to 1          ; debug: 1 ambush, 2 merchant, 3 deserters, 4 courier on the next tick
```

`RWD_EncounterCount` counts the encounters you've had.

## Known issues (early beta)

- Encounters only appear **behind** you. Without the Creation Kit's navmesh tools, the mod can't safely pick unexplored ground ahead of you, so it uses ground you have already walked. If you stand still or move in circles, nothing spawns because there is no marker far enough away.
- The markers follow wherever you walk, roads or not, so a "road" encounter can turn up in the wilderness you just crossed.
- Deserters, merchants and couriers have no AI packages: they stand where they spawned. The merchant runs from the fight (cowardly).
- No voiced lines. The encounter text comes up as notifications and message boxes, so a box can open in the middle of exploring when you walk up to a courier or the deserters.
- The courier's "wound" is 75% of their health taken away, with no injured animation.
- Highwaymen use the vanilla bandit leveled lists, so they look and fight like bandits.

## Building

`./build.sh` on Linux builds the release zip from this repo. Papyrus is compiled with the open-source [papyrus-compiler](https://github.com/russo-2025/papyrus-compiler), the plugin is generated from C# with [Mutagen](https://github.com/Mutagen-Modding/Mutagen), and everything is validated. You need .NET SDK 9+, python3, curl and, optionally, xmllint. See [tools/modkit/README.md](tools/modkit/README.md).

## Layout

```
src/plugin/Roadwarden.Generator/   C# generator (actors, lists, messages, controller quest, settings)
src/plugin/formids.json            pinned FormIDs
src/papyrus/                       controller and player alias scripts
fomod/                             FOMOD installer config
tools/modkit/                      shared build tooling (Mutagen helpers, validator, Papyrus, FOMOD, compat check)
docs/                              design notes, testing checklist, Nexus page
```

## Credits

- Built with [Mutagen](https://github.com/Mutagen-Modding/Mutagen) and [russo-2025/papyrus-compiler](https://github.com/russo-2025/papyrus-compiler).
- All actors are based on vanilla Skyrim.esm templates. The mod ships no Bethesda assets.

## License

MIT (code and text in this repository). See [LICENSE](LICENSE).
