# Boss link diagnostic 01

Research only; no production behavior change. Target: Steam1.09/build12996889,
UE4.27 and the locally installed UE4SS v3.0.1-1181-g83330635.

## Question and method

Does the character returned by the host's exact `Boss` query own both the
attribute object sent to the large boss bar and the overhead `MeterOnHead2`?
Static inspection established the data path but cannot prove live UE4SS binding,
object identity or teardown. Existing production logs do not contain that link;
visual observation alone cannot reveal the addresses. Therefore this standalone
observer records the host's calls without invoking the query, creating events,
writing state, or changing rendering. No synthetic actors, HP or HUD flags.

Five fixed hooks, no scene scans or speculative alternate function lookup:

| Boundary | Observation |
| --- | --- |
| `GameGlobal:GetSceneGameCharacterWithTag` native post | Actual `Boss` query output with final flag `false`; member addresses and returned order |
| `CoherentUIGTJSEvent:AddObject` native pre | Character attribute component added by the host to that event |
| `CoherentUIGTBaseComponent:TriggerJSEvent` native pre | `UpdateBossStat` recipient component, owning NormalHUDBP, event identity, source character and HP |
| `NormalHUDBP_C:UpdateBossStat` Blueprint post | HUD instance discovery; no assumed Blueprint pre-hook |
| `MeterOnHead2_C:Tick` Blueprint post | Existing overhead widget discovery and its Avatar/HPBar/lock state |

The source component must report the same character as its owner. The outgoing
component must belong to the observed NormalHUDBP and equal its CoherentUIGTHUD;
the event must equal that HUD's JsEventObject. Query membership is compared by
character and attribute-component addresses. Query indices in `QUERY order` are
the indices exposed by UE4SS's Lua array iteration, not a claimed zero-based JS idx.

Pending source packets are consumed on every observed dispatch, expire after two
seconds and are validated again on boss dispatch. `query_member` uses the latest
observed matching query at AddObject time only while it is at most two seconds
old; it is `unknown` otherwise. It does not claim query call-stack provenance.
`OVERHEAD query_member=false` after a recent query is the ordinary-enemy control.
`unknown` before/after current query traffic is not proof of non-boss status.

## Installation and frozen identity

- Separate loader folder: `Mods/SoulsEnemyHUDBossProbe/Scripts/main.lua` plus an
  empty `Mods/SoulsEnemyHUDBossProbe/enabled.txt`. No load-order dependency and no
  edit to shared mods.txt; all object access waits for existing reflected functions.
- Payload id: `boss-link-diagnostic-01`. Once installed/handed, these script bytes
  are immutable; a changed probe gets a new diagnostic number. This research id
  does not increment VERSION or claim a new production release.
- Script SHA256:
  `F2CBB6E7CC3C14A8E5F5E96919741BC801F7D80C2589FA45DD9343BAC830EE30`.
- Exact source commit, installed hash and preserved pre-test log/baseline belong in
  root ignored `.local/research/boss-hud/diagnostic-01/deployment.json`.
- Install only with the game closed; preserve existing payload/log outside loader
  paths, verify installed bytes. Do not launch, terminate or hot-reload the game.

## User test

1. Launch the game yourself and load a save near a boss; wait a few seconds.
2. Observe an ordinary enemy if one is available nearby. Start the boss encounter;
   report the visible boss name and whether the large bar appeared.
3. Land several hits with lock-on, then several without it. Note whether both
   large and small bars belong to that same boss. No need to transcribe HP.
4. Defeat the boss or leave the encounter by the usual game route. Wait five
   seconds and report whether the large bar disappeared, then close the game.
5. Tell the agent the test is finished. The agent snapshots and reads the local
   UE4SS.log before another launch, correlates the identities and removes the probe
   while the game is closed. No log upload, console command or config editing needed.

Do not require a second boss or repeat unrelated earlier visual acceptance.
If multiple candidates naturally occur, preserve all dispatches and their order;
otherwise multi-boss runtime behavior stays unverified.

## Reading results and limits

All lines start `BOSS_LINK_DIAGNOSTIC`. START identifies the payload. HOOK confirms
registration only. HEARTBEAT reports hook states and observed call counts;
`waiting`/`error` is an evidence gap, never a success. DISPATCH records the real
engine-side outgoing event sequence, source HP and matching overhead widget(s).
HUD/OVERHEAD and their REMOVED records show observed lifecycle changes.
INCOMPLETE cannot establish a link. ERROR disables the affected observer; all
callbacks return nil to preserve host return values. No UObject/parameter setters.

Changes are logged immediately at dispatch; unchanged source state is repeated at
most once per five seconds per HUD. Overhead state is sampled once per second;
heartbeat is every fifteen seconds. Observation ends after thirty minutes or 1200
lines; hooks then remain inert until normal game shutdown. The probe has no
hot-reload cleanup contract. Saving is permitted: it only reads runtime objects
and writes the normal loader log, with no session/save state mutations.

This proves an engine-side association only when all required observations agree.
It does not measure JS delivery order, DOM state, animation or rendered font/color.
The user's visible-name/bar observation is still needed. Multiple-source dispatch
order alone must not be promoted to proven final rendering ownership.

Offline verification: `python tools/test.py` from the repository root
with the configured external Lupa2.8 environment. Strict read-only mocks cover
matching/negative sources, multiple bosses, stale events, return-value preservation,
isolated errors, deferred hooks and bounded lifetime. They do not prove binding in
the installed UE4SS or gameplay acceptance; production readiness remains BLOCKED.

API references inspected when preparing this probe:
[RegisterHook phase/return contract](https://docs.ue4ss.com/dev/lua-api/global-functions/registerhook.html),
[TArray iteration](https://docs.ue4ss.com/dev/lua-api/classes/tarray.html),
[loader activation](https://docs.ue4ss.com/guides/installing-a-c%2B%2B-mod.html).
