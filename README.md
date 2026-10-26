# SoulsEnemyHUD

Компактные полоски противников, маркер захвата и суммирующийся урон.

Status: accepted 0.1.0 baseline; 0.2.0 boss candidate awaits game acceptance.
No packaged public release yet. Target: Steam1.09/build12996889, Windows x64.

- [Current status and next task](docs/STATUS.md)
- [Adopted requirements](docs/REQUIREMENTS.md)
- [Verified runtime](docs/VERIFIED_RUNTIME.md)
- Version: VERSION in this directory.

Runtime Lua: Scripts/. Tests: tests/. Requires external UE4SS and UEHelpers; run from repository root: `python tools/test.py SoulsEnemyHUD`.

Boss candidate 0.2.0 additionally uses an authored HTML/CSS/JS addon, built locally
against verified game HTML; see [candidate mechanism/build/acceptance](docs/BOSS_IMPLEMENTATION.md).
The host-derived pak is local only and is not included in this source repository.

Original code is covered by repository MPL-2.0; see root LICENSING.md.
