# Resolved Dependency Manifest

Date: 2026-07-10  
Branch: `codex/20260710-clarity-simplification`  
Base: `b072da5049092ab495cfa6f6c6a0152dfbdfba45`

## Result

- Resolved enabled plugins in the core noninteractive profile: 25.
- Loaded at empty headless startup: 4 (`LazyVim`, `lazy.nvim`, `lush.nvim`,
  `snacks.nvim`), down from the reviewed baseline of 10.
- Lock entries after policy/lock separation: 26, down from 39.
- Removed lock entry: `nvim-web-devicons`; LazyVim's `mini.icons` compatibility
  satisfies Neo-tree without a second icon implementation.
- Lock transaction backup:
  `/Users/frank/.local/state/clarity_lazyvim/lock-backups/20260710T223518.375284Z-lazy-lock.json`.

## Enabled Runtime Set

`LazyVim`, `lazy.nvim`, `snacks.nvim`, `neo-tree.nvim`, `toggleterm.nvim`,
`gitsigns.nvim`, `conform.nvim`, `nvim-treesitter`,
`nvim-treesitter-textobjects`, `nvim-ts-autotag`, `nvim-lspconfig`,
`mason.nvim`, `mason-lspconfig.nvim`, `blink.cmp`, `friendly-snippets`,
`lazydev.nvim`, `lualine.nvim`, `lush.nvim`, `mini.icons`, `mini.pairs`,
`noice.nvim`, `nui.nvim`, `plenary.nvim`, `ts-comments.nvim`, and
`which-key.nvim`.

## Product Exclusions And Optional Lock Entries

The following plugins remain explicit `enabled = false` product exclusions in
`nvim/lua/plugins/minimal.lua`, but are no longer lock entries:

- `bufferline.nvim`
- `catppuccin`
- `dashboard-nvim`
- `flash.nvim`
- `grug-far.nvim`
- `lazygit.nvim`
- `mini.ai`
- `nvim-lint`
- `persistence.nvim`
- `todo-comments.nvim`
- `tokyonight.nvim`
- `trouble.nvim`

`copilot.lua` remains locked but is excluded from the core resolved set through
`cond`; it becomes available only with `CLARITY_COPILOT=1`. Keeping it locked is
intentional so the optional profile remains reproducible.

## Retention Decisions

- Lush remains because `custom_colorblind_theme` directly uses its HSL and DSL.
- Tree-sitter textobjects remains because LazyVim owns current class/function/
  parameter motions, including the restored `[c`/`]c` class namespace.
- `nvim-ts-autotag` remains inherited for supported markup workflows; removal
  requires a separate usage decision, not lockfile aesthetics.
- Noice remains presentation-only; Clarity diagnostics remain the structured
  authority. Removal requires measured UI evidence.
- Mason remains, but installs are limited to the explicit development profile.
- ToggleTerm remains because the single reusable float passes the current product
  contract; the extra layouts and system-monitor feature were removed.

## Verification And Rollback

- `update_clarity_lock.py --apply` validated the copied candidate before replacing
  the source lock.
- Old hash: `af8ad1dff2b125573e19a37c3a30af25a152450d2b9b1d0320ee78fd35db04d7`.
- Post-normalization hash:
  `4f702e2bde3020465ffa2b28c3a681f4b56b415b6164171d73151c8aa717a6db`.
- Policy-separated hash:
  `33ec35118884af5ebdada829196672d4d7e25c2a0d4084418a3505b2c3bafcdc`.
- Pre-prune backup:
  `/Users/frank/.local/state/clarity_lazyvim/lock-backups/20260710T224848Z-pre-policy-prune-lazy-lock.json`.
- Both predecessor locks remain in the listed backups. Rollback is an atomic
  replacement from the pre-prune backup followed by copied-candidate smoke and
  release validation; the backup was hash-verified and was not applied during
  this review.
