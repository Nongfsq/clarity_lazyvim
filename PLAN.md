# PLAN.md

## Objective

Move `clarity_lazyvim` from a strong but still uneven configuration into a polished, beginner-friendly Neovim product with cleaner command semantics, lower cognitive load, and more reliable Windows + WSL workflows.

## Current execution focus (post help / validation round)

This round has already completed four linked outcomes:

1. a first-class in-editor recovery entrypoint
2. clipboard and sync guidance inside the product
3. explicit Windows -> WSL source-of-truth workflow
4. behavioral validation beyond binary presence

The next focus is now:

1. polish first-run guidance so the first five minutes feel calmer
2. reduce setup friction for optional Windows tools
3. keep docs and runtime behavior tightly synchronized

## Strategic phases

### Phase 1. Documentation and orientation

Goal:

- Make the project usable without tribal knowledge

Deliverables:

- rewritten Chinese complete guide
- rewritten evaluation report
- root requirements / plan / tasks documents

Validation:

- docs describe the current real command surface
- docs clearly define recommended primary workflows

### Phase 2. Command-surface cleanup

Goal:

- reduce duplicate workflows and stabilize the meaning of high-frequency commands

Deliverables:

- recommended-vs-secondary command policy
- Git namespace redesign proposal
- buffer and window workflow simplification proposal

Validation:

- each core intent has one obvious recommended path
- Git commands no longer overload the same namespace with conflicting meanings

### Phase 3. In-editor guidance

Goal:

- make forgetting survivable without leaving the editor

Deliverables:

- a dedicated help entrypoint such as `:ClarityStart` or `<leader>hh`
- a compact in-editor cheat sheet
- explicit clipboard help for Windows + WSL users

Validation:

- a user can recover from forgetting commands without external search

### Phase 4. Environment ergonomics and reliability

Goal:

- reduce cross-environment friction and drift

Deliverables:

- documented source-of-truth workflow for Windows and WSL repos
- clearer update flow
- stronger startup or audit signals for stale or mismatched setups

Validation:

- fewer “I updated it but the old config is still running” failure cases

### Phase 5. Continuous enforcement

Goal:

- prevent regression back into undocumented plugin sprawl or command chaos

Deliverables:

- repeatable validation checklist
- optional CI coverage for startup and audit
- doc-sync rule for keymap and UX changes

Validation:

- major UX changes cannot land without doc and audit updates

## Decision rules

1. Prefer removal over addition when a new feature adds cognitive load without strong product value.
2. Prefer naming consistency over historical compatibility when both cannot be preserved cleanly.
3. Preserve existing power where possible, but hide it behind secondary paths rather than the main user story.
4. Keep the project anchored to LazyVim unless a concrete blocker proves otherwise.

## Parallel execution structure

The implementation is intentionally split into parallel tracks so progress is steady and auditable.

### Track A. Product entrypoint and in-editor guidance

Scope:

- deliver `:ClarityStart` and `<leader>hh` style onboarding path
- make top workflows and recovery routes visible in-editor

Primary tasks:

- `T-006`
- part of `T-010`

Expected evidence:

- entrypoint command exists
- entrypoint content includes search, diagnostics, terminal, clipboard, audit

### Track B. Clipboard and cross-environment ergonomics

Scope:

- clarify terminal copy vs Neovim copy vs system clipboard
- provide deterministic source-of-truth workflow for Windows and WSL

Primary tasks:

- `T-007`
- `T-009`

Expected evidence:

- docs and help surfaces explain copy/paste clearly
- sync steps are explicit and short
- stale-config diagnosis can be followed without advanced knowledge

### Track C. Validation and audit expansion

Scope:

- extend validation from binary presence into user-visible behavior checks

Primary tasks:

- `T-011`

Expected evidence:

- scripted checks for startup and keymaps
- checks for dashboard / neo-tree / terminal behavior
- provider readiness reporting for clipboard, Python, and Node

### Track D. Documentation and governance sync

Scope:

- keep all user-facing and governance docs aligned with runtime behavior

Primary tasks:

- `T-012` (continuous)

Expected evidence:

- docs updated in the same implementation round
- no conflict between README, guide, and root planning files

## Execution order with parallelism

1. Treat Track A, B, and C as delivered for the current round.
2. Continue Track D every time UX or runtime behavior changes.
3. Use the next cycle to turn `T-010` from partial progress into a smoother first-run experience.
4. Keep Windows and WSL validation narratives aligned before every release.

## Target outcome

Raise the combined project score from `88/100` to `92+/100` by focusing on:

- discoverability
- workflow consistency
- Git keymap clarity
- Windows + WSL usability
- stronger in-product onboarding
