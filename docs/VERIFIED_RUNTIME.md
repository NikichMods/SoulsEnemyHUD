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
