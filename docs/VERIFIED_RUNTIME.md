# Verified runtime — Steam1.09/build12996889

MeterOnHead2_C:Tick under /Game/MainContent/Template/UMG/MeterOnHead2. ownAvatar validates GenesisCharacter; skip player controlled. CurVals/MaxVals/CurColorClasses real arrays use HP index2 in observed Lua runtime; adapter identifies red color class and matches HPBar.Percent, does not blindly assume full bars distinguish health. Observed max HP252/588/420 give widths90/112/102. High HP is not proof of boss status.

Actual large floating digits: /Game/MainContent/Template/UMG/HudUmg.HudUmg_C, dedicated root CanvasPanel contains20 TextBlocks DamageDigits0..19. Hide that root opacity after verified parent relationship; animations remain. MeterOnHead2.DamageText stayed9876; HUDDamageTip_BP had no observed combat instances. Hiding those alone did not solve the symptom. Production no longer scans every numeric text block.

Garamond asset /Game/Fonts/EBGaramond-SemiBold_Font.EBGaramond-SemiBold_Font is UFont, Default typeface references EBGaramond-SemiBold FontFace. FontObject/TypefaceFontName/Size/OutlineSettings set explicitly, no global font change. User accepted size12/outline1.



Historical raw evidence remains in the ignored root .local/evidence archive. Do not copy proprietary dumps into this folder.

## Boss HUD: static research, 2026-10-26

Status: verified static asset/Blueprint findings on the installed Steam1.09 data;
not a live boss encounter or accepted implementation. Production and installed Lua
were unchanged. Exact evidence and reproduction are below.

### Native selection and data ownership

- `/Game/uiresources/NormalHUDBP.NormalHUDBP_C:UpdateBossStat` is the relevant
  Blueprint function. Its `DeltaSeconds` argument is not an enemy reference.
- At bytecode offset 5 it exits when `IsShowBossStat` is false. At offset 26 it
  calls `/Script/Genesis.GameGlobal:GetSceneGameCharacterWithTag` with the literal
  name `Boss`, an output array of `GenesisCharacter`, and a final boolean `false`.
  The native meaning of that boolean and the query's internal tag storage were
  not established; do not invent a parameter name or replace the query with an
  assumed equivalent `ActorHasTag("Boss")` check.
- It iterates that returned array. For each character it constructs a JS event
  containing the zero-based array index, that exact character's `DisplayName`
  (offset 586), and its `CharAttrComponent` object (offset 709). Offset 773 sends
  `UpdateBossStat` through this HUD's `CoherentUIGTHUD` component.
- The `ActorHasTag("SubBoss")` test at offset 313 is **not an exclusion** in these
  bytes: its conditional jump at 368 targets 382, also the next instruction.
  Both outcomes continue into event creation. Do not filter SubBoss based on the
  presence/name of that test.
- No retained boss-avatar property was found in these HUD Blueprint declarations.
  The demonstrated owner link is the local query result -> character ->
  `CharAttrComponent`, rather than a guessed `BossHUD.Avatar` property.
- `baraad_BP`'s exported defaults contain `Tags=["Baraad"]`; this is not evidence
  that every live boss carries an Actor.Tags entry `Boss`. Placed-instance and
  runtime tags, native query semantics and base defaults remain distinct.

### Update and rendering path

- `NormalHUDBP_C:ReceiveTick` enters its ubergraph at 5531; offset 5606 calls
  `HudTickUpdate(DeltaSeconds)`. `HudTickUpdate` first requires `IsPageReady`.
  Its boss branch uses `CheckTickUpdate` with `HudTickTime[6]` and interval `0.1`,
  then calls `UpdateBossStat(1.0)` at offset 395. This is the host's existing
  throttled path; a new full-scene scan on every overhead-widget Tick is unnecessary.
- `ToggleBossStatEvent(ToShow)` routes to `Toggle Boss Stat(ToShow)`, which sets
  `IsShowBossStat`, sends `ToggleDisplayBossStat`, and updates the native HUD state
  and `UI.HUDShow.IsShowBossStat` game-data value. Research must observe this
  boundary, not invoke it or write game-data flags to manufacture a test.
- The parent `/Game/uiresources/GTGameHUDBPLocal` selects `MainHTML="hud.html"`,
  `BaseURLPath="coui://uiresources/"`. The HTML handler for `UpdateBossStat`
  reads `HP`/`MaxHP` from the passed attribute object and displays `name.toUpperCase()`.
  It updates `#BossHP .meter` through `MeterJS.AddVal`/`UpdateVal`.
- `#BossHP` contains `.pre_val`, `.cur_val` and `#BossName`. The visibility event
  changes this element's visibility. A separate
  `PlaySpecialIncreasingAnimationForBoss` handler can animate its HP display.
  Thus numeric HP data and current animated fill width are distinct evidence.
- There is **one** `#BossHP` element and its update handler does not use `idx`.
  With multiple query results the Blueprint sends multiple events to that one
  element. The last event delivered would overwrite the preceding name/values;
  actual event delivery order and multi-boss behavior have not been observed.
  Do not select the first query result or assume one active boss globally.
- These are positive static proofs of a Coherent boss-bar path, separate from
  `MeterOnHead2` and its UMG `ProgressBar`. Activation and appearance in the next
  live encounter still require observation; do not infer that the presence of an
  HTML handler alone proves which surface is visible in a running session.

### Mechanism judgment and remaining evidence gate

The preferred research direction is the host's exact `Boss` query and the object
identity carried into its boss event. Match the returned character to the existing
overhead entry's `MeterOnHead2.Avatar`; cross-check its `CharAttrComponent` identity
against the event source. Neither MaxHP, display name, enemy class name nor array
index is a stable identity substitute. Entity validity/lifetime must be checked,
and ownership must be discarded when the HUD/encounter changes.

Two levels must remain separate: membership in the host's boss-query result, and
ownership of the currently rendered large bar. The latter additionally needs an
active/ready HUD and the actual event recipient/source. A tag alone cannot prove
that a large bar is currently displayed. An empty, stale or ambiguous match must
preserve existing presentation until the association is established.

Production readiness: **BLOCKED**, pending one narrow observation-only runtime
test. Verify that UE4SS can observe this exact query/event boundary, obtain the
native output-array signature correctly, and correlate HUD identity/state,
character address, overhead `Avatar`, attribute-component address, displayed name
and actual HP before/during/after a boss fight. Include an ordinary enemy nearby
as a negative control, damage while unlocked, and defeat/encounter exit. If several
boss candidates occur, capture all event sources and their order; otherwise leave
multi-boss support unverified. No need to change colors, visibility, fonts or game
state to answer this question. Do not launch the game or hot-reload to conduct it.

### Evidence identity and local recovery

- Starting source: `516b859cc81447f4c6d889130b454bf9ae6219c8`.
- Installed `Scripts/main.lua` matched source SHA256
  `DC4B98ACF5197817066FC6DF68AE28B863DB07B980FB8FC82FBC916EF3C0FC01`;
  `policy.lua` matched
  `98C003F7EC48D34923809CB7CFEFE089F3DA1B4178492134FF86A7C02761E254`.
- Installed executable SHA256:
  `DDEA6B5CA5D34836F01702993D20209C2595367287E6CD5A135A7ACE1958B1C0`.
  Stock `pakchunk0-WindowsNoEditor.utoc` SHA256:
  `0E9D27F84B97F24651AE1CA0ED38FACAD171E620702CAB08198B14B56E52513E`.
- Installed override inventory contained no replacement NormalHUDBP,
  GTGameHUDBPLocal or MeterOnHead2 assets. `repak hash-list` verified that the
  installed SubtitleSoftEdges package's `Hud.html` matches the archived
  verify-extracted HTML, SHA256
  `D68D844CE6BE1527BA4B4341D75E4723458337A32450A667B5A08072E24AC4A5`.
  Its boss handlers were inspected; the subtitle mod remains a separate owner.
- Ignored root `.local/research/boss-hud/` holds raw exports, installed-override
  inventory and an original local reader. CUE4Parse1.2.2, UE4.27,
  `ReadScriptData=true`; retain `StatementIndex` with each decoded instruction
  to check branch targets, not just reflected function/property names.
- Reproduction: build the local `reader/reader.csproj`, then invoke the reader
  with Paks-directory, external AES-key-file, ignored output-directory and asset
  name filter (`NormalHUDBP`, `GTGameHUDBPLocal`, `baraad_BP`). Machine paths
  resolve from root `.local/environment.json` and its legacyArchive pointer;
  the external key stays local. No new runtime probe was installed.
- `NormalHUDBP--UpdateBossStat.bytecode.json` SHA256:
  `7B274C89BE659ABC25E960F6CFFD74D3241B3BDB82C7B07ED33920116C83653B`.
  Automated checks of decoded output confirmed the exact query/tag, source
  fields, outgoing event, and the SubBoss branch's next-instruction target.

## Boss HUD: diagnostic 01 runtime result, 2026-10-27

Status: **partial positive runtime evidence**, not full readiness or visual
acceptance. The user completed a session and closed the game. Frozen payload:
`c470c37ee61ccc44d4c56fc71f04d3bc95cb5875`, SHA256
`F2CBB6E7CC3C14A8E5F5E96919741BC801F7D80C2589FA45DD9343BAC830EE30`.
Installed probe and production hashes were checked again after the session;
production still matches the accepted hashes recorded above.

Preserved log: ignored root
`.local/research/boss-hud/diagnostic-01/run-20261027-014536-UE4SS.log`, SHA256
`2B07964F753CF88EAB6E130C965F9D3169613CD34FFD1B1301D9699296ED691C`.
The adjacent `run-20261027-014536-analysis.json` contains the extracted observations
and session-local addresses. Log session: 01:45:36–01:50:04 MSK, loader enabled
the expected probe, all five hooks registered, and the log ends `Event loop end`.
At collection no Genesis/Asterigos process was present. The empty activation
marker was moved outside the loader into this evidence folder; diagnostic 01 is
now disabled. Its immutable script and baseline backups remain preserved.

### What the session establishes

- Lines 730–847 contain 116 emitted DISPATCH records for
  `raveneous_BP_C`, `DisplayName="Пожиратель Ненасытный"`. The internal dispatch
  counter reaches 1093; this is not 1093 emitted log records.
- Every emitted record has the same actor, attribute component, NormalHUDBP and
  Coherent sender component, with `shown=true ready=true`. The observer validated
  attribute ownership, HUD-component ownership and the HUD's JS-event identity
  before emitting each record. Native AddObject and TriggerJSEvent hooks operated
  on the actual host path and did not invoke/reconstruct the outgoing event.
- All 116 records match that actor to exactly one observed overhead widget via
  its current `MeterOnHead2.Avatar` identity (`overhead_count=1`). This establishes
  the engine-side association of the native boss-bar event source and small bar
  for this boss, independently of the failed query observer.
- Recorded HP goes from 5880/5880 down to approximately 18.8113/5880. There are
  81 emitted records with lock-on and 35 without it, including HP changes while
  unlocked. The source association therefore does not depend on lock-on in this
  observed encounter.
- Overhead HPBar.Percent sometimes trails the attribute ratio. For example,
  line 829 records HP=933.2980/5880 but Percent=0.2693878. These are actual samples
  at different host update boundaries; they do not by themselves diagnose the
  rendering or its cause. Do not require instantaneous percentage equality as a
  boss-identity criterion or derive authoritative damage from animated fill width.

### What failed or remains unknown

- Line 725, 01:46:17: periodic observation stopped on
  `attribute component owner mismatch` in identity validation. The offending
  object and lifecycle transition were not logged; the cause is unknown. Failure
  was contained to that observer, but it also stopped the periodic scheduler,
  heartbeat and HUD/removal sampling. This containment was too broad for a
  single stale/mismatched object and must be narrowed in any successor probe.
- Line 729, 01:47:24: the native-query callback stopped at its expected tag read
  (`tag:get():ToString()`), reporting `attempt to index a boolean value`.
  The callback argument shape does not satisfy diagnostic 01's assumption.
  Actual argument types/order were not recorded, so do not guess a corrected ABI
  from this error alone. No QUERY output was captured; every dispatch consequently
  has `query=0 query_member=unknown`. The static Boss-query path remains established,
  but its live output-array adapter and ordinary-enemy negative control are not.
- No post-encounter `shown=false`, removal or zero-HP observation was captured.
  Boss events stop after 01:49:14; another HUD reports combat=false at 01:49:21,
  but that does not prove this boss HUD's cleanup. Absence of later dispatches is
  not a verified teardown signal, particularly after the poll failure.
- This is one boss/source. Multi-boss selection and final JS delivery/DOM ownership
  remain unverified. The user has not supplied an explicit visible-name/bar result
  for this session, so the log must not stand in for that visual observation.

### Consequence for the next step

Do not discard the successful source/Avatar association or repeat the whole fight
to prove it again. Re-open mechanism selection before automatically repairing the
query adapter: the actual outgoing event already supplies a more direct source
identity, so a mirrored Boss-query result may be unnecessary for production.
Whichever mechanism is selected still needs a bounded inactive/active/exit
observation, safe invalidation and representative failure containment. Isolate
per-object observation failures and observe the native visibility/lifecycle
boundary directly; do not infer cleanup from silence. If a query adapter is still
needed, establish its actual reflected signature/callback argument types first.
This is the next research scope, not implemented diagnostic 02 or a READY gate.

## Boss HUD: diagnostic 02 defeat/respawn result, 2026-10-27

Status: **reset through invalidation/replacement of the HUD confirmed for the
observed player-death/respawn scenario**, with matching explicit user observation.
This closes the missing defeat-path lifecycle evidence from diagnostic 01; it is
not a production implementation, victory test or general multi-boss claim.

Frozen payload: `7e7e4e83181c72e970e19c86bd3e821903ceb6b7`, script SHA256
`08245B5996CD87CF154C5617E2C800318E2341AAB9B22B18F0FEE543DBFB58AA`.
Installed bytes matched this identity after the session; both production Lua files
still matched the accepted hashes above. Collection found no game process.

Preserved log: ignored root
`.local/research/boss-hud/diagnostic-02/run-20261027-020402-UE4SS.log`, SHA256
`1E1687FCBC522B9C14B012CE1C3A5BB7840B4BE0B190C7C06682BD65D3D528F9`.
Adjacent `run-20261027-020402-analysis.json` records extracted lines and identities.
Session: 02:04:02–02:07:05 MSK; ends `Event loop end`. Expected loader activation,
four HOOK records, 19 HEARTBEAT records, no REJECT, ERROR or early STOP.

Observed sequence (line numbers refer to the frozen log):

| Time MSK / line | Direct observation |
| --- | --- |
| 02:06:03 / 768 | Actual ToggleDisplayBossStat payload=true; active HUD shown=true, ready=true |
| 02:06:03–02:06:38 / 769–786 | Eight emitted SOURCE records for the same raveneous_BP_C, «Пожиратель Ненасытный», attribute component and HUD |
| 02:06:41 / 787 | That exact active HUD is no longer valid; HUD_REMOVED identifies its previous source |
| 02:06:42 / 788 | A different HUD is valid and ready=true, with the native IsShowBossStat=false |
| 02:06:43 and 02:06:53 / 789, 796 | Heartbeat continues with one HUD; dispatch counter stays at 368 |
| 02:07:00–02:07:05 / 797–801 | Replacement HUD becomes invalid during later session closure; heartbeat still operates, then loader loop ends |

The user explicitly reported dying to the boss, respawning outside the arena,
seeing the large boss bar disappear, waiting and closing the game. Those visual/
gameplay observations and the native invalidation/new inactive HUD agree.
`last_actor=none` on the new instance is the observer's empty history, not a
reflected host-owned boss-reference field. The positive reset proof is the old
HUD's invalidity plus the new HUD's native inactive/ready state and the user's
visible result, not silence or a diagnostic-written cleared value.

Only visibility=true was captured. There is no outgoing native visibility=false
event in this transition; do not claim that event was verified or infer the old
boss actor/component also became invalid. A visibility-event-only cleanup design
would miss the demonstrated lifetime boundary. Bind source state to the exact HUD
instance, reject invalid objects, discard its association when that HUD becomes
invalid/replaced and never transfer it to a new HUD merely because it is the same
class. Native inactive state is an additional guard; a fresh outgoing boss-source
event is the evidence for a new association. These are implementation constraints
derived from the observations, not behavior already shipped in production.

The failed Boss-query adapter is not required to prove this source/reset path and
was deliberately absent from diagnostic 02. Its ABI stays unverified rather than
being repaired speculatively. Further production edits still require their own
per-property gates, particularly final visibility writers on the overhead widget
and the separate Coherent appearance/font path. No repeat of this death test is
needed solely to recover already preserved evidence. Victory, multiple sources,
and any future production candidate need their own appropriate acceptance.

After collection the activation marker was moved outside loader paths into this
session's ignored evidence directory; diagnostic 02 is disabled, its frozen script
and prior payloads are retained, and no game launch/termination was performed.

## Candidate 0.2.0: runtime binding and visual acceptance, 2026-10-27

The user completed the installed 0.2.0 session, closed the game and explicitly
reported: «визуально всё отработало идеально, всё как надо». This is visual/
behavioral acceptance of this tested local candidate, not an instruction to publish
host-derived assets or promote source to main. Installed bytes were not changed.

Exact source: `9211d885d5a0cf7e5e5bb7e845ce192193daa5c8`. Verified after the session:

| Payload | SHA256 |
| --- | --- |
| Scripts/main.lua | FCAAF0A58D47FE83B0CF6AEBA54551FA43106A736D6403CDF5DA385DDDB806C9 |
| Scripts/policy.lua | 98C003F7EC48D34923809CB7CFEFE089F3DA1B4178492134FF86A7C02761E254 |
| Scripts/boss.lua | BEFF1F61A4482914FB777910FDFE9B98494D2F1824B0AA5026A6A18AC2696BDB |
| Local z330_SoulsEnemyHUD_P.pak | 9C37974EB79CA807A05DC889347232BDA89895C14D56AE65665C05CAA6CAD277 |

Preserved root ignored log:
`.local/candidates/SoulsEnemyHUD-0.2.0/run-20261027-023344-UE4SS.log`, SHA256
`A45997CC922B4FF6202713EF8A821C3DD5EF280AEFF2A60DA062483DA30271EE`.
An adjacent analysis JSON and deployment manifest preserve session/payload identity.
Session 02:33:44–02:36:06 MSK, expected 0.2.0 loader line, no diagnostic-probe
START, log ends `Event loop end`; no game process was present during collection.

Native hooks for the boss event path registered, and line 728 at 02:34:37 records
`Boss source bound; bridge=SEH1` for the same raveneous_BP_C whose overhead widget
and HP were observed immediately earlier. Ordinary enemy HP entries also used the
accepted width adapter. Across 35 SoulsEnemyHUD log records there were no module
errors, disabled integration, fallback activation or restoration-after-error.
This is positive evidence for the new binding/AddString path. A new damage-pool
widget is acquired later, and the session closes without recorded mod failure.

The production log deliberately does not contain every HP/damage/visibility frame,
DOM error stream or a direct teardown trace. It therefore does not independently
prove numeric timing, exact rendering or all cleanup steps. Those visual outcomes
are accepted from the user's explicit complete visual report, with defeat/reset
seam evidence additionally preserved in diagnostic 02. Do not infer a boss victory
or multiple-source test from this report/log. These scopes remain unverified.

The accepted local payload stays installed. Original host-derived package and raw
logs remain local and are not uploaded to the source repository. No rebuild or
version reuse occurred after acceptance.

## Source promotion of 0.2.0, 2026-10-27

The user explicitly authorized fixing 0.2.0 and moving the accepted changes to
main, with public installer publication deferred. Main was fast-forwarded from
516b859cc81447f4c6d889130b454bf9ae6219c8 to the accepted feature history. The tag
`SoulsEnemyHUD-v0.2.0` freezes exact tested runtime source
9211d885d5a0cf7e5e5bb7e845ce192193daa5c8; per-mod naming avoids a combined bundle
version. Runtime Scripts/UI/VERSION/build inputs were compared against that
commit with no differences. Only current-state documentation changed afterward.
Existing offline checks and live acceptance remain applicable; no verification
rebuild, payload replacement, game launch or repeated gameplay test was needed.
GitHub Release and public host-derived installer assets are explicitly deferred.

## Candidate 0.3.0 installed — runtime acceptance pending, 2026-10-27

Source `16310410a44c3498a4a0b9def3b48345c8c086fc`, feature/boss-aphes-name.
User adopted side damage and large short / automatically fitted long decorative
Aphes name. The user delegated spelling to simplicity/reliability; the addon
transliterates the supplied Russian DisplayName without extra native queries.

All SoulsEnemyHUD offline checks passed. A local browser exercised the actual
authored CSS/JS with extracted game fonts across 24 combinations: three names
(including the observed current boss), two damage amounts, four viewports.
No layout overflow/overlap or script errors in those cases. These are browser
checks, not proof of Coherent resource loading or real host rendering.

The game was closed before installation. Original 0.2.0 Lua/pak hashes were
compared against its accepted manifest. Prior main.lua/policy.lua/boss.lua and
z330 were copied to the new candidate's previous-payload outside loader paths
and verified. Candidate sources were clean at build/install; the pak hash-list
contained only `Genesis/Content/uiresources/Hud.html`, content SHA256
`B4736DF94C6491085CAED9454E8AF6033D510CABE29DEE0E8D0B376F46E635B0`.
Removing the single authored addon recovers exact accepted subtitle input bytes.
No fonts are included. Installed Lua and pak hashes were compared with candidate
payloads. Pak SHA256:
`870361D4BD6D3D4C47FB1CB461E7E736BCD71CA405C6CDA499F3732BB18B476E`.
policy.lua and boss.lua retain the accepted 0.2.0 bytes; main.lua changes only its
version/status log. Subtitle z320 and mods.txt hashes are unchanged.

Exact installation/hashes/build command/pretest log identity are in ignored
`.local/candidates/SoulsEnemyHUD-0.3.0/deployment.json`; the pretest log was
preserved before any new run. The game was not launched or terminated. No runtime
result is claimed yet: verify Aphes glyphs, fit/margins and side damage in game.
0.2.0 remains the accepted stable source in main; no public release was created.
