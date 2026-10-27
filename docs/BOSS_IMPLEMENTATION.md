# Boss behavior 0.2.0

## Candidate 0.3.0: decorative name and side damage (runtime pending)

Pre-mutation READY checkpoint: the user adopted the side-damage layout and a
large short / fitted long Aphes name, then delegated name spelling to the simplest
reliable mechanism. The existing native UpdateBossStat callback supplies the exact
localized DisplayName and validated identity. Owned CSS is the final writer of
the addon nodes; neither native BossName nor MeterJS is changed. Whole-file builder
preservation and the accepted source/lifetime bridge are reused.

The raw stock font exists at `Genesis/Content/Fonts/Aphes.ttf` (stock asset
inventory); a scoped font-face references `../Fonts/Aphes.ttf` from Hud.html.
Font cmap inspection established ASCII coverage and no Cyrillic coverage. The
addon transliterates the already supplied Russian name, avoiding extra native
queries, English-name tables and boss classification. Unsupported scripts omit
the decoration. The exact Coherent font URL/rendering remains a runtime acceptance
item; browser font substitution does not prove that loader path.

Separate new nodes remain children of BossHP. Name layout is measured after a
name change, resize, available font-load notification and one bounded delayed
refit for older Coherent without FontFaceSet. Short names keep the maximum size;
long names first tighten tracking then reduce font size to measured width. Damage
retains the existing algorithm and receives a separate right-hand area, fitting
to the remaining viewport only when necessary. No per-frame name polling or new
native hooks. Reset clears the decoration and delayed refit as well as damage.

Preserved: native lower name, bar size/chrome/animations, HP palette, accumulation
and fade timing, boss identity/overhead suppression/lock dot, subtitles and all
ordinary-enemy behavior. UI mocks cover transliteration, native-name preservation,
reset and invalid identity. Local browser checks use actual authored CSS/JS and
extracted fonts, with 24 combinations of short/current/long names, damage and
viewport dimensions; no overlap/overflow or script errors were observed. Those
checks do not establish rendering or font loading in the host. Candidate hashes
and rollback belong to the ignored 0.3.0 deployment manifest. User runtime
acceptance is pending; 0.2.0 remains the accepted stable version.

## Accepted baseline

0.2.0 tested and visually accepted, then promoted to main (2026-10-27); see the
runtime result in VERIFIED_RUNTIME.md. The user deferred public installer publication.
Accepted runtime source is frozen by SoulsEnemyHUD-v0.2.0. The baseline production Lua remains
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
