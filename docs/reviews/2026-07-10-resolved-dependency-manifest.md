# Resolved Dependency Manifest

Last updated: 2026-07-11

Branch: `codex/20260711-observation-surface`

Reviewed base: `c7f80052362860c2500327cb00365754c5f7997e`

Implementation evidence: `596cffac0e08b3e21012c908d929c55aff0a4fe4`

## Result

- Resolved enabled plugins: 18.
- `lazy-lock.json` entries: 18.
- Empty headless loaded plugins: three (`LazyVim`, `lazy.nvim`, and
  `snacks.nvim`).
- Lock SHA-256:
  `e158ec437e8cdd2ada480aa6f01e11479db7d322e4f16ad21d1626f5340c57ca`.
- The earlier 23-entry state in this document is historical and is superseded
  by the parity-gated observation-surface migration.

## Enabled Runtime Set And Ownership

| Dependency | Retained product or transitive job |
| --- | --- |
| LazyVim, lazy.nvim | Runtime foundation, resolution, and locked lifecycle |
| snacks.nvim | Picker, dashboard, terminal, and shared UI support |
| neo-tree.nvim | Sole file explorer |
| gitsigns.nvim | Read-only hunk navigation and preview |
| conform.nvim | Project-owned formatter routing and LSP fallback |
| nvim-lspconfig | Host/project language-server attachment |
| blink.cmp | Completion UI using native/project snippets |
| nvim-treesitter, nvim-treesitter-textobjects, ts-comments.nvim | Parsing, folds, syntax-aware review, text objects, and comments |
| which-key.nvim | Small bilingual action discovery surface |
| lualine.nvim | Stable status context |
| mini.icons | Shared component icon adapter |
| mini.pairs | Tested small-edit pairing behavior |
| noice.nvim, nui.nvim | Accessible message presentation and required UI support |
| plenary.nvim | Locked transitive utility used by retained integrations |

## Removed After Independent Parity Gates

- `mason.nvim` and `mason-lspconfig.nvim`: system/project LSP attachment and the
  missing-server no-install recovery path pass without editor provisioning.
- `lush.nvim`: the checked-in static theme passes reload and contrast behavior.
- `friendly-snippets`: native/project LSP snippet insertion and completion pass.
- `lazydev.nvim`: Lua review, LSP attachment, completion, and diagnostics pass
  without a separate maintainer-oriented development helper.

Noice and mini.pairs remain because their independent presentation and small-
edit behavior gates still justify them. Removal is not scored by plugin count.

## Product Exclusions Are Not Lock Sentinels

`config.product_policy` owns 18 reviewed exclusions. Every entry has a product
rationale and revisit trigger. `nvim/lua/plugins/minimal.lua` is generated from
that registry, and lock normalization prunes only names present in both the
registry and the resolved runtime-disabled set. Conditional or unrelated lazy
state therefore cannot become product policy accidentally.

This replaces the old design in which disabled entries were kept in the lock as
implicit LazyVim policy sentinels. The same experience is preserved with a
smaller, explicit, testable authority.

## Transactions, Verification, And Rollback

- Existing Gitsigns/Neo-tree drift was accepted separately in `1706819`.
- Dependency removal and normalization landed in `57328ae`.
- Pre-observation lock backup:
  `~/.local/state/clarity_lazyvim/lock-backups/20260711T192244Z-pre-observation-surface-lazy-lock.json`.
- Pre-dependency-normalization backup:
  `~/.local/state/clarity_lazyvim/lock-backups/20260711T193717.081606Z-lazy-lock.json`.
- Check-only normalization, exact active/lock parity, first boot, restart,
  proxy/PATH-blocked offline restart, and clean commit-bound release pass.
- Rollback restores an exact backup before rerunning copied-candidate smoke and
  release validation; no user config/data/state/cache is deleted.

Evidence is commit-bound on macOS only. Exact-commit Ubuntu, Windows, WSL, and
hosted CI remain unverified and are not inferred from this manifest.
