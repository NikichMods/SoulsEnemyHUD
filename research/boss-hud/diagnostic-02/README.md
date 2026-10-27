# Boss link diagnostic 02 — player death and respawn

Research-only observer, Steam1.09/build12996889, UE4.27 and the installed UE4SS
v3.0.1-1181-g83330635. Production source, HP, equipment and save state are unchanged.
Payload id `boss-link-diagnostic-02`; immutable once handed/installed. This is not
a production version bump or a released package.

Script SHA256:
`08245B5996CD87CF154C5617E2C800318E2341AAB9B22B18F0FEE543DBFB58AA`.
The exact source commit and verified installed identity are recorded under root
ignored `.local/research/boss-hud/diagnostic-02/deployment.json`.

## Scope agreed with the user

The arena prevents ordinary retreat; another full fight is not required merely to
exercise cleanup. The user chose **natural player death -> respawn outside the
arena**. This tests the defeat/reset path, not boss victory. The expected reset is
a hypothesis to observe, not an assumed successful result. No damage multiplier,
special weapon, forced death, teleport, synthetic encounter or save modification.

Diagnostic 01 already proved the native outgoing source/overhead Avatar
association for the observed boss. This probe deliberately does not repeat its
Boss-query adapter or broad overhead registry. Static inspection and the first
session provide enough evidence to choose the actual outgoing boss event as the
source. New observation code is justified only by the missing native hide/state
and HUD lifecycle evidence; visual observation cannot supply those identities.

## What is measured

Four exact reflected hooks:

- `CoherentUIGTJSEvent:AddObject`: actual character attribute object used by the
  host's boss event, with reciprocal actor/component identity validation.
- `CoherentUIGTJSEvent:AddBool`: the actual visibility boolean, including false.
- `CoherentUIGTBaseComponent:TriggerJSEvent`: actual `UpdateBossStat` and
  `ToggleDisplayBossStat` inputs, with NormalHUDBP sender-component identity.
- `NormalHUDBP_C:UpdateBossStat` post: discover live HUD instances, including
  those whose native boss visibility is currently false.

Native input hooks use pre-callbacks; the Blueprint hook uses a post-callback.
This reuses the [RegisterHook contract](https://docs.ue4ss.com/dev/lua-api/global-functions/registerhook.html)
already examined for diagnostic 01. The new AddBool boundary still needs live
binding verification. All callbacks return nil; they do not override native results.

Static `Toggle Boss Stat` creates a LOCAL JS event and sends its own
`IsShowBossStat` boolean. Therefore visibility must not be checked against the
shared HUD JsEventObject; that shared-event check applies only to UpdateBossStat.
The relevant bytecode remains in ignored boss-hud/bytecode evidence from the first
investigation; no host Blueprint or HTML is patched/copied into this probe.

Log prefix is `BOSS_LINK_DIAGNOSTIC`; START must identify diagnostic-02.

| Record | Meaning |
| --- | --- |
| SOURCE | Validated native boss source and ready/shown HUD state; unchanged sources repeat at most every five seconds |
| VISIBILITY | Actual outgoing native show/hide boolean and contemporaneous HUD fields |
| HUD_STATE | One-second observations of shown/ready state, historical last source and its validity/ownership |
| HUD_REMOVED | Previously observed HUD is no longer valid |
| HEARTBEAT | Every ten seconds: scheduler still operates; required hooks are hooked/waiting/error |
| REJECT | Sample rejected; later samples, other objects and heartbeat continue |

`last_actor`/`previous_actor` are historical addresses, deliberately retained for
comparison. They do not claim the host stores or has cleared a boss link. A hide
event with shown=false while the boss object remains valid is useful evidence
that lifetime alone cannot control a production link. A new HUD starts without a
recorded source. Mere absence of SOURCE records does not prove cleanup.

No scene scan or native query invocation. Only known HUDs and their last validated
source are sampled. Per-object errors are contained; a malformed sender/payload
does not count as positive evidence. Pending event packets expire after two
seconds and are consumed by every observed dispatch. Maximum eight HUDs, 64
pending packets, thirty minutes or 600 log lines. After STOP callbacks are inert
until normal shutdown; no hot reload contract exists.

## Minimum game procedure

1. Launch the game yourself and enter the boss arena. Confirm the large bar has
   appeared; wait about five seconds. No need to repeat damage/lock-on tests.
2. Let the boss kill your character naturally. Do not close the game during the
   death transition; allow the ordinary respawn to finish.
3. Once control returns outside the arena, wait ten seconds. Note whether the
   large boss bar is gone. Then close the game and report the result.

Normal gameplay/save consequences of dying remain those of the unmodified game;
the observer makes no gameplay or save changes. If the bar does not appear, death
does not lead outside the arena, or the game requires another action, report the
actual state rather than treating the expected sequence as observed.

The agent installs only with the host closed, preserves the prior probe/log
outside loader paths, checks hashes and enables only this probe in the existing
SoulsEnemyHUDBossProbe loader folder. Production mod and mods.txt stay unchanged.
After the test the agent snapshots the local UE4SS.log before another launch and
disables the probe with the game closed. No console commands, uploads or manual
file operations are required from the user.

## Evidence gate and verification

Sufficient positive evidence for this scenario: SOURCE associated with the active
HUD, then a native VISIBILITY=false and/or directly sampled shown=false or an
invalid old HUD followed by a ready inactive replacement, with continued heartbeat
after the transition. Correlate with the user's actual death/respawn and visible
bar report. Report which signals were observed; do not invent the others.
Final DOM delivery, victory and multiple-boss behavior are separate unverified
properties. Production readiness still requires assessing the observed reset seam
and failure behavior; this probe is not the production implementation.

`python tools/test.py` with the configured external Lupa environment
exercises both frozen probes and the accepted production adapter. Diagnostic 02
tests include native local visibility events, direct/wrapped booleans, a live boss
after hide, malformed independent HUD, stale component owner, destroyed/new HUD,
continued heartbeat/recovery, rejected stale source and temporary queue failure.
Read-only mock proxies reject UObject/parameter writes and every hook call asserts
nil return. These tests do not substitute for the pending real game session.
