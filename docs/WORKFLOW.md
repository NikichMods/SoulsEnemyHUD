# Work and verification

Read AGENTS.md and current NikichMods/DevRules. This repository owns only SoulsEnemyHUD; sibling mod changes require their own scope/evidence. VERSION, docs/STATUS.md and exact candidate records govern stable vs pending state.

Run `python tools/test.py` from this repository with Python 3 and dependencies in requirements-test.txt. Where no executable tests exist, the runner reports that fact; validate the authored recipe/fragment or research documents without claiming a runtime build. Research harnesses stay separate and are not current installation tasks. No new hosted CI is required for this source-preserving split.

Runtime files and historical evidence were copied without reconstruction. Do not rebuild a frozen version. New production behavior requires ENGINEERING_RULES readiness, focused offline checks and the project's real-game acceptance. No installation or runtime test is part of the organizational migration.

Use one writer per checkout and separate worktrees for concurrency. Keep game deployment serialized, with a closed host and verified backup outside loader directories. Never launch/terminate the game automatically or use unverified hot reload. Do not change unrelated mods, settings or saves.

Shared research: [Asterigos-Research](https://github.com/NikichMods/Asterigos-Research/blob/main/docs/RESEARCH_INDEX.md). Mod-specific acceptance and implementation stay here. See LOCAL_DEPENDENCIES.md for external inputs and MIGRATION.md for exact historical identity.
