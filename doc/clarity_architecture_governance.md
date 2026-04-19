# Clarity LazyVim Architecture Governance

Last updated: 2026-04-19 (round 1 remediation complete)
Repository: `E:\Project\clarity_lazyvim`
Status: Active governance, round 1 shipped

## 1. Mission

Turn `clarity_lazyvim` from a strong personal setup into a portable, auditable, publicly distributable Neovim configuration.

This document is the single source of truth for:

- architecture evaluation
- evidence and risk tracking
- execution plan and task priority
- audit and test expectations
- update log after each meaningful change

## 2. Executive Summary

`clarity_lazyvim` has a real product idea: an accessible, high-contrast, colorblind-friendly editing experience on top of LazyVim.

The current problem is not product taste. The current problem is systems discipline:

- the repository layout does not match the installation instructions
- dependency ownership is unclear
- optional tools behave like hidden hard dependencies
- version truth is split across duplicate lock files
- testing and audit workflows are weak

The repo is currently closer to a "personal workstation snapshot" than a "reliable public distribution".

## 3. Baseline Scores

### 3.1 Product and Architecture Scores

| Dimension | Score | Notes |
| --- | ---: | --- |
| Product differentiation | 82 | Clear value from accessibility-focused theme and curated experience. |
| UX coherence | 74 | Theme, dashboard, keymaps, terminal flows point in one direction. |
| Architecture boundaries | 44 | Personal preferences, distribution concerns, and environment assumptions are mixed. |
| Portability | 35 | Install path mismatch and hidden tool assumptions break first-run portability. |
| Dependency governance | 38 | Tool ownership and fallback behavior are inconsistent. |
| Version governance | 42 | Duplicate lock files create ambiguity about the canonical state. |
| Testability | 31 | No repeatable smoke-test or audit workflow. |
| Auditability | 29 | Missing single command/report for dependency and environment inspection. |
| Documentation quality | 46 | Good storytelling, but operational guidance is incomplete and partly incorrect. |
| Public project readiness | 48 | Promising, but not yet dependable enough for broad reuse. |

### 3.2 Overall Scores

- Personal vibe-coding setup: `76/100`
- Publicly distributable engineering project: `48/100`
- Combined architecture maturity: `58/100`

## 3.3 Current Scores After Round 1

| Dimension | Baseline | Current | Delta | Notes |
| --- | ---: | ---: | ---: | --- |
| Product differentiation | 82 | 82 | +0 | Core value proposition is unchanged and still strong. |
| UX coherence | 74 | 76 | +2 | Terminal and dependency messaging are more consistent. |
| Architecture boundaries | 44 | 66 | +22 | Bootstrap, audit, dependency, and docs responsibilities are cleaner. |
| Portability | 35 | 79 | +44 | Root bootstrap now matches clone-path installation and nested config self-resolves. |
| Dependency governance | 38 | 74 | +36 | Optional tools now degrade gracefully and formatter assumptions are narrower. |
| Version governance | 42 | 81 | +39 | Canonical lock file reduced to one source of truth. |
| Testability | 31 | 73 | +42 | Real smoke tests and a reusable audit script now exist. |
| Auditability | 29 | 86 | +57 | `:ClarityAudit` and `scripts/run_clarity_audit.py` provide repeatable inspection. |
| Documentation quality | 46 | 87 | +41 | README is now operationally aligned with reality. |
| Public project readiness | 48 | 74 | +26 | Still not perfect, but now credible for wider reuse. |

### 3.4 Current Overall Scores

- Personal vibe-coding setup: `81/100`
- Publicly distributable engineering project: `74/100`
- Combined architecture maturity: `76/100`

## 4. Evidence Log

### 4.1 Confirmed Findings

1. Install path mismatch
   - README tells users to clone into `~/.config/nvim`.
   - Repository structure keeps the actual config under `nvim/`.
   - Result: first-run bootstrap fails because Neovim does not automatically look for `~/.config/nvim/nvim/init.lua`.
   - Real validation on 2026-04-19:
     - `nvim --headless -u "E:/Project/clarity_lazyvim/nvim/init.lua" "+q"`
     - failure: `module 'config.lazy' not found`

2. Dependency governance is incomplete
   - `mason.ensure_installed` declares some tools, but formatter definitions also rely on commands such as `eslint_d` and `jsonlint`.
   - This creates an author-machine bias.

3. Optional tools are treated like they are always available
   - `lazygit` and `htop` integrations assume those binaries exist.
   - Missing optional tools should degrade gracefully, not produce fragile flows.

4. Version truth is ambiguous
   - Both `lazy-lock.json` and `nvim/lazy-lock.json` exist and differ.

5. Responsibility is partially duplicated
   - Keymap ownership is split between multiple config locations.

6. README accuracy is below engineering-grade expectations
   - install flow is misleading
   - terminal shortcuts are inconsistent with implementation
   - optional dependencies are not clearly called out

### 4.3 Resolved in Round 1

1. Installation path and repository layout now align operationally.
   - Added root `init.lua` bootstrap.
   - Made `nvim/init.lua` self-resolve its own Lua module path.

2. Duplicate lock-file ambiguity was removed.
   - Root `lazy-lock.json` is now the single canonical lock file.

3. Environment auditing is now built in.
   - Added `:ClarityAudit`
   - Added `scripts/run_clarity_audit.py`

4. Optional external tools now degrade gracefully.
   - `lazygit`
   - `htop`
   - `btop`

5. Formatter assumptions are narrower and more portable.
   - Removed brittle `eslint_d` and `jsonlint` reliance from the default path.
   - Shifted JS/TS/JSON/Markdown formatting toward `prettier`.

6. Keymap ownership is cleaner.
   - Global key definitions were consolidated into `nvim/lua/config/keymaps.lua`.

7. TypeScript LSP naming was modernized.
   - Replaced `tsserver` with `ts_ls` to better align with current upstream naming.

### 4.2 Strengths Worth Preserving

1. Accessibility is a genuine product wedge, not decoration.
2. Building on LazyVim is the correct leverage point.
3. The plugin structure is already modular enough to govern.
4. The repo is small, which makes cleanup tractable.

## 5. Non-Negotiable Principles

1. Shell frameworks are not architecture foundations.
   - `oh-my-zsh`, `zsh`, PowerShell profiles, and terminal preferences must remain replaceable environment layers.

2. Public install instructions must match actual repository layout.

3. Optional tools must be explicitly optional.

4. One file must be the version truth for plugin locks.

5. Every major change must end with:
   - a smoke test
   - an audit note
   - a document update

## 6. Priority Order

### P0: Must Fix First

1. Make the repository boot from the documented clone path.
2. Establish one canonical lock file.
3. Add a repeatable audit entry point for environment and dependency inspection.

### P1: Must Fix Next

1. Convert hidden hard dependencies into optional capabilities with friendly fallbacks.
2. Reconcile formatter ownership and reduce command brittleness.
3. Repair README so it becomes operationally correct.

### P2: Important Cleanup

1. Clarify config ownership and reduce duplicate keymap definitions.
2. Add a more structured test matrix for Windows, WSL, and Linux distributions.
3. Consider flattening the repository layout in a future breaking cleanup.

### Current Remaining Risks

1. The nested `nvim/` layout still exists.
   - It now works correctly, but it remains less conventional than a flattened config root.

2. There is still no CI pipeline.
   - Validation is now scriptable, but not yet enforced automatically.

3. Compiler/toolchain setup on Windows still depends on shell refresh behavior.
   - WinGet-installed compiler aliases may require a new shell before `gcc` is visible globally.

4. Optional tools are still absent on this local machine.
   - `fd`
   - `lazygit`
   - `htop`/`btop`

## 7. Execution Plan

### Phase 1: Bootstrap and Governance

- add a root `init.lua` entrypoint
- make nested config self-bootstrap reliably
- remove duplicate lock-file ambiguity
- add a built-in audit command/report

### Phase 2: Dependency Resilience

- detect external executables before wiring related features
- provide user-facing fallback notifications
- prefer stable formatter defaults over brittle machine-local assumptions

### Phase 3: Documentation and Operational Readiness

- rewrite installation section
- document required vs optional dependencies
- document audit workflow and known limitations
- keep this governance file updated after each major change

## 8. Task Board

| ID | Priority | Task | Status |
| --- | --- | --- | --- |
| T-001 | P0 | Add root bootstrap entrypoint | Completed |
| T-002 | P0 | Make nested init self-resolving for local and headless runs | Completed |
| T-003 | P0 | Choose and enforce one canonical lock file | Completed |
| T-004 | P0 | Add `:ClarityAudit` command and repeatable audit report | Completed |
| T-005 | P1 | Gracefully handle missing `lazygit` and `htop` | Completed |
| T-006 | P1 | Reduce formatter brittleness and declare fallback strategy | Completed |
| T-007 | P1 | Rewrite README installation and dependency sections | Completed |
| T-008 | P2 | Review duplicated keymap ownership | Completed |
| T-009 | P2 | Expand automated smoke-test coverage | In progress |

## 9. Audit Procedure

Every major change should be validated in this order:

1. Boot smoke test
   - `nvim --headless -u ./init.lua "+qall"`

2. Audit report
   - `:ClarityAudit`
   - or headless JSON form if available

3. Documentation update
   - update this file with results, new score, and remaining risk

4. Commit only after all three are completed

## 10. Initial Environment Notes

- Confirmed on 2026-04-19:
  - Git present
  - `nvim` installed locally via `winget`
  - GCC toolchain installed locally via `winget` WinLibs package
  - no `lua` or `luac` executables separately installed

## 11. Validation Results

### Round 1 Verification

1. Bootstrap smoke test
   - Command:
     - `nvim --headless -u "E:/Project/clarity_lazyvim/init.lua" "+qall"`
   - Result:
     - Passed after bootstrap/runtime-path remediation and compiler availability.

2. Built-in audit command
   - Command:
     - `nvim --headless -u "E:/Project/clarity_lazyvim/init.lua" "+ClarityAudit" "+qall"`
   - Result:
     - Passed
     - Current readiness score: `93/100`

3. Headless audit script
   - Command:
     - `python scripts/run_clarity_audit.py`
   - Result:
     - Passed
     - Current readiness score: `93/100`

4. Python syntax validation for audit tooling
   - Command:
     - `python -m py_compile scripts/run_clarity_audit.py`
   - Result:
     - Passed

### Interpreting the `93/100` Audit Score

The local environment is now strong enough to validate the repo meaningfully.

The missing points are currently from optional tools only:

- `fd`
- `lazygit`
- `htop` or `btop`

## 12. Change Log

### 2026-04-19

- Created governance baseline.
- Captured initial scores, evidence, and task priority.
- Confirmed the bootstrap failure with real `nvim` headless execution.
- Installed `nvim` locally for real verification.
- Installed a local GCC toolchain to satisfy `nvim-treesitter` requirements during validation.
- Added root bootstrap entrypoint and nested config self-resolution.
- Added `:ClarityAudit` and a headless audit script.
- Removed duplicate lock-file ambiguity.
- Simplified default formatter strategy and reduced hidden dependency risk.
- Made optional tool integrations fail gracefully.
- Rewrote README to match reality.
- Re-ran smoke tests and updated current architecture scores.
