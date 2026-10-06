Scriptname RWD_PlayerAliasScript extends ReferenceAlias
{Roadwarden: restarts the road clock after a save is loaded.}

RWD_RoadScript Property Road Auto

Event OnPlayerLoadGame()
	Road.GameLoaded()
EndEvent
