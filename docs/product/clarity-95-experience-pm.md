# Clarity 95+ Product And Experience Plan

Date: 2026-07-09
Status: historical approved product baseline; local implementation followed;
current truth is in `docs/ai/current-reality.md` and the active PLAN+TASK

## Problem And Product Intent

Clarity already behaves like a thoughtful personal editor, but it does not yet
behave like a product that a new user can trust. Local caches, implicit config
paths, stale validation claims, plugin lifecycle replacement, and platform-
specific assumptions leak implementation complexity into the experience.

The product intent is not to add more Neovim features. It is to make the existing
core feel inevitable: safe to install, obvious to use, honest when degraded, and
recoverable without plugin expertise.

## Target Users And Jobs

Primary users:

- developers migrating from VS Code or another GUI editor;
- Chinese- or English-speaking users who want Neovim speed without building a
  configuration from scratch;
- terminal-first developers moving among macOS, Linux/WSL, and Windows;
- the project owner maintaining a small, understandable distribution over time.

Primary jobs:

1. install or update without losing an existing configuration;
2. open a project and know how to find, edit, search, navigate, format, and run;
3. understand loading, missing-tool, and failure states without plugin knowledge;
4. recover from drift using one product-owned diagnose/repair/recheck path;
5. move the same committed configuration across supported platforms with
   predictable behavior;
6. trust every published readiness and compatibility claim.

## Jobs-Caliber PM Judgment

### Essential Promise

> Clarity is a legible, calm, trustworthy terminal editor with one obvious path
> through daily coding and one obvious way home when something goes wrong.

### Emotional Promise

The user should feel oriented and safe. They should not wonder whether the wrong
config file loaded, whether a perfect score is lying, whether an update changed
an invisible cache, or which of five terminal/search paths is the intended one.

### Taste Bar

- One promoted path per high-frequency job.
- No silent failure for a marketed core capability.
- Every loading/error/degraded state answers: what happened, what is affected,
  what should I do, and how do I recheck?
- No self-congratulatory score without reproducible evidence.
- Accessibility is measured in resolved runtime colors and redundant signals,
  not inferred from palette names.
- Startup and first interaction remain perceptibly immediate.
- Documentation speaks in user tasks; internal architecture stays out of the
  newcomer path.

### Product Narrative

The journey should read as one story:

1. **Arrive safely:** preflight detects an existing config and required tools.
2. **See progress:** bootstrap explains what it is doing and how to recover.
3. **Learn ten actions:** responsive help presents only the daily core.
4. **Work without translation:** search, edit, navigate, run, and Git use stable
   task-oriented names.
5. **Recover with confidence:** health shows core-ready versus optional-degraded,
   with exact repair and recheck actions.
6. **Update without fear:** one source of truth, compatibility evidence, and a
   tested rollback.

### Rejected Compromises

- Reject adding features to compensate for unclear core workflows.
- Reject classifying a primary job dependency as optional without a fallback.
- Reject multiple promoted terminal layouts for newcomers.
- Reject Copilot as a core readiness dependency.
- Reject blanket “Windows source of truth” guidance for macOS/native Linux.
- Reject English-only output in Clarity-owned recovery surfaces.
- Reject subjective accessibility and performance claims without budgets/tests.
- Reject using Ubuntu as evidence for WSL.

## Current Reality

What works:

- coherent file/text search, LSP, terminal, and Git hunk skeleton;
- built-in first-run/help, audit, validation, and doctor concepts;
- bilingual Clarity-owned key descriptions and help content;
- a small active plugin story and strong local headless startup;
- targeted fold/wrap and single-explorer tests.

What breaks trust:

- no canonical clean-clone runtime proof;
- no successful public CI baseline;
- perfect readiness can exclude broken integrations;
- first-run help clips on common small terminals and may mark itself seen before
  rendering;
- install/update/rollback is a personal workflow, not a general product flow;
- Clarity-owned recovery output and platform guidance are inconsistent;
- theme and plugin ownership defects can make an apparently healthy runtime
  behave incorrectly.

The evidence baseline is maintained in
`docs/reviews/2026-07-09-clarity-95-quality-review.md`.

## Proposed Behavior

### Install And Bootstrap

- A preflight reports supported Neovim, Git, compiler, and core search/tool
  requirements before plugin bootstrap.
- Existing config/data is never overwritten or deleted automatically.
- The documented install path includes backup, first boot, expected progress,
  failure recovery, and rollback.
- Bootstrap errors name the failed prerequisite/action instead of surfacing a
  secondary Lua module error.

### Daily Core

- Promote exactly one default path for file search, text search, explorer,
  terminal, format, rename, diagnostics, and help.
- Keep secondary power-user paths functional where cheap, but remove them from
  onboarding and primary product menus.
- Rename visual wrapping so it explicitly means display-only, not code
  formatting.
- Give Git hunks, product help/health, and optional utilities truthful,
  non-overlapping namespaces.

### Loading, Empty, Error, And Degraded States

- Search explains when `ripgrep` is missing and offers an approved fallback or
  exact install/recheck action.
- Formatter/LSP state distinguishes installing, ready, unavailable, and LSP
  fallback.
- Bootstrap exposes current stage and bounded failure.
- Audit shows `core ready`, `profile degraded`, or `core blocked`; it never shows
  a perfect headline with a required failure.
- Every Clarity-owned failure has stable ID, user impact, repair action, and
  recheck action.

### Help And Onboarding

- The help UI clamps to available rows/columns, wraps content, supports scrolling,
  and exposes a visible close/help affordance.
- It renders without clipping at 60x16 and 80x24.
- First-run state persists only after successful presentation.
- The first page contains the minimum lovable actions, not the full command
  surface.

### Localization And Platform Behavior

- All Clarity-owned help, audit, validation, and recovery output supports English
  and Chinese.
- Platform classification distinguishes Windows, WSL, Linux, and macOS.
- Sync/clipboard docs describe platform-specific recipes, not a universal
  personal source-of-truth rule.
- Upstream plugin UI localization remains out of scope.

### Accessibility And Perceived Performance

- Resolved normal text reaches at least 4.5:1 contrast; meaningful non-text
  controls reach at least 3:1.
- Git/diagnostic meaning is not encoded only by color.
- Small terminals remain usable without horizontal clipping.
- Baselines cover startup, first insert, help open, file search open, and terminal
  open; performance work is accepted only when it protects a measured journey.

### Trust And Release

- Host capability, feature readiness, and release quality are distinct signals.
- Support statements are bound to a commit/tag, date, platform matrix, and CI
  artifact.
- Update and rollback use matching lock/config state.
- A 95+ claim is allowed only after every release gate in the architecture
  blueprint passes.

## Success Criteria

Product acceptance:

- a GUI-editor migrant can install, open, edit/save, search text, open a terminal,
  and find help within five minutes without external plugin knowledge;
- no supported install path overwrites user state;
- 90% of moderated target users find recovery within 30 seconds;
- one promoted path exists for each core job and group names match their contents;
- all Clarity-owned recovery messages are localized and actionable;
- no help clipping at 60x16 or 80x24;
- no core-required failure can produce a perfect readiness state;
- optional-tool absence does not break the core profile;
- accessibility thresholds and latency budgets pass in release evidence;
- clean archive, offline restart, platform matrix, update, and rollback gates are
  green before a 95+ release claim.

The project score is recalculated from these outcomes; the target is at least
95/100 with no open P0/P1, not a formula adjusted to reach 95.

## Non-Goals

- Replacing LazyVim.
- Supporting or teaching every inherited LazyVim feature.
- Adding plugins to increase perceived completeness.
- Full localization of third-party plugin interfaces.
- Multiple themes in this refactor.
- Hosted analytics or telemetry.
- Automatic destructive repair of user state.
- Promoting Copilot, system monitor, or multiple terminal layouts as core.
- Claiming WSL support from a generic Ubuntu job.

## Risks And Open Questions

Risks:

- simplification may initially frustrate existing power-user habits;
- strict clean-environment gates may expose more hidden assumptions;
- Tree-sitter migration can break syntax behavior if separated from the lock
  update;
- Windows/WSL evidence requires an environment not available in the current
  macOS workspace;
- accessibility metrics still require visual/manual confirmation in representative
  terminals.

Open questions: none blocking.

Defaults for non-blocking choices:

- keep secondary terminal paths available but remove them from newcomer surfaces;
- make Copilot opt-in/optional;
- prefer installation instructions and preflight over a large installer until
  repeated user evidence justifies one;
- use the smallest maintained test/lint tooling that adds no runtime dependency;
- retain historical docs and remove stale authority rather than deleting history.
