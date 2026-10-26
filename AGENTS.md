# SoulsEnemyHUD

Follow the repository-root AGENTS.md and NikichMods/DevRules. This folder owns only SoulsEnemyHUD: Компактные полоски противников, маркер захвата и суммирующийся урон.

Before work read this folder's docs/STATUS.md, docs/REQUIREMENTS.md and docs/VERIFIED_RUNTIME.md, plus root docs/WORKFLOW.md. All this folder's runtime/installation behavior remains subject to the root acceptance and no-launch rules.

VERSION in this folder is the canonical version for this mod only. Do not increment other mods. Packaging is independent; no combined bundle release is currently defined. Changes to sibling mods need their own scope/evidence; do not refactor siblings opportunistically. Shared verified host facts belong in root docs/VERIFIED_RUNTIME.md, feature-specific findings stay here.

Parallel chats require separate Git worktrees even for different mod folders; root Git index/branch/shared docs are not isolated by folders. See root docs/WORKFLOW.md. Keep deployment to the same installed game serialized. This file does not authorize launching the game.
