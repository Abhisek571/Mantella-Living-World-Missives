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

Function Register()
	RegisterForModEvent("MantellaConversation_NPC_Added", "OnNpcAdded")
EndFunction

Event OnNpcAdded(Form akActor)
	Actor npc = akActor as Actor
	If !npc || npc == PlayerRef
		Return
	EndIf
	string path = DIR + BaseId(npc) + ".json"
	JsonUtil.SetStringValue(path, "job", JobsOf(npc))
	JsonUtil.Save(path)
EndEvent

; NPCs who come to talk (Mantella Living World - World, MLWW_Initiative): a giver of a posted job nearby has work to
; offer. Shared StorageUtil list, so neither module needs the other; each job is offered once.
Function OfferNearbyWork()
	int n = JsonUtil.StringListCount(JOBS, "quests")
	int i = 0
	While i < n
		string id = JsonUtil.StringListGet(JOBS, "quests", i)
		Quest q = Quest.GetQuest(id)
		If q && q.IsRunning() && q.GetStage() == 0 && StorageUtil.GetIntValue(q, "MLWM_Offered") == 0
			Actor giver = AliasActor(q, "QuestGiver")
			If giver && giver.Is3DLoaded() && !giver.IsDead() && giver.GetDistance(PlayerRef) < 3000.0
				StorageUtil.SetIntValue(q, "MLWM_Offered", 1)
				StorageUtil.FormListAdd(None, "MLWW_WantsToTell", giver, false)
				StorageUtil.SetStringValue(giver, "MLWW_WantsToTellWhy", "has work to offer: " + JobLine(q, id, giver))
			EndIf
		ElseIf q && !q.IsRunning()
			StorageUtil.UnsetIntValue(q, "MLWM_Offered")  ; a new job on the same quest may be offered again
		EndIf
		i += 1
	EndWhile
EndFunction

; One sentence per job this NPC gave (at most 2), or "".
string Function JobsOf(Actor akNpc)
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

; The job in this NPC's words, if they are its giver.
string Function JobLine(Quest akQuest, string asId, Actor akNpc)
	bool bounty = StringUtil.Find(asId, "Kill") >= 0 || StringUtil.Find(asId, "TrackFugitive") >= 0
	If bounty
		If AliasActor(akQuest, "Steward") != akNpc && AliasActor(akQuest, "Jarl") != akNpc
			Return ""
		EndIf
	ElseIf AliasActor(akQuest, "QuestGiver") != akNpc
		Return ""
	EndIf
	string item = AliasItem(akQuest, "Item")
	If item == ""
		item = AliasItem(akQuest, "Book")
	EndIf
	string what = ""
	If bounty
		string target = AliasName(akQuest, "target")
		If target == ""
			target = AliasName(akQuest, "Criminal")
		EndIf
		string place = AliasPlace(akQuest, "Dungeon")
		what = "The hold has posted a bounty"
		If target != ""
			what += " on " + target
		EndIf
		If place != ""
			what += " at " + place
		EndIf
	ElseIf StringUtil.Find(asId, "Courier") >= 0
		what = "You need " + Either(item, "a package") + " delivered"
		string to = AliasName(akQuest, "recipient")
		string city = AliasPlace(akQuest, "City")
		If to != ""
			what += " to " + to
		EndIf
		If city != ""
			what += " in " + city
		EndIf
	ElseIf StringUtil.Find(asId, "Retrieve") >= 0
		what = "You want " + Either(item, "something of yours") + " brought back"
		string place = AliasPlace(akQuest, "Dungeon")
		If place != ""
			what += " from " + place
		EndIf
	ElseIf StringUtil.Find(asId, "TrackThief") >= 0
		what = "A thief stole " + Either(item, "something") + " from you"
	Else
		what = "You need " + Either(item, "some goods") + " brought to you"
	EndIf
	If akQuest.GetStage() >= 20
		Return what + "; " + PlayerRef.GetDisplayName() + " took your notice from the job board and is on it."
	EndIf
	Return what + "; you posted a notice on the job board for it, and whoever wants the work takes the notice from there."
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
