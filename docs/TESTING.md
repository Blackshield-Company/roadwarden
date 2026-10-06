# Testing checklist (v0.1.0, early beta)

Automated (every `./build.sh`):

- [x] Papyrus compiles.
- [x] Plugin validation: ESL range, Skyrim.esm only, every form link resolves, every script property is filled and its record type matches, SEQ contents, byte-exact round trip.
- [x] FOMOD schema.
- [x] Cross-mod check (`tools/modkit/Modkit.Compat`) with every released mod of the series.

In game (not done yet; please help). The fastest way to test is the debug trigger: walk along a road for 20 or 30 seconds (so markers exist behind you), then `set RWD_ForceNext to <1-4>`. The encounter starts on the next 5-second tick once there is a marker in range.

Useful: `help "Highwayman" 4`, `help "Deserter" 4`, `help "Traveling Merchant" 4`, `help "Wounded Courier" 4` list the actor FormIDs (they load as FE xxx 8xx). `show RWD_EncounterCount` counts encounters.

1. **Ambush** (`set RWD_ForceNext to 1`)
   - [ ] "Footsteps on the road behind you. Highwaymen!" and 2 to 4 "Highwayman" / "Highway Archer" actors come at you from behind.
   - [ ] They are level-appropriate and drop bandit loot.
2. **Merchant** (`2`)
   - [ ] "Someone is shouting for help..." A "Traveling Merchant" fights or flees from highwaymen or wolves.
   - [ ] The attackers can't kill the merchant (Protected).
   - [ ] After the last attacker dies, walking up to the merchant shows the thanks box with a gold amount, and the gold is added.
3. **Deserters** (`3`)
   - [ ] "Hold there, traveler!" "Imperial Deserter" or "Stormcloak Deserter" actors stand behind you on the road.
   - [ ] Walking within about 7 m opens the toll box with an amount. Test each option:
     - [ ] Pay with enough gold: the gold is removed, they fade out. Pay without enough: "You don't have enough gold" and they attack.
     - [ ] Intimidate with Speech 50+: they fade out. Below 50: they laugh and attack.
     - [ ] Fight: they attack.
   - [ ] Attacking one before talking turns all of them hostile without a box.
4. **Courier** (`4`)
   - [ ] "A faint cry for help..." A "Wounded Courier" at about a quarter of their health.
   - [ ] The box offers potion, healing spell or leave. Without a potion or spell, a notification shows and the box comes back.
   - [ ] Helping heals the courier and shows the thanks box with gold. About 40% of the time: "The courier's attackers have caught up!" and highwaymen attack.
5. **Rules**
   - [ ] Nothing happens in towns, cities, inns, interiors, camps, dungeons or forts, during combat, or within 2 minutes after a fight (normal mode, `RWD_ForceNext 0`).
   - [ ] After an encounter, walking about 90 m away removes the leftover actors (check with `prid <id>` that they are gone).
   - [ ] Save and reload during an encounter: it keeps running and cleans up afterwards.
   - [ ] `set RWD_Enabled to 0`: no new encounters.
6. **With Contract Hunter** (optional)
   - [ ] Let a Dread warrant lapse and make sure the avengers and a Roadwarden encounter don't arrive together. Roadwarden should stay quiet for 2 minutes after the avengers' fight.

When reporting a bug, include the encounter type, your level, what you saw, and the Papyrus log lines containing `RWD_` (enable Papyrus logging in `Skyrim.ini`: `[Papyrus] bEnableLogging=1`, `bEnableTrace=1`).
