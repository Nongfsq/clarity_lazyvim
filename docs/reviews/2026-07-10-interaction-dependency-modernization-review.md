# Clarity Interaction, Dependency, And Modern Workflow Review

Date: 2026-07-10  
Review commit: `b072da5049092ab495cfa6f6c6a0152dfbdfba45`  
Scope: read-only review of keymaps, commands, user-facing behavior, plugin ownership,
dependency weight, startup policy, host requirements, validation, and current Neovim
0.12 / LazyVim workflow fit.

## Executive Judgment

Clarity does not need more features. Its best path to a 95+ experience is to become
a thinner, calmer product layer over LazyVim:

1. keep one obvious path for each core job;
2. stop replacing lifecycle setup already owned by LazyVim;
3. make optional capabilities truly optional;
4. test behavior and ownership rather than existence;
5. remove dead dependency and compatibility surface only after resolved-spec and
   rollback evidence exists.

The product foundations are sound: LazyVim, Snacks picker, Neo-tree as the sole
explorer, Conform, Gitsigns, Tree-sitter, LSP, which-key, the typed fold action,
and dependency-free diagnostics should remain. The largest problems are duplicated
ownership and a feature surface that is broader than the newcomer promise.

## Evidence Inventory

- 47 active global or plugin-level key definitions.
- 27 buffer-local definitions: 17 help-panel actions and 10 terminal mappings.
- 7 Clarity commands and 13 which-key group registrations.
- 7 autocmd registrations spanning 14 event subscriptions.
- 39 lockfile entries, of which 27 resolve as enabled and 12 are explicitly
  disabled but remain locked.
- 10 plugins load during an empty noninteractive startup. The broad
  `defaults.lazy = false` policy is a primary cause.
- Large maintenance surfaces include `audit.lua` (746 lines), `i18n.lua` (632),
  the legacy validator (694), runtime contracts (663), `help.lua` (449), and
  `menu_i18n.lua` (258).

Line count alone is not a removal reason. It identifies surfaces that need a
single schema, passive collection, and reduced duplication.

## Priority Findings

### P1 — Repair Before Feature Expansion

1. **Validation checks the wrong navigation key.**
   `nvim/lua/config/validation.lua:134` checks `<leader>gd`, while the actual map
   is `gd` at `nvim/lua/config/keymaps.lua:21`. A required check can therefore
   report a false failure or encode the wrong product contract.

2. **Clarity globally replaces capability-scoped LazyVim LSP maps.**
   `nvim/lua/config/keymaps.lua:17-39` installs global `gd`, `gD`, `K`, `gi`,
   `gr`, `<leader>ca`, `<leader>cr`, `gl`, `[d`, and `]d` mappings with
   `remap = true`. LazyVim owns most of these as buffer-local, capability-gated
   mappings. The duplicates should be removed unless a measured Clarity-specific
   behavior remains.

3. **Git navigation has one broken branch and one destructive collision.**
   In `nvim/lua/plugins/git.lua:19-38`, diff-mode `[h` / `]h` returns keys from a
   non-expression mapping, so the native motion is not executed. The legacy
   `[c` / `]c` aliases overwrite current LazyVim Tree-sitter class motions.

4. **Neo-tree lifecycle ownership is replaced instead of extended.**
   `nvim/lua/plugins/neo-tree.lua:5-97` forces eager loading and calls complete
   setup. This discards upstream rename propagation and other handlers. Its
   `event_handlers` block is also nested under `default_component_configs`
   instead of the documented top level.

5. **Gitsigns lifecycle ownership is replaced and compensated with polling.**
   `nvim/lua/plugins/git.lua:69-105` calls setup directly, replaces upstream
   `on_attach`, registers four event triggers, retries each buffer up to six
   times, and performs a delayed global scan. This is hidden latency and state
   complexity rather than a user feature.

6. **Conform availability is frozen at startup and upstream fallback is lost.**
   `nvim/lua/plugins/formatting.lua:4-88` returns replacement opts and removes
   formatters not executable at evaluation time. A formatter installed later is
   invisible until restart, and LazyVim's LSP fallback contract is not retained.

7. **Tree-sitter mixes configuration generations.**
   The lock follows the rewritten `nvim-treesitter` generation while
   `nvim/lua/plugins/treesitter.lua` still supplies legacy module-style options.
   This requires one atomic code-and-lock migration, not incremental edits.

8. **The first-run panel can fail and still mark itself complete.**
   `nvim/lua/config/help.lua` uses a minimum width of 84, even at 60 columns,
   disables wrapping, and records the guide as seen before deferred rendering is
   proven successful.

### P2 — Simplify The Product Surface

1. **Terminal is the clearest feature bloat hotspot.**
   `nvim/lua/plugins/toggleterm.lua` is 203 lines and promotes four layouts, a
   system monitor, a raw toggle, terminal-wide mappings, and repeated terminal
   construction. Keep one floating terminal job. Evaluate Snacks terminal only
   as a dependency-removal path; do not expose both implementations.

2. **`<leader>h` has no truthful mental model.**
   It is labelled Clarity but contains product help, eight Git hunk actions, and
   a system monitor. Git, product health/help, and optional utilities need
   separate ownership. Existing muscle memory requires a documented deprecation
   window where aliases change.

3. **Menu localization rewrites mappings to change descriptions.**
   `nvim/lua/config/menu_i18n.lua:185-223` recreates leader mappings and can lose
   plugin metadata or ownership semantics. Localization should own labels, not
   callbacks.

4. **Audit and validation mutate the session they claim to inspect.**
   They replay lifecycle events, edit README, open Neo-tree, and wait for
   Gitsigns. Collection must be passive; behavior probes belong in disposable
   isolated scenarios with full restoration.

5. **Line-number enforcement is wider than the product contract.**
   `nvim/lua/config/autocmds.lua:58-78` reacts to all `User` events and repeatedly
   overwrites window-local choices on focus/window changes. Absolute line numbers
   remain the default, but per-window user intent should not be fought.

6. **Copilot is optional in policy but eager in experience.**
   InsertEnter auto-triggering and ownership of `<Tab>`, `<C-n>`, `<C-p>`,
   `<C-e>`, and `<leader>co` can collide with completion and code namespaces.
   Copilot should be an explicit profile with a conflict-free default key policy.

7. **The lockfile contains 12 dead runtime entries.**
   Bufferline, Catppuccin, dashboard, Flash, grug-far, lazygit, mini.ai,
   nvim-lint, persistence, todo-comments, TokyoNight, and Trouble are disabled
   but locked. Prune only through the existing atomic lock transaction after
   proving they are not active or transitive.

8. **Global eager loading undermines lazy.nvim and LazyVim.**
   `nvim/lua/config/lazy.lua:127` sets `defaults.lazy = false`. Restore upstream
   handler semantics only after resolved-spec and first-action latency tests
   reveal undeclared dependencies.

### P3 — Improve Or Monitor

- Scope terminal mappings to ToggleTerm buffers; do not alter every `term://*`
  buffer.
- Prefer LazyVim/current Neovim diagnostic navigation instead of duplicate
  deprecated-style wrappers.
- Measure whether `timeoutlen = 200` is accessible enough for slower key entry.
- Let EditorConfig, ftplugins, and project formatters own indentation instead of
  forcing four spaces for every filetype.
- Standardize one real colorscheme lifecycle; retain Lush only if the accepted
  theme implementation proves it necessary.
- Audit whether real `nvim-web-devicons` is necessary when LazyVim already
  supplies `mini.icons` compatibility.
- Keep native `vim.pack`, native completion replacement, and broad native-fold
  migration on the monitor list until LazyVim adopts them and parity is proven.

## Keep, Fix, Improve, Remove, Investigate

| Decision | Surface |
| --- | --- |
| Keep | LazyVim/lazy.nvim; Snacks picker; Neo-tree as sole explorer; Conform; Gitsigns; Tree-sitter; LSP; which-key; lualine; typed fold action; `<leader>fw`; one wrap toggle; one terminal job; seven Clarity command concepts |
| Fix | Neo-tree/Gitsigns/Conform lifecycle ownership; Git diff navigation; validation key contract; first-run rendering/state; passive validation; theme lifecycle; Tree-sitter generation |
| Improve | absolute-number default without constant reassertion; truthful which-key groups; small-screen help; runtime capability discovery; provider and recovery copy; measured startup/first-action budgets |
| Remove or deprecate | `[c`/`]c` Git aliases; duplicate global LSP/diagnostic maps; promoted `<leader>tr/tv/th/ht`; system-monitor product surface; dead lock entries after proof |
| Optionalize | Copilot; language/parser/tool profiles; provider packages; secondary terminal layouts during compatibility only |
| Investigate before removal | ToggleTerm versus already-present Snacks terminal; real devicons; Lush; inherited textobjects/autotag/Noice; `<leader>fw` convention cost |

## Rejected Cuts And Additions

- Do not remove Snacks because of checkout size; it owns the promoted picker and
  multiple LazyVim services.
- Do not replace Neo-tree merely because Snacks Explorer is newer.
- Do not remove the terminal job; collapse it to one path.
- Do not remove Mason; separate core and optional ownership.
- Do not add Telescope, fzf-lua, Oil, Harpoon, AI chat panes, another clipboard
  plugin, another diagnostics dashboard, or a second explorer/terminal surface.
- Do not migrate from lazy.nvim to native `vim.pack` while LazyVim depends on the
  lazy.nvim spec and lock ecosystem.

## Required Evidence Before Removal

1. A resolved-spec manifest with plugin owner, enabled state, handlers, and setup
   owner.
2. Empty/file/directory startup and first picker/terminal/help latency baselines.
3. Real key input and collision tests against the locked LazyVim generation.
4. Missing dependency/profile tests for Git, ripgrep, formatter, compiler, Node,
   clipboard, and optional utilities.
5. Directory startup, file rename propagation, format fallback, Git diff motion,
   terminal cwd/shell, small-screen help, SSH OSC52, fold, and wrap behavior.
6. A clean archive first boot, offline restart, unchanged authority hashes, and
   rollback rehearsal for every lock transaction.

## Current-Technology Sources

- [Neovim 0.12 news](https://neovim.io/doc/user/news-0.12/)
- [Neovim LSP](https://neovim.io/doc/user/lsp/)
- [Neovim clipboard providers and OSC52](https://neovim.io/doc/user/provider.html)
- [LazyVim keymaps](https://www.lazyvim.org/configuration/keymaps)
- [LazyVim Snacks picker](https://www.lazyvim.org/extras/editor/snacks_picker)
- [lazy.nvim specification and lifecycle](https://github.com/folke/lazy.nvim/blob/main/doc/lazy.nvim.txt)
- [nvim-treesitter generation guidance](https://github.com/nvim-treesitter/nvim-treesitter)
- [Conform runtime and fallback APIs](https://github.com/stevearc/conform.nvim)
- [Neo-tree configuration and events](https://github.com/nvim-neo-tree/neo-tree.nvim)
- [Snacks terminal/picker capabilities](https://github.com/folke/snacks.nvim)

## Review Boundary

This review proves source and locked-upstream conflicts. It does not certify
Windows behavior, GitHub Actions, terminal-rendering quality, or dependency
removal. Those require the acceptance matrix in the execution plan. No runtime,
Git, cache, lock, or external state was modified by the review lanes.

