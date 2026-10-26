# Boss candidate 0.2.0

0.2.0 tested and visually accepted on feature/boss-hud (2026-10-27); see the
candidate runtime result in VERIFIED_RUNTIME.md. Source promotion/public packaged
release has not been performed. The baseline production Lua remains
available at 271149ee2770cb219cc20a85e59a158f690f3b89. No gameplay/stat changes.

## Mechanism and readiness checkpoints

| Property / gate before mutation | Owner and last relevant writer | Preservation and verification |
| --- | --- | --- |
| Boss association: READY for candidate | Actual Coherent AddObject + TriggerJSEvent inputs, adopted after NormalHUDBP.UpdateBossStat completes | Diagnostic 01 proved actor/attribute/overhead identity; 02 proved old HUD invalidation and inactive replacement. No Boss-query ABI dependency. Mock tests cover inactive/destroyed HUD, incomplete/multiple batches and hook failure. |
| Hide small HP/digits; keep dot: READY for candidate | SoulsEnemyHUD's post MeterOnHead2.Tick adapter, individual child render opacity | Its created frame/trail/damage and native HP/damage children only; root, stamina, distance culling and dot projection remain native/accepted. Adapter test proves hidden HP/digits with visible lock dot; visual acceptance recorded for the tested session. |
| Large bar palette: READY for candidate | #BossHP scoped CSS backgrounds; MeterJS writes widths, not these colors | Only current/previous span backgrounds change. Existing frame/highlight/native animation timings remain. Linear accepted RGB converted to sRGB: #9e3737 and #d3ad61. |
| Large accumulated damage: READY for candidate | Additional CoherentHelper callback, new child of #BossHP, scoped stylesheet/timer | Basic.css already defines EBGBold from uiresources/Font/EBGaramond-SemiBold.ttf. Read actual HP/MaxHP through GetUOVal, not animated fill or integer-truncated BossStat. Size follows computed #BossName font size. Tests exercise accumulation/healing/reset/fade and preserve native listeners. Coherent font/layout visually accepted for the tested session. |

Considered alternatives: an unexposed ExecuteScript API was not invented;
reflection inventory has the native event seam. A second UMG boss-bar overlay
would duplicate native anchors, scale and lifecycle. The selected mechanism keeps
the native HTML/HP calculations and animations, with one authored addon.

## Identity bridge

The native boss update has three inputs in HTML: index, name, attribute object.
At native pre-dispatch, the Lua bridge validates HUD/component/event/character
ownership and appends **one fourth string argument** using the existing AddString
UFunction: `SEH1:<hud address>:<actor address>:<attribute address>`.
The original three-argument handler ignores extra arguments and is unchanged.
The addon alone consumes this identity; absent/malformed identity hides its own
numbers. It never writes HP, tags or other game properties. This small payload
extension received positive native-binding evidence and user visual acceptance in the 0.2.0 session.

CoherentHelper.Bind appends through engine.on and stores callbacks for native
unbind/rebind; original and addon callbacks coexist. Color overrides have an ID
selector stronger than native .red rules. The addon uses the existing font-face;
no fonts or other host assets are bundled in Git. Sum is actual positive float
HP loss, rounded only for display. State/timeout is owned by the HTML document;
native show/hide resets the series, and HUD document recreation starts fresh.

Lua keeps only the validated source from a complete single-source native batch.
It checks the exact HUD validity/readiness/visibility before suppressing overhead
children. It does not transfer the association to another instance of the same
class. Multiple sources keep the accepted overhead behavior; source changes reset
the addon's series. Registration/API failures disable this narrow integration and
leave ordinary accepted overhead behavior. Research probes stay disabled.

## Local build/install

Run `tools/build_boss_ui.py <verified Hud.html> <ignored staging folder>` with
configured Python, then `repak pack <staging> <output pak>` using the known repak
tool from local environment/legacyArchive. Builder accepts exact stock HTML or
the exact accepted SubtitleSoftEdges HTML. Removing the one appended addon
recovers the input bytes, including every native script and any subtitle CSS.
Only the staged Genesis/Content/uiresources/Hud.html goes into the pak.

Current local coexistence input is the installed SubtitleSoftEdges HTML. The
later-loading `z330_SoulsEnemyHUD_P.pak` therefore includes that accepted CSS
unchanged; z320 and the sibling mod are not edited. Because UE overrides whole
files, disabling z320 alone will not remove subtitle CSS while this composed z330
is active. Rebuild against verified stock HTML for a standalone no-subtitle setup;
rebuild composition when that input changes. Unknown inputs are rejected.

Host-derived staged HTML/pak, tools, fonts and logs stay ignored/local. This is
not a public packaged release. Canonical installed names remain Scripts/main.lua,
policy.lua, boss.lua and z330_SoulsEnemyHUD_P.pak. Freeze exact source and all payload
hashes in the local candidate manifest, preserve previous files outside loader
paths, verify the host is closed and compare installed hashes. Never hot-reload or
launch automatically. VERSION owns this mod's version only.

## Acceptance envelope

One representative ordinary enemy must retain its accepted bars/damage/dot.
At the boss, verify small HP/frame/trail/digits are absent, lock dot remains,
large colors and Garamond number placement/size are right, repeated hits sum with
and without lock-on and fade as agreed. A normal death/respawn should show no
stale boss sum or association. Victory and multiple simultaneous bosses remain
unverified unless actually exercised. No new research-only probe is required.
The user accepted the tested 0.2.0 appearance/behavior as ideal; the loader log
confirms source binding without mod errors. Do not treat the production log as
independent frame-by-frame visual/timing telemetry; see the preserved session and
exact payload identity in VERIFIED_RUNTIME.md.
