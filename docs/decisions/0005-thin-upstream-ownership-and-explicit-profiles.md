# ADR-0005: Thin Upstream Ownership And Explicit Profiles

Status: accepted locally and on manual Ubuntu; Windows/release evidence pending  
Date: 2026-07-10

## Context

Clarity replaced several LazyVim-owned setup lifecycles, globally redefined
capability-scoped keymaps, eagerly loaded unspecified plugins, and promoted
optional terminal/tooling paths. The result was more code, polling,
conflicts, and host dependencies without more core user value.

## Decision

- LazyVim retains setup/load lifecycle ownership for Neo-tree, Gitsigns,
  Conform, Tree-sitter, and LSP. Clarity mutates incoming opts and composes
  handlers only for product deltas.
- Clarity performs no background language-tool/parser installation. Project
  environments and agents own their toolchains.
- Embedded AI generation is outside the product boundary.
- Clarity promotes one Snacks-owned floating terminal through `<leader>tf`.
- Desktop, WSL, SSH OSC52, and missing clipboard states are separate. SSH OSC52
  promises outbound copy, not remote clipboard read/paste.
- lazy.nvim's lazy default is restored. Every eager exception or retained
  dependency requires a named product or transitive contract.
- Product exclusions live in `nvim/lua/plugins/minimal.lua`; the lock contains active
  dependencies and explicitly supported optional profiles only. A policy test
  prevents disabled defaults from returning or accumulating stale lock pins.

## Rejected Alternatives

- Copying upstream `config` functions: rejected because it loses upstream
  lifecycle fixes and creates compensating polling.
- One automatic all-language install profile: rejected because optional tooling
  becomes startup state and cross-platform burden.
- Multiple terminal layouts and system monitor integration: rejected because
  they weaken the one-obvious-path promise.
- Using disabled lock entries as policy: rejected because lazy.nvim preserves
  existing disabled pins but does not use them to enforce `enabled = false`.
- Adding a clipboard plugin: rejected because Neovim providers and OSC52 cover
  the required paths with a smaller surface.
- Migrating to `vim.pack`: rejected while LazyVim uses lazy.nvim contracts.

## Consequences

- Empty headless loaded plugins decrease from 10 to 4.
- Optional provider and clipboard capabilities remain independent of core.
- Gitsigns hunk actions move under `<leader>gh`; `[c`/`]c` return to Tree-sitter.
- Plugin upgrades are less likely to silently lose upstream behavior.
- Release claims still require the platform evidence defined by ADR-0003.

## Revisit Trigger

Revisit when LazyVim changes its package/profile model, Snacks terminal proves a
strict dependency-removing parity win, native Neovim features are adopted by
LazyVim, or measured user evidence shows the explicit profile model harms the
primary experience.
