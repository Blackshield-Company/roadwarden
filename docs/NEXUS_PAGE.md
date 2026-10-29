# Nexus Mods page: Roadwarden

Early beta: v0.1.2 passes every automated build check but nobody has playtested it in game yet. The page says this at the top. The exact upload-form values are in [NEXUS_FIELDS.md](NEXUS_FIELDS.md).

## Page settings

- **Game:** Skyrim Special Edition
- **Mod name:** Roadwarden
- **Version:** 0.1.2 (early beta)
- **Category:** Gameplay
- **Suggested tags:** Gameplay, Combat, Encounters, Immersion, Bandits, Lore-Friendly, ESL, No SKSE, Scripted
- **Requirements:** none.
- **Permissions (suggested):** the source is on GitHub under MIT, so allow modification and conversions with credit, but not re-uploads of the archive itself.
- **File to upload:** `Roadwarden-0.1.2.zip` (FOMOD) as the main file, named "Roadwarden".

## Description (paste into the BBCode editor)

```bbcode
[center][size=6][b]ROADWARDEN[/b][/size]
[size=3][i]The road is never as empty as it looks.[/i][/size]

[size=3][color=#e0a030][b]EARLY BETA (v0.1.2)[/b]: this version passes every automated build check but hasn't been playtested in game yet. Please report bugs in the Bugs tab or on GitHub, ideally with your Papyrus log.[/color][/size][/center]

[line]

[size=4][b]Summary[/b][/size]
Four rare, level-scaled encounters for the roads of Skyrim. They are script-driven, with no world edits and no SKSE. They turn up on the stretch of road you just walked, never in towns and never while you're fighting, and they clean up after themselves.

[size=4][b]The encounters[/b][/size]
[list]
[*][b]Ambush:[/b] footsteps behind you. Two to four highwaymen (an archer among them) come up the road after you.
[*][b]Merchant in trouble:[/b] a cry for help. A traveling merchant is attacked by highwaymen or wolves. Kill the attackers and the merchant pays you.
[*][b]Deserters:[/b] "Hold there, traveler!" Imperial or Stormcloak deserters want a road toll. [b]Pay[/b], [b]intimidate[/b] them (Speech 50), or [b]fight[/b].
[*][b]Wounded courier:[/b] heal them with a potion or a healing spell for a reward. Sometimes the attackers come back.
[/list]
Leveled bandit, soldier and wolf templates, plus 2 to 4 attackers depending on your level.

[size=4][b]When and where[/b][/size]
[list]
[*]Only outdoors, on ground you just walked or rode through, about 20 to 50 m behind you (deserters and the courier call out from about 10 to 25 m).
[*]Never in cities, towns, settlements, homes or any interior (inns, dungeons, forts inside). Never during Helgen, in combat, or within 2 minutes after a fight. Riding a horse counts as travel.
[*]Rare: one check every 45 seconds while you travel, a 15% chance, and at least 4 game hours between encounters.
[*]Fast travel and carriages skip the road, so they never trigger encounters. You only meet people on roads you actually walk or ride.
[*]Leftover actors are removed once you've moved on.
[/list]

[size=4][b]Requirements[/b][/size]
[list]
[*]Skyrim Special Edition or Anniversary Edition (1.5.97 or 1.6.x). Works on Steam under Proton on Linux.
[*]Nothing else. No SKSE, no SkyUI, no DLC, no Creation Club content.
[/list]

[size=4][b]Installation[/b][/size]
Install with [b]Mod Organizer 2[/b] or [b]Vortex[/b] (FOMOD installer) and enable [b]Roadwarden.esp[/b]. It's ESL-flagged, so it doesn't take a full load-order slot. Safe to add mid-playthrough.

[size=4][b]Compatibility[/b][/size]
[list]
[*][b]No edits to vanilla records and nothing placed in the world.[/b] Skyrim.esm is the only master.
[*]Works alongside vanilla world encounters and other encounter mods (they don't share anything; you may just meet more people on the road).
[*][b]Contract Hunter:[/b] Roadwarden stays quiet for 2 minutes after any fight, and Contract Hunter's avengers wait while you're in combat, so the two don't stack up.
[*]Compatible with the rest of my mods (Blackshield Company, Bounties of Oblivion, Contract Hunter, Steel Oath, Ember Smithing, The Gray-Mane Debt, Blackshield Codex, War Banners), checked by loading all plugins together.
[/list]

[size=4][b]Settings (console)[/b][/size]
[code]set RWD_ChancePct to 10 / set RWD_CooldownHours to 8 / set RWD_MaxHostiles to 4
set RWD_WeightAmbush to 35   (also RWD_WeightMerchant, RWD_WeightDeserters, RWD_WeightCourier; 0 turns one off)
set RWD_LevelMod to 1        (0 easy ... 3 very hard)
set RWD_Enabled to 0         (pause)
set RWD_ForceNext to 1       (debug: 1 ambush, 2 merchant, 3 deserters, 4 courier)
set RWD_Debug to 1           (debug: log every check and why it was skipped, Papyrus log lines with RWD_)[/code]
You'll see "Roadwarden active" when a game loads; that means the mod is running.
The full list is in the README on GitHub.

[size=4][b]Uninstalling[/b][/size]
Set [code]RWD_Enabled to 0[/code] and walk away from any running encounter so it cleans up. As with any scripted mod, prefer not to remove it mid-playthrough.

[size=4][b]Known issues / early beta limits[/b][/size]
[list]
[*]Encounters only come from [b]behind[/b] you: without navmesh tools, the mod only spawns on ground you've already walked. Standing still means no encounters.
[*]That ground follows wherever you walked, so a "road" encounter can happen in the wilderness you just crossed.
[*]No voiced lines: the encounters talk through notifications and message boxes.
[*]The courier's wound is lost health only, with no injured animation.
[/list]

[size=4][b]Source[/b][/size]
Open source (MIT): [url=https://github.com/Blackshield-Company/roadwarden]github.com/Blackshield-Company/roadwarden[/url]

[size=4][b]Credits[/b][/size]
[list]
[*][url=https://github.com/Mutagen-Modding/Mutagen]Mutagen[/url] by Noggog and contributors, which generates the plugin from code.
[*][url=https://github.com/russo-2025/papyrus-compiler]papyrus-compiler[/url] by russo-2025, the open-source Papyrus compiler.
[*][url=https://github.com/GandaG/fomod-schema]FOMOD schema[/url] by GandaG.
[*]Bethesda Game Studios for Skyrim.
[/list]
```
