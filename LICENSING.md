# Scope and provenance

MPL-2.0 (LICENSE) applies to original Lua policies/adapters, Python tests/tools and the authored CSS patch. They were authored in the user's local development session; no external source contribution was identified in the imported files. No copied UEHelpers or loader source is included. License notice for each mod folder (including its tests) and tools/: SPDX-License-Identifier: MPL-2.0. A directory notice preserves the imported runtime bytes without modifying accepted Lua files.

Game code/assets, fonts (including EB Garamond/Roboto/Aphes), extracted HTML, render-target assets, UE4SS, CUE4Parse, repak/retoc, Lupa and third-party costume/texture mods retain their respective rights. They are not relicensed or bundled here. The repository contains asset references and authored patches only. The root MPL text was copied unchanged from the existing DetailedTechnologyTooltips repository's standard MPL-2.0 LICENSE. The user authorized public source hosting on 2026-10-26. CombatHUD 0.2.0 packages only original Lua and license/installation metadata under MPL-2.0, with UE4SS/UEHelpers supplied separately. This original-code release does not include game resources. Public packaging of host-derived files has not been authorized or cleared.

While actively maintained, upstream issues/PRs are preferred; community maintenance is welcome if unmaintained. This is etiquette, not an additional license restriction.

## Host HTML distribution review (2026-10-27)

The bounded review did not locate an Asterigos-specific EULA or official modding
policy explicitly permitting redistribution of modified `Hud.html`. No EULA link
was visible in the parsed Steam store page; attempted Steam EULA endpoints were
inaccessible. This does not establish that no game-specific agreement exists.

[tinyBuild Terms of Use](https://www.tinybuild.com/tou), dated March 21, 2023,
define Services to include games. Section 7 reserves content rights and restricts
unauthorized copying, modification and distribution. Section 8 also grants a
limited license for UGC integrating their content. The text does not expressly
resolve whether a modified complete game HTML resource qualifies for that grant.
Applicability to this particular game/purchase and redistribution of this file
remain unconfirmed; this review establishes neither clearance nor a definitive
legal prohibition. The [Influencer Policy](https://www.tinybuild.com/influencer-policy)
expressly covers images/sounds in videos, not distribution of game resource files.

Current author distribution pages demonstrate practice, not rights-holder consent:
[Carefree Mode](https://www.nexusmods.com/asterigoscurseofthestars/mods/14)
instructs extraction into `Genesis/Content/Paks/~mods`;
[OutfitCheatMod](https://www.nexusmods.com/asterigoscurseofthestars/mods/19)
offers UE4SS runtime packages. These descriptions do not prove permission to
redistribute our HTML. [Nexus submission rules](https://help.nexusmods.com/article/28-file-submission-guidelines)
leave copyright compliance with the uploader and require compliance with the
modified game's agreements.

The narrow unresolved question is permission to distribute a free same-game UI
mod containing a complete modified `Genesis/Content/uiresources/Hud.html`, without
other game resources or fonts. [Steam's official support listing](https://help.steampowered.com/en/wizard/HelpWithGameTechnicalIssue?appid=1731070)
provides an Acme Gamestudio contact for clarification. No inquiry was sent.
The user explicitly declined contacting the developers on 2026-10-27. Do not
treat such an inquiry as a pending task or a required next step. This decision
does not establish rights-holder permission or itself authorize publishing a
package; distribution remains a separate user decision.
No new installer architecture is adopted by this research; public host-derived
packaging remains uncleared. Source publication and accepted runtime behavior
are unchanged. The current local combined subtitle/boss HTML is documented in
[SoulsEnemyHUD build composition](https://github.com/NikichMods/SoulsEnemyHUD/blob/main/docs/BOSS_IMPLEMENTATION.md); that composition is a compatibility
build choice, not an inherent dependency between the two mods.
