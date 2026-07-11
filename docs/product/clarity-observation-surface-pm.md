# Clarity Observation Surface PM

Date: 2026-07-11

Status: approved for implementation by the owner on 2026-07-11.

## Problem And Product Intent

Clarity has already removed several obsolete dependencies, but its visible and
contextual interaction surface still behaves like a general-purpose LazyVim
distribution. A tracked file exposes 133 global normal-mode leader actions; a
Git+LSP Lua buffer reaches 153 global-plus-buffer leader entries. Neo-tree and a
single Snacks picker expose another 70 and 134 local map rows. English-only
buffer-local descriptions, duplicate paths, maintenance utilities, and hidden
Git write actions make the editor harder to trust than its dependency count
suggests.

The product intent is to make Clarity an observation-first review console for
agent-produced code. Humans should immediately understand what changed, whether
it is correct, and how to make a small deliberate correction. External agents
own broad code, file-tree, and repository mutation.

## Target Users And Jobs

- The owner reviews agent output, follows code structure, inspects diagnostics,
  diffs, status, history, branch topology, and provenance, then makes bounded
  corrections.
- GUI-editor migrants need memorable save, search, explorer, window, wrap, fold,
  help, and exit behavior without learning a plugin showcase.
- Accessibility-sensitive users need absolute line numbers, stable wrap,
  high-contrast highlights, reversible zoom, readable messages, and complete
  English/Chinese labels.
- Coding agents need deterministic action IDs, zero-mutation observation
  contracts, isolated tests, machine-readable failures, and no hidden editor
  maintenance.

## Jobs-Caliber PM Judgment

- **Essential promise:** Clarity reveals agent-produced work without quietly
  changing the repository or asking the user to memorize inherited machinery.
- **Emotional promise:** opening the editor feels calm and trustworthy; every
  visible action has an obvious purpose and a safe result.
- **Narrative:** agents create and restructure; Clarity lets people see, judge,
  navigate, and precisely correct.
- **Taste bar:** one promoted path per job, no English leaks in a Chinese session,
  no public mutation disguised as status/diff/log, and no toggle that can make a
  trustworthy product default look broken.
- **Minimum lovable scope:** files, buffers, explorer, text search, symbols,
  diagnostics, format, fold, wrap, windows, terminal, Git observation, Health,
  and language.
- **Rejected compromise:** hiding keys only in which-key. Callable aliases and
  component-local write actions remain product behavior.
- **Rejected compromise:** plugin-count theater. Noice, mini.pairs, Tree-sitter,
  and code intelligence remain when behavior evidence says they improve review.

## Current Reality

- The exact audit is
  `docs/reviews/2026-07-11-keymap-surface-decision-report.md`.
- The approved system target is
  `docs/architecture/2026-07-11-agent-era-observation-surface-blueprint.md`.
- Current menu localization translates exact English descriptions and only
  scans global normal/visual mappings on `VeryLazy`.
- Live `:ClarityLanguage` changes effective locale but does not emit a refresh
  event; contextual LSP/Gitsigns/Neo-tree/Picker labels remain stale or English.
- Snacks status/diff/log/branch pickers and Neo-tree Git source contain
  repository-writing actions.
- Gitsigns attachment composes upstream mutation maps and then adds a duplicate
  Clarity namespace.
- Formatter arguments impose Clarity-wide style choices; lazy.nvim background
  checking remains enabled in interactive sessions.
- The current worktree contains a pre-existing two-entry lock drift for
  Gitsigns and Neo-tree. It must be diagnosed and committed or rejected in a
  dedicated lock-only transaction before dependency work.

## Proposed Behavior

- Materialize exactly 28 global normal-mode leader actions and seven additional
  capability-scoped normal actions in the fullest Git+LSP context. Removed
  inherited actions are explicitly unmapped, not merely hidden.
- Use a stable action catalog for IDs, keys, modes, scope, mutability, ownership,
  and English/Chinese labels. Which-key, help, tests, and component profiles
  consume the catalog.
- Implement status, diff, history, branch graph, and blame through bounded,
  argument-vector, read-only Git commands with `GIT_OPTIONAL_LOCKS=0`. Retain
  Gitsigns signs, hunk navigation, and preview only.
- Disable the Neo-tree Git source and all repository-write mappings. Neo-tree is
  observation-first: file creation remains available through the canonical new
  file action, while tree-based create/rename/delete/copy/move operations are
  disabled by default because agents own structural mutation.
- Curate Neo-tree to at most 24 actions, each core picker to at most 20 actions,
  and the dashboard to at most six actions.
- Emit `User ClarityLocaleChanged` once per effective change and refresh global,
  buffer-local, component, dashboard, and open Clarity views without restart.
- Promote only `ClarityHealth` and `ClarityLanguage`. Keep old commands as
  undocumented compatibility routes for one release while Health gains overview,
  recovery, messages, and diagnostic-event views.
- Honor project formatter configuration/tool defaults, disable background
  dependency checking, make source visibility explicit (`conceallevel=0`), and
  keep fault recovery in Health.
- Remove Mason/mason-lspconfig, Lush, friendly-snippets, and lazydev only when
  isolated system-LSP, theme, completion, and small-edit parity tests pass. Keep
  Noice until its existing attached fault blocker is resolved.

## Success Criteria

- Global normal leader count is exactly 28; the fullest reviewed Git+LSP normal
  union is at most 35.
- Every promoted action has a stable ID, owner, mutability class, English label,
  Chinese label, and behavior test.
- Public and component-local Git mutation actions are zero. Status/diff/log/
  graph/blame/hunk observation leave HEAD, refs, index, worktree, and optional
  lock artifacts unchanged under real input.
- Neo-tree exposes at most 24 curated actions; each core picker exposes at most
  20; dashboard exposes at most six.
- `en -> zh -> en` updates global and buffer-local labels and open Clarity views
  without restart or callback/rhs/options drift.
- Formatting creates no Clarity-wide indentation, width, quote, or EOL policy.
- Interactive startup schedules no lazy.nvim update checker, Mason install, or
  parser install.
- Local isolated fast, contract, behavior, fault, and release routers pass.
  GitHub Actions is not triggered and no Windows/WSL/release claim is invented.

## Non-Goals

- No embedded AI, forge client, Git mutation UI, second explorer/picker/terminal,
  hosted telemetry, background updater, or arbitrary Git command prompt.
- No removal of Noice while the raw-fold attached fault contract fails without
  it.
- No weakening of tests, scoring, platform gates, or error visibility to obtain
  a green result.
- No deletion or overwrite of user config/data/state/cache.
- No GitHub CI execution, PR merge, tag, or release in this plan.

## Risks And Defaults

- **Filesystem mutation:** default to agent-owned structural mutation; retain
  `<leader>fn` for deliberate new buffers and normal save, but disable tree-based
  create/rename/delete/copy/move by default.
- **Component usability:** if a ≤20/24 key budget removes a required keyboard-only
  path, preserve the path and document the measured exception rather than hiding
  it.
- **LSP provisioning:** if system/project-owned LSP attachment fails after Mason
  removal, retain Mason disabled from auto-install until parity is restored; do
  not background-install.
- **Completion:** if LSP snippet expansion or insertion fixtures regress without
  friendly-snippets, retain it and record the exact protected behavior.
- **Theme:** if static highlight parity or contrast fails, retain Lush until the
  static definition passes; never ship a degraded fallback as success.
- **Lock drift:** accept only after isolated validation in a lock-only commit;
  otherwise restore the committed bytes from a recorded backup.
- Zero blocking product questions remain.
