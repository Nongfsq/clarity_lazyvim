# Default Agent Delivery Workflow

This document defines the detailed workflow behind the stable rules in `AGENTS.md`.

## 1. PM Audit/Plan

Start with non-modifying investigation unless the user explicitly asks for immediate execution.

Investigate:

- product goal and user impact
- existing docs and instruction files
- current repository layout
- technical stack and runtime assumptions
- tests, validation scripts, CI, and deployment path
- known risks, local machine issues, and previous progress notes

For this repository, always consider whether a problem is:

- product/config code that belongs in GitHub
- local Neovim data/cache/parser/provider state that should be fixed locally
- documentation or validation drift

Do not commit local machine fixes as product code unless the investigation shows the repo should prevent or detect that class of issue.

## 2. Architecture PLAN+TASK

For substantial work, produce a decision-complete plan before editing.

Use task IDs that match the work area:

- `DOCS-001` for documentation and instruction work
- `NVIM-001` for Neovim runtime/config changes
- `I18N-001` for Clarity-owned language behavior
- `VALIDATE-001` for audit/validation changes
- `CI-001` for GitHub Actions and automation
- `LOCAL-001` for machine-local remediation that should not be committed

Each task should include:

- objective
- files or local paths affected
- implementation notes
- validation command
- acceptance criteria
- risk or rollback note

## 3. Execution

Execute only after one of these is true:

- the user asked for direct implementation
- the task is small and low-risk
- the PM/architecture plan is complete enough to act on

During execution:

- keep changes scoped
- preserve user edits and unrelated working tree changes
- do not widen the plugin surface without explicit rationale
- update docs when behavior changes
- add or update tests/validation when meaningful
- run validation before closeout

## 4. Closeout

Every code, architecture, or rule change needs a progress closeout.

Closeout must include:

- date
- summary
- files changed
- validation run and result
- follow-ups or known risks

Do not use `AGENTS.md` as a changelog.
Use `docs/ai/current-reality.md` for current state and `progress/` for historical session records.

## 5. Commit Policy

If the issue is local-only, stop after local remediation and validation.

If the issue is repository code or documentation, update the repo and commit when the user requested or authorized that behavior.

Before committing:

- confirm `git status -sb`
- ensure ignored local-only files are not staged
- run relevant validation
- write a clear commit message

Never commit `AGENTS.md` unless the project owner explicitly changes the ignore policy.
