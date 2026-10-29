# Mantella Living World - Missives

Mantella NPCs who posted a job on a [Missives](https://www.nexusmods.com/skyrimspecialedition/mods/20208) board know about it. A module of [Mantella Living World - Integration Hub](https://github.com/Abhisek571/Mantella-Living-World-Hub).

| Feature | What it does |
|---|---|
| Posters know their jobs | Ask the smith about work: he needs ore and the notice is on the board. Once you have taken the notice, he knows that too. An NPC mentions at most 2 jobs; finished jobs are dropped |
| Job wording | Courier, retrieve, thief and gather jobs each get their own wording. Bounties name the target and the dungeon |
| Hold bounties | The Steward or Jarl who posted a kill or fugitive bounty knows it |
| Expansions | With MissivesExpansion, its gather, find and similar jobs are covered too |
| Quest list | 284 job quests across the 9 Missives holds (264 from Missives, 20 from MissivesExpansion) |
| Walk-up offers | With the World module, a job giver within 3000 units of you who has a posted job can walk over to offer it, once per job |
| Knowledge | With the Knowledge module, a job that mentions an ore also gives that NPC up to two mines to talk about |
| Hub tab | The Hub's Living World tab shows a Missives row and lets you turn the rule off |

Without Missives the module does nothing. Old saves work: the module hooks Mantella's events again on every load. The poster only points you to the board; the NPC cannot hand out the job. Not tested with Land.esp, which overrides many of the Missives quests.

Requires: [Mantella Living World - Integration Hub](https://github.com/Abhisek571/Mantella-Living-World-Hub), [Mantella](https://www.nexusmods.com/skyrimspecialedition/mods/98631) 0.14, Mantella - Direct AI Connect with the Living World patch (the Hub's extension host; without it the job text never reaches the NPC), [Missives](https://www.nexusmods.com/skyrimspecialedition/mods/20208), SKSE and PapyrusUtil.
Optional: MissivesExpansion (the expansion jobs), Mantella Living World - World (walk-up offers), Mantella Living World - Knowledge (mines).

Build: the Hub's `tools/build.py --only missives`; `py -3 tools/make_records.py` writes the plugin as Spriggit YAML.

License: GNU AGPL-3.0.
