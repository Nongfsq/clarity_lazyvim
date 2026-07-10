# Clarity Agent-Era Review Console PM

Date: 2026-07-10
Status: implemented locally; available-host and release evidence pending

## Problem And Product Intent

Clarity still carries assumptions from a workflow where people author most code
inside Neovim. The owner now expects AI agents to generate and refactor code,
with Neovim serving as the trusted place to understand changes, inspect diffs,
diagnose failures, and make precise corrections. Embedded generation,
editor-owned global tool provisioning, and duplicate presentation frameworks add
maintenance without strengthening that job.

The product intent is not “fewer plugins” in isolation. It is a calmer review
console whose remaining features each help a person answer one question: what
changed, is it correct, and how do I repair it safely?

## Target Users And Jobs

- The owner uses external AI agents for broad implementation and Neovim for
  review, navigation, diagnosis, and small edits.
- Terminal-first developers need one dependable escape hatch for commands, not a
  terminal framework showcase.
- Accessibility-sensitive users need high contrast, wrapping, folding, stable
  messages, and bilingual recovery even when implementation surfaces shrink.
- Coding agents need deterministic commands, JSON evidence, stable failure IDs,
  and a repository contract rather than a model-specific editor plugin.

## Jobs-Caliber PM Judgment

- Essential promise: Clarity makes agent-produced code easy to inspect, trust,
  and correct without turning Neovim into another AI application.
- Taste bar: one obvious path per review job; no feature remains because it is
  popular, inherited, or inexpensive to keep superficially.
- Narrative: agents create; Clarity reveals structure, changes, failures, and
  recovery.
- Minimum lovable scope: project/file search, topology, semantic navigation,
  readable syntax, Git hunks, diagnostics, formatting, folding, wrapping, one
  terminal, and one clear help/health path.
- Rejected compromise: “optional” unused features. Optional Copilot still costs
  Node setup, CI time, audit logic, documentation, lock maintenance, and security
  review, so it is removed end to end.
- Rejected compromise: plugin-count theater. LSP, Tree-sitter, Gitsigns,
  formatting, search, and accessibility features remain because they improve
  review quality.

## Current Reality

- The active core resolves 25 plugins and the lock contains 26 entries, one of
  which is optional Copilot.
- Copilot spans a plugin spec, environment flag, Node capability/profile,
  validation, audit, CI installation, tests, README, guide, and decisions.
- Development-profile provisioning spans Mason, LSP server lists, Tree-sitter
  parser lists, tests, docs, and readiness semantics.
- ToggleTerm is a dedicated dependency for one floating terminal job already
  available through required Snacks capabilities, subject to parity evidence.
- Noice and autotag are inherited surfaces without an approved review-first job.
- Audit, Validate, Doctor, Log, Start, Sync, and Clipboard expose overlapping
  recovery concepts; the underlying evidence remains valuable but the human
  surface is fragmented.

## Proposed Behavior

- Clarity contains no embedded AI generation or Copilot/Node profile.
- Project toolchains install their own servers, formatters, and parsers; Clarity
  discovers capabilities and reports actionable absence without background
  installation.
- `<leader>tf` remains the sole floating terminal behavior while its owner moves
  to the already-required Snacks stack after parity.
- Noice and autotag are removed only after attached-UI and markup negative/parity
  fixtures prove that required behavior remains.
- One user-facing Clarity health/help entry presents overview, recovery,
  clipboard, log, and validation views. Existing commands remain aliases for one
  compatibility release; automation CLIs and stable report IDs remain intact.
- English and Chinese remain supported through declarative catalogs and stable
  action/finding IDs rather than mapping recreation.

## Success Criteria

- Zero `Copilot`, `CLARITY_COPILOT`, required Node, or Node-provider references
  remain in current runtime, public docs, tests, CI, audit, or lock authority.
- Startup performs no Mason/parser auto-install and exposes no development
  profile switch.
- The same real-input behavior passes for search, explorer, Git hunks, LSP,
  formatting, fold, wrap, terminal, messages, recovery, and clipboard.
- Disabled/removed dependencies do not remain locked; active authority hashes do
  not change during startup or validation.
- Human commands converge without changing stable machine-readable finding IDs.
- Local release gate passes; macOS and available Ubuntu evidence are recorded
  honestly; Windows/WSL remain pending until actually tested.

## Non-Goals

- No AI pane, model SDK, MCP runtime, prompt library, or provider telemetry.
- No removal of code intelligence merely because agents generate code.
- No second explorer, picker, terminal, Git client, or diagnostics dashboard.
- No GitHub Actions execution without separate authorization.
- No user-state deletion, overwrite, or implicit migration.

## Risks And Open Questions

- Risk: removing Node-provider checks may hide a user-owned Vim plugin need.
  Default: Clarity reports only product-owned requirements; users manage external
  plugins separately.
- Risk: Snacks terminal differs across platforms. Default: keep ToggleTerm until
  all local/available parity gates pass; never ship both as promoted paths.
- Risk: native messages may be less accessible than Noice. Default: removal is
  blocked by attached-UI visibility tests.
- Risk: health/help consolidation becomes a rewrite. Default: preserve the model
  and stable IDs, consolidate renderers and aliases incrementally.
- Zero blocking product questions remain.
