"""Writes the Missives module's plugin as Spriggit YAML: one quest running MLWM_Jobs, with a player alias that
re-registers its events on every game load. No Missives master: the job quests are found by editor id at run time.
Run from the project root."""
import json, os

E = 'Mantella Living World - Missives.esp'


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w', encoding='utf-8', newline='\n').write(text)


write(f'esp/Quests/MLWM_QuestJobs - 000800_{E}.yaml',
      f"FormKey: 000800:{E}\nEditorID: MLWM_QuestJobs\nVirtualMachineAdapter:\n  Scripts:\n  - Name: MLWM_Jobs\n    Properties:\n"
      f"    - MutagenObjectType: ScriptObjectProperty\n      Name: PlayerRef\n      Object: 000014:Skyrim.esm\n  FileName: ''\n"
      f"  Aliases:\n  - Property:\n      Name: ''\n      Object: 000800:{E}\n      Alias: 0\n    Scripts:\n    - Name: MLWM_PlayerAlias\n"
      f"Name:\n  TargetLanguage: English\n  Value: Mantella Living World - Missives jobs\nFlags:\n- StartGameEnabled\nNextAliasID: 1\n"
      f"Aliases:\n- Name: PlayerAlias\n  Flags: []\n  ForcedReference: 000014:Skyrim.esm\n  VoiceTypes: Null\n")
write('esp/RecordData.yaml', f'ModKey: {E}\nGameRelease: SkyrimSE\nModHeader:\n  Flags:\n  - Small\n  Author: itsPigeon2000\n'
      '  Description: Mantella Living World - Missives. NPCs know the Missives board jobs they posted.\n'
      '  MasterReferences:\n  - Master: Skyrim.esm\n    FileSize: 0\n')
write('esp/spriggit-meta.json', json.dumps({'PackageName': 'Spriggit.Yaml.Skyrim', 'Version': '0.40.0', 'Release': 'SkyrimSE', 'ModKey': E}, indent=2))
print('missives records written: 1 quest')
