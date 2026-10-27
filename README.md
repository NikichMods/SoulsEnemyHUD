# SoulsEnemyHUD

Compact enemy health bars, accumulated damage and a separate lock-on dot for **Asterigos: Curse of the Stars**.

**Stable version: 0.3.1.** Download the ZIP from [GitHub Releases](https://github.com/NikichMods/SoulsEnemyHUD/releases/latest).

## Features

- Compact enemy HP bars with a trailing damage indicator and accumulated damage.
- Bosses use their native large bar; duplicate small HP bars/numbers are hidden while the lock-on dot stays visible.
- Matching boss HP/trail colors, accumulated damage to the right, and a decorative Aphes inscription above the bar. Long inscriptions fit within 90% of the full bar width. The localized name stays below it.
- Includes the soft-edged subtitle backdrop from SubtitleSoftEdges.

## Requirements and installation

Tested on Steam 1.09/build12996889, Windows x64, UE4.27, with UE4SS v3.0.1-1181-g83330635 and its UEHelpers module. Other builds are unverified. UE4SS is required and is not bundled.

1. Close the game and install the external UE4SS/UEHelpers runtime if needed.
2. Extract `SoulsEnemyHUD-0.3.1.zip` into the game installation folder containing `Asterigos.exe`, merging its `Genesis` folder.
3. The archive places Lua under `Genesis/Binaries/Win64/ue4ss/Mods/SoulsEnemyHUD/Scripts/` and `z330_SoulsEnemyHUD_P.pak` under `Genesis/Content/Paks/~mods/`. The included `enabled.txt` enables the mod; if you already explicitly list SoulsEnemyHUD as disabled in `mods.txt`, set its value to `1`.

## Compatibility and removal

The package replaces the complete `Hud.html` resource. Other mods replacing that resource need a compatible combined version; load order alone does not merge edits. The bundled resource already includes SubtitleSoftEdges: disabling a separate subtitle pak does not remove that style while this package is active.

The decorative boss inscription can shift horizontally as it appears; this is an accepted cosmetic limitation.

To uninstall, close the game, remove the `SoulsEnemyHUD` mod folder and `z330_SoulsEnemyHUD_P.pak`. If manually added, remove its `mods.txt` entry. Leave other mods and UE4SS files intact.

Original project code is MPL-2.0; game-owned content in the modified HUD retains its original rights and is not covered by that license. Fonts and third-party loader binaries are not included. See [LICENSING.md](LICENSING.md).

[Verified runtime](docs/VERIFIED_RUNTIME.md) · [Release identity](docs/RELEASE-0.3.1.md) · [Changelog](CHANGELOG.md).
