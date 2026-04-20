# Clarity LazyVim Architecture Governance

Last updated: 2026-04-20 (round 3 dependency floor hardening complete)
Repository: `E:\Project\clarity_lazyvim`
Status: Active governance, round 3 shipped

## 1. Mission

Turn `clarity_lazyvim` from a strong personal setup into a portable, auditable, publicly distributable Neovim configuration.

This document is the single source of truth for:

- architecture evaluation
- evidence and risk tracking
- execution plan and task priority
- plugin minimization decisions
- audit and test expectations
- update log after each meaningful change

## 2. Executive Summary

`clarity_lazyvim` has a real product idea: an accessible, high-contrast, colorblind-friendly editing experience on top of LazyVim.

The original repo was promising but unstable in one specific way: the custom plugin layer was not consistently reaching runtime. That meant the product story and the actual running editor had drifted apart.

Round 2 closes that gap:

- custom plugin import is now explicit and verified
- the custom colorscheme is now loaded from the repo itself, not by accident from a fallback
- the public plugin surface has been reduced to a minimal necessary set
- non-essential default plugins were disabled to improve portability and auditability
- docs and audit expectations are now aligned with the reduced architecture
- plugin auditing now distinguishes active runtime plugins from plugins merely preserved in the lockfile
- Copilot now resolves a compatible Node.js runtime explicitly instead of trusting ambient shell PATH state

Top-level conclusion:

- LazyVim remains the correct base for this repo
- `oh-my-zsh` is not and should never be part of the runtime architecture
- the best path is "LazyVim as governed foundation, custom layers only where they create real product value"

## 3. Scorecard

### 3.1 Baseline Scores

| Dimension | Baseline | Notes |
| --- | ---: | --- |
| Product differentiation | 82 | Clear value from accessibility-focused theme and curated experience. |
| UX coherence | 74 | Theme and workflows were promising, but runtime state did not fully match intent. |
| Architecture boundaries | 44 | Personal preferences, distribution concerns, and environment assumptions were mixed. |
| Portability | 35 | Install path mismatch and hidden tool assumptions broke first-run portability. |
| Dependency governance | 38 | Tool ownership and fallback behavior were inconsistent. |
| Version governance | 42 | Duplicate lock files created ambiguity about canonical state. |
| Testability | 31 | No repeatable smoke-test or audit workflow. |
| Auditability | 29 | Missing single command/report for dependency and environment inspection. |
| Documentation quality | 46 | Good storytelling, but operational guidance was incomplete and partly incorrect. |
| Public project readiness | 48 | Promising, but not dependable enough for broad reuse. |

### 3.2 Current Scores After Round 2

| Dimension | Baseline | Current | Delta | Notes |
| --- | ---: | ---: | ---: | --- |
| Product differentiation | 82 | 84 | +2 | Accessibility-first identity is preserved and now more faithfully active at runtime. |
| UX coherence | 74 | 81 | +7 | Startup theme, keymaps, terminal flows, and README now describe the same product surface. |
| Architecture boundaries | 44 | 78 | +34 | LazyVim base, custom plugin layer, and optional external tools are more cleanly separated. |
| Portability | 35 | 84 | +49 | Root bootstrap, runtimepath remediation, and reduced plugin surface improved cross-machine resilience. |
| Dependency governance | 38 | 85 | +47 | Minimal plugin selection and optional-tool cleanup reduce hidden dependency risk. |
| Version governance | 42 | 81 | +39 | Single lock file remains the source of truth; plugin surface is now intentionally smaller. |
| Testability | 31 | 80 | +49 | Startup, theme, keymap, and audit verification are all repeatable headlessly. |
| Auditability | 29 | 89 | +60 | Environment audit and plugin-layer validation are now concrete and documented. |
| Documentation quality | 46 | 91 | +45 | Architecture, plugin policy, and operational guidance are synchronized again. |
| Public project readiness | 48 | 82 | +34 | The repo now behaves more like a product distribution than a workstation snapshot. |

### 3.3 Overall Scores

- Personal vibe-coding setup: `85/100`
- Publicly distributable engineering project: `82/100`
- Combined architecture maturity: `83/100`

## 4. Architecture Conclusion

### 4.1 PM View

The product should optimize for one sentence:

"A stable, accessible, high-contrast Neovim distribution that feels opinionated without being fragile."

Anything that does not reinforce that sentence is a candidate for removal.

### 4.2 Architect View

The correct stack is:

1. LazyVim for ecosystem leverage and sane defaults
2. a thin custom product layer for accessibility, terminal ergonomics, Git visibility, and AI assist
3. optional system tools that never become hard runtime requirements

The wrong stack would be:

1. shell framework assumptions
2. machine-local binaries treated as always present
3. inherited plugins kept only because they arrived transitively

## 5. Evidence Log

### 5.1 Resolved Findings

1. Install path mismatch
   - fixed with a root `init.lua` bootstrap and nested config self-resolution

2. Duplicate lock-file ambiguity
   - fixed by keeping root `lazy-lock.json` as the single canonical lock file

3. Missing audit entry point
   - fixed with `:ClarityAudit` and `scripts/run_clarity_audit.py`

4. Optional tools behaving like hard dependencies
   - terminal integrations now degrade gracefully when optional tools are absent

5. Formatter brittleness
   - formatter defaults were narrowed toward more portable commands

6. Custom plugin specs not reaching runtime
   - fixed by replacing directory import ambiguity with explicit plugin aggregation through `nvim/lua/plugins/init.lua`
   - validated by runtime checks showing:
     - `theme=custom_colorblind_theme`
     - `<leader>e` resolved to `nvim/lua/plugins/neo-tree.lua`
     - `<leader>tf` resolved to `nvim/lua/plugins/toggleterm.lua`

7. Copilot runtime depended too heavily on ambient PATH state
   - `copilot.lua` now resolves a Node.js `22+` binary explicitly
   - `fnm`-managed Node installations are preferred when present
   - audit now marks outdated Node runtimes as insufficient for the supported Copilot feature set

### 5.2 Strengths Worth Preserving

1. Accessibility is genuine product differentiation.
2. LazyVim is the right leverage point.
3. The repo is small enough to govern tightly.
4. The custom plugin layer is now modular and explicit.

## 6. Minimal Necessary Plugin Set

### 6.1 Keep

These layers directly support the product promise and remain part of the public distribution:

- `LazyVim/LazyVim`
  - core LSP, completion, Telescope, Mason, and UI defaults
- `rktjmp/lush.nvim`
  - theme composition support for the custom accessibility theme
- custom colorscheme loader
  - the actual accessibility differentiator
- `nvim-neo-tree/neo-tree.nvim`
  - project navigation
- `akinsho/toggleterm.nvim`
  - terminal workflow integration
- `lewis6991/gitsigns.nvim`
  - lightweight Git feedback without a second Git UI dependency
- `stevearc/conform.nvim`
  - formatter orchestration with explicit executable checks
- `nvim-treesitter/nvim-treesitter`
  - syntax intelligence and parser-driven editing
- `zbirenbaum/copilot.lua`
  - the single AI-assist layer

### 6.2 Disable or Remove

These plugins were judged non-essential for the public product surface and were disabled or removed from custom ownership:

- `akinsho/bufferline.nvim`
- `catppuccin/nvim`
- `nvimdev/dashboard-nvim`
- `folke/flash.nvim`
- `MagicDuck/grug-far.nvim`
- `kdheepak/lazygit.nvim`
- `nvim-mini/mini.ai`
- `mfussenegger/nvim-lint`
- `folke/persistence.nvim`
- `folke/todo-comments.nvim`
- `folke/tokyonight.nvim`
- `folke/trouble.nvim`

Removed custom files:

- `nvim/lua/plugins/bufferline.lua`
- `nvim/lua/plugins/dashboard.lua`

### 6.3 Why This Is the Right Cut

1. It preserves the differentiators.
2. It removes generic power-user surface area that was not central to the repo story.
3. It reduces version coordination pressure.
4. It makes audit results easier to interpret.
5. It keeps future maintenance focused on product value, not plugin sprawl.

### 6.4 Lockfile Interpretation Rule

`lazy.nvim` intentionally preserves disabled plugin pins in `lazy-lock.json`.

That means:

- `lazy-lock.json` is still the canonical pin file
- but it is not a trustworthy human-readable inventory of only active plugins
- the real minimal-plugin policy lives in `nvim/lua/plugins/minimal.lua`
- runtime truth should be audited from `lazy.core.config` and `Config.spec.disabled`

## 7. Priority Order

### P0: Must Fix First

1. Make the repository boot from the documented clone path.
2. Establish one canonical lock file.
3. Fix custom plugin import so repository-owned behavior is actually active at runtime.

### P1: Must Fix Next

1. Convert hidden hard dependencies into optional capabilities with friendly fallbacks.
2. Define and implement the minimal necessary plugin set.
3. Reconcile documentation and audit language with the reduced product surface.

### P2: Important Cleanup

1. Expand structured smoke-test coverage.
2. Add CI so audit and smoke tests are enforced automatically.
3. Consider flattening the nested `nvim/` layout in a future breaking cleanup.

## 8. Task Board

| ID | Priority | Task | Status |
| --- | --- | --- | --- |
| T-001 | P0 | Add root bootstrap entrypoint | Completed |
| T-002 | P0 | Make nested init self-resolving for local and headless runs | Completed |
| T-003 | P0 | Choose and enforce one canonical lock file | Completed |
| T-004 | P0 | Add `:ClarityAudit` command and repeatable audit report | Completed |
| T-005 | P1 | Gracefully handle missing optional terminal tools | Completed |
| T-006 | P1 | Reduce formatter brittleness and declare fallback strategy | Completed |
| T-007 | P1 | Rewrite README installation and dependency sections | Completed |
| T-008 | P2 | Review duplicated keymap ownership | Completed |
| T-009 | P2 | Expand automated smoke-test coverage | In progress |
| T-010 | P0 | Fix custom plugin import path and runtime activation | Completed |
| T-011 | P1 | Define minimal necessary plugin set | Completed |
| T-012 | P1 | Disable non-essential default plugins and remove dead custom modules | Completed |
| T-013 | P1 | Re-verify theme, keymaps, and plugin activation headlessly | Completed |
| T-014 | P1 | Reconcile docs and audit scope with plugin minimization | Completed |

## 9. Validation Procedure

Every major change should be validated in this order:

1. Boot smoke test
   - `nvim --headless -u ./init.lua "+qall"`

2. Runtime verification
   - verify colorscheme name
   - verify custom keymaps resolve to repository files
   - verify disabled plugins are no longer active

3. Audit report
   - `:ClarityAudit`
   - or `python scripts/run_clarity_audit.py`
   - confirm Node.js is both present and modern enough for Copilot

4. Documentation update
   - update this file with results, score change, and remaining risk

5. Commit only after all four are completed

## 10. Validation Results

### Round 1 Verification

1. Bootstrap smoke test
   - passed after bootstrap/runtime-path remediation

2. Built-in audit command
   - passed
   - readiness score: `93/100`

3. Headless audit script
   - passed
   - readiness score: `93/100`

4. Python syntax validation for audit tooling
   - passed

### Round 2 Verification

1. Headless startup
   - command:
     - `C:\Program Files\Neovim\bin\nvim.exe --headless -u "E:/Project/clarity_lazyvim/init.lua" "+qall"`
   - result:
     - passed

2. Runtime theme and keymap verification
   - command:
     - `C:\Program Files\Neovim\bin\nvim.exe --headless -u "E:/Project/clarity_lazyvim/init.lua" "+lua print('theme=' .. tostring(vim.g.colors_name)); print('leader_e=' .. tostring(vim.fn.maparg('<leader>e','n'))); print('leader_tf=' .. tostring(vim.fn.maparg('<leader>tf','n')))" "+qall"`
   - result:
     - passed
     - `theme=custom_colorblind_theme`
     - `<leader>e` points to `nvim/lua/plugins/neo-tree.lua`
     - `<leader>tf` points to `nvim/lua/plugins/toggleterm.lua`

3. Disabled plugin verification
   - command:
     - headless inspection of `require("lazy.core.config").plugins`
   - result:
     - passed
     - `neo-tree.nvim=true`
     - `toggleterm.nvim=true`
     - `copilot.lua=true`
     - `dashboard-nvim=nil`
     - `bufferline.nvim=nil`
     - `lazygit.nvim=nil`
     - `flash.nvim=nil`
     - `trouble.nvim=nil`

4. Headless audit script
   - command:
     - `python scripts/run_clarity_audit.py`
   - result:
     - passed
     - readiness score: `94/100`
     - audit now reports both active plugin count and disabled-by-policy plugin count

## 11. Plugin Audit Results

### 11.1 Plugin-Layer Score

| Dimension | Before | Current | Delta | Notes |
| --- | ---: | ---: | ---: | --- |
| Plugin necessity | 72 | 90 | +18 | The remaining public plugin set now maps cleanly to the product story. |
| Plugin overlap control | 64 | 87 | +23 | Several non-essential or overlapping power-user plugins were disabled. |
| Plugin activation correctness | 28 | 97 | +69 | Custom plugin specs and theme now load reliably from repository-owned code. |
| Plugin maintainability | 58 | 85 | +27 | Plugin ownership is simpler and dead custom modules were removed. |
| Plugin architecture maturity | 55 | 89 | +34 | The plugin layer is now much closer to an auditable product architecture. |

### 11.2 Current Plugin Conclusion

The critical failure mode was not "too many plugins" by itself. The critical failure mode was:

- too many plugins without a tightly governed product boundary
- and a broken import path that left core custom behavior inactive

That combination is now materially improved.

## 12. Remaining Risks

1. There is still no CI pipeline.
   - validation is scriptable, but not enforced automatically

2. The nested `nvim/` layout still exists.
   - it now works, but it remains less conventional than a flattened root config

3. Optional tools are still absent on this local machine.
   - `fd`
   - `htop` or `btop`

4. The lockfile should be refreshed whenever plugin policy changes again.
   - plugin minimization and lockfile contents must stay synchronized
   - note: disabled plugin pins may intentionally remain in the lockfile by `lazy.nvim` design

## 13. Change Log

### 2026-04-19 Round 1

- Created governance baseline.
- Installed local Neovim for real validation.
- Installed a local GCC toolchain for Treesitter compilation checks.
- Added root bootstrap entrypoint and nested config self-resolution.
- Added `:ClarityAudit` and a headless audit script.
- Removed duplicate lock-file ambiguity.
- Simplified default formatter strategy and reduced hidden dependency risk.
- Made optional tool integrations fail gracefully.
- Rewrote README to match reality.

### 2026-04-19 Round 2

- Fixed custom plugin import by switching to explicit plugin aggregation.
- Added a minimal plugin policy module to disable non-essential default plugins.
- Removed dead custom ownership for dashboard and bufferline.
- Switched LazyVim fallback colorscheme to `habamax` while keeping the custom theme authoritative.
- Verified the custom theme and custom keymaps load from repo-owned files.
- Reconciled README, audit scope, and governance documentation with the reduced plugin surface.
- Extended audit output to report active plugin inventory and disabled plugin policy explicitly.

### 2026-04-20 Round 3

- Hardened Copilot startup by resolving a Node.js `22+` runtime explicitly.
- Preferred `fnm`-managed Node binaries over stale system PATH entries.
- Updated audit semantics so outdated Node runtimes fail the Copilot-capable dependency check.
- Documented the Copilot Node.js floor and preferred runtime resolution behavior.
