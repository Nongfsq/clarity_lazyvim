# Agent-Era Observation Surface PLAN+TASK

Date: 2026-07-11

Status: approved; implementation authorized and in progress.

PM: `docs/product/clarity-observation-surface-pm.md`

Architecture:
`docs/architecture/2026-07-11-agent-era-observation-surface-blueprint.md`

Evidence:
`docs/reviews/2026-07-11-keymap-surface-decision-report.md`

## Summary

Replace Clarity's inherited-first interaction surface with a stable bilingual
action catalog, zero-mutation Git observation, curated Neo-tree/Picker/dashboard
profiles, one Health entry, project-owned formatting, and evidence-gated
dependency reductions. Keep LazyVim lifecycle ownership and preserve all
review, accessibility, diagnostic, and machine-readable contracts.

The owner approved the architecture and authorized this plan's full local
execution, commits, and push on 2026-07-11. GitHub CI is explicitly excluded.

## Current Reality

- Baseline is `main` at `c7f80052362860c2500327cb00365754c5f7997e`.
- The worktree contains the approved untracked blueprint/report plus document
  index edits and a pre-existing two-entry `lazy-lock.json` drift:
  Gitsigns `25050e4 -> eb60cc7`, Neo-tree `a3adf0a -> b01ee17`.
- Natural runtime evidence: 133 global normal leader actions; 20 buffer-local
  leader rows in a Lua Git+LSP buffer; 153 effective union; Neo-tree 70 local
  rows; one files picker 134 rows.
- Locked Snacks/Neo-tree interfaces expose hidden Git mutation. The current
  Gitsigns `on_attach` also retains and duplicates repository-write mappings.
- Live locale changes do not refresh menus or contextual maps.
- The active and locked plugin sets each contain 23 entries before any approved
  dependency gate is executed.

## Architecture Decisions

1. `config.actions.catalog` is the only product-action authority. It stores
   stable ID, job, keys/modes, scope, owner, mutability, visibility, and locale
   keys. Runtime handlers remain in focused action modules.
2. Global inherited maps outside the catalog are explicitly deleted after
   LazyVim map materialization; lazy/buffer-local owners receive explicit plugin
   or attach-time overrides so removed paths cannot reappear later.
3. Git observations use `vim.system` argument arrays, repository cwd, bounded
   output/time, `GIT_OPTIONAL_LOCKS=0`, typed outcomes, and a read-only scratch
   renderer. No retained Git view delegates to mutation-capable picker confirms.
4. Gitsigns keeps config lifecycle ownership but Clarity replaces its mapping
   delta with `[h`/`]h` and dynamic preview only; upstream mutation mappings are
   not composed.
5. Neo-tree keeps upstream setup ownership while Clarity supplies a complete
   curated mapping profile and removes the Git source. Snacks keeps plugin
   ownership while Clarity supplies a curated picker/dashboard profile.
6. `User ClarityLocaleChanged` is the live refresh contract. Mapping identity
   never changes when only a label changes.
7. Health becomes the human model/renderer facade. Legacy commands remain thin,
   undocumented one-release compatibility routes; CLI/JSON IDs stay stable.
8. Project configuration and formatter defaults own style. Clarity owns routing
   and fallback only.
9. Lock drift and dependency removal are separate atomic transactions. No lock
   bytes are mixed into interaction commits.

## Test And QA Plan

### Static And Unit

- Catalog schema/parity, exact global/dynamic budgets, duplicate lhs/scope/mode,
  mutability, label parity, and explicit disable-set coverage.
- Git argv allowlist, no shell strings, bounded result normalization, safe cwd,
  and renderer key allowlist.
- Resolved Neo-tree/Picker/dashboard profiles and absence of hidden Git source or
  mutation actions.
- Locale event cardinality, `en -> zh -> en` metadata refresh, buffer-local
  coverage, and callback/rhs/options identity.
- Formatter ownership, checker/provisioning absence, dependency resolution, and
  static theme parity.

### Isolated Behavior

- Natural empty/file/directory/Git/LSP lifecycles with attached UI at 60x16 and
  80x24.
- Real input for every promoted action and negative input for removed aliases.
- Disposable Git fixture snapshots HEAD, refs, index hash, worktree status, and
  optional-lock files before/after status, diff, log, graph, blame, preview, and
  attempted mutation keys.
- Neo-tree and picker contextual map enumeration with exact budgets.
- System/project-owned LSP attach with Mason disabled; missing-server recovery
  schedules no install.
- Theme reload/contrast, LSP snippet insertion, mini.pairs small edits, format
  present/missing/project-config, and raw-fold fault visibility.

### Local Release Boundary

- Run `python3 scripts/run_clarity_tests.py fast`, `contracts`, `behavior`,
  `faults`, then `release` from copied candidates and isolated roots.
- Run Ruff/StyLua and check-only lock normalization through existing routers.
- Do not trigger GitHub Actions. Windows/WSL and commit-bound release evidence
  remain pending and are not inferred from macOS.

## Frontend Workstream

Neovim attached UI only: which-key, scratch observation views, Neo-tree, Snacks
picker, dashboard, Health, and small-screen behavior. There is no browser UI.

## Backend/API/Data Workstream

No service, database, or public network API. Internal contracts are the action
catalog, typed Git outcomes, Health routes, diagnostic event IDs, CLI/JSON
reports, and user-owned locale/onboarding/log state. No destructive data
migration is allowed.

## Analytics, Observability, And Security Considerations

- No analytics or telemetry.
- Git commands are fixed argv templates with no prompt-supplied subcommand or
  shell interpolation; output is bounded and sanitized before diagnostics.
- No buffer contents, clipboard contents, environment values, credentials, or
  unbounded Git output enter persistent logs.
- Repository immutability is a behavior gate, not a label assertion.
- Existing structured diagnostic IDs and sanitized export remain compatible.

## Migration Order

1. `SURFACE-001` and `LOCK-001` establish authority and a clean reviewed base.
2. `SURFACE-002` materializes the catalog and global/context ownership.
3. `SURFACE-003` makes labels live and scope-aware.
4. `SURFACE-004` replaces Git observation and closes hidden mutation paths.
5. `SURFACE-005` curates component-local surfaces and dashboard.
6. `SURFACE-006` unifies Health/help/command presentation.
7. `SURFACE-007` removes editor-wide style/background maintenance.
8. `SURFACE-008` executes dependency gates and any atomic lock migration.
9. `SURFACE-009` closes behavior/release evidence.
10. `SURFACE-010` reconciles docs, commits, and pushes the branch.

## Rollout, Compatibility, And Rollback Notes

- Work on `codex/20260711-observation-surface`; do not push directly to `main`.
- Commit planning/docs, existing lock drift, interaction/i18n, Git/components,
  dependency migration, and closeout as reviewable boundaries.
- Legacy Clarity commands remain callable for one release but disappear from
  promoted menus/help.
- Removed inherited key aliases have no compatibility period because leaving
  them callable defeats the approved product contract. Native Neovim mappings
  remain untouched.
- Roll back a task by reverting its commit. Lock rollback restores the exact
  task backup; never delete user config/data/state/cache.
- A failed Git immutability, error visibility, accessibility, system-LSP,
  completion, theme, or clean-candidate gate blocks the corresponding migration.

## Tasks

### SURFACE-001: Approve Product And Execution Authority

- Status: done — 2026-07-11; PM, approved architecture, exact decision report,
  standalone execution plan, and canonical index pass path/field/whitespace checks
- Depends on: none
- Files: `docs/product/clarity-observation-surface-pm.md`,
  `docs/architecture/2026-07-11-agent-era-observation-surface-blueprint.md`,
  `docs/reviews/2026-07-11-keymap-surface-decision-report.md`,
  `progress/2026-07-11-agent-era-observation-surface-plan.md`,
  `docs/DOCUMENT_INDEX.md`
- Change: record the approved product boundary, exact per-key evidence,
  zero-mutation correction, decisions, task dependencies, local-only evidence
  boundary, and no-GitHub-CI authorization.
- Acceptance: a fresh agent can implement without inventing product scope; all
  canonical paths resolve; no document presents proposed behavior as current.
- Validation: path/link checks; task-template checklist; `git diff --check`.

### LOCK-001: Resolve Existing Gitsigns And Neo-tree Lock Drift

- Status: pending
- Depends on: SURFACE-001
- Files: `lazy-lock.json`, owner-only backup under
  `~/.local/state/clarity_lazyvim/lock-backups/`, task evidence in this plan
- Change: back up exact committed and current bytes; validate the two resolved
  updates in an isolated copied candidate; accept them in a lock-only commit if
  all current behavior gates pass, otherwise restore committed bytes. Do not
  combine this with dependency removal.
- Acceptance: drift has an explicit accept/reject decision, check-only
  normalization is clean, rollback restores exact bytes, and no other lock entry
  changes.
- Validation: lock diff whitelist; fast/contracts/behavior/faults routers;
  `python3 scripts/update_clarity_lock.py` in check-only mode; rollback hash.

### SURFACE-002: Materialize The Product Action Catalog

- Status: pending
- Depends on: SURFACE-001, LOCK-001
- Files: `nvim/lua/config/actions/catalog.lua`,
  `nvim/lua/config/keymaps.lua`, `nvim/lua/plugins/{tooling,treesitter,git}.lua`,
  `tests/lua/test_keymap_ownership.lua`, new catalog/runtime tests
- Change: define the 28 global and seven normal dynamic actions, visual variants,
  stable metadata, explicit global/nonleader/buffer-local disable sets, and
  materialization/pruning hooks. Preserve native mappings and one canonical path
  per job; set absolute numbers, wrap, and source visibility as stable defaults.
- Acceptance: exact global count 28; full Git+LSP normal union <=35; every action
  has one owner and bilingual key; removed aliases are not callable after natural
  load or late plugin/LSP/Git attachment.
- Validation: catalog unit test; natural attached global/Git/LSP enumeration;
  real input for fold/wrap/window/search; removed-key negative assertions.

### SURFACE-003: Make Localization Live And Scope-Aware

- Status: pending
- Depends on: SURFACE-002
- Files: `nvim/lua/config/{i18n,menu_i18n,help,health}.lua`, action catalog,
  i18n/keymap/help tests
- Change: emit `User ClarityLocaleChanged` once per effective change; render
  labels by action ID; refresh global and buffer-local which-key metadata,
  component profiles, dashboard, and open Clarity buffers without recreating
  action callbacks or requiring restart.
- Acceptance: `en -> zh -> en` leaves zero stale-language promoted labels and
  preserves rhs/callback/mode/scope/options; invalid/no-op choices emit no event;
  locale catalogs have exact parity.
- Validation: event cardinality test; global and LSP/Git buffer metadata
  snapshots; open-view refresh; i18n validation report.

### SURFACE-004: Implement Zero-Mutation Git Observation

- Status: pending
- Depends on: SURFACE-002, SURFACE-003
- Files: `nvim/lua/config/actions/git.lua`, `nvim/lua/plugins/git.lua`,
  `nvim/lua/plugins/neo-tree.lua`, Git action and behavior tests
- Change: implement bounded asynchronous read-only status/diff/log/graph/blame
  actions and a keyboard-accessible scratch renderer; replace `<leader>gs/gd/gl/
  gt/gb`; keep dynamic `ghp` and `[h`/`]h`; stop composing Gitsigns mutation
  mappings; disable Neo-tree Git source and source switching to it.
- Acceptance: zero public or component-local Git mutation key; no retained
  confirm executes checkout; all observation jobs render actionable success,
  missing-Git, not-repo, timeout, and bounded-output outcomes; repository
  snapshots are byte/identity stable after real input.
- Validation: argv/unit tests; disposable-repo immutability fixture including
  `<Tab>`, `<C-r>`, `<CR>` negative input; attached UI; source forbidden scan.

### SURFACE-005: Curate Neo-tree, Picker, And Dashboard Profiles

- Status: pending
- Depends on: SURFACE-002, SURFACE-004
- Files: `nvim/lua/plugins/{neo-tree,ui}.lua`, action catalog, component-profile
  tests, help/i18n strings
- Change: replace inherited Neo-tree mappings with the approved observation
  profile; disable file-tree structural mutation and Git source; reduce core
  Snacks pickers to one confirm/cancel/navigation/preview/help path; present a
  localized six-action dashboard: files, text, recent, new file, Health, quit.
- Acceptance: Neo-tree <=24 visible actions, each core picker <=20, dashboard <=6;
  no tab, multi-select, quickfix export, split/vsplit/window picker, layout tuning,
  register insertion, maintainer, or mutation controls remain promoted.
- Validation: resolved opts; natural component map enumeration; directory and
  picker attached UI; mouse-independent keyboard task walkthrough; localization
  snapshots.

### SURFACE-006: Make Health The Human Entry

- Status: pending
- Depends on: SURFACE-003, SURFACE-005
- Files: `nvim/lua/config/{health,help,commands,audit,validation}.lua`, README,
  guide, Health/help/command tests
- Change: render Health overview, recovery, Messages, and Clarity diagnostic
  events through one facade; move Start/Clipboard/Sync content into routes;
  preserve path/export and machine contracts; keep legacy commands as
  undocumented compatibility routes for one release.
- Acceptance: only Health and Language are promoted; Messages includes native/
  Noice history separately from structured events; repeated/open-view locale
  refresh is non-destructive; old commands reach equivalent content.
- Validation: route/alias equivalence; session-state before/after; log export;
  message/fault fixture; 60x16 and 80x24 attached UI.

### SURFACE-007: Remove Global Style And Background Maintenance

- Status: pending
- Depends on: SURFACE-002
- Files: `nvim/lua/plugins/formatting.lua`, `nvim/lua/config/lazy.lua`,
  `nvim/lua/config/options.lua`, tooling/Tree-sitter policy and related tests
- Change: remove Clarity-wide formatter style arguments; preserve formatter
  routing and LSP fallback; disable lazy.nvim background checker; keep Mason and
  parser auto-install empty while dependency parity is evaluated; default
  `conceallevel=0` and move Tree-sitter recovery to Health.
- Acceptance: project config/tool defaults own style; no background checker or
  install task starts; format and raw-fold failure remain visible and recoverable;
  stable absolute-number/wrap behavior remains.
- Validation: project formatter fixtures; process/autocmd negative assertions;
  options/runtime contracts; fault router.

### SURFACE-008: Execute Dependency Parity Gates And Atomic Migration

- Status: pending
- Depends on: SURFACE-004, SURFACE-005, SURFACE-006, SURFACE-007
- Files: `nvim/lua/plugins/{minimal,tooling,colorscheme}.lua`,
  `nvim/colors/custom_colorblind_theme.lua`, `lazy-lock.json`, dependency/theme/
  completion/LSP tests, resolved dependency manifest
- Change: prove system/project LSP without Mason, static theme without Lush,
  LSP/native snippets without friendly-snippets, and general review without
  lazydev. Remove only passing dependencies in one dedicated compatibility+
  lock transaction; retain mini.pairs and Noice unless their existing behavior
  gates independently pass.
- Acceptance: every removed plugin is absent from resolved spec and lock; every
  retained plugin owns a named behavior/blocker; static theme reload and contrast,
  system LSP attach, snippet insertion, pairs, and raw-fold fault all pass;
  rollback restores exact pre-task bytes.
- Validation: isolated A/B fixtures; resolved active/lock manifest; theme/LSP/
  completion/edit tests; check-only normalization; offline restart; rollback hash.

### SURFACE-009: Close The Local Behavior And Release Gate

- Status: pending
- Depends on: SURFACE-003, SURFACE-004, SURFACE-005, SURFACE-006, SURFACE-007,
  SURFACE-008
- Files: runtime/contract tests, `scripts/run_clarity_tests.py` only if routing
  coverage is missing, evidence fields in this plan
- Change: run the complete local layered gate from clean copied candidates;
  record exact counts, hashes, versions, kept blockers, and honest platform
  boundary. Do not edit scoring or required gates to obtain success.
- Acceptance: fast, contracts, behavior, faults, and release pass; candidate and
  authority hashes remain stable; zero P0/P1 remains locally; Windows/WSL and
  GitHub-hosted release evidence stay pending.
- Validation: all five router commands; JSON report inspection; `git diff
  --check`; clean archive/offline restart.

### SURFACE-010: Reconcile Truth, Commit, And Push

- Status: pending
- Depends on: SURFACE-009
- Files: `README.md`, `doc/clarity_lazyvim_complete_guide_zh.md`,
  `docs/ai/current-reality.md`, `docs/DOCUMENT_INDEX.md`, product/architecture/
  review documents, this plan, dated closeout/ADR/dependency manifest as needed
- Change: reconcile documentation with actual runtime and evidence; record
  deviations and rollback; commit by atomic boundary and push
  `codex/20260711-observation-surface` to `origin` without creating/running
  GitHub Actions.
- Acceptance: no stale public key, command, dependency, mutation, localization,
  or platform claim; worktree after commits contains no task-owned changes;
  pre-existing/user-owned state is preserved; remote branch matches local HEAD.
- Validation: docs path/link/stale scan; `git status --short --branch`; commit
  review; `git push -u origin codex/20260711-observation-surface`; verify remote
  ref only, do not inspect or trigger workflow runs.

## Handoff

- Assumptions/defaults: external agents own repository and file-tree structural
  mutation; `<leader>fn` and ordinary buffer save remain deliberate precision
  editing; native mappings remain available but are not Clarity-promoted.
- Non-goals: GitHub CI, PR/merge, tag/release, embedded AI, new plugin, second
  workflow, destructive user-state migration, or unsupported platform claim.
- Rollback: revert task commits in reverse order and restore the matching exact
  lock backup for `LOCK-001`/`SURFACE-008`; never clean user-owned files.
- Status line: PM written to
  `docs/product/clarity-observation-surface-pm.md`; PLAN+TASK written to this
  file; owner approval and implementation authorization were supplied in the
  same request, so execution proceeds without a second approval stop.
