using Mutagen.Bethesda.Plugins;

namespace Roadwarden.Generator;

/// <summary>
/// Skyrim.esm records this mod links to (FormIDs looked up with Mutagen.Bethesda.FormKeys.SkyrimSE).
/// Nothing here is overridden; the mod only references these.
/// </summary>
internal static class Vanilla
{
    public static readonly ModKey Skyrim = ModKey.FromFileName("Skyrim.esm");
    private static FormKey K(uint id) => new(Skyrim, id);

    public static readonly FormKey PlayerRef = K(0x000014);
    public static readonly FormKey MQ101 = K(0x03372B);
    public static readonly FormKey XMarker = K(0x00003B);
    public static readonly FormKey Gold001 = K(0x00000F);

    // Templates and creatures (leveled, so encounters scale with the player)
    public static readonly FormKey LCharBanditMeleeAny = K(0x03DECD);
    public static readonly FormKey LCharBanditMissile = K(0x01E770);
    public static readonly FormKey LCharSoldierImperial = K(0x01FC5B);
    public static readonly FormKey LCharSoldierSons = K(0x01FC5C);
    public static readonly FormKey WEMerchantMiscMaleCommoner = K(0x0BBCD2);
    public static readonly FormKey WEMerchantMiscFemaleCommoner = K(0x0B5D5A);
    public static readonly FormKey LvlWERoadCourier = K(0x1065F7);
    public static readonly FormKey LvlWolf = K(0x0B83C1);

    public static readonly FormKey NordRace = K(0x013746);
    public static readonly FormKey ClassWarrior1H = K(0x013176);
    public static readonly FormKey ClassCitizen = K(0x01326B);
    public static readonly FormKey CsHumanMelee = K(0x068849);

    // Location types where nothing spawns
    public static readonly FormKey LocTypeCity = K(0x013168);
    public static readonly FormKey LocTypeTown = K(0x013166);
    public static readonly FormKey LocTypeSettlement = K(0x013167);
    public static readonly FormKey LocTypeDwelling = K(0x0130DC);
    public static readonly FormKey LocTypeHabitation = K(0x039793);
    public static readonly FormKey LocTypePlayerHouse = K(0x0FC1A3);
    public static readonly FormKey LocTypeBanditCamp = K(0x0130DF);
    public static readonly FormKey LocTypeDungeon = K(0x0130DB);
    public static readonly FormKey LocTypeMilitaryFort = K(0x0130E7);

    // Populated places that are not reliably tagged City/Town/Settlement/Dwelling (RWD_AvoidLocations).
    // A location here also covers every location under it (Location.IsChild). Never put a hold here.
    public static readonly FormKey[] AvoidLocations =
    {
        K(0x076F3A), // WinterholdCollegeLocation
        K(0x018A51), // WinterholdLocation
        K(0x018A50), // DawnstarLocation
        K(0x018A53), // MorthalLocation
        K(0x018A49), // FalkreathLocation
        K(0x013163), // RiverwoodLocation
        K(0x018A5A), // SolitudeLocation
        K(0x0358B9), // SolitudeDocksLocation
        K(0x018E44), // SolitudeSawmillLocation
        K(0x018E38), // KatlasFarmLocation
        K(0x07046A), // SolitudeStablesLocation
        K(0x018A57), // WindhelmLocation
        K(0x0209F5), // WindhelmStablesLocation
        K(0x018A56), // WhiterunLocation
        K(0x01F87C), // WhiterunStablesLocation
        K(0x018A59), // MarkarthLocation
        K(0x0C6C2A), // MarkarthStablesLocation
        K(0x018A58), // RiftenLocation
        K(0x02264C), // RiftenStablesLocation
        K(0x018E42), // SkyHavenTempleLocation
        K(0x018E34), // HighHrothgarLocation
        K(0x018A4B), // IvarsteadLocation
        K(0x018A47), // RoriksteadLocation
        K(0x018A46), // DragonBridgeLocation
        K(0x018A54), // KarthwastenLocation
        K(0x018A4C), // ShorsStoneLocation
        K(0x018A4E), // KynesgroveLocation
        K(0x018A55), // OldHroldanLocation
    };

    // Map markers just outside the walled cities and the College (RWD_TownRadius around each, Tamriel worldspace).
    public static readonly FormKey[] TownMarkers =
    {
        K(0x0162CE), // WhiterunMapMarkerREF
        K(0x04D0F4), // SolitudeMapmarkerRef
        K(0x038436), // WindhelmMapMarkerRef
        K(0x01C38A), // MarkarthMapMarkerREF
        K(0x01C390), // RiftenMapMarkerREF
        K(0x046BDF), // WinterholdCollegeMapMarkerRef
        K(0x0177EF), // WinterholdMapMarker
    };

    // Healing
    public static readonly FormKey[] HealingPotions =
    {
        K(0x03EADD), K(0x03EADE), K(0x03EADF), K(0x03EAE3), K(0x039BE4), K(0x039BE5), // RestoreHealth01-06
    };
    public static readonly FormKey[] HealingSpells =
    {
        K(0x012FCC), K(0x02F3B8), K(0x0B62EF), K(0x0B62EE), K(0x04D3F2), K(0x012FD2), // Healing, FastHealing, CloseWounds, GrandHealing, HealingHands, HealOther
    };
}
