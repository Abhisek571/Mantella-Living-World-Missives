Scriptname MLWM_Jobs extends Quest
{Mantella Living World - Missives: an NPC who posted a job on a Missives board knows about it. When an NPC joins a
Mantella conversation, the job quests (listed in MantellaLivingWorld/missives_jobs.json, editor ids) are checked; if
this NPC is the giver of a posted or taken job (the steward or Jarl for bounties), one line goes into their file
(npc/<base id>.json, "job") for the Integration Hub's extension. No master: without Missives nothing is found.

Missives keeps one quest per hold and job type: stage 0 posted on the board, 20 taken, 100 and up done.}

Actor Property PlayerRef Auto

string Property JOBS = "MantellaLivingWorld/missives_jobs.json" AutoReadOnly
string Property DIR = "MantellaLivingWorld/npc/" AutoReadOnly

Event OnInit()
	Register()
EndEvent

bool scanning = false  ; one scan of the job quests at a time
bool cached = false  ; the giver cache was built this session
bool rescan = false  ; a location change came during a scan: one more scan when it ends

Function Register()
	RegisterForModEvent("MantellaConversation_NPC_Added", "OnNpcAdded")
	scanning = false
	rescan = false
	cached = false  ; quests and aliases may differ in the loaded save: built again at the next location change or join
	RegisterForSingleUpdate(10.0)  ; build the cache soon after load, so the first talk does not wait on the scan
EndFunction

Event OnUpdate()
	If MissivesLoaded() && !cached && !scanning
		OfferNearbyWork(false)
	EndIf
EndEvent

bool Function MissivesLoaded()
	Return Game.IsPluginInstalled("Missives.esp")
EndFunction

Event OnNpcAdded(Form akActor)
	If StorageUtil.GetIntValue(None, "MLW_TimingOn", 0) == 1  ; speed testing (off by default): one stage-time row
		MiscUtil.WriteToFile("Data/SKSE/Plugins/StorageUtilData/MantellaLivingWorld/timing_game.csv", StorageUtil.GetIntValue(None, "MLW_TimingTalk", 0) + "," + Utility.GetCurrentRealTime() + ",MLWM_Jobs,OnNpcAdded_start,\n", true, false)
	EndIf
	Actor npc = akActor as Actor
	If !npc || npc == PlayerRef
		Return
	EndIf
	string path = DIR + BaseId(npc) + ".json"
	string job = ""  ; without Missives an old line is cleared
	If MissivesLoaded()
		job = JobsOf(npc)
	EndIf
	If JsonUtil.GetStringValue(path, "job") != job  ; written only when it changed
		JsonUtil.SetStringValue(path, "job", job)
		JsonUtil.Save(path)
	EndIf
	If StorageUtil.GetIntValue(None, "MLW_TimingOn", 0) == 1  ; speed testing (off by default): one stage-time row
		MiscUtil.WriteToFile("Data/SKSE/Plugins/StorageUtilData/MantellaLivingWorld/timing_game.csv", StorageUtil.GetIntValue(None, "MLW_TimingTalk", 0) + "," + Utility.GetCurrentRealTime() + ",MLWM_Jobs,OnNpcAdded_end,\n", true, false)
	EndIf
EndEvent

; NPCs who come to talk (Mantella Living World - World, MLWW_Initiative): a giver of a posted job nearby has work to
; offer. Shared StorageUtil list, so neither module needs the other; each job is offered once. An offer that is no
; longer true (the job was taken, finished, dropped or replaced by a new one) is taken back before the giver comes over.
; abLocationChange: called on a location change (false: a join building the giver cache).
Function OfferNearbyWork(bool abLocationChange = true)
	If !MissivesLoaded()
		Return
	EndIf
	; offers are for World's NPCs who walk up to the player; without World only the giver cache is built
	bool offers = Game.IsPluginInstalled("Mantella Living World - World.esp")
	If scanning
		If abLocationChange
			rescan = true
		EndIf
		Return
	EndIf
	If abLocationChange && !offers
		cached = false  ; no offers to make: the cache is built again at the next join
		Return
	EndIf
	scanning = true
	rescan = false
	bool again = true
	While again
		cached = false  ; while the cache is emptied and built again, a join reads the quests (ScanJobs), not half a cache
		ClearCache()
		int n = JsonUtil.StringListCount(JOBS, "quests")
		int i = 0
		While i < n
			string id = JsonUtil.StringListGet(JOBS, "quests", i)
			Quest q = Quest.GetQuest(id)
			If q && StorageUtil.GetIntValue(q, "MLWM_Offered") == 1
				Actor offeredTo = StorageUtil.GetFormValue(q, "MLWM_OfferedTo") as Actor
				If !q.IsRunning() || q.GetStage() != 0 || (offeredTo && JobLine(q, id, offeredTo) != StorageUtil.GetStringValue(q, "MLWM_OfferedLine"))
					WithdrawOffer(q)  ; a new job on the same quest may be offered again
				EndIf
			EndIf
			If q && q.IsRunning() && q.GetStage() < 100
				CacheQuest(q, id)
			EndIf
			If offers && q && q.IsRunning() && q.GetStage() == 0 && StorageUtil.GetIntValue(q, "MLWM_Offered") == 0
				Actor giver = AliasActor(q, "QuestGiver")
				If giver && giver.Is3DLoaded() && !giver.IsDead() && giver.GetDistance(PlayerRef) < 3000.0
					string line = JobLine(q, id, giver)
					If line != ""
						StorageUtil.SetIntValue(q, "MLWM_Offered", 1)
						StorageUtil.SetFormValue(q, "MLWM_OfferedTo", giver)
						StorageUtil.SetStringValue(q, "MLWM_OfferedLine", line)
						StorageUtil.FormListAdd(None, "MLWW_WantsToTell", giver, false)
						StorageUtil.SetStringValue(giver, "MLWW_WantsToTellWhy", "has work to offer: " + line)
						StorageUtil.SetFormValue(giver, "MLWW_WantsToTellQuest", q)  ; World drops the visit when this quest moves on
						StorageUtil.SetIntValue(giver, "MLWW_WantsToTellStage", q.GetStage())
					EndIf
				EndIf
			EndIf
			i += 1
		EndWhile
		cached = true
		again = rescan && offers
		If rescan && !offers
			cached = false  ; the location changed while a join built the cache
		EndIf
		rescan = false
	EndWhile
	scanning = false
EndFunction

; The giver cache: on each giver, the job quests they gave ("MLWM_JobIds") with the stage the line was made at
; ("MLWM_JobStages") and the line ("MLWM_JobLines"), so a join reads that instead of every job quest.
Function ClearCache()
	int i = StorageUtil.FormListCount(self, "MLWM_CachedGivers")
	While i > 0
		i -= 1
		Form giver = StorageUtil.FormListGet(self, "MLWM_CachedGivers", i)
		StorageUtil.StringListClear(giver, "MLWM_JobIds")
		StorageUtil.IntListClear(giver, "MLWM_JobStages")
		StorageUtil.StringListClear(giver, "MLWM_JobLines")
	EndWhile
	StorageUtil.FormListClear(self, "MLWM_CachedGivers")
EndFunction

Function CacheQuest(Quest akQuest, string asId)
	Actor[] candidates = new Actor[3]
	candidates[0] = AliasActor(akQuest, "QuestGiver")
	If !candidates[0]
		candidates[1] = AliasActor(akQuest, "Steward")
		candidates[2] = AliasActor(akQuest, "Jarl")
	EndIf
	int c = 0
	While c < 3
		Actor who = candidates[c]
		If who
			string line = JobLine(akQuest, asId, who)
			If line != ""
				StorageUtil.FormListAdd(self, "MLWM_CachedGivers", who, false)
				StorageUtil.StringListAdd(who, "MLWM_JobIds", asId)
				StorageUtil.IntListAdd(who, "MLWM_JobStages", akQuest.GetStage())
				StorageUtil.StringListAdd(who, "MLWM_JobLines", line)
			EndIf
		EndIf
		c += 1
	EndWhile
EndFunction

; Takes a job offer back: the giver no longer walks up about it (only when that is still their reason; another
; module's reason is left alone).
Function WithdrawOffer(Quest akQuest)
	Actor giver = StorageUtil.GetFormValue(akQuest, "MLWM_OfferedTo") as Actor
	If !giver
		giver = AliasActor(akQuest, "QuestGiver")  ; offers made before the giver was stored
	EndIf
	; Only when the reason is this job's line: one giver with two jobs keeps the reason of the other one. Offers made
	; before the line was stored match on the prefix.
	string why = StorageUtil.GetStringValue(giver, "MLWW_WantsToTellWhy")
	string offered = StorageUtil.GetStringValue(akQuest, "MLWM_OfferedLine")
	bool ours = StringUtil.Find(why, "has work to offer: ") == 0
	If offered != ""
		ours = why == "has work to offer: " + offered
	EndIf
	If giver && ours
		StorageUtil.FormListRemove(None, "MLWW_WantsToTell", giver, true)
		StorageUtil.UnsetStringValue(giver, "MLWW_WantsToTellWhy")
		StorageUtil.UnsetFormValue(giver, "MLWW_WantsToTellQuest")
		StorageUtil.UnsetIntValue(giver, "MLWW_WantsToTellStage")
	EndIf
	StorageUtil.UnsetIntValue(akQuest, "MLWM_Offered")
	StorageUtil.UnsetFormValue(akQuest, "MLWM_OfferedTo")
	StorageUtil.UnsetStringValue(akQuest, "MLWM_OfferedLine")
EndFunction

; One sentence per job this NPC gave (at most 2), or "". From the giver cache when it was built this session: the
; cache says which jobs to look at, and each line is worked out again (the job may have changed on the same quest).
string Function JobsOf(Actor akNpc)
	If !cached && !scanning
		OfferNearbyWork(false)  ; the first join after a load, before any location change
	EndIf
	If cached
		Return CachedJobs(akNpc)
	EndIf
	Return ScanJobs(akNpc)
EndFunction

string Function CachedJobs(Actor akNpc)
	string out = ""
	int found = 0
	int count = StorageUtil.StringListCount(akNpc, "MLWM_JobIds")
	int i = 0
	While i < count && found < 2
		string id = StorageUtil.StringListGet(akNpc, "MLWM_JobIds", i)
		string line = ""
		Quest q = Quest.GetQuest(id)
		If q && q.IsRunning() && q.GetStage() < 100 && StillGiver(q, akNpc)  ; not gone, finished, or given to another
			line = JobLine(q, id, akNpc)
		EndIf
		If line != ""
			If out != ""
				out += " "
			EndIf
			out += line
			found += 1
		EndIf
		i += 1
	EndWhile
	Return out
EndFunction

string Function ScanJobs(Actor akNpc)
	string out = ""
	int found = 0
	int n = JsonUtil.StringListCount(JOBS, "quests")
	int i = 0
	While i < n && found < 2
		string id = JsonUtil.StringListGet(JOBS, "quests", i)
		Quest q = Quest.GetQuest(id)
		If q && q.IsRunning() && q.GetStage() < 100
			string line = JobLine(q, id, akNpc)
			If line != ""
				If out != ""
					out += " "
				EndIf
				out += line
				found += 1
			EndIf
		EndIf
		i += 1
	EndWhile
	Return out
EndFunction

; The job in a line about this NPC (by name), if they are its giver.
string Function JobLine(Quest akQuest, string asId, Actor akNpc)
	; a quest with a QuestGiver (Missives Expansion KillPests) is that person's job, not a hold bounty
	Actor giver = AliasActor(akQuest, "QuestGiver")
	bool kill = StringUtil.Find(asId, "Kill") >= 0
	bool bounty = !giver && (kill || StringUtil.Find(asId, "TrackFugitive") >= 0)
	If bounty
		If AliasActor(akQuest, "Steward") != akNpc && AliasActor(akQuest, "Jarl") != akNpc
			Return ""
		EndIf
	ElseIf !giver || giver != akNpc
		Return ""
	EndIf
	string item = AliasItem(akQuest, "Item")
	If item == ""
		item = AliasItem(akQuest, "Book")
	EndIf
	string who = akNpc.GetDisplayName()
	string what = ""
	If bounty
		string target = AliasName(akQuest, "target")
		If target == ""
			target = AliasName(akQuest, "Criminal")
		EndIf
		string place = AliasPlace(akQuest, "Dungeon")
		If place == ""
			place = AliasPlace(akQuest, "Den")
		EndIf
		what = "The hold has posted a bounty"
		If target != ""
			what += " on " + target
		EndIf
		If place != ""
			what += " at " + place
		EndIf
	ElseIf kill
		what = who + " wants the " + Either(AliasName(akQuest, "Target"), "pests") + " nearby dealt with"
		string den = AliasPlace(akQuest, "Den")
		If den != ""
			what += "; they are at " + den
		EndIf
	ElseIf StringUtil.Find(asId, "Courier") >= 0
		what = who + " needs " + Either(item, "a package") + " delivered"
		string to = AliasName(akQuest, "recipient")
		string city = AliasPlace(akQuest, "City")
		If to != ""
			what += " to " + to
		EndIf
		If city != ""
			what += " in " + city
		EndIf
	ElseIf StringUtil.Find(asId, "Retrieve") >= 0
		what = who + " wants " + Either(item, "a lost belonging") + " brought back"
		string place = AliasPlace(akQuest, "Dungeon")
		If place != ""
			what += " from " + place
		EndIf
	ElseIf StringUtil.Find(asId, "TrackThief") >= 0
		what = "A thief stole " + Either(item, "something") + " from " + who
	Else
		what = who + " wants " + Either(item, "some goods") + " brought over"
	EndIf
	If akQuest.GetStage() >= 20
		Return what + "; " + PlayerRef.GetDisplayName() + " took " + who + "'s notice from the job board and is on it."
	EndIf
	Return what + "; " + who + " posted a notice on the job board, and whoever wants the work takes it from there."
EndFunction

; akNpc still holds the job quest's giver role, as CacheQuest picks it: the quest giver, else the steward or the Jarl.
bool Function StillGiver(Quest akQuest, Actor akNpc)
	Actor giver = AliasActor(akQuest, "QuestGiver")
	If giver
		Return giver == akNpc
	EndIf
	Return AliasActor(akQuest, "Steward") == akNpc || AliasActor(akQuest, "Jarl") == akNpc
EndFunction

Actor Function AliasActor(Quest akQuest, string asAlias)
	ReferenceAlias a = akQuest.GetAliasByName(asAlias) as ReferenceAlias
	If a
		Return a.GetActorRef()
	EndIf
	Return None
EndFunction

string Function AliasName(Quest akQuest, string asAlias)
	ReferenceAlias a = akQuest.GetAliasByName(asAlias) as ReferenceAlias
	If a && a.GetRef()
		Return a.GetRef().GetDisplayName()
	EndIf
	Return ""
EndFunction

string Function AliasItem(Quest akQuest, string asAlias)
	ReferenceAlias a = akQuest.GetAliasByName(asAlias) as ReferenceAlias
	If a && a.GetRef() && a.GetRef().GetBaseObject()
		Return a.GetRef().GetBaseObject().GetName()
	EndIf
	Return ""
EndFunction

string Function AliasPlace(Quest akQuest, string asAlias)
	LocationAlias l = akQuest.GetAliasByName(asAlias) as LocationAlias
	If l && l.GetLocation()
		Return l.GetLocation().GetName()
	EndIf
	Return ""
EndFunction

string Function Either(string asValue, string asFallback)
	If asValue != ""
		Return asValue
	EndIf
	Return asFallback
EndFunction

; The base record's FormID as its last 6 hex digits, like the Integration Hub's file channel.
string Function BaseId(Actor akNpc)
	string digits = "0123456789ABCDEF"
	int v = akNpc.GetActorBase().GetFormID()
	string out = ""
	int i = 0
	While i < 6
		out = StringUtil.GetNthChar(digits, Math.LogicalAnd(v, 15)) + out
		v = Math.RightShift(v, 4)
		i += 1
	EndWhile
	Return out
EndFunction
