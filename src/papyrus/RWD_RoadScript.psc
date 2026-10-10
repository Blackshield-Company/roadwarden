Scriptname RWD_RoadScript extends Quest
{Roadwarden: rare encounters on the stretch of road you just traveled.

The script drops a few markers behind the player while they travel outdoors
(about one every 400 units, eight in all). When an encounter fires it spawns at
one of those markers. A marker is a spot the player just walked through, so it
is reachable ground, it is behind the player and out of the way, and it is
never inside a city, town, home, camp or dungeon.

Encounters: 1 ambush, 2 merchant in trouble, 3 deserters, 4 wounded courier.
Everything is tuned with RWD_* globals. Set RWD_ForceNext to 1-4 to trigger
one on the next tick (it still waits for a valid spot outside combat).}

; ---------------------------------------------------------------------------
; Settings (globals)
; ---------------------------------------------------------------------------
GlobalVariable Property RWD_Enabled Auto
GlobalVariable Property RWD_CheckSeconds Auto
GlobalVariable Property RWD_ChancePct Auto
GlobalVariable Property RWD_CooldownHours Auto
GlobalVariable Property RWD_MinLevel Auto
GlobalVariable Property RWD_QuietSeconds Auto
GlobalVariable Property RWD_SpawnMinDist Auto
GlobalVariable Property RWD_SpawnMaxDist Auto
GlobalVariable Property RWD_CallMinDist Auto
GlobalVariable Property RWD_CallMaxDist Auto
GlobalVariable Property RWD_CleanupDist Auto
GlobalVariable Property RWD_ExpireHours Auto
GlobalVariable Property RWD_TalkDistance Auto
GlobalVariable Property RWD_WeightAmbush Auto
GlobalVariable Property RWD_WeightMerchant Auto
GlobalVariable Property RWD_WeightDeserters Auto
GlobalVariable Property RWD_WeightCourier Auto
GlobalVariable Property RWD_MaxHostiles Auto
GlobalVariable Property RWD_LevelMod Auto
GlobalVariable Property RWD_RewardBase Auto
GlobalVariable Property RWD_TollBase Auto
GlobalVariable Property RWD_IntimidateSpeech Auto
GlobalVariable Property RWD_PursuitPct Auto
GlobalVariable Property RWD_Notify Auto
GlobalVariable Property RWD_ForceNext Auto
GlobalVariable Property RWD_EncounterCount Auto
GlobalVariable Property RWD_Debug Auto
{1: log every check and why it was rejected to the Papyrus log (prefix [Roadwarden] RWD_).}

; ---------------------------------------------------------------------------
; Records
; ---------------------------------------------------------------------------
ActorBase[] Property Highwaymen Auto
{Melee and archer highwaymen (leveled bandit templates).}
ActorBase[] Property Merchants Auto
ActorBase[] Property Deserters Auto
{One per side; a band is always from one side.}
ActorBase Property Courier Auto
ActorBase Property Wolf Auto
Form Property XMarker Auto
MiscObject Property Gold001 Auto
FormList Property RWD_HealingPotions Auto
FormList Property RWD_HealingSpells Auto
Keyword[] Property AvoidLocationTypes Auto
{No encounters (and no markers) inside these: cities, towns, settlements, homes, player houses. Interiors (dungeons, inns, forts inside) are always excluded.}
Quest Property MQ101 Auto

Message Property RWD_MsgAmbush Auto
Message Property RWD_MsgMerchantHeard Auto
Message Property RWD_MsgMerchantThanks Auto
Message Property RWD_MsgDesertersHeard Auto
Message Property RWD_MsgDeserters Auto
Message Property RWD_MsgDesertersPaid Auto
Message Property RWD_MsgDesertersCowed Auto
Message Property RWD_MsgDesertersBluff Auto
Message Property RWD_MsgNoGold Auto
Message Property RWD_MsgCourierHeard Auto
Message Property RWD_MsgCourier Auto
Message Property RWD_MsgNoPotion Auto
Message Property RWD_MsgNoSpell Auto
Message Property RWD_MsgCourierThanks Auto
Message Property RWD_MsgPursuers Auto

; ---------------------------------------------------------------------------
; Constants and state
; ---------------------------------------------------------------------------
Int Property ENC_NONE = 0 AutoReadOnly
Int Property ENC_AMBUSH = 1 AutoReadOnly
Int Property ENC_MERCHANT = 2 AutoReadOnly
Int Property ENC_DESERTERS = 3 AutoReadOnly
Int Property ENC_COURIER = 4 AutoReadOnly

Int Property STAGE_OPEN = 0 AutoReadOnly
Int Property STAGE_FIGHT = 1 AutoReadOnly
Int Property STAGE_DONE = 2 AutoReadOnly

Int Property CRUMB_COUNT = 8 AutoReadOnly
Int Property MAX_ACTORS = 6 AutoReadOnly
Float Property CRUMB_SPACING = 400.0 AutoReadOnly
Float Property IDLE_TICK = 5.0 AutoReadOnly
Float Property ACTIVE_TICK = 2.0 AutoReadOnly

ObjectReference[] crumbs
Int crumbNext = 0
Actor[] hostiles
Actor victim
ObjectReference anchor
Int encType = 0
Int encStage = 0
Float encStart = 0.0
Float nextAllowed = 0.0
Float lastCombat = -100000.0
Float lastCheck = 0.0
String rejectReason = ""

Event OnInit()
	crumbs = new ObjectReference[8]
	hostiles = new Actor[6]
	Announce("started")
	RegisterForSingleUpdate(15.0)
EndEvent

; Startup/load heartbeat so players (and bug reports) can tell the controller is running.
Function Announce(String asWhy)
	Debug.Trace("[Roadwarden] RWD_ controller " + asWhy + " (v0.1.1): enabled=" + RWD_Enabled.GetValueInt() + " chance=" + RWD_ChancePct.GetValueInt() + "% every " + RWD_CheckSeconds.GetValueInt() + "s, cooldown " + RWD_CooldownHours.GetValue() + "h, encounters so far " + RWD_EncounterCount.GetValueInt())
	If RWD_Notify.GetValueInt() != 0
		Debug.Notification("Roadwarden active")
	EndIf
EndFunction

Function DebugLog(String asText)
	If RWD_Debug && RWD_Debug.GetValueInt() != 0
		Debug.Trace("[Roadwarden] RWD_ " + asText)
	EndIf
EndFunction

Bool Function Reject(String asReason)
	rejectReason = asReason
	Return False
EndFunction

; The real-time clock restarts with the game, so reset everything measured in it.
Function GameLoaded()
	lastCombat = -100000.0
	lastCheck = Utility.GetCurrentRealTime()
	If !crumbs
		crumbs = new ObjectReference[8]
	EndIf
	If !hostiles
		hostiles = new Actor[6]
	EndIf
	Announce("loaded")
	RegisterForSingleUpdate(IDLE_TICK)
EndFunction

Event OnUpdate()
	Actor player = Game.GetPlayer()
	Float now = Utility.GetCurrentRealTime()
	If now < lastCheck
		lastCheck = now
	EndIf
	If player.IsInCombat()
		lastCombat = now
	EndIf
	If encType != ENC_NONE
		Tick(player)
	ElseIf RWD_Enabled.GetValueInt() != 0
		DropCrumb(player)
		Float interval = RWD_CheckSeconds.GetValue()
		If interval < 10.0
			interval = 10.0
		EndIf
		If RWD_ForceNext.GetValueInt() > 0 || now - lastCheck >= interval
			lastCheck = now
			TryStart(player, now)
		EndIf
	EndIf
	If encType != ENC_NONE
		RegisterForSingleUpdate(ACTIVE_TICK)
	Else
		RegisterForSingleUpdate(IDLE_TICK)
	EndIf
EndEvent

; ---------------------------------------------------------------------------
; Where and when
; ---------------------------------------------------------------------------

Bool Function IsRoadside(Actor player)
	If player.IsInInterior() || !player.GetWorldSpace()
		Return False
	EndIf
	Location here = player.GetCurrentLocation()
	If here
		Int i = 0
		While i < AvoidLocationTypes.Length
			If here.HasKeyword(AvoidLocationTypes[i])
				Return False
			EndIf
			i += 1
		EndWhile
	EndIf
	Return True
EndFunction

Function DropCrumb(Actor player)
	If !IsRoadside(player)
		Return
	EndIf
	Int last = crumbNext - 1
	If last < 0
		last = CRUMB_COUNT - 1
	EndIf
	ObjectReference prev = crumbs[last]
	If prev && prev.GetWorldSpace() == player.GetWorldSpace() && prev.GetDistance(player) < CRUMB_SPACING
		Return
	EndIf
	If crumbs[crumbNext]
		crumbs[crumbNext].MoveTo(player)
	Else
		crumbs[crumbNext] = player.PlaceAtMe(XMarker, 1, True)
	EndIf
	crumbNext += 1
	If crumbNext >= CRUMB_COUNT
		crumbNext = 0
	EndIf
EndFunction

Bool Function CanStart(Actor player, Float now, Bool abForced)
	If player.IsInCombat()
		Return Reject("in combat")
	EndIf
	; Riding counts as travel; only real sitting (chairs, benches, carriages) blocks.
	If player.GetSitState() != 0 && !player.IsOnMount()
		Return Reject("sitting")
	EndIf
	If !IsRoadside(player)
		Return Reject("not roadside (interior or excluded location)")
	EndIf
	If !Game.IsMovementControlsEnabled() || !Game.IsFightingControlsEnabled()
		Return Reject("controls disabled")
	EndIf
	If MQ101 && MQ101.IsRunning() && !MQ101.IsCompleted()
		Return Reject("Helgen (MQ101) running")
	EndIf
	If abForced
		Return True
	EndIf
	If player.GetLevel() < RWD_MinLevel.GetValueInt()
		Return Reject("player level below RWD_MinLevel")
	EndIf
	; Leave room after any fight (Contract Hunter's avengers, dragons, anything).
	If now - lastCombat < RWD_QuietSeconds.GetValue()
		Return Reject("quiet period after combat")
	EndIf
	If Utility.GetCurrentGameTime() < nextAllowed
		Return Reject("cooldown")
	EndIf
	Return True
EndFunction

; Farthest marker within [afMin, afMax] that is in a loaded cell of the player's worldspace.
ObjectReference Function PickSpot(Actor player, Float afMin, Float afMax)
	ObjectReference best = None
	Float bestDist = 0.0
	Int i = 0
	While i < CRUMB_COUNT
		ObjectReference c = crumbs[i]
		If c && c.GetWorldSpace() == player.GetWorldSpace()
			Float d = c.GetDistance(player)
			If d >= afMin && d <= afMax && d > bestDist
				Cell crumbCell = c.GetParentCell()
				If crumbCell && crumbCell.IsAttached()
					best = c
					bestDist = d
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile
	Return best
EndFunction

Int Function PickKind()
	Int wA = Max0(RWD_WeightAmbush.GetValueInt())
	Int wM = Max0(RWD_WeightMerchant.GetValueInt())
	Int wD = Max0(RWD_WeightDeserters.GetValueInt())
	Int wC = Max0(RWD_WeightCourier.GetValueInt())
	Int total = wA + wM + wD + wC
	If total <= 0
		Return ENC_NONE
	EndIf
	Int roll = Utility.RandomInt(1, total)
	If roll <= wA
		Return ENC_AMBUSH
	ElseIf roll <= wA + wM
		Return ENC_MERCHANT
	ElseIf roll <= wA + wM + wD
		Return ENC_DESERTERS
	EndIf
	Return ENC_COURIER
EndFunction

Int Function Max0(Int aiValue)
	If aiValue < 0
		Return 0
	EndIf
	Return aiValue
EndFunction

Function TryStart(Actor player, Float now)
	Int forced = RWD_ForceNext.GetValueInt()
	If !CanStart(player, now, forced > 0)
		DebugLog("check rejected: " + rejectReason)
		Return
	EndIf
	If forced <= 0 && Utility.RandomInt(1, 100) > RWD_ChancePct.GetValueInt()
		DebugLog("check rejected: roll failed (" + RWD_ChancePct.GetValueInt() + "%)")
		Return
	EndIf
	Int kind = forced
	If kind < ENC_AMBUSH || kind > ENC_COURIER
		kind = PickKind()
	EndIf
	If kind == ENC_NONE
		Return
	EndIf
	ObjectReference spot
	If kind == ENC_DESERTERS || kind == ENC_COURIER
		; These call out and wait, so they start closer.
		spot = PickSpot(player, RWD_CallMinDist.GetValue(), RWD_CallMaxDist.GetValue())
	Else
		spot = PickSpot(player, RWD_SpawnMinDist.GetValue(), RWD_SpawnMaxDist.GetValue())
	EndIf
	If !spot
		DebugLog("check rejected: no marker behind you in range yet (keep moving)")
		Return ; a forced encounter stays queued until there is a spot
	EndIf
	RWD_ForceNext.SetValueInt(0)
	StartEncounter(kind, spot, player)
EndFunction

; ---------------------------------------------------------------------------
; Spawning
; ---------------------------------------------------------------------------

Int Function HostileCount(Actor player)
	Int level = player.GetLevel()
	Int n = 2
	If level >= 25
		n = 4
	ElseIf level >= 12
		n = 3
	EndIf
	Int cap = RWD_MaxHostiles.GetValueInt()
	If cap > MAX_ACTORS
		cap = MAX_ACTORS
	EndIf
	If cap < 1
		cap = 1
	EndIf
	If n > cap
		n = cap
	EndIf
	Return n
EndFunction

Int Function LevelMod()
	Int m = RWD_LevelMod.GetValueInt()
	If m < 0
		Return 0
	ElseIf m > 3
		Return 3
	EndIf
	Return m
EndFunction

Actor Function Spawn(ObjectReference akAt, ActorBase akBase, Int aiSlot)
	Actor a = akAt.PlaceActorAtMe(akBase, LevelMod())
	If a && aiSlot >= 0
		hostiles[aiSlot] = a
	EndIf
	Return a
EndFunction

Function SpawnHighwaymen(ObjectReference akAt, Int aiCount, Actor akTarget)
	Int i = 0
	While i < aiCount
		ActorBase base = Highwaymen[0]
		If i % 3 == 2
			base = Highwaymen[1] ; every third one is an archer
		EndIf
		Actor a = Spawn(akAt, base, FreeSlot())
		If a && akTarget
			a.StartCombat(akTarget)
		EndIf
		i += 1
	EndWhile
EndFunction

Int Function FreeSlot()
	Int i = 0
	While i < MAX_ACTORS
		If !hostiles[i]
			Return i
		EndIf
		i += 1
	EndWhile
	Return -1
EndFunction

Function StartEncounter(Int aiKind, ObjectReference akSpot, Actor player)
	ClearActors()
	anchor = akSpot
	encType = aiKind
	encStage = STAGE_OPEN
	encStart = Utility.GetCurrentGameTime()
	nextAllowed = encStart + RWD_CooldownHours.GetValue() / 24.0
	RWD_EncounterCount.SetValue(RWD_EncounterCount.GetValue() + 1.0)
	Int n = HostileCount(player)
	Debug.Trace("[Roadwarden] RWD_ encounter " + aiKind + " with " + n + " hostiles at " + akSpot.GetDistance(player) + " units")

	If aiKind == ENC_AMBUSH
		SpawnHighwaymen(akSpot, n, player)
		encStage = STAGE_FIGHT
		Notify(RWD_MsgAmbush)
	ElseIf aiKind == ENC_MERCHANT
		victim = akSpot.PlaceActorAtMe(Merchants[Utility.RandomInt(0, Merchants.Length - 1)])
		If Utility.RandomInt(0, 1) == 0
			Int i = 0
			While i < n
				Actor w = Spawn(akSpot, Wolf, FreeSlot())
				If w
					w.StartCombat(victim)
				EndIf
				i += 1
			EndWhile
		Else
			SpawnHighwaymen(akSpot, n, victim)
		EndIf
		encStage = STAGE_FIGHT
		Notify(RWD_MsgMerchantHeard)
	ElseIf aiKind == ENC_DESERTERS
		ActorBase side = Deserters[Utility.RandomInt(0, Deserters.Length - 1)]
		Int i = 0
		While i < n
			Spawn(akSpot, side, FreeSlot())
			i += 1
		EndWhile
		Notify(RWD_MsgDesertersHeard)
	ElseIf aiKind == ENC_COURIER
		victim = akSpot.PlaceActorAtMe(Courier)
		If victim
			victim.DamageActorValue("Health", victim.GetActorValue("Health") * 0.75)
		EndIf
		Notify(RWD_MsgCourierHeard)
	EndIf
EndFunction

Function Notify(Message akMsg)
	If RWD_Notify.GetValueInt() != 0
		akMsg.Show()
	EndIf
EndFunction

; ---------------------------------------------------------------------------
; Running encounter
; ---------------------------------------------------------------------------

Function Tick(Actor player)
	; Ends quietly once the player has moved on or changed worldspace. A stale
	; encounter (RWD_ExpireHours) also ends, but never right in front of the player.
	If !anchor || player.GetWorldSpace() != anchor.GetWorldSpace()
		EndEncounter()
		Return
	EndIf
	Float d = anchor.GetDistance(player)
	Bool stale = Utility.GetCurrentGameTime() > encStart + RWD_ExpireHours.GetValue() / 24.0
	If d > RWD_CleanupDist.GetValue() || (stale && d > RWD_SpawnMinDist.GetValue())
		If !player.IsInCombat()
			EndEncounter()
		EndIf
		Return
	EndIf
	If encStage == STAGE_DONE
		Return
	EndIf
	If encType == ENC_AMBUSH
		If AllHostilesDead()
			encStage = STAGE_DONE
		EndIf
	ElseIf encType == ENC_MERCHANT
		TickMerchant(player)
	ElseIf encType == ENC_DESERTERS
		TickDeserters(player)
	ElseIf encType == ENC_COURIER
		TickCourier(player)
	EndIf
EndFunction

Function TickMerchant(Actor player)
	If !victim || victim.IsDead()
		encStage = STAGE_DONE
		Return
	EndIf
	If !AllHostilesDead()
		Return
	EndIf
	If victim.GetDistance(player) <= RWD_TalkDistance.GetValue() * 1.5 && !player.IsInCombat()
		Int gold = RewardGold(player, 1.5)
		player.AddItem(Gold001, gold, True)
		RWD_MsgMerchantThanks.Show(gold as Float)
		encStage = STAGE_DONE
	EndIf
EndFunction

Function TickDeserters(Actor player)
	If encStage == STAGE_FIGHT
		If AllHostilesDead()
			encStage = STAGE_DONE
		EndIf
		Return
	EndIf
	If AllHostilesDead()
		encStage = STAGE_DONE
		Return
	EndIf
	; Someone threw the first punch: no more talking.
	If AnyHostileInCombat()
		TurnHostile(player)
		Return
	EndIf
	Actor nearest = NearestHostile(player)
	If !nearest || nearest.GetDistance(player) > RWD_TalkDistance.GetValue() || player.IsInCombat()
		Return
	EndIf
	Int toll = RWD_TollBase.GetValueInt() + 5 * player.GetLevel()
	Int choice = RWD_MsgDeserters.Show(toll as Float)
	If choice == 0
		If player.GetItemCount(Gold001) >= toll
			player.RemoveItem(Gold001, toll)
			SendAway()
			RWD_MsgDesertersPaid.Show()
		Else
			RWD_MsgNoGold.Show()
			TurnHostile(player)
		EndIf
	ElseIf choice == 1
		If player.GetActorValue("Speechcraft") >= RWD_IntimidateSpeech.GetValue()
			SendAway()
			RWD_MsgDesertersCowed.Show()
		Else
			RWD_MsgDesertersBluff.Show()
			TurnHostile(player)
		EndIf
	Else
		TurnHostile(player)
	EndIf
EndFunction

Function TurnHostile(Actor player)
	Int i = 0
	While i < MAX_ACTORS
		Actor a = hostiles[i]
		If a && !a.IsDead()
			a.SetActorValue("Aggression", 2.0)
			a.StartCombat(player)
		EndIf
		i += 1
	EndWhile
	encStage = STAGE_FIGHT
EndFunction

; Paid or cowed: they fade out and are cleaned up.
Function SendAway()
	Int i = 0
	While i < MAX_ACTORS
		Actor a = hostiles[i]
		If a && !a.IsDead()
			a.Disable(True)
			a.Delete()
			hostiles[i] = None
		EndIf
		i += 1
	EndWhile
	encStage = STAGE_DONE
EndFunction

Function TickCourier(Actor player)
	If encStage == STAGE_FIGHT
		If AllHostilesDead()
			encStage = STAGE_DONE
		EndIf
		Return
	EndIf
	If !victim || victim.IsDead()
		encStage = STAGE_DONE
		Return
	EndIf
	If victim.GetDistance(player) > RWD_TalkDistance.GetValue() || player.IsInCombat()
		Return
	EndIf
	Bool asking = True
	While asking
		Int choice = RWD_MsgCourier.Show()
		If choice == 0
			Form potion = FindPotion(player)
			If potion
				player.RemoveItem(potion, 1)
				CourierHelped(player)
				asking = False
			Else
				RWD_MsgNoPotion.Show()
			EndIf
		ElseIf choice == 1
			If KnowsHealing(player)
				CourierHelped(player)
				asking = False
			Else
				RWD_MsgNoSpell.Show()
			EndIf
		Else
			encStage = STAGE_DONE
			asking = False
		EndIf
	EndWhile
EndFunction

Function CourierHelped(Actor player)
	victim.RestoreActorValue("Health", 10000.0)
	Int gold = RewardGold(player, 1.0)
	player.AddItem(Gold001, gold, True)
	RWD_MsgCourierThanks.Show(gold as Float)
	encStage = STAGE_DONE
	If Utility.RandomInt(1, 100) <= RWD_PursuitPct.GetValueInt()
		ObjectReference spot = PickSpot(player, RWD_SpawnMinDist.GetValue(), RWD_SpawnMaxDist.GetValue())
		If !spot
			spot = anchor
		EndIf
		SpawnHighwaymen(spot, HostileCount(player), player)
		Notify(RWD_MsgPursuers)
		encStage = STAGE_FIGHT
	EndIf
EndFunction

Form Function FindPotion(Actor player)
	Int i = 0
	Int n = RWD_HealingPotions.GetSize()
	While i < n
		Form p = RWD_HealingPotions.GetAt(i)
		If p && player.GetItemCount(p) > 0
			Return p
		EndIf
		i += 1
	EndWhile
	Return None
EndFunction

Bool Function KnowsHealing(Actor player)
	Int i = 0
	Int n = RWD_HealingSpells.GetSize()
	While i < n
		Form s = RWD_HealingSpells.GetAt(i)
		If s && player.HasSpell(s)
			Return True
		EndIf
		i += 1
	EndWhile
	Return False
EndFunction

Int Function RewardGold(Actor player, Float afMult)
	Return ((RWD_RewardBase.GetValue() + 10.0 * player.GetLevel()) * afMult) as Int
EndFunction

; ---------------------------------------------------------------------------
; Helpers
; ---------------------------------------------------------------------------

Bool Function AllHostilesDead()
	Int i = 0
	While i < MAX_ACTORS
		If hostiles[i] && !hostiles[i].IsDead()
			Return False
		EndIf
		i += 1
	EndWhile
	Return True
EndFunction

Bool Function AnyHostileInCombat()
	Int i = 0
	While i < MAX_ACTORS
		If hostiles[i] && !hostiles[i].IsDead() && hostiles[i].IsInCombat()
			Return True
		EndIf
		i += 1
	EndWhile
	Return False
EndFunction

Actor Function NearestHostile(Actor player)
	Actor best = None
	Float bestDist = 0.0
	Int i = 0
	While i < MAX_ACTORS
		Actor a = hostiles[i]
		If a && !a.IsDead()
			Float d = a.GetDistance(player)
			If !best || d < bestDist
				best = a
				bestDist = d
			EndIf
		EndIf
		i += 1
	EndWhile
	Return best
EndFunction

; Living spawns are removed; bodies are flagged for deletion and vanish when their cell unloads.
Function ClearActors()
	Int i = 0
	While i < MAX_ACTORS
		If hostiles[i]
			RemoveActor(hostiles[i])
			hostiles[i] = None
		EndIf
		i += 1
	EndWhile
	If victim
		RemoveActor(victim)
		victim = None
	EndIf
EndFunction

Function RemoveActor(Actor akActor)
	If !akActor.IsDead()
		akActor.Disable()
	EndIf
	akActor.Delete()
EndFunction

Function EndEncounter()
	Debug.Trace("[Roadwarden] RWD_ encounter " + encType + " ended (stage " + encStage + ")")
	ClearActors()
	encType = ENC_NONE
	encStage = STAGE_OPEN
	anchor = None
EndFunction
