Scriptname MLWM_PlayerAlias extends ReferenceAlias
{Player alias of the Missives job quest: re-registers its events on every game load (saves made before the quest
existed never ran OnInit again) and looks for job givers nearby on each location change.}

Event OnPlayerLoadGame()
	MLWM_Jobs jobs = GetOwningQuest() as MLWM_Jobs
	If jobs
		jobs.Register()
	EndIf
EndEvent

Event OnLocationChange(Location akOldLoc, Location akNewLoc)
	MLWM_Jobs jobs = GetOwningQuest() as MLWM_Jobs
	If jobs
		jobs.OfferNearbyWork()
	EndIf
EndEvent
