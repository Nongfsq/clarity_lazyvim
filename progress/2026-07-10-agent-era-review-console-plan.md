# Clarity Agent-Era Review Console PLAN+TASK

Date: 2026-07-10
Status: implementation complete on local macOS and manual Ubuntu; Windows/WSL and release evidence pending
PM: `docs/product/clarity-agent-era-review-console-pm.md`
Architecture: `docs/architecture/2026-07-10-agent-era-editor-surface-blueprint.md`

> **Historical / superseded:** this document records the state and decisions at
> the stated date or commit. It is not current runtime, dependency, release,
> CI, or task-status authority. Use
> [`../docs/ai/current-reality.md`](../docs/ai/current-reality.md) and the active
> PLAN+TASK linked there.

## Summary

Convert Clarity from a conventional curated IDE surface into a review-first
console for agent-produced code. Remove generation/provisioning duplication,
retain review and accessibility jobs, replace dedicated implementations only
after parity evidence, and keep machine-readable verification provider-neutral.

## Current Reality

- Branch `codex/20260710-clarity-simplification` is clean except for the approved
  agent-era architecture blueprint before this plan is added.
- Commits `6a99335` and `1f79069` established thin runtime ownership and separated
  product exclusions from the lock.
- Core resolves 25 plugins; lock contains 26 entries including optional Copilot.
- Local macOS and manual Ubuntu release gates passed for the preceding surface;
  Windows/WSL and commit-bound release evidence remain pending.
- GitHub Actions is not authorized by this plan.

## Architecture Decisions

- External agents own generation; Clarity owns review, precision edits,
  accessibility, recovery, and deterministic evidence.
- Remove optional historical features end to end, not only from the plugin spec.
- LazyVim retains lifecycle ownership; Clarity supplies thin opts, actions, and
  explicit exclusions.
- Project environments own language-tool installation; Clarity detects but does
  not mutate toolchains in the background.
- One implementation owns each terminal, explorer, picker, presentation, and
  health job.
- Stable report/action IDs and root authority files are compatibility contracts.

## Test And QA Plan

- Static: forbidden-reference scans; resolved plugin/lock manifest; exact command
  and key ownership; no background install/network AI paths.
- Unit: Lua product policy, terminal adapter, native-message, i18n parity, passive
  health model; Python audit/doctor/report schemas and platform fixtures.
- Behavior: real input for fold/wrap, explorer, search, Git, formatting, terminal,
  messages, help, clipboard, and command aliases.
- Isolation: copied candidate; clean roots; first boot; cache-backed restart;
  authority hashes unchanged; rollback backup verified for every lock change.
- Quality: Ruff, StyLua, Actionlint, JSON parse, documentation paths/links, and
  `git diff --check`.
- Release: full local router after every dependency batch; available Ubuntu
  manual evidence at phase close; Windows/WSL explicitly pending; no implicit CI.

## Frontend Workstream

Neovim attached-UI work covers terminal, messages, bilingual help/health views,
small-screen layout, command aliases, and accessibility. There is no web UI.

## Backend/API/Data Workstream

The passive health/diagnostic model and CLI JSON reports are the internal API.
Stable finding/action IDs remain source-of-truth contracts. No database or user
data migration exists; locale/onboarding/log state remains user-owned.

## Analytics, Observability, And Security Considerations

- No hosted analytics or telemetry.
- Preserve bounded local JSONL events, redaction, sanitized export, stable IDs,
  repair text, and recheck commands.
- Removal must eliminate unused network-capable Copilot code and Node supply-chain
  setup from the product matrix.
- Tests use isolated roots and never export clipboard contents, source buffers,
  credentials, tokens, or user paths beyond existing sanitized contracts.

## Migration Order

1. Remove Copilot and Node profile authority atomically.
2. Remove editor-owned development provisioning while retaining discovery.
3. Prove and switch the one terminal implementation.
4. Prove native presentation and markup behavior, then remove Noice/autotag where
   evidence permits.
5. Consolidate human help/health/i18n surfaces while preserving machine contracts.
6. Reconcile locks, docs, decisions, current reality, and closeout evidence.

## Rollout, Compatibility, And Rollback Notes

- Copilot has no compatibility window by explicit owner decision.
- `<leader>tf` and stable health finding IDs remain compatible throughout.
- Old human commands remain aliases for one documented release after the unified
  entry is introduced.
- Each dependency change uses a copied candidate and exact pre-change lock backup.
- Roll back the stage commit and corresponding lock bytes if a required behavior,
  authority hash, attached-UI accessibility check, or available platform gate
  fails.

## Tasks

### AGENT-001: Remove Embedded Copilot And Node Product Surface

- Status: done — 2026-07-10
- Depends on: none
- Files: `nvim/lua/plugins/copilot.lua`, `nvim/lua/plugins/init.lua`,
  `nvim/lua/config/{capabilities,audit,validation}.lua`, `lazy-lock.json`,
  `.github/workflows/clarity-validate.yml`, `scripts/clarity_doctor.py`, relevant
  Lua/Python tests, README, guide, current docs and decisions
- Change: remove Copilot spec, flag, readiness profile, Node/provider probing,
  CI Node/npm installation, tests, documentation, and lock pin. Keep no disabled
  tombstone because the feature is outside the product rather than inherited
  LazyVim policy.
- Acceptance: current runtime/docs/tests/CI contain no product Copilot or required
  Node concept; resolved active set is unchanged except Copilot disappears from
  disabled/conditional metadata; lock normalizes cleanly; audit has no removed
  profile warning.
- Validation: forbidden-reference scan scoped to current authorities; Python and
  Lua suites; copied-candidate first/restart; full release router; lock backup and
  authority-hash review.

### AGENT-002: Remove Editor-Owned Development Provisioning

- Status: done — 2026-07-10
- Depends on: AGENT-001
- Files: `nvim/lua/plugins/tooling.lua`, `nvim/lua/plugins/treesitter.lua`,
  plugin aggregator, audit/capability/help/docs, profile tests
- Change: remove `CLARITY_PROFILE=development`, curated Mason server/tool/parser
  installation lists, and related readiness language. Retain LazyVim-owned LSP,
  Mason, and Tree-sitter lifecycles only where the resolved core requires them;
  capability reporting describes discovered project tools without installing.
- Acceptance: noninteractive and interactive startup schedule no package/parser
  installation; no environment profile controls tool mutation; LSP/format/parser
  behavior works when project tools exist and fails actionably when absent.
- Validation: source/process negative checks; LSP attach/no-attach, formatter
  fallback, parser/query fixtures; resolved spec; full release router.

### AGENT-003: Replace Dedicated ToggleTerm With The Required Snacks Stack

- Status: done — 2026-07-10
- Depends on: AGENT-002
- Files: `nvim/lua/plugins/toggleterm.lua`, replacement terminal action/spec,
  plugin aggregator, lock, terminal/runtime contracts, help/i18n/docs
- Change: reproduce the single `<leader>tf` floating terminal through Snacks;
  preserve shell, cwd, reuse, dimensions, close/reopen, terminal-local navigation,
  and small-screen behavior; then remove ToggleTerm and its lock entry.
- Acceptance: one promoted terminal path and zero ToggleTerm runtime/lock
  references; repeated real input reuses the terminal; cwd/shell and terminal
  navigation pass on local and available Ubuntu hosts.
- Validation: unit adapter test; attached-UI 60x16/80x24; shell/cwd/reuse fixture;
  copied first/restart; rollback rehearsal; full release router.

### AGENT-004: Remove Unowned Presentation And Markup Automation

- Status: done with evidence-based deviation — 2026-07-10; autotag removed;
  Noice retained because native messages blocked the attached raw-fold fault
  contract
- Depends on: AGENT-003
- Files: `nvim/lua/plugins/minimal.lua`, UI policy, lock, message/diagnostic tests,
  markup fixtures, help/menu/docs
- Change: prove native message plus Clarity diagnostic visibility, then disable
  Noice and remove its lock/transitive-only dependencies when unused; prove
  precision-edit behavior without autotag, then disable/remove
  `nvim-ts-autotag`. Preserve native command-line/errors and structured logs.
- Acceptance: notification, error, long-message, command-line, and log recovery
  remain visible and accessible; HTML/JSX edits do not undergo unexpected tag
  mutation; removed plugins do not resolve or remain locked.
- Validation: attached-UI message matrix; injected action failures; log export;
  HTML/JSX fixtures; resolved dependency graph; copied restart; full release.

### AGENT-005: Unify Human Help And Health Without Weakening Agent Contracts

- Status: done — 2026-07-10; `:ClarityHealth` is the primary entry and old
  commands remain compatibility routes over existing passive evidence models
- Depends on: AGENT-004
- Files: `nvim/lua/config/{audit,validation,commands,help,i18n,menu_i18n}.lua`,
  CLI adapters, Lua/Python/contracts tests, README and guide
- Change: create one user-facing Clarity health/help entry with overview,
  recovery, clipboard, validation, and log views backed by one passive model;
  preserve existing commands as aliases for one release; replace mapping rewrite
  localization with declarative stable-ID labels.
- Acceptance: one obvious entry is documented; repeated invocation from modified
  buffers changes no session state; old aliases return equivalent views; English
  and Chinese catalogs have exact parity; CLI JSON schemas and stable IDs do not
  drift.
- Validation: state serialization/repeat/fault fixtures; 60x16/80x24 attached UI;
  alias equivalence; locale parity; CLI schema snapshots; full release router.

### AGENT-006: Reconcile Agent-Era Product Truth And Closeout

- Status: done on local macOS and manual Ubuntu — 2026-07-10; Windows/WSL and
  commit-bound release evidence remain pending
- Depends on: AGENT-005
- Files: `README.md`, Chinese guide, `docs/ai/current-reality.md`, product PM,
  architecture blueprint, dependency manifest, ADRs, document index, this plan,
  dated closeout
- Change: record the final active/locked surface, before/after maintenance and
  startup evidence, adopted decisions, exact rollback paths, supported hosts,
  pending Windows/WSL evidence, and no-implicit-CI boundary.
- Acceptance: current authorities contain no stale Copilot, Node profile,
  development provisioning, ToggleTerm, Noice, or autotag product claims; every
  remaining direct dependency owns a named review/accessibility job; no 95+ or
  cross-platform claim exceeds evidence.
- Validation: documentation path/link scan; cross-document forbidden/stale term
  scan; dependency manifest reconciliation; `git diff --check`; clean worktree
  release evidence bound to the final commit when authorized.

## Handoff

- Assumptions: external agents remain the generation path; review/accessibility
  behaviors are protected; uncertain removals default to parity-first; GitHub CI
  remains unauthorized.
- Non-goals: no model integration, hosted telemetry, second workflow, user-state
  mutation, or release certification without platform evidence.
- Rollback: revert one stage at a time and restore its exact lock backup; never
  roll back by deleting user config/data/state/cache.
- Deviations: Noice was not removed. With Noice disabled, ordinary attached UI
  passed after correcting opts ownership, but the injected raw-fold failure
  blocked the native-message embed channel. The plan's parity gate therefore
  required restoration. Health/help consolidation uses a unified routing facade
  and stable aliases rather than rewriting the already-passive collectors.
- Status: implementation, commit, PR, and manual Ubuntu deployment validation are
  complete. Windows/WSL and commit-bound release evidence remain pending.
