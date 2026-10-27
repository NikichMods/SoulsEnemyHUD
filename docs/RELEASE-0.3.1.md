# SoulsEnemyHUD 0.3.1

Accepted in game and authorized for stable promotion/public release on 2026-10-28.
Runtime source: `9f2cf4e6e75b665c3f1cb5573acf701583c98a1c`. Tag `v0.3.1` freezes that exact source.
Subsequent stable-promotion commits change documentation only; no runtime rebuild.

- ZIP: `SoulsEnemyHUD-0.3.1.zip`
- ZIP SHA256: `c2caf38d4c5ef5b97da5440dbb0fb805d19d10d7ed982dfdb107faf6a1b9d37a`
- SHA256SUMS.txt SHA256: `17654e6c23f706aa0546b5c84a58f038a65c3465c362eb93a739bb2faecdb287`
- Accepted pak SHA256: `288EBE6DF6018A4067BE2CBE45951EF103D6E708E4065EB08D8E0785E832FA3F`
- main.lua SHA256: `0275DBB11F0CA094F940734504A3B9E9B6CE0DEDF1D27E78F34FB7A56F9207DD`
- policy.lua SHA256: `98C003F7EC48D34923809CB7CFEFE089F3DA1B4178492134FF86A7C02761E254`
- boss.lua SHA256: `BEFF1F61A4482914FB777910FDFE9B98494D2F1824B0AA5026A6A18AC2696BDB`

The archive copies the exact accepted Lua and already-built pak, with an activation
marker and original source/license/install metadata. ZIP extraction was compared
byte-for-byte against accepted payloads. No loader binaries or fonts are bundled.
The complete modified Hud.html includes the unchanged SubtitleSoftEdges patch.
MPL applies only to original project code, not game-owned portions.

[Stable release](https://github.com/NikichMods/SoulsEnemyHUD/releases/tag/v0.3.1).
Logs, screenshot and visual/user acceptance are recorded in VERIFIED_RUNTIME.md.
Victory/multiple simultaneous bosses are not newly claimed. The native font class
now renders the desired glyphs in the accepted session; the exact 0.3.0 failure
was not retrospectively diagnosed.
