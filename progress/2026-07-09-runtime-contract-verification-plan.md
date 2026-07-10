# Clarity Runtime Contract Verification PLAN+TASK

Date: 2026-07-09
Status: first execution batch complete locally — 2026-07-10; evidence review required
Product intent:
[`../docs/product/clarity-runtime-trust-pm.md`](../docs/product/clarity-runtime-trust-pm.md)
Architecture:
[`../docs/architecture/2026-07-09-runtime-contract-verification-blueprint.md`](../docs/architecture/2026-07-09-runtime-contract-verification-blueprint.md)
Parent plan:
[`2026-07-09-clarity-95-refactor-plan.md`](2026-07-09-clarity-95-refactor-plan.md)

## Summary

Build a code-level verification contract that proves Clarity modules load
naturally in real startup shapes, final state belongs to the intended owner,
promoted workflows execute correctly, and diagnostics do not mutate the runtime
they inspect.

The first vertical slice adopts the current local line-number/wrap repair and
must reproduce the original false-green defect before accepting the fix. The
work then expands through startup scenarios, product behavior ownership,
negative controls, passive diagnostics, coverage manifests, and the existing
platform CI gate.

PM quality bar: the owner performs a short qualitative experience review;
repository automation owns deterministic correctness and coverage.

## Current Reality

- Branch: `codex/20260709-clarity-trust-foundation` at committed baseline
  `6e6112a` plus local uncommitted runtimepath, line-wrap, validation, and
  architecture-planning changes.
- Root `lazy-lock.json` and `lazyvim.json` are clean at the accepted hashes.
- Real file startup previously left `config.options` unloaded and used LazyVim's
  relative numbering; validation replayed `VeryLazy` and still passed.
- The local fix preserves `vim.g.clarity_nvim_dir` in lazy.nvim runtime paths,
  enables visual wrapping with line/break indentation, and adds direct runtime
  assertions. It is not committed and belongs to `RUNTIME-004`.
- `scripts/run_clarity_validate.py` is 681 lines and replays `VeryLazy` in five
  paths. Runtime audit/validation replay it in two more paths.
- Ten config modules and ten plugin modules have no general completeness or load
  phase gate.
- `run_clarity_smoke.py` proves candidate/source hashes and boot stability but
  only snapshots paths, Neovim version, and plugin count.
- `CI-002` is still in progress because no commit-bound remote matrix has run.

## Architecture Decisions

1. `tests/contracts/runtime_contract.lua` is the single test-owned catalog for
   module classification, startup scenarios, promoted capabilities, ownership,
   required/optional profile, and coverage state.
2. The probe observes natural lifecycle events. Test and production diagnostics
   must not replay `VeryLazy`, `VimEnter`, `BufEnter`, or `FileType` to complete
   inspected state.
3. Every scenario runs from a copied candidate with isolated config/data/state/
   cache roots and hashes authority files before and after.
4. Product-critical checks assert final state, intended owner, and behavior. A
   matching value or mapping from the wrong owner is a failure.
5. New modules/capabilities may be `covered`, `planned` with a named task, or
   intentionally inherited/non-promoted. `unclassified` always fails; release
   rejects `planned` core capabilities.
6. Critical gates include fault injection so the suite proves it detects the
   target defect.
7. `run_clarity_validate.py` remains a product behavior adapter during migration;
   startup correctness and coverage move to the contract runner.
8. Existing `VALIDATE-003` owns removal of lifecycle replay and live-session
   restoration. This plan supplies the passive runner it depends on.
9. Existing plugin/UX tasks convert their catalog entries from `planned` to
   `covered`; this plan does not prematurely implement those plugin migrations.
10. `CI-002` cannot close until the contract runner and artifacts are integrated
    through `RUNTIME-008` and the real platform matrix passes.

## Frontend Workstream

N/A — there is no browser frontend. Attached terminal UI verification is an
isolated Neovim runtime scenario under this plan.

## Backend/API/Data Workstream

N/A — there is no backend, API, database, schema, or application data migration.
Repository authority files are read-only inputs; candidate runtime state and CI
artifacts are test-process-owned ephemeral data.

## Analytics, Observability, And Security Considerations

- No telemetry or user analytics are added.
- JSON contract results use stable check IDs and include scenario, phase, owner,
  expected, actual, severity, repair, source hashes, and tool versions.
- CI uploads scenario snapshots, coverage manifest, environment manifest, and
  bounded failure logs without user files or secrets.
- All subprocesses retain explicit timeouts; tests never repair live user state.
- The coverage manifest separates local readiness, planned refactor coverage,
  and commit-bound release evidence.

## Test And QA Plan

### Fast PR Tier

- Ruff, StyLua, Actionlint, JSON/Markdown/diff checks.
- Python unit tests for schema, catalog completeness, scenario commands,
  coverage calculation, hashes, timeout, and negative fixtures.
- Lua unit tests for catalog schema and passive snapshot normalization.
- Empty and file-start contract scenarios in a copied candidate.

### Runtime Tier

- Empty, file, directory, stdin, arbitrary checkout, symlink, clean first boot,
  and offline restart.
- Promoted fold/wrap and single-explorer behavior in disposable fixtures.
- Passive audit/validation repeat and session restoration.
- Authority-file hash equality per scenario.

### Full Release Tier

- Required Ubuntu, Windows, and macOS runtime matrix.
- Attached UI at 60x16 and 80x24 through CI-provided `pynvim`.
- All critical negative controls.
- Zero unclassified modules/capabilities and zero planned core capabilities.
- Commit-bound environment, coverage, scenario, lock, and JSON evidence.

### Human Acceptance

- Confirm absolute line numbering plus wrapped continuation readability.
- Confirm fold/wrap interaction feels understandable.
- Review small-terminal help, color/spacing, copy, and perceived latency.
- No exhaustive functional walkthrough; deterministic failures return to
  automated fixtures.

## Tasks

### RUNTIME-001: Define The Runtime Contract Catalog

- Status: done — 2026-07-10; catalog drift, owner, coverage, and task-reference tests pass
- Depends on: QA-001
- Files: `tests/contracts/runtime_contract.lua`,
  `tests/lua/test_runtime_contract_catalog.lua`,
  `tests/python/test_runtime_contracts.py`
- Change: define the versioned catalog schema for config modules, load classes,
  natural phases, startup scenarios, promoted capabilities, owners, profiles,
  final-state checks, behavior checks, platform scope, allowed mutations, and
  `covered|planned|inherited` status. Seed all ten current config modules and the
  public daily-core surface. Scan `nvim/lua/config/*.lua` and fail on an
  unclassified file. `planned` entries must name an existing task ID.
- Acceptance: all current config modules are classified; every README-promoted
  daily-core action has one catalog entry; duplicate IDs/owners/scenarios fail;
  missing files and nonexistent planned task IDs fail; no runtime product code
  imports the test catalog.
- Validation: `python3 scripts/run_clarity_lua_tests.py`; `python3 -m unittest
  tests.python.test_runtime_contracts -v`; catalog drift fixture adds an orphan
  config module and receives the expected failure ID.

### RUNTIME-002: Build The Passive Runtime Probe

- Status: done — 2026-07-10; passive schema and no-lifecycle-replay tests pass
- Depends on: RUNTIME-001
- Files: `tests/lua/runtime_probe.lua`, `tests/lua/test_runtime_probe.lua`,
  `tests/fixtures/runtime/minimal/`
- Change: collect a read-only JSON snapshot of canonical paths/hashes, versions,
  `package.loaded` Clarity modules, natural lifecycle event counts, critical
  options, maps, commands, autocmds, resolved plugin specs, windows, buffers,
  filetypes, and errors. The probe may wait with a bounded predicate but must not
  execute lifecycle autocmds, plugin setup, repair, or user commands that mutate
  the inspected state.
- Acceptance: repeated snapshots of stable fixture state normalize identically;
  the probe records missing modules rather than requiring them; source contains
  no lifecycle replay; snapshot schema is versioned and reports unsupported
  fields explicitly rather than omitting them silently.
- Validation: Lua probe unit tests under `--clean`; source-policy test rejects
  `doautocmd`, lifecycle `nvim_exec_autocmds`, and repair calls in the probe;
  JSON schema/normalization unit tests pass.

### RUNTIME-003: Orchestrate Natural Startup Scenarios

- Status: done — 2026-07-10; empty/file headless plus attached-UI orchestration passes
- Depends on: RUNTIME-001, RUNTIME-002
- Files: `scripts/run_clarity_contracts.py`, `scripts/clarity_runtime.py`,
  `tests/python/test_runtime_contracts.py`, `tests/fixtures/runtime/`
- Change: copy the repository candidate, configure isolated native roots, launch
  Neovim with exact scenario arguments, wait for natural lifecycle completion,
  invoke the passive probe, compare with the catalog, hash source/candidate
  authority files, and emit per-check plus coverage JSON. Initial scenarios are
  empty and tracked-file startup. The evaluator never edits the candidate to
  make a positive test pass; fault injection uses explicit fixture transforms on
  a second disposable copy.
- Acceptance: empty and file startup produce stable scenario IDs and evidence;
  source/candidate mutation identifies the exact file/scenario; timeout includes
  command and bounded logs; evaluator reports phase/owner/expected/actual/repair;
  no real user roots appear in environment or artifacts.
- Validation: Python orchestration unit tests; `python3
  scripts/run_clarity_contracts.py --scenario empty --scenario file --json`;
  forced timeout, invalid JSON, and authority-write fixtures fail predictably.

### RUNTIME-004: Prove And Fix The Line-Number Lifecycle Regression

- Status: done — 2026-07-10; positive runtime and exact four-ID negative control pass
- Depends on: RUNTIME-003
- Files: `nvim/lua/config/lazy.lua`, `nvim/lua/config/options.lua`,
  `nvim/lua/config/autocmds.lua`, `nvim/lua/config/keymaps.lua`,
  `scripts/run_clarity_validate.py`, runtime contract catalog and fault fixtures
- Change: adopt or revise the current local fix so lazy.nvim preserves the
  nested Clarity runtime while LazyVim loads options and file-argument autocmds.
  Product defaults are absolute line numbers, relative numbering off, visual
  wrapping on with word-boundary/continuation indentation, `<leader>uw` toggle,
  and `<leader>cz` fold toggle. Add a negative fixture that removes the nested
  runtime path and prove file startup fails for module load phase, numbering,
  autocmd ownership, and mapping ownership before the fixed candidate passes.
  Migrate temporary assertions from the monolithic validator into the contract
  evidence where appropriate.
- Acceptance: real empty, file, and directory startup load options/autocmds/
  keymaps naturally exactly once; editing windows show `number=true`,
  `relativenumber=false`, `wrap=true`; wrapped continuation lines preserve
  readable indentation; fold/wrap callbacks execute and restore state; Neo-tree
  and dashboard remain numberless; source lock/JSON hashes remain accepted and
  unchanged.
- Validation: run the negative fixture and assert its four intended stable
  failures; run the same scenarios against the fix; run
  `python3 scripts/run_clarity_validate.py --json`,
  `python3 scripts/run_clarity_smoke.py`, Ruff, StyLua, unit suites, and
  `git diff --check`; perform only the short human readability review.

### RUNTIME-005: Complete The Startup And Mutation Matrix

- Status: pending
- Depends on: RUNTIME-004
- Files: `scripts/run_clarity_contracts.py`, contract catalog,
  `tests/fixtures/runtime/`, Python/Lua contract tests
- Change: add directory, stdin, arbitrary checkout, symlink config, clean first
  boot, and network-blocked offline restart. Hash root and candidate lock/JSON
  before and after every phase. Snapshot event counts and fail duplicate module/
  autocmd registration. Keep attached UI out of the fast local requirement and
  classify it for the full CI tier.
- Acceptance: every scenario uses isolated roots and natural lifecycle; directory
  startup has exactly one Neo-tree and zero Snacks Explorer; stdin does not open
  explorer/help unexpectedly; arbitrary/symlink paths resolve one authority;
  offline restart performs no network/bootstrap action; all authority hashes are
  unchanged and event/module counts are stable across restart.
- Validation: run all non-UI scenarios locally; forced duplicate event, network
  attempt, symlink drift, and authority-write fixtures fail their stable IDs;
  repeat the full matrix twice and compare normalized results.

### RUNTIME-006: Map Promoted Capabilities To Owners And Behaviors

- Status: pending
- Depends on: RUNTIME-003
- Files: runtime contract catalog, `tests/fixtures/runtime/`, behavior probe/test
  modules, existing feature tests where ownership belongs
- Change: classify file search, text search, explorer, fold/wrap, terminal, Git
  hunks, format, LSP navigation, parser, help/recovery, language, audit, and
  validation. Implement current stable behavior checks for fold/wrap and
  single-explorer ownership. Map unresolved migrations to their existing task
  owners (`NVIM-003` through `NVIM-007`, `VALIDATE-003`, `UX-002`, `THEME-001`)
  with `planned` status; do not mark them covered from existence alone.
- Acceptance: zero unowned promoted capabilities; fold/wrap and current explorer
  behavior execute in disposable fixtures; maps with correct LHS but wrong owner
  fail; every planned core entry names an existing task and release coverage
  reports it as incomplete.
- Validation: catalog coverage tests; behavior fixtures execute callbacks and
  restore state; wrong-owner and existence-only fixtures fail; generated coverage
  manifest separates covered, planned, inherited, optional, and unclassified.

### VALIDATE-003 Integration: Make Diagnostics Passive And Session-Safe

- Status: governed by the parent plan; not renumbered
- Depends on: RUNTIME-003, RUNTIME-006, QA-001, VALIDATE-002
- Files: as defined in the parent task plus passive snapshot/session fixtures
- Change: remove all production audit/validation lifecycle replay; split pure
  passive reporting from active subprocess behavior probes; preserve stable check
  IDs or publish an explicit mapping; serialize and restore the complete live
  session on success and injected failure.
- Acceptance: the existing parent-task criteria remain, plus zero lifecycle
  replay in production diagnostic modules and exact before/after session-state
  equality on two consecutive invocations.
- Validation: use the parent task commands plus source-policy search and
  success/failure session snapshots from a modified buffer.

### RUNTIME-007: Add Negative Controls And Coverage Gates

- Status: pending
- Depends on: RUNTIME-005, RUNTIME-006, VALIDATE-003
- Files: `tests/fixtures/runtime/faults/`, contract evaluator/tests, coverage
  manifest schema
- Change: add critical faults for hidden options module, missing nested runtime,
  duplicate lifecycle event, wrong-owner mapping, upstream option override,
  duplicate explorer, authority-file write, and diagnostic cleanup failure. Make
  fast CI reject unclassified entries and invalid planned ownership; make release
  mode reject planned core entries.
- Acceptance: every injected fault fails the intended stable check ID without
  unrelated cascades obscuring the root cause; the unchanged candidate passes;
  deleting a test or catalog entry cannot make coverage greener; coverage output
  is deterministic and versioned.
- Validation: run the fault suite and assert expected ID sets; run mutation guard
  twice; compare coverage manifests; Python/Lua unit tests cover schema and
  aggregation behavior.

### RUNTIME-008: Integrate Contract Evidence Into CI

- Status: pending
- Depends on: RUNTIME-007
- Files: `.github/workflows/clarity-validate.yml`, contract runner/config,
  artifact manifest tests, README validation section if implementation changes
  public commands
- Change: add fast contract gates and platform scenario artifacts to the existing
  pinned Ubuntu/Windows/macOS workflow. Install `pynvim` for the full attached-UI
  tier, run 60x16 and 80x24 UI contracts, upload coverage/scenario/environment
  evidence, retain current timeouts/permissions/action pinning, and make
  authority drift fail before artifact upload. Do not claim WSL from Ubuntu.
- Acceptance: Actionlint passes; artifacts identify commit, scenario, platform,
  versions, hashes, covered/planned/unclassified counts, and failure logs; local
  workflow helpers pass; remote required matrix completes for the exact commit;
  `CI-002` remains in progress until that remote evidence exists.
- Validation: local workflow/helper tests; `actionlint`; manually dispatched or
  PR-bound Ubuntu/Windows/macOS run with downloadable artifacts; artifact schema
  and commit/hash verification.

## Migration Order

1. Catalog and passive observation: `RUNTIME-001`, `RUNTIME-002`.
2. Natural runner and proof slice: `RUNTIME-003`, `RUNTIME-004`.
3. Scenario breadth and ownership inventory: `RUNTIME-005`, `RUNTIME-006`.
4. Passive production diagnostics: existing `VALIDATE-003`.
5. Negative controls and CI: `RUNTIME-007`, `RUNTIME-008`.
6. Close `CI-002` only after the exact remote platform evidence passes.
7. Existing plugin/UX tasks convert planned catalog entries to covered in their
   dependency order; release rejects remaining planned core entries.

`RUNTIME-005` and `RUNTIME-006` may run in parallel after `RUNTIME-004` where
their files do not overlap. No later task may bypass a failed required contract.

## Rollout, Compatibility, And Rollback Notes

- Keep existing stable validation IDs during migration or publish one explicit
  old-to-new mapping.
- Run legacy and contract checks together until the replacement has positive and
  negative evidence parity; do not keep duplicate paths indefinitely.
- The first implementation batch is `RUNTIME-001` through `RUNTIME-004` and stops
  for evidence review before expanding the matrix.
- Each task is independently reviewable and must leave the repository runnable.
- Revert a failed task commit and restore its matching contract schema/catalog;
  authority lock/JSON files do not change in this workstream.
- If the new gate is nondeterministic or exceeds the budget, keep it informative
  while fixing the runner, but do not remove the corresponding required legacy
  gate.
- Release rollback uses the prior green commit and its matching artifacts; local
  user state is never a rollback mechanism.

## Handoff

### First Batch Evidence — 2026-07-10

- Catalog: all 10 `config` modules classified; zero unclassified or missing;
  fold and wrap are covered, 12 later capabilities remain planned with owners.
- Natural phases: empty headless observes `LazyVimOptions`; file headless adds
  `LazyVimAutocmds`; attached UI adds `LazyVimKeymaps` after real `UIEnter`.
- Positive contract scenarios have zero failures. Options resolve to
  `number=true`, `relativenumber=false`, `wrap=true`, `linebreak=true`, and
  `breakindent=true`; fold/wrap callbacks execute and restore state.
- Negative candidate with the nested runtime removed returns exactly
  `CLARITY_RUNTIME_OPTIONS_CONTRACT`, `AUTOCMDS_CONTRACT`,
  `EDITING_DEFAULTS`, and `KEYMAP_CONTRACT`; the command exits successfully only
  when this exact expected set is observed.
- Source and candidate root authority hashes remain lock
  `79e5323b3074c5f6434a708a7c209c84f41b1bcb97541af512bfb069929b710a`
  and JSON
  `3911b0251e3c51aa127f937aa5de323dba1eb6227636549264bde36e1674ad02`.
- Regression compatibility: 25 Python tests, 3 Lua tests, Ruff, StyLua,
  Actionlint, legacy 51-check validation, 27-plugin first/restart smoke, 12/12
  core audit, lock transaction, and `git diff --check` pass locally.
- Scope deviation: attached UI was pulled into `RUNTIME-003/004` through optional
  ephemeral `pynvim` because `VeryLazy` naturally requires `UIEnter`; headless
  checks do not fake that event. It remains a CI-only dependency, not local core.
- Stop gate: do not begin `RUNTIME-005` before owner evidence review.

### Assumptions And Defaults

- LazyVim retains lifecycle ownership.
- Current root-wrapper/nested-runtime layout remains supported.
- `pynvim` is full-CI-only for attached UI, not a local core requirement.
- Fast contract budget defaults to 10 minutes; platform runtime budget remains
  20 minutes per job.
- Planned core coverage is allowed only during refactor with an existing task
  owner and is forbidden at release.
- Existing local runtimepath/line-number/wrap changes belong to `RUNTIME-004`.

### Non-Goals And Out Of Scope

- Exhaustive inherited LazyVim coverage.
- Plugin additions or feature expansion.
- Visual snapshots for all terminals/fonts.
- Hosted telemetry.
- Destructive live-user tests or repair.
- WSL claims from Ubuntu evidence.
- Implementing existing Neo-tree/Git/format/Tree-sitter/theme/help migrations
  inside this verification workstream.

### Rollback Note

The catalog, runner, behavior migration, and CI integration remain separate
commits. A task rollback reverts only its code and test contract. Root lock and
LazyVim JSON stay at the accepted hashes throughout this workstream.

### Status

Product intent is written to `docs/product/clarity-runtime-trust-pm.md`; the
approved architecture input is
`docs/architecture/2026-07-09-runtime-contract-verification-blueprint.md`; this
decision-complete PLAN+TASK is written to
`progress/2026-07-09-runtime-contract-verification-plan.md`. `RUNTIME-001`
through `RUNTIME-004` are complete locally and stopped at the required evidence
gate; `RUNTIME-005` remains pending.
