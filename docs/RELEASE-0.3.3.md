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

## Complete installation archive

Download [SoulsEnemyHUD-0.3.3.zip](https://github.com/NikichMods/SoulsEnemyHUD/releases/download/v0.3.3/SoulsEnemyHUD-0.3.3.zip) and extract it into the game directory, merging the Genesis folder. Requires the external UE4SS runtime and UEHelpers. The archive includes the activation marker and exact accepted Lua and z330 pak. Extraction into an empty directory verified every file.

- Complete ZIP SHA-256: `008083b0952020bdf3565a358b07d674e065d1972d3be6751f8c912c82395bde`
- [Complete ZIP checksum](https://github.com/NikichMods/SoulsEnemyHUD/releases/download/v0.3.3/SoulsEnemyHUD-0.3.3.zip.sha256)
- Pak provenance: published 0.3.1 ZIP, verified against the recorded release and pak digests.

The original Lua update and SHA256SUMS.txt remain available for users who already have the exact z330 pak. Both original assets were downloaded and hash-verified on 2026-11-05. See [candidate evidence and rollback](CANDIDATE-0.3.3.md).

The complete public ZIP and its checksum file were downloaded without authentication and matched the local SHA-256 digests.
