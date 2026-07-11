# Agent-Era Observation Surface PLAN+TASK

Date: 2026-07-11

Status: complete for the authorized local boundary; remote platform evidence pending.

PM: `docs/product/clarity-observation-surface-pm.md`

Architecture:
`docs/architecture/2026-07-11-agent-era-observation-surface-blueprint.md`

Evidence:
`docs/reviews/2026-07-11-keymap-surface-decision-report.md` and
`docs/reviews/2026-07-11-observation-surface-implementation-review.md`

## Summary

Replace Clarity's inherited-first interaction surface with a stable bilingual
action catalog, zero-mutation Git observation, curated Neo-tree/Picker/dashboard
profiles, one Health entry, project-owned formatting, and evidence-gated
dependency reductions. Keep LazyVim lifecycle ownership and preserve all
review, accessibility, diagnostic, and machine-readable contracts.

The owner approved the architecture and authorized this plan's full local
execution, commits, and push on 2026-07-11. GitHub CI is explicitly excluded.

## Current Reality

- The reviewed baseline is `main` at
  `c7f80052362860c2500327cb00365754c5f7997e`.
- The accepted lock drift is isolated in `1706819`; product behavior is in
  `9a69835`; gated dependency removal is in `57328ae`; isolated contract and
  release hardening is in `596cffa`; exact i18n and real-input trust-gap closure
  is in `21f8d29`.
- Natural runtime evidence now proves exactly 28 global normal leader actions
  plus seven context-scoped actions: five LSP, one Git hunk preview, and one
  editable-buffer formatting recovery. Neo-tree exposes 20 local mappings;
  files Picker exposes input 19 normal/18 insert, list 20 normal, and preview
  two normal mappings; dashboard exposes six actions.
- Five Git observations and retained Gitsigns navigation/preview pass full
  HEAD/refs/index/worktree/optional-lock snapshots. No promoted or component-
  local Git mutation path remains.
- English/Chinese switching refreshes global/contextual which-key, Neo-tree,
  active/future Picker instances, dashboard, and open Health content without
  changing callback identity.
- Resolved active and locked plugin sets each contain exactly 18 entries after
  the approved parity gates.
- Clean macOS release evidence binds `69ecfbf1872446287c1ec849e432b8d78fe48934`
  under owner-only artifact `20260711-69ecfbf`. Exact-commit Ubuntu, Windows,
  WSL, and hosted-CI evidence remains pending.

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
   unpromoted one-release compatibility routes; CLI/JSON IDs stay stable.
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
- Do not trigger GitHub Actions. The required remote Ubuntu/Windows/macOS matrix
  and real-WSL evidence remain pending; they are not inferred from the completed
  owner-provided macOS commit-bound release.

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

- Status: done — 2026-07-11; accepted in lock-only commit `1706819` after copied-
  candidate validation; exact pre-task bytes remain in owner-only backup
  `20260711T192244Z-pre-observation-surface-lazy-lock.json`
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

- Status: done — 2026-07-11; implemented in `9a69835`, with exact catalog,
  disable-set, scope, identity, and real-input contracts hardened in `596cffa`
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

- Status: done — 2026-07-11; implemented in `9a69835` and verified through
  `en -> zh -> en` global, contextual, component, dashboard, and open-view tests
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

- Status: done — 2026-07-11; implemented in `9a69835`, with real-input repository
  immutability and optional-lock snapshots hardened in `596cffa`
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

- Status: done — 2026-07-11; implemented in `9a69835` and verified against
  natural resolved component maps and removed-action negative input
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

- Status: done — 2026-07-11; seven Health routes, live rendering, stable machine
  contracts, and one-release legacy command adapters landed in `9a69835`
- Depends on: SURFACE-003, SURFACE-005
- Files: `nvim/lua/config/{health,help,commands,audit,validation}.lua`, README,
  guide, Health/help/command tests
- Change: render Health overview, recovery, Messages, and Clarity diagnostic
  events through one facade; move Start/Clipboard/Sync content into routes;
  preserve path/export and machine contracts; keep legacy commands as
  unpromoted compatibility routes for one release.
- Acceptance: only Health and Language are promoted; Messages includes native/
  Noice history separately from structured events; repeated/open-view locale
  refresh is non-destructive; old commands reach equivalent content.
- Validation: route/alias equivalence; session-state before/after; log export;
  message/fault fixture; 60x16 and 80x24 attached UI.

### SURFACE-007: Remove Global Style And Background Maintenance

- Status: done — 2026-07-11; project-owned formatting, disabled background
  checker, stable wrap/numbers, and visible fold failures landed in `9a69835`
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

- Status: done — 2026-07-11; five dependencies removed in `57328ae` after
  system-LSP, static-theme, native-snippet/completion, pairs, and fold gates;
  active and locked sets are 18/18
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

- Status: done — 2026-07-11; clean commit-bound release passed for `69ecfbf`
  with owner-only artifact `20260711-69ecfbf`; 60 Python and 26 Lua tests pass
- Depends on: SURFACE-003, SURFACE-004, SURFACE-005, SURFACE-006, SURFACE-007,
  SURFACE-008
- Files: `scripts/{clarity_runtime,run_clarity_action_matrix,run_clarity_contracts,
  run_clarity_smoke,run_clarity_tests}.py`, `tests/lua/real_input_action_matrix.lua`,
  fake LSP/formatter fixtures, action-matrix/runtime/i18n Python tests, evidence
  fields in this plan
- Change: run the complete local layered gate from clean copied candidates;
  record exact counts, hashes, versions, kept blockers, and honest platform
  boundary. Do not edit scoring or required gates to obtain success.
- Acceptance: fast, contracts, behavior, faults, and release pass; candidate and
  authority hashes remain stable; zero P0/P1 remains locally; Ubuntu, Windows,
  WSL, and GitHub-hosted release evidence stay pending.
- Validation: all five router commands; JSON report inspection; `git diff
  --check`; clean archive/offline restart.

### SURFACE-010: Reconcile Truth, Commit, And Push

- Status: done — 2026-07-11; public/current docs, ADRs, implementation review,
  dependency manifest, and closeout are reconciled; clean release passed; the
  feature branch was pushed at `57ff1be` without a PR or GitHub Actions run
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

## Execution Evidence And Deviations

- Lock acceptance and dependency pruning remained separate transactions. The
  pre-observation backup is mode `0600`; normalization only prunes the
  intersection of the reviewed exclusion registry and runtime-disabled specs.
- `config.product_policy` is the single reviewed exclusion registry. It carries
  18 rationale/revisit-trigger records and generates `minimal.lua`, replacing
  hand-maintained disabled lock sentinels with an auditable policy mechanism.
- Picker which-key trigger filetypes are disabled because they reintroduced
  inherited input mappings after profile resolution. The curated built-in help
  remains the one discoverability path and the exact component budgets pass.
- The static palette preserves the approved visual intent and corrects contrast
  for `Visual`, `LineNr`, and `DiagnosticError`; exact Lush implementation values
  were not treated as product behavior.
- Git observations use bounded fixed argv and repository-local cwd. Gitsigns
  keeps upstream lifecycle ownership and receives only Clarity's navigation and
  preview delta; behavior snapshots, not environment labels, prove no mutation.
- System/project LSP, formatter, snippets, and parsers remain user/project owned.
  Missing tools produce recovery outcomes and schedule no install path.
- Real input now covers 28 global, seven contextual, and four native/diagnostic
  actions. WorkspaceEdits must change and restore buffers; startup, cleanup,
  repository/authority immutability, path privacy, and fake-process exit are
  required gates rather than informational fields.
- Candidate copies use Git tracked/non-ignored files, so ignored local `.env`,
  agent contracts, and private state cannot enter copied-candidate evidence.
- Attached-UI execution is pinned to `pynvim==0.6.0`; test manifests record the
  pin and all command timeouts terminate descendant process groups.
- GitHub Actions was not run or inspected. The local score therefore remains
  below 95 until the separately authorized platform evidence gates are met.
- `codex/20260711-observation-surface` was created on `origin`; the final
  closeout-only ledger commit changes no runtime authority and remote-ref
  equality is verified in the delivery handoff.

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
