# GameThread setup scheduler — 2026-10-31

## Pre-mutation evidence gate — READY for candidate, not game acceptance

Scope: replace only stable 0.3.1 recurring async setup with one nominal 1000ms
GameThread timer. Base main c098bd650b2b564f981b26e416ffca5b3dd98719; accepted
runtime source 9f2cf4e6e75b665c3f1cb5573acf701583c98a1c. No UI/pak modification.

Owner/final consumer: pinned UE4SS LuaMod.cpp delayed-action registry and
process_delayed_actions; final presentation still belongs to unchanged overhead
Tick logic and native Coherent HTML. Existing setup order is Boss.poll, stale
entry cleanup, floating hook registration, HudUmg scan, overhead hook registration.
Keep that order and the same hook paths/bodies; add only disabled guards.

Installed UE4SS DLL SHA256 ce5e3c46a920cc00b2817ac61e438c9162830290379d0b5b9c4dfc2b29459290
matches the established 83330635 dependency. Prior source/runtime evidence is
Asterigos-Research R-008 and CombatHUD SCHEDULER_READINESS/CANDIDATE-0.4.1.
[Exact source](https://github.com/UE4SS-RE/RE-UE4SS/blob/8333063595fa3c49ad307f3b0f732accbb760d25/UE4SS/src/Mod/LuaMod.cpp):
3949–4090 marks actions Executing, suppresses nested action execution, ignores
callback return values and rearms after the batch without catch-up.4716–4792
registers one loop and returns its handle;5115–5159 marks an owned action for
removal. Current config selects EngineTick; fallback/source semantics do not prove
every possible ProcessEvent caller is the GameThread.

Choice: LoopInGameThreadWithDelay(1000, callback), no extra dispatch/producer,
no new hooks/framework. Keep the two existing Tick hooks registered once; on
setup failure make main hook bodies inert and stop the boss bridge through a
new pure-Lua stop method. Restore existing overhead entries best-effort and
restore captured floating-pool opacity BEFORE cancellation: pinned code retains
action-vector indices across unlocked callbacks and nested ProcessEvent may
clean pending removals. Do no UObject calls after cancellation. A failed cancel
is reported once; an inert callback cannot keep doing setup. No live unhook or
restart is introduced. Boss identification/batches/identity algorithm is unchanged.

Blast radius: setup scheduling, owned error shutdown and owned cleanup only.
Preserve HP/width/trail/damage/dot policy, association and binding order, all UI
bytes, full-bar behavior, native menu/owner checks and accepted appearance quirk.
Baseline local tests passed. Verify sequential setup/no duplicate hooks, missing
objects, reentrant Tick calls, error/cancel/restore failure, inert delivery, exact
pak/UI bytes and unchanged policy through offline models and source diff. Actual
engine timing, rendering, native registry/lifecycle safety need user acceptance.

## Upstream status and limits

[Official delayed actions](https://docs.ue4ss.com/dev/lua-api/global-functions/delayedactions.html)
requires handle cancellation. [1345](https://github.com/UE4SS-RE/RE-UE4SS/issues/1345)
reports shared-registry/async concurrency; maintainer recommends delayed GT APIs.
[1456](https://github.com/UE4SS-RE/RE-UE4SS/issues/1456) is another game's crash report
and is not proof of its reporter's proposed cause in Asterigos.
[1445](https://github.com/UE4SS-RE/RE-UE4SS/issues/1445) also reports load/teardown
races without async callbacks. Removing this producer does not upgrade UE4SS or
prove all shared-state/GC/native hook hazards fixed. HildaSoftLight causality is
unknown. Successful CombatHUD0.4.1 acceptance permits serialized testing of this
new candidate, not skipping its own game acceptance.
