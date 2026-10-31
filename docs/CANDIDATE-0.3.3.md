# SoulsEnemyHUD 0.3.3 — Lua scheduler candidate

Status: installed with game closed on 2026-10-31; **runtime acceptance pending**.
Stable main/tag/release remains 0.3.1. The stopped 0.3.2 appearance experiment is excluded.

Branch: `fix/safe-game-thread-scheduler`.
Exact runtime source: `cc5974b9406d8ff1b38c36114abffa21db846235`.
[Exact-source CI passed](https://github.com/NikichMods/SoulsEnemyHUD/actions/runs/41187455602). Local `python tools/test.py` passed; output retained privately with the candidate.

## Change and evidence

`LoopAsync` / nested `ExecuteInGameThread` / pending flag are replaced by one
`LoopInGameThreadWithDelay(1000, callback)` and a stored cancellation handle.
Setup order, existing two Tick paths, boss association, damage/HP/dot policy stay
as before. Fatal setup failures disable owned callback bodies, stop the boss bridge
in pure Lua, restore owned widgets/opacity best-effort and cancel last. No UObject
calls after cancellation; no added native hook, worker or periodic job.

Tests exercise actual production Lua in strict mocks: timer registration once,
nominal 1000ms/no catch-up, nested Tick/setup reentry, no duplicate hooks,
missing/reappearing HUDs, cancellation/registration/cleanup faults and inert
callbacks. Real boss module stop and existing policy/bridge/UI tests passed.
Mock timing is a pinned-source contract check, not a native runtime measurement.
See [readiness and upstream limitations](SCHEDULER_READINESS.md).

## Exact bytes and installation

Lua-only ZIP: `SoulsEnemyHUD-0.3.3-LuaUpdate.zip` (requires accepted 0.3.1 pak).
SHA256: `3f4c1723d074041d6e349eed8e89a23d726a821adaa741f6d0672db69e88c408`.

| Installed path | SHA256 |
|---|---|
| `Scripts/main.lua` | `6ccb45cb6b6d8fdf700035f3926249df2f3580ae98d21b8acf0ce8445cdfc686` |
| `Scripts/boss.lua` | `c2d9a4f2309c524efb8124737a16c9f2e05956c5932a160aa8f36c6c2689c6db` |
| `Scripts/policy.lua` | `98c003f7ec48d34923809cb7cfefe089f3da1b4178492134ff86a7c02761e254` |
| `VERSION` | `44919006fb7aff92e5c31d5d94bc563d9b3b16a00646d4c1831cc32b538b599b` |

`git diff v0.3.1 -- UI Scripts/policy.lua tools/build_boss_ui.py` is empty.
No HTML, CSS, JS, fonts, SubtitleSoftEdges or pak was built or replaced.
Installed z330 SHA256 before/after:
`288ebe6df6018a4067be2cbe45951ef103d6e708e4065eb08d8e0785e832fa3f`.
The accepted deployment's Hud.html SHA256 remains
`6d4231d7c008d5a055b5fce384784f8b782c053d4c06067ebbb0f0223e8cb00a`;
this task verifies the unchanged enclosing pak rather than extracting/rebuilding HTML.

Before installation, verified all three installed 0.3.1 Lua files against the
accepted deployment and CombatHUD against accepted 0.4.1 source/manifest.
Game process absence checked before each write; 59 neighbor files including
other mods, settings/mods.txt and pak files hash-identical before/after.
Only own main.lua, boss.lua and previously absent VERSION were written;
policy.lua bytes were already identical. Game was not launched or terminated.
Private evidence: `.local/candidates/SoulsEnemyHUD-0.3.3/deployment.json`,
exact `payload/`, `previous-payload/`, pretest UE4SS log, ZIP/checksums and rollback.

## User test and rollback

Launch normally. Wait for setup, check an ordinary enemy: compact HP/trail,
summed damage, lock dot; then a boss: native large HP/damage/Aphes and no duplicate
small boss bar/digits. Check pause/resume and, if convenient, one area transition.
No boss kill/death is required for this scheduler smoke test. Close normally and
return for UE4SS/native log review. A short pass cannot prove absence of crashes.

With game closed run the private candidate's `rollback.ps1` (or have Codex do it).
It validates current candidate hashes, all backups and the unchanged pak before
restoring three exact 0.3.1 Lua files and removing the new root VERSION to recover
its prior absence. It verifies restored hashes. Script syntax parsed offline;
a live rollback was not performed because that would uninstall this candidate.
Do not copy a backup folder into the loader or touch other mods/pak.

This removes one async producer; it does not establish HildaSoftLight crash
causality or eliminate UE4SS shared-registry/GC/teardown hazards. Existing boss
limitations and accepted appearance quirk remain. No hot reload or stable promotion.
No new transferable engine finding: reuse Asterigos-Research R-008; no duplicate
shared-research update is needed.
