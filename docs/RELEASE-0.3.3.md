# SoulsEnemyHUD 0.3.3

User accepted the in-game run on 2026-11-05. UE4SS loaded 0.3.3, registered both
HUD Tick hooks once and verified compact enemy HP. No SoulsEnemyHUD setup or Lua
errors were found. Genesis.log records RequestExit(0) and orderly engine shutdown.

- Exact runtime source: `cc5974b9406d8ff1b38c36114abffa21db846235`
- [Source CI](https://github.com/NikichMods/SoulsEnemyHUD/actions/runs/41187455602)
- Original accepted Lua update: `SoulsEnemyHUD-0.3.3-LuaUpdate.zip`
- ZIP SHA-256: `3f4c1723d074041d6e349eed8e89a23d726a821adaa741f6d0672db69e88c408`
- Required 0.3.1 z330 pak SHA-256: `288ebe6df6018a4067be2cbe45951ef103d6e708e4065eb08d8e0785e832fa3f`
- Private acceptance UE4SS.log SHA-256: `f2cc24a824b031465906ba00317e15af68c5b232a391c1b9d23874ebd3e544c7`
- Private acceptance Genesis.log SHA-256: `1c4c9f910b61ff3ac70a54bd9625506fb5734208827eb19e20c3416401038a21`

Use the [0.3.1 base](https://github.com/NikichMods/SoulsEnemyHUD/releases/tag/v0.3.1)
and apply this Lua update to the UE4SS Mods folder with the game closed.
The ZIP preserves its original test-era README as part of the accepted archive.
See [candidate evidence and rollback](CANDIDATE-0.3.3.md).
