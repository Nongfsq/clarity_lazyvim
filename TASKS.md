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

Status: `TODO`

Acceptance criteria:

- global Git browsing commands and hunk actions no longer overload the same mental model
- user can predict what `g`-group commands mean in any buffer
- docs updated after redesign

### T-005 Define one recommended path per core task

Status: `TODO`

Acceptance criteria:

- file search, text search, terminal, formatting, rename, buffer switching, and window management each have one primary documented path
- secondary or legacy paths are clearly labeled as optional

## P1

### T-006 Add in-editor onboarding entrypoint

Status: `TODO`

Acceptance criteria:

- a command such as `:ClarityStart` or a key like `<leader>hh` exists
- it surfaces the top workflows and recovery paths
- it links to clipboard help and audit help

### T-007 Add clipboard help for Windows + WSL users

Status: `TODO`

Acceptance criteria:

- the guide explains terminal copy vs Neovim copy vs system clipboard
- an in-editor help path exists
- the recommended copy and paste flow is short and unambiguous

### T-008 Reduce duplicate window and buffer workflows

Status: `TODO`

Acceptance criteria:

- primary navigation path is consistent
- duplicate custom mappings are either removed or explicitly demoted
- documentation reflects the final decision

### T-009 Clarify repo source-of-truth workflow

Status: `TODO`

Acceptance criteria:

- docs explain clearly whether Windows or WSL repo is canonical
- update flow is short and deterministic
- stale config diagnosis is documented

## P2

### T-010 Add stronger startup guidance

Status: `TODO`

Acceptance criteria:

- first-run or help entrypoint teaches the top 10 actions
- stale search-backend or dependency problems are easier to interpret

### T-011 Add CI or scripted validation expansion

Status: `TODO`

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

1. T-004 Resolve Git namespace conflict
2. T-005 Define one recommended path per core task
3. T-006 Add in-editor onboarding entrypoint
4. T-008 Reduce duplicate window and buffer workflows
5. T-007 Add clipboard help for Windows + WSL users
6. T-009 Clarify repo source-of-truth workflow
7. T-011 Add CI or scripted validation expansion
