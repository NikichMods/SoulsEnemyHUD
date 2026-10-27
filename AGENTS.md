# SoulsEnemyHUD — project contract

Follow [NikichMods/DevRules](https://github.com/NikichMods/DevRules): WORKING_RULES.md and its action-based reading map; local checkout work also CODEX_WORKFLOW.md. Read README.md, docs/STATUS.md, docs/REQUIREMENTS.md, docs/VERIFIED_RUNTIME.md and docs/WORKFLOW.md before changes. Recover actual Git/worktree and ignored files; preserve unfamiliar work.

This independent repository owns SoulsEnemyHUD source, requirements, tests, version, acceptance and release evidence. Shared game knowledge belongs to [NikichMods/Asterigos-Research, docs/RESEARCH_INDEX.md](https://github.com/NikichMods/Asterigos-Research/blob/main/docs/RESEARCH_INDEX.md); consult it before new host research and promote reusable findings there under DevRules. Original exact evidence remains readable in [AsterigosMods](https://github.com/NikichMods/AsterigosMods), with extraction provenance in docs/MIGRATION.md and docs/IMPORT_PROVENANCE.json.

Target: Asterigos: Curse of the Stars, Steam 1.09/build12996889, UE4.27, Windows x64, UE4SS v3.0.1-1181-g83330635 plus external UEHelpers. Accepted baseline uses DX11 and NVIDIA Smooth Motion; other builds remain unverified.

main is stable; new behavior belongs to feature/* or research/* and needs exact candidate identity and explicit in-game acceptance before promotion. VERSION is the sole semantic-version owner. Numbered artifacts are immutable. A history extraction changes commit IDs, not acceptance or runtime bytes; original published tags/releases stay at original URLs. Never rebuild accepted releases under their existing versions.

One writer per checkout; concurrent writers use separate worktrees. Serialize deployment to the shared game. This organizational migration authorizes no installation, game launch/termination, settings/save changes or hot reload. Future authorized installation requires a closed host, verified rollback outside loader paths and installed hashes. Offline tests do not establish engine rendering or user acceptance.

Only original source and authored patches enter public Git. Host HTML/assets, fonts, dumps, saves, credentials, tools and third-party payloads remain external/ignored under .local. MPL-2.0 scope is in LICENSING.md; do not infer redistribution rights for host-derived packages. Local paths belong in .local/environment.json.

Stable main remains accepted 0.2.0; public installer publication is deferred. feature/boss-aphes-name preserves unaccepted 0.3.0 and user feedback; do not promote it. Local z330 composes the exact SubtitleSoftEdges HTML input; see docs/LOCAL_DEPENDENCIES.md.
