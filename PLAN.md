# PLAN.md

## Objective

Move `clarity_lazyvim` from a strong but still uneven configuration into a polished, beginner-friendly Neovim product with cleaner command semantics, lower cognitive load, and more reliable Windows + WSL workflows.

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

## Target outcome

Raise the combined project score from `84/100` to `90+/100` by focusing on:

- discoverability
- workflow consistency
- Git keymap clarity
- Windows + WSL usability
- stronger in-product onboarding
