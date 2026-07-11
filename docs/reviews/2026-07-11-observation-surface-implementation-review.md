# Observation Surface Implementation Review

Date: 2026-07-11

Scope: approved local observation-surface implementation and macOS evidence

Status: implementation complete; final clean release rerun pending before branch push

## Executive Conclusion

The approved refactor is implemented and materially improves the experience:
Clarity now behaves as a small bilingual review console rather than a hidden
full-LazyVim menu. The layered development gate is green and no P0/P1 runtime
finding remains inside this plan's macOS scope; the final clean release rerun is
still required before delivery.

The full project score is **92/100**, up from the historical 58/100 baseline.
This is deliberately below 95: the owner excluded GitHub CI from this delivery,
and the exact commit has no Ubuntu, Windows, WSL, cold-network install, branch
protection, or moderated newcomer evidence. Local success is not substituted for
those missing facts.

| Dimension | Score | Evidence-backed assessment |
| --- | ---: | --- |
| User experience | 34/35 | Exact low-density surface, live bilingual components, Health facade, absolute numbers/wrap, accessible theme |
| Runtime correctness | 20/20 | Natural lifecycle, real input, Git immutability, missing-tool, fold fault, and restoration contracts pass |
| Architecture and maintainability | 15/15 | Catalog/policy authorities, thin upstream ownership, typed actions, independent contract IDs |
| Reproducibility and platform fidelity | 10/15 | Clean copied candidate and blocked-network restart pass on macOS; exact other platforms remain unverified |
| Verification and release | 8/10 | Clean commit-bound local release artifact passes; hosted matrix and branch protection remain pending |
| Documentation and governance | 5/5 | Public guide, current ledger, ADRs, PLAN+TASK, dependency manifest, and evidence boundary reconciled |
| **Total** | **92/100** | **Local product quality is strong; release-wide 95+ remains evidence-gated** |

## Delivered Product Surface

- Exactly 28 global normal leader actions and seven context-scoped actions:
  five LSP, one Git hunk preview, and one editable-buffer formatting recovery.
- Exactly 20 Neo-tree mappings; files Picker input 19 normal/18 insert, list 20
  normal, preview two normal; six dashboard actions.
- Five repository observations: status, changes, recent history, branch graph,
  and line provenance. Gitsigns retains `[h`, `]h`, and contextual preview only.
- No public or component-local stage, reset, checkout, commit, split-export,
  multi-select, maintainer, or file-tree mutation path.
- English/Chinese changes refresh global/contextual which-key metadata,
  Neo-tree, active/future Picker instances, dashboard, and open Health content
  while preserving callback/rhs/options identity.
- Health owns overview, recovery, Messages, structured Events, Clipboard,
  Environment, and Language. Compatibility commands route into this facade.
- Project config and formatter defaults own style. Clarity owns routing and LSP
  fallback only; global indentation arguments and background update checks are gone.

## Dependency Decision Manifest

The active resolved set and `lazy-lock.json` each contain exactly 18 entries:

| Dependency | Retained job |
| --- | --- |
| LazyVim, lazy.nvim | Runtime foundation and locked lifecycle |
| snacks.nvim | Picker, dashboard, terminal, and supporting UI |
| neo-tree.nvim | Sole file explorer |
| gitsigns.nvim | Read-only hunk navigation and preview |
| conform.nvim | Project-owned formatter routing and LSP fallback |
| nvim-lspconfig | Host/project LSP attachment |
| blink.cmp | Completion UI with native/project snippets |
| nvim-treesitter, nvim-treesitter-textobjects, ts-comments.nvim | Parsing, folds, syntax-aware review, comments |
| which-key.nvim | Small bilingual action discovery surface |
| lualine.nvim | Stable status context |
| mini.icons | Shared component icon adapter |
| mini.pairs | Tested small-edit pairing behavior |
| noice.nvim, nui.nvim | Accessible message presentation and its UI dependency |
| plenary.nvim | Locked transitive utility for retained integrations |

Removed after parity gates: Mason, mason-lspconfig, Lush, friendly-snippets, and
lazydev. The 18 reviewed product exclusions live in `config.product_policy` with
a rationale and revisit trigger. `minimal.lua` is generated from that registry;
lock normalization removes only exclusions also confirmed disabled by the
resolved runtime.

## Real-Input And Cleanup Evidence

- `scripts/run_clarity_action_matrix.py` and
  `tests/lua/real_input_action_matrix.lua` type every promoted action: 28 global,
  seven contextual, and four retained native/diagnostic actions.
- `<leader>ca` and `<leader>cr` must apply a fake-server WorkspaceEdit, then
  restore buffer lines, modified state, and cursor. `gd`/`gr` must open the exact
  `lsp_definitions`/`lsp_references` sources.
- `scripts/clarity_runtime.py` terminates descendant process groups on timeout;
  the matrix requires startup-clean state, injected cleanup recovery, repository
  and three-file authority immutability, three fake-LSP exits, and zero serialized
  fixture/home paths.
- Representative fixtures and contracts live in
  `tests/fixtures/{lsp/fake_server.py,runtime/fake_formatter.py}`,
  `tests/python/{test_action_matrix.py,test_clarity_runtime.py}`, and
  `tests/python/test_i18n_catalog_contract.py`.

## Release Evidence

- Previous clean release commit: `596cffac0e08b3e21012c908d929c55aff0a4fe4`
- Current trust-gap hardening commit: `21f8d29`; final documentation-bound clean
  release rerun pending
- Platform: macOS arm64, Neovim 0.12.4, Python 3.14.6
- Previous artifact: `~/.local/state/clarity_lazyvim/release-evidence/20260711-596cffa`
- Authority hashes: `init.lua`
  `c5cb9129c78ec53b9646855c63e4025656961997788cf96afd5a127ea859b559`;
  lock
  `e158ec437e8cdd2ada480aa6f01e11479db7d322e4f16ad21d1626f5340c57ca`;
  LazyVim JSON
  `3911b0251e3c51aa127f937aa5de323dba1eb6227636549264bde36e1674ad02`
- Development gates: 60 Python tests, 26 Lua tests, empty/file/attached scenarios,
  independent behavior contracts, raw-fold expected failure, passive validate,
  audit, exact active/lock parity, first boot, restart, and proxy/PATH-blocked
  offline restart.

## Remaining Evidence Gates

1. Run the required exact-commit remote Ubuntu/Windows/macOS matrix; validate
   WSL separately on a real Windows 11 + WSL2 path. The existing owner-provided
   macOS evidence does not replace that remote matrix.
2. Prove cold-network first install, backup/update, and rollback from a clean
   user configuration rather than a copied plugin cache.
3. Enable branch protection only when the owner chooses hosted CI as a required
   release gate.
4. Run terminal/font screenshots and a newcomer comprehension walkthrough.

No GitHub workflow was triggered during this implementation, by explicit owner
instruction.
