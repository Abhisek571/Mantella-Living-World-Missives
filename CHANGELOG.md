# Changelog

Every change to Mantella Living World - Missives. The Nexus page lists only the main changes for each version.

## 1.1.1 (2026-11-18)

### Changed
- The job quests are looked through only when Missives is installed, once per location change (not again at every talk start), with what each job giver posted kept until then.
- Without Mantella Living World - World, a location change no longer looks through every job quest; the job list is built at the next talk instead.
- An NPC's file is saved at talk start only when their job line changed.
- Job lines name the job giver instead of saying "you", so in a group talk another NPC no longer takes the job as their own. After updating, a job an NPC already offered may be offered once more, because its wording changed.
- The job list is built about 10 seconds after a load, so the first talk no longer waits on it or reads an old job line.
- With Mantella Living World - World, a job giver no longer walks up about a job that was taken or changed meanwhile.

### Fixed
- A job giver talked to while the job list is being rebuilt no longer denies her notice, and a giver whose job quest was restarted with someone else no longer claims the job.
- An NPC no longer keeps talking about an old job after Missives is removed.
- A job giver's line follows a new job posted on the same quest instead of describing the old one.
- A location change during a job list rebuild is no longer missed: the list is built once more afterwards.

## 1.1.0 (2026-11-09)

### New
- An NPC stops offering a job once it is taken or gone.

### Fixed
- When one job was taken, the same NPC's other job offer was lost.

## 1.0.1 (2026-10-30)
- Adds the version file the Integration Hub's update check reads. No change in game.

## 1.0.0 (2026-10-30)
- First release. Requires Mantella Living World - Integration Hub and Missives.
