# TASKS.md

Status legend:

- `TODO`
- `IN_PROGRESS`
- `DONE`

## P0

### T-001 Rewrite user-facing docs

Status: `DONE`

Acceptance criteria:

- Chinese complete guide fully rewritten
- guide is organized around real user tasks, not plugin names
- guide highlights recommended primary workflows

### T-002 Rewrite product evaluation report

Status: `DONE`

Acceptance criteria:

- report includes UI / UX / PM / architecture views
- report assigns 0-100 scores
- report identifies top strengths and top liabilities

### T-003 Create AI execution document system

Status: `DONE`

Acceptance criteria:

- root `REQUIREMENTS.md`, `PLAN.md`, `TASKS.md` exist
- the three documents can serve as the persistent execution baseline for future AI work

### T-004 Resolve Git namespace conflict

Status: `DONE`

Acceptance criteria:

- global Git browsing commands and hunk actions no longer overload the same mental model
- user can predict what `g`-group commands mean in any buffer
- docs updated after redesign

### T-005 Define one recommended path per core task

Status: `DONE`

Acceptance criteria:

- file search, text search, terminal, formatting, rename, buffer switching, and window management each have one primary documented path
- secondary or legacy paths are clearly labeled as optional

## P1

### T-006 Add in-editor onboarding entrypoint

Status: `DONE`

Acceptance criteria:

- a command such as `:ClarityStart` or a key like `<leader>hh` exists
- it surfaces the top workflows and recovery paths
- it links to clipboard help and audit help

### T-007 Add clipboard help for Windows + WSL users

Status: `DONE`

Acceptance criteria:

- the guide explains terminal copy vs Neovim copy vs system clipboard
- an in-editor help path exists
- the recommended copy and paste flow is short and unambiguous

### T-008 Reduce duplicate window and buffer workflows

Status: `DONE`

Acceptance criteria:

- primary navigation path is consistent
- duplicate custom mappings are either removed or explicitly demoted
- documentation reflects the final decision

### T-009 Clarify repo source-of-truth workflow

Status: `DONE`

Acceptance criteria:

- docs explain clearly whether Windows or WSL repo is canonical
- update flow is short and deterministic
- stale config diagnosis is documented

## P2

### T-010 Add stronger startup guidance

Status: `IN_PROGRESS`

Acceptance criteria:

- first-run or help entrypoint teaches the top 10 actions
- stale search-backend or dependency problems are easier to interpret

### T-011 Add CI or scripted validation expansion

Status: `DONE`

Acceptance criteria:

- startup smoke test is automated
- audit script remains green
- major command-surface regressions become easier to detect

### T-012 Keep docs synced with behavior

Status: `IN_PROGRESS`

Acceptance criteria:

- every significant UX or keymap change updates:
  - `doc/clarity_lazyvim_complete_guide_zh.md`
  - `doc/clarity_architecture_governance.md`
  - `REQUIREMENTS.md`
  - `PLAN.md`
  - `TASKS.md`

## Suggested next execution order

1. T-010 Add stronger startup guidance
2. T-012 Keep docs synced with behavior
3. Add provider-install convenience guidance for Windows
4. Evaluate whether clipboard setup should become fully self-healing

## Current verified state

1. Windows authoring machine:
   - `python scripts/run_clarity_audit.py` => `94/100`
   - required checks green
   - integration checks green
   - remaining optional gaps: `fd`, `htop` / `btop`
2. WSL runtime machine:
   - `python3 scripts/run_clarity_audit.py` => `100/100`
   - `python3 scripts/run_clarity_validate.py` => all required checks green
3. Product help commands now available:
   - `:ClarityStart`
   - `:ClarityClipboard`
   - `:ClaritySync`
   - `:ClarityValidate`

## Parallel task breakdown (current round)

### Lane A: In-editor onboarding (T-006)

- `A1` Define onboarding content contract:
  - top workflows
  - clipboard route
  - audit route
- `A2` Wire command and key entrypoint (`:ClarityStart`, `<leader>hh`)
- `A3` Add short in-editor recovery cheatsheet
- `A4` Verify entrypoint discoverability from `Space` menu

### Lane B: Clipboard and source-of-truth (T-007, T-009)

- `B1` Document terminal copy vs Neovim yank vs system clipboard
- `B2` Add WSL-to-Windows practical copy/paste flow
- `B3` Define canonical repo sync rule:
  - Windows commit/push
  - WSL pull
- `B4` Add stale-config diagnosis checklist for outdated runtime behavior

### Lane C: Validation expansion (T-011)

- `C1` Add startup smoke checks for Windows and Ubuntu (WSL)
- `C2` Add keymap assertions for:
  - `<leader>ff`
  - `<leader>fw`
  - `<leader>gd`
  - `<leader>hs`
- `C3` Add special UI behavior checks:
  - dashboard
  - neo-tree
  - terminal
- `C4` Add provider readiness checks:
  - clipboard provider
  - `pynvim`
  - `npm neovim`
  - Copilot Node runtime floor

### Lane D: Documentation sync (T-012)

- `D1` Update README with current sprint direction and source-of-truth rules
- `D2` Update Chinese guide with in-editor recovery and sync workflow
- `D3` Update governance report with scoring deltas and execution order
- `D4` Keep requirements/plan/tasks wording aligned with implementation output

## Exit criteria for this round

1. `T-006`, `T-007`, `T-009`, and `T-011` are all delivered with visible implementation evidence.
2. Validation coverage includes behavior checks, not only binary presence.
3. Users can recover commands and clipboard flows from inside the product.
4. Windows and WSL source-of-truth workflow is documented in one unambiguous path.
