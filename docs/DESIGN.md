# Design notes (v0.1, early beta)

## Records (55, FormIDs 0x800-0x836, ESL-flagged, Skyrim.esm only, no overrides)

| EditorID | Type | Purpose |
|---|---|---|
| `RWD_RoadQuest` | QUST (Start Game Enabled, Run Once) | Controller (`RWD_RoadScript`). Alias 0 = player (`RWD_PlayerAliasScript`: resets the real-time clock on load). In `SEQ/Roadwarden.seq`. |
| `RWD_Highwayman`, `RWD_HighwayArcher` | NPC_ | Template `LCharBanditMeleeAny` / `LCharBanditMissile`, everything but the name from the template. |
| `RWD_DeserterImperial`, `RWD_DeserterSons` | NPC_ | Template `LCharSoldierImperial` / `LCharSoldierSons` for traits, stats, spells, gear, attack data and keywords. They have their own name, the `RWD_DeserterFaction` faction, unaggressive AI and no packages, so they don't carry the soldier factions (guards and soldiers don't take sides). |
| `RWD_MerchantM`, `RWD_MerchantF` | NPC_ | Template `WEMerchantMiscMaleCommoner` / `...FemaleCommoner` for looks and gear. Protected, cowardly, class Citizen, no factions or packages. |
| `RWD_Courier` | NPC_ | Template `LvlWERoadCourier`, same setup as the merchants. |
| `RWD_DeserterFaction` | FACT | Hidden, no relations. Only there so the deserters aren't factionless. |
| `RWD_HealingPotions` | FLST | `RestoreHealth01`-`06`. |
| `RWD_HealingSpells` | FLST | Healing, Fast Healing, Close Wounds, Grand Healing, Healing Hands, Heal Other. |
| `RWD_AvoidLocations` | FLST | Populated Skyrim.esm locations not reliably tagged City/Town/Settlement/Dwelling (College of Winterhold, towns, stables, ...); every location under them counts too. The Dawnguard/Dragonborn ones are looked up by FormID at runtime. |
| `RWD_Msg*` | MESG (15) | Hints (notifications) and choice boxes. |
| `RWD_*` settings | GLOB (28) | See the README. |

Wolves are the vanilla `LvlWolf`. The markers are the vanilla `XMarker` static, placed by script.

## Controller loop

`OnUpdate` runs every 5 real seconds while nothing is happening, and every 2 seconds while an encounter is running. It uses no `RegisterForUpdate` loop, only `RegisterForSingleUpdate`, so the script can't stack.

1. **Breadcrumbs.** If the player is outdoors, not in an avoided location (type keyword, `RWD_AvoidLocations` or anything under them) and not within `RWD_TownRadius` of a town map marker, and has moved 400+ units since the last marker, the oldest of eight `XMarker` references is moved to the player. The references are created once with `PlaceAtMe(XMarker, 1, abForcePersist = True)`.
2. **Check.** At most every `RWD_CheckSeconds`, if the player can take an encounter (see below), roll `RWD_ChancePct`, pick a kind by weight, and pick a spot. The spot is the farthest marker in the right distance band that is in the player's worldspace, in an attached (loaded) cell, and itself passes the same location and town-radius rules (so markers from an older save or dropped just before an exclusion applied are skipped). No spot means no encounter. A forced one (`RWD_ForceNext`) stays queued until a spot turns up.
3. **Can start** when the player is not in combat, not sitting, outdoors, not in an avoided location, controls enabled, MQ101 not running, level >= `RWD_MinLevel`, at least `RWD_QuietSeconds` since the player was last seen in combat, and the game-time cooldown is over. A forced encounter skips the last three conditions.
4. **Spawn** with `PlaceActorAtMe(base, RWD_LevelMod)` at the marker. Ambush: `StartCombat(player)`. Merchant: attackers `StartCombat(merchant)`. Deserters and courier: nothing until the player is within `RWD_TalkDistance`.
5. **Tick** while running:
   - Merchant: when every attacker is dead, the merchant is alive and the player is within 1.5x talk distance, pay the reward.
   - Deserters: when the player is within talk distance, show the toll box. If any deserter is in combat first, they all turn hostile (`SetActorValue("Aggression", 2)` + `StartCombat`). Paying or a successful intimidation (`Speechcraft >= RWD_IntimidateSpeech`) fades them out.
   - Courier: show the choice box. It loops until the player helps or leaves, and it checks the potion list and the known healing spells.
6. **End** when the player changes worldspace or is more than `RWD_CleanupDist` from the spot. It also ends when the encounter has gone stale (`RWD_ExpireHours`) and the player is out of sight, but never while the player is in combat nearby. Living actors are disabled and deleted. Dead ones are flagged for deletion, so the bodies stay lootable until their cell unloads.

## Why behind the player

Vanilla world encounters use Story Manager nodes and hand-placed encounter markers along the roads. Roadwarden can't add either without the Creation Kit (placing markers is a world edit, and the brief rules those out). Spawning at a random offset can land actors inside rocks, in water or off a cliff. Spots the player has just walked through are known-good ground, and they're out of sight behind the player. The cost is that encounters come from behind.

## Contract Hunter

`CHT_HunterScript.TrySendAvengers` refuses while the player is in combat or in a safe location, and it ticks hourly. The avengers can't be read from outside without a master dependency, so Roadwarden doesn't depend on Contract Hunter. It uses the quiet period after any combat instead. See the README for the remaining overlap case.

## Save safety

All state lives in script variables of one quest. Uninstalling mid-game leaves at most eight orphaned marker references and the current encounter's actors. Before uninstalling, set `RWD_Enabled` to 0 and walk away from any running encounter so it cleans up.
