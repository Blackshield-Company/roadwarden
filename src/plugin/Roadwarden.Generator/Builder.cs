using Modkit.Mutagen;
using Mutagen.Bethesda;
using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.Plugins.Records;
using Mutagen.Bethesda.Skyrim;
using Noggog;
using static Roadwarden.Generator.Vanilla;

namespace Roadwarden.Generator;

internal sealed class Builder
{
    private readonly SkyrimMod _mod;
    private readonly FormIdRegistry _ids;
    private static readonly SkyrimRelease R = SkyrimRelease.SkyrimSE;
    private const byte VanillaQuestFormVersion = 65;
    public const int AliasPlayer = 0;

    public Builder(SkyrimMod mod, FormIdRegistry ids)
    {
        _mod = mod;
        _ids = ids;
    }

    private FormKey Id(string editorId) => _ids.Get(editorId);
    private static FormLink<T> L<T>(FormKey k) where T : class, IMajorRecordGetter => new(k);

    public void Build()
    {
        var qRoad = Id("RWD_RoadQuest");

        // --- Settings ------------------------------------------------------------------------------
        // (name, default) in script property order; every one is a plain global you can `set` in the console.
        var settings = new (string Name, float Value)[]
        {
            ("RWD_Enabled", 1), ("RWD_CheckSeconds", 60), ("RWD_ChancePct", 10), ("RWD_CooldownHours", 8),
            ("RWD_MinLevel", 3), ("RWD_QuietSeconds", 120),
            ("RWD_SpawnMinDist", 1500), ("RWD_SpawnMaxDist", 3500), ("RWD_CallMinDist", 700), ("RWD_CallMaxDist", 1800),
            ("RWD_CleanupDist", 6000), ("RWD_ExpireHours", 4), ("RWD_TalkDistance", 500),
            ("RWD_WeightAmbush", 35), ("RWD_WeightMerchant", 25), ("RWD_WeightDeserters", 20), ("RWD_WeightCourier", 20),
            ("RWD_MaxHostiles", 4), ("RWD_LevelMod", 1), ("RWD_RewardBase", 50), ("RWD_TollBase", 50),
            ("RWD_IntimidateSpeech", 50), ("RWD_PursuitPct", 40), ("RWD_Notify", 1), ("RWD_ForceNext", 0), ("RWD_EncounterCount", 0),
        };
        var globals = settings.Select(s => (s.Name, Key: Global(s.Name, s.Value))).ToList();

        // --- Actors --------------------------------------------------------------------------------
        const NpcConfiguration.TemplateFlag allButName = NpcConfiguration.TemplateFlag.Traits | NpcConfiguration.TemplateFlag.Stats
            | NpcConfiguration.TemplateFlag.Factions | NpcConfiguration.TemplateFlag.SpellList | NpcConfiguration.TemplateFlag.AIData
            | NpcConfiguration.TemplateFlag.AIPackages | NpcConfiguration.TemplateFlag.ModelAnimation | NpcConfiguration.TemplateFlag.Inventory
            | NpcConfiguration.TemplateFlag.Script | NpcConfiguration.TemplateFlag.DefPackList | NpcConfiguration.TemplateFlag.AttackData
            | NpcConfiguration.TemplateFlag.Keywords;
        // Looks, stats, gear and combat from the template; own name, factions, AI data and (no) packages.
        const NpcConfiguration.TemplateFlag looksAndGear = NpcConfiguration.TemplateFlag.Traits | NpcConfiguration.TemplateFlag.Stats
            | NpcConfiguration.TemplateFlag.SpellList | NpcConfiguration.TemplateFlag.ModelAnimation | NpcConfiguration.TemplateFlag.Inventory
            | NpcConfiguration.TemplateFlag.AttackData | NpcConfiguration.TemplateFlag.Keywords;

        var highwayman = Add(TemplatedNpc("RWD_Highwayman", "Highwayman", "Highwayman", LCharBanditMeleeAny, allButName));
        var archer = Add(TemplatedNpc("RWD_HighwayArcher", "Highway Archer", "Archer", LCharBanditMissile, allButName));

        var deserterFaction = Add(new Faction(Id("RWD_DeserterFaction"), R)
        {
            EditorID = "RWD_DeserterFaction",
            Name = "Roadwarden Deserters",
            Flags = Faction.FactionFlag.HiddenFromPC,
        });
        Npc Deserter(string edid, string name, FormKey template)
        {
            var n = TemplatedNpc(edid, name, "Deserter", template, looksAndGear);
            n.Factions.Add(new RankPlacement { Faction = L<IFactionGetter>(deserterFaction.FormKey), Rank = 0 });
            n.AIData = new AIData
            {
                Aggression = Aggression.Unaggressive, Confidence = Confidence.Average, Assistance = Assistance.HelpsAllies,
                Responsibility = Responsibility.NoCrime, Mood = Mood.Neutral, EnergyLevel = 50,
            };
            return Add(n);
        }
        var desImperial = Deserter("RWD_DeserterImperial", "Imperial Deserter", LCharSoldierImperial);
        var desSons = Deserter("RWD_DeserterSons", "Stormcloak Deserter", LCharSoldierSons);

        Npc Traveler(string edid, string name, string shortName, FormKey template)
        {
            var n = TemplatedNpc(edid, name, shortName, template, looksAndGear);
            n.Configuration.Flags |= NpcConfiguration.Flag.Protected; // only the player can kill them
            n.Class = L<IClassGetter>(ClassCitizen);
            n.AIData = new AIData
            {
                Aggression = Aggression.Unaggressive, Confidence = Confidence.Cowardly, Assistance = Assistance.HelpsNobody,
                Responsibility = Responsibility.NoCrime, Mood = Mood.Neutral, EnergyLevel = 50,
            };
            return Add(n);
        }
        var merchantM = Traveler("RWD_MerchantM", "Traveling Merchant", "Merchant", WEMerchantMiscMaleCommoner);
        var merchantF = Traveler("RWD_MerchantF", "Traveling Merchant", "Merchant", WEMerchantMiscFemaleCommoner);
        var courier = Traveler("RWD_Courier", "Wounded Courier", "Courier", LvlWERoadCourier);

        // --- Lists -----------------------------------------------------------------------------------
        var potions = Add(new FormList(Id("RWD_HealingPotions"), R) { EditorID = "RWD_HealingPotions" });
        foreach (var p in HealingPotions) potions.Items.Add(L<ISkyrimMajorRecordGetter>(p));
        var spells = Add(new FormList(Id("RWD_HealingSpells"), R) { EditorID = "RWD_HealingSpells" });
        foreach (var s in HealingSpells) spells.Items.Add(L<ISkyrimMajorRecordGetter>(s));

        // --- Messages --------------------------------------------------------------------------------
        var msgs = new List<(string, FormKey)>
        {
            ("RWD_MsgAmbush", Notice("RWD_MsgAmbush", Texts.Ambush)),
            ("RWD_MsgMerchantHeard", Notice("RWD_MsgMerchantHeard", Texts.MerchantHeard)),
            ("RWD_MsgMerchantThanks", Msg("RWD_MsgMerchantThanks", Texts.MerchantThanks, Btn("Ok"))),
            ("RWD_MsgDesertersHeard", Notice("RWD_MsgDesertersHeard", Texts.DesertersHeard)),
            ("RWD_MsgDeserters", Msg("RWD_MsgDeserters", Texts.Deserters, Btn("Pay the toll"), Btn("Intimidate them (Speech)"), Btn("Fight"))),
            ("RWD_MsgDesertersPaid", Notice("RWD_MsgDesertersPaid", Texts.DesertersPaid)),
            ("RWD_MsgDesertersCowed", Notice("RWD_MsgDesertersCowed", Texts.DesertersCowed)),
            ("RWD_MsgDesertersBluff", Notice("RWD_MsgDesertersBluff", Texts.DesertersBluff)),
            ("RWD_MsgNoGold", Notice("RWD_MsgNoGold", Texts.NoGold)),
            ("RWD_MsgCourierHeard", Notice("RWD_MsgCourierHeard", Texts.CourierHeard)),
            ("RWD_MsgCourier", Msg("RWD_MsgCourier", Texts.Courier, Btn("Give a healing potion"), Btn("Tend the wound (healing spell)"), Btn("Leave"))),
            ("RWD_MsgNoPotion", Notice("RWD_MsgNoPotion", Texts.NoPotion)),
            ("RWD_MsgNoSpell", Notice("RWD_MsgNoSpell", Texts.NoSpell)),
            ("RWD_MsgCourierThanks", Msg("RWD_MsgCourierThanks", Texts.CourierThanks, Btn("Ok"))),
            ("RWD_MsgPursuers", Notice("RWD_MsgPursuers", Texts.Pursuers)),
        };

        // --- Controller quest --------------------------------------------------------------------------
        var quest = Add(new Quest(qRoad, R)
        {
            EditorID = "RWD_RoadQuest",
            Name = "Roadwarden",
            Flags = Quest.Flag.StartGameEnabled | Quest.Flag.RunOnce,
            Priority = 30,
            Type = Quest.TypeEnum.None,
            QuestFormVersion = VanillaQuestFormVersion,
        });
        quest.Aliases.Add(new QuestAlias
        {
            ID = AliasPlayer, Type = QuestAlias.TypeEnum.Reference, Name = "Player",
            ForcedReference = new FormLinkNullable<IPlacedGetter>(PlayerRef),
        });
        quest.NextAliasID = 1;

        var props = new List<ScriptProperty>();
        props.AddRange(globals.Select(g => Vmad.Obj(g.Name, g.Key)));
        props.Add(Vmad.ObjList("Highwaymen", highwayman.FormKey, archer.FormKey));
        props.Add(Vmad.ObjList("Merchants", merchantM.FormKey, merchantF.FormKey));
        props.Add(Vmad.ObjList("Deserters", desImperial.FormKey, desSons.FormKey));
        props.Add(Vmad.Obj("Courier", courier.FormKey));
        props.Add(Vmad.Obj("Wolf", LvlWolf));
        props.Add(Vmad.Obj("XMarker", XMarker));
        props.Add(Vmad.Obj("Gold001", Gold001));
        props.Add(Vmad.Obj("RWD_HealingPotions", potions.FormKey));
        props.Add(Vmad.Obj("RWD_HealingSpells", spells.FormKey));
        props.Add(Vmad.ObjList("AvoidLocationTypes", LocTypeCity, LocTypeTown, LocTypeSettlement, LocTypeDwelling,
            LocTypeHabitation, LocTypePlayerHouse, LocTypeBanditCamp, LocTypeDungeon, LocTypeMilitaryFort));
        props.Add(Vmad.Obj("MQ101", MQ101));
        props.AddRange(msgs.Select(m => Vmad.Obj(m.Item1, m.Item2)));

        quest.VirtualMachineAdapter = Vmad.QuestAdapter(Vmad.Script("RWD_RoadScript", props.ToArray()))
            .WithAliasScripts(qRoad, AliasPlayer, Vmad.Script("RWD_PlayerAliasScript", Vmad.Obj("Road", qRoad)));
    }

    // ----------------------------------------------------------------------------------------
    private T Add<T>(T record) where T : SkyrimMajorRecord
    {
        _mod.GetTopLevelGroup<T>().Add(record);
        return record;
    }

    private FormKey Global(string edid, float value)
    {
        var g = new GlobalFloat(Id(edid), R) { EditorID = edid, Data = value };
        _mod.Globals.Add(g);
        return g.FormKey;
    }

    private static MessageButton Btn(string text) => new() { Text = text };

    private FormKey Msg(string edid, string text, params MessageButton[] buttons)
    {
        var m = new Message(Id(edid), R) { EditorID = edid, Description = text, Flags = Message.Flag.MessageBox, INAM = new byte[4] };
        m.MenuButtons.AddRange(buttons);
        _mod.Messages.Add(m);
        return m.FormKey;
    }

    private FormKey Notice(string edid, string text)
    {
        var m = new Message(Id(edid), R) { EditorID = edid, Description = text, Flags = 0, DisplayTime = 2, INAM = new byte[4] };
        _mod.Messages.Add(m);
        return m.FormKey;
    }

    private Npc TemplatedNpc(string edid, string name, string shortName, FormKey template, NpcConfiguration.TemplateFlag flags) => new(Id(edid), R)
    {
        EditorID = edid,
        Name = name,
        ShortName = shortName,
        ObjectBounds = new ObjectBounds { First = new P3Int16(-22, -14, 0), Second = new P3Int16(22, 14, 128) },
        Template = new FormLinkNullable<INpcSpawnGetter>(template),
        Race = L<IRaceGetter>(NordRace),
        Class = L<IClassGetter>(ClassWarrior1H),
        CombatStyle = L<ICombatStyleGetter>(CsHumanMelee).AsNullable(),
        Configuration = new NpcConfiguration
        {
            Flags = NpcConfiguration.Flag.AutoCalcStats,
            TemplateFlags = flags,
            Level = new PcLevelMult { LevelMult = 1 },
            CalcMinLevel = 1,
            CalcMaxLevel = 0,
            SpeedMultiplier = 100,
            DispositionBase = 35,
        },
        AIData = new AIData { Aggression = Aggression.Aggressive, Confidence = Confidence.Average, Assistance = Assistance.HelpsAllies, EnergyLevel = 50 },
        PlayerSkills = new PlayerSkills(),
        Height = 1,
        Weight = 50,
    };
}
