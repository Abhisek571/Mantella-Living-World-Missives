# Mantella Living World - Missives

[Mantella](https://www.nexusmods.com/skyrimspecialedition/mods/98631) NPCs who posted a job on a
[Missives](https://www.nexusmods.com/skyrimspecialedition/mods/20208) board know about it. Ask the smith about work
and he tells you he needs ore and that the notice is on the board; once you have taken the notice, he knows that too.
Stewards and Jarls know the bounties their hold posted. A module of
[Mantella Living World - Integration Hub](https://github.com/Abhisek571/Mantella-Living-World-Hub).

Requires Mantella, the Integration Hub and Missives (the Voice and Quest Expansion jobs are covered too). Without
Missives the module does nothing.

## Build

`py -3 tools/make_records.py` writes the plugin as Spriggit YAML; the Hub's `tools/build.py --only missives` builds
the mod.
