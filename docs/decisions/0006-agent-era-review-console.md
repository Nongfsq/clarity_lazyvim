# ADR-0006: Agent-Era Review Console

Status: accepted; commit-bound macOS evidence complete, other platforms pending
Date: 2026-07-10

## Context

External AI agents now perform broad code generation and refactors. Embedded
Copilot, editor-owned language-tool provisioning, a dedicated terminal plugin,
and duplicate presentation/markup automation imposed runtime, CI, lock, and
support cost without strengthening review of agent-produced changes.

## Decision

- Clarity is a review and precision-edit console, not an AI generation host.
- Copilot and its Node/provider profile are removed end to end.
- Project environments and agents own language-tool installation; Clarity
  discovers capabilities and explicitly clears global install lists.
- Snacks owns the one floating terminal job.
- Autotag is excluded from the review-first surface. Noice remains a presentation
  adapter because native messages failed the attached fault contract; structured
  Clarity diagnostics remain the truth authority.
- Search, Neo-tree, LSP, Tree-sitter, completion, Gitsigns, Conform, folding,
  wrapping, accessibility, bilingual recovery, and deterministic evidence remain.
- `:ClarityHealth` is the primary human entry; existing commands remain
  compatibility routes while stable machine-readable IDs and CLIs remain.

## Rejected Alternatives

- Optional Copilot: rejected because unused options still require Node, CI,
  security, docs, tests, and lock maintenance.
- Removing all code intelligence: rejected because semantic navigation and
  diagnostics improve review quality.
- Removing the terminal entirely: rejected because tests and recovery still need
  one escape hatch.
- Keeping duplicate implementations: rejected because one job must have one
  owner.

## Consequences

- The active and locked set decreased from 25/26 to 23/23 in this decision's
  initial slice, then to 18/18 through the later observation-surface parity gates
  that removed Mason, mason-lspconfig, Lush, friendly-snippets, and lazydev.
- CI no longer installs Node or npm provider packages.
- Startup never schedules curated Mason or parser installation.
- Product exclusions increase to 18 reviewed registry records and are enforced
  separately from the lock.
- Exact-commit Ubuntu, Windows, WSL, and hosted-CI evidence remains pending;
  commit-bound macOS release evidence is complete.

## Revisit Trigger

Revisit when sustained manual authoring becomes a primary job, an editor-local AI
workflow has a concrete provider-neutral advantage, or native/required-stack
behavior loses accessibility or platform parity.
