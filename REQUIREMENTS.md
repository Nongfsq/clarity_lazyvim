# REQUIREMENTS.md

## Product name

Clarity LazyVim

## Product intent

Build an accessibility-first, beginner-friendly, high-contrast Neovim distribution on top of LazyVim that feels fast for experienced users without becoming hostile to returning or zero-foundation users.

## Primary users

1. Zero-foundation users coming from VS Code or text editors
2. Returning Vim or Neovim users who forgot many commands
3. Windows 11 + WSL2 users who want one stable coding cockpit

## Product principles

1. Beginner-first, not beginner-only
2. One recommended path per common task
3. Accessibility is a product feature, not decoration
4. Optional tools remain optional
5. Product behavior must be auditable
6. Docs and runtime behavior must match

## Core jobs to be done

1. Open a project and find the right file fast
2. Search code or text across the project fast
3. Edit, save, format, and rename safely
4. Navigate definitions, references, and diagnostics quickly
5. Open an integrated terminal without leaving the editor
6. Understand whether the environment is healthy
7. Copy and paste reliably between WSL and Windows
8. Recover quickly after forgetting commands

## Hard requirements

### R1. Search must be stable

- `Space f f` must always open file search
- `Space f w` must always open project text search
- Search behavior must not depend on removed backends like Telescope

### R2. Command discoverability must improve

- Pressing `Space` must remain a reliable path to command discovery
- There must be a clearly documented and preferably in-editor route for:
  - file search
  - text search
  - diagnostics
  - terminal
  - clipboard help

### R3. Command surface must be simplified

- Duplicate paths for the same intent should be reduced or clearly marked as secondary
- The project should define one recommended path for:
  - file open
  - text search
  - terminal
  - formatting
  - rename
  - buffer switching
  - window management

### R4. Git workflows must be deconflicted

- Global Git browsing and buffer-local hunk actions must not fight over the same mental model
- Keymaps should make it obvious whether the user is:
  - browsing Git state
  - previewing diff
  - staging or resetting hunks

### R5. Windows + WSL ergonomics must be first-class

- Clipboard guidance must be accurate and explicit
- The active source of truth repo should be obvious
- Update and sync workflows should be documented simply

### R6. Auditability must remain strong

- `:ClarityAudit` must remain available
- Headless audit must remain scriptable
- Major changes must preserve or improve audit clarity

### R7. Dependency discipline must continue

- New dependencies require documented product justification
- Optional integrations should degrade gracefully
- Tooling version floors must be documented

## Non-goals

1. Becoming a maximalist plugin showcase
2. Supporting every possible Vim workflow equally
3. Turning the project into a shell-framework bundle
4. Optimizing for expert-only memorization at the expense of discoverability

## Success metrics

1. A new user can successfully:
   - start Neovim
   - find a file
   - search text
   - save and quit
   - open a terminal
   - read an error
   within 10 minutes using the docs alone
2. The most common command set fits within a one-page cheat sheet
3. Git keymaps no longer have ambiguous meaning between global and buffer-local contexts
4. Every major UX change updates docs in the same commit or task round

## Current baseline

- Combined project score: `84/100`
- Strongest areas:
  - architecture
  - auditability
  - theme differentiation
- Weakest areas:
  - Git namespace consistency
  - command-surface simplification
  - beginner in-product onboarding
