# ADR-0005: Thin Upstream Ownership And Explicit Profiles

Status: accepted locally and on manual Ubuntu; Windows/release evidence pending  
Date: 2026-07-10

## Context

Clarity replaced several LazyVim-owned setup lifecycles, globally redefined
capability-scoped keymaps, eagerly loaded unspecified plugins, and promoted
optional terminal/Copilot/tooling paths. The result was more code, polling,
conflicts, and host dependencies without more core user value.

## Decision

- LazyVim retains setup/load lifecycle ownership for Neo-tree, Gitsigns,
  Conform, Tree-sitter, and LSP. Clarity mutates incoming opts and composes
  handlers only for product deltas.
- The core profile performs no background language-tool/parser installation.
  `CLARITY_PROFILE=development` enables the curated development set.
- `CLARITY_COPILOT=1` enables locked optional Copilot. It does not claim core
  completion or code-action keys.
- Clarity promotes one reusable floating terminal through `<leader>tf`.
- Desktop, WSL, SSH OSC52, and missing clipboard states are separate. SSH OSC52
  promises outbound copy, not remote clipboard read/paste.
- lazy.nvim's lazy default is restored. Every eager exception or retained
  dependency requires a named product or transitive contract.
- Resolved specs are runtime dependency authority; policy tombstones may remain
  locked when they prevent LazyVim defaults from re-expanding the product.

## Rejected Alternatives

- Copying upstream `config` functions: rejected because it loses upstream
  lifecycle fixes and creates compensating polling.
- One automatic all-language install profile: rejected because optional tooling
  becomes startup state and cross-platform burden.
- Multiple terminal layouts and system monitor integration: rejected because
  they weaken the one-obvious-path promise.
- Removing all disabled lock entries: rejected because several specs are product
  policy that disables inherited LazyVim defaults.
- Adding a clipboard plugin: rejected because Neovim providers and OSC52 cover
  the required paths with a smaller surface.
- Migrating to `vim.pack`: rejected while LazyVim uses lazy.nvim contracts.

## Consequences

- Empty headless loaded plugins decrease from 10 to 4.
- Optional profiles require explicit environment configuration.
- Gitsigns hunk actions move under `<leader>gh`; `[c`/`]c` return to Tree-sitter.
- Plugin upgrades are less likely to silently lose upstream behavior.
- Release claims still require the platform evidence defined by ADR-0003.

## Revisit Trigger

Revisit when LazyVim changes its package/profile model, Snacks terminal proves a
strict dependency-removing parity win, native Neovim features are adopted by
LazyVim, or measured user evidence shows the explicit profile model harms the
primary experience.

