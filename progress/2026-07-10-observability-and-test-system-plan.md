# Clarity Observability And Command-Driven Testing PLAN+TASK

Date: 2026-07-10
Status: `OBS-001` through `OBS-007` complete locally — 2026-07-10; `OBS-008` remote evidence required
Product intent:
[`../docs/product/clarity-diagnostics-and-test-experience-pm.md`](../docs/product/clarity-diagnostics-and-test-experience-pm.md)
Approved architecture:
[`../docs/architecture/2026-07-10-observability-and-test-system-blueprint.md`](../docs/architecture/2026-07-10-observability-and-test-system-blueprint.md)
Parent refactor plan:
[`2026-07-09-clarity-95-refactor-plan.md`](2026-07-09-clarity-95-refactor-plan.md)
Runtime-contract plan:
[`2026-07-09-runtime-contract-verification-plan.md`](2026-07-09-runtime-contract-verification-plan.md)

## Summary

Repair the confirmed `<leader>cz` false-green through a typed fold action,
introduce a small privacy-safe Clarity diagnostic boundary, and make promoted
interactive behavior directly executable through one command-driven test
surface with real attached-UI input and three-platform evidence.

The execution order deliberately fixes trust before breadth. The first batch
freezes the failing contract, builds the diagnostic foundation, fixes fold
behavior, and stops for evidence review. Logging commands, unified orchestration,
hardening, CI, and legacy migration follow only after that vertical slice proves
that expected edge states and unexpected failures are distinguishable.

PM quality bar: the user reviews only whether informational copy feels calm and
useful. Automation owns deterministic fold behavior, error capture, privacy,
cleanup, platform paths, and release evidence.

## Current Reality

- Baseline commit: `a7229e1` on
  `codex/20260709-clarity-trust-foundation`.
- `<leader>cz` at `nvim/lua/config/keymaps.lua` directly executes
  `normal! za`.
- With no fold at the cursor, clean Neovim deterministically raises `E490`, which
  becomes the observed `E5108` Lua error.
- Existing validators create a manual fold and call the callback directly; they
  do not type the mapping, cover a no-fold line, or observe UI/RPC errors.
- The runtime catalog currently labels `code_fold` as `covered`; this is broader
  than the evidence and must be corrected before further runtime-matrix work.
- Clarity has audit, validation, native messages, Noice, Snacks, and native
  `nvim.log`, but no Clarity-owned schema-versioned diagnostic event stream.
- `RUNTIME-001` through `RUNTIME-004` are locally complete. `RUNTIME-005` remains
  paused until this regression and the coverage definition are resolved.
- Root `lazy-lock.json` and `lazyvim.json` remain accepted authorities and are
  out of scope for this workstream.

## Architecture Decisions

1. Clarity-owned promoted actions return typed outcomes; expected context states
   do not escape as exceptions.
2. `no_fold` and `unsupported_buffer` are handled outcomes with unchanged editor
   state and localized informational feedback.
3. Unexpected Clarity-owned failures pass through a narrow `xpcall` guard and
   emit one structured ERROR event plus one bounded repair message.
4. `config.diagnostics` is dependency-free and does not override global
   `vim.notify`, Neovim error handlers, Noice, or Snacks.
5. Schema-versioned JSONL under `stdpath("state")/clarity/events.jsonl` is the
   diagnostic source of truth; UI strings and `:messages` are supporting data.
6. Default persistence is WARN/ERROR, with a 200-event memory ring, 1 MiB active
   file, and two rotations. Writer failure falls back in memory without
   recursion.
7. Diagnostic context uses an allowlist and never records user text, clipboard,
   environment values, secrets, command arguments, or raw provider payloads.
8. Attached-UI tests type real keys through `pynvim==0.6.0`; direct callback
   tests remain lower-level evidence only.
9. `scripts/run_clarity_tests.py` is a thin router over existing owners, not a
   replacement monolith.
10. A promoted critical capability is `covered` only with success,
    expected-edge, injected-failure, and restoration evidence.

## Frontend Workstream

N/A — there is no browser frontend. The affected UI is Neovim notification,
scratch-buffer diagnostics, and attached terminal UI behavior.

## Backend/API/Data Workstream

N/A — there is no backend or application database. The only persistence is
bounded user-owned local diagnostic state; implementation is additive and never
deletes existing user files.

## Analytics, Observability, And Security Considerations

- No telemetry, network upload, hosted analytics, or crash reporting.
- Event schema version 1 requires: `seq`, UTC timestamp, session ID, level,
  stable event ID, component, action, outcome, message key, allowlisted context,
  and optional normalized error code/message/traceback.
- Persisted files use user-only permissions where the platform exposes them.
- HOME is collapsed to `~`; repository paths are relative; export applies a
  second redaction pass.
- Tests inject fixture secrets, Unicode paths, Windows separators, writer
  failure, rotation boundaries, and recursive fallback attempts.
- CI artifacts contain only copied candidates, repository fixtures, generated
  state, bounded raw streams, versions, hashes, and stable reports.

## Test And QA Plan

### Static And Unit Layer

- Ruff for Python and StyLua for Lua.
- Python unit tests for CLI routing, artifact bounds, JSONL schema, exit codes,
  platform paths, timeout, truncation, and manifest binding.
- Clean-Neovim Lua tests for typed fold outcomes, diagnostic ring/order/levels,
  redaction, rotation, guard behavior, export, and injected writer failure.
- Actionlint, JSON/JSONL parsing, Markdown links, accepted authority hashes, and
  `git diff --check`.

### Headless Contract Layer

- Natural empty/file lifecycle and ownership remain passive.
- Contract catalog rejects `code_fold=covered` until all required evidence
  classes exist.
- Fault fixtures assert exact stable failure IDs and unchanged candidate/source
  authority hashes.
- Tests always use copied candidates and isolated config/data/state/cache roots.

### Attached-UI Behavior Layer

- Send real `<leader>cz` input rather than invoking only the Lua callback.
- Capture action outcome, fold state, cursor/window/buffer/options before and
  after, `vim.v.errmsg`, message delta, RPC exceptions, and diagnostic events.
- Required cases: manual closed/open, plain no-fold, expr-ready,
  parser/provider unavailable, fold disabled, Neo-tree/help/terminal,
  injected callback exception, cleanup failure, and logger-writer failure.
- Use bounded predicates; fixed sleeps may only yield the event loop, never
  decide pass/fail.

### Artifact Contract

Each scenario emits:

```text
manifest.json
checks.json
events.jsonl
snapshot-before.json
snapshot-after.json
messages.txt
stdout.txt
stderr.txt
junit.xml
```

- Structured scenario data: at most 256 KiB.
- Each raw stream: at most 1 MiB with head/tail and truncation marker.
- Per-platform aggregate: at most 10 MiB.
- CI retention: 14 days.
- Manifest binds commit, platform, Neovim/Python/pynvim versions, scenario,
  authority hashes, and artifact schema.

### Human Review

The owner checks only:

- whether `no_fold` and `unsupported_buffer` feedback is calm and useful;
- whether `:ClarityLog` is readable at 60x16 and 80x24;
- whether the fold action feels immediate.

All deterministic findings become automated cases. No exhaustive manual
walkthrough is required.

## Tasks

### OBS-001: Freeze The Fold Failure And Coverage Contract

- Status: done — 2026-07-10; raw-fold fault reproduces exact target contract failure
- Depends on: none
- Files: `tests/contracts/runtime_contract.lua`, new or extended diagnostic/action
  contract under `tests/contracts/`, `tests/python/test_runtime_contracts.py`,
  `tests/fixtures/runtime/`, `scripts/run_clarity_contracts.py`
- Change: record the current no-fold `E490/E5108` as an expected negative
  baseline in a copied candidate; define stable fold outcomes, event/check IDs,
  required evidence classes, diagnostic schema v1, and privacy field allowlist.
  Change `code_fold` from `covered` to `planned` under this task until success,
  expected-edge, injected-failure, and restoration evidence all exist. The
  negative fixture must not mutate source or accepted authority files.
- Acceptance: the unchanged current implementation deterministically produces
  the intended no-fold failure ID; a prebuilt manual fold remains a passing
  control; schema rejects unknown context fields and missing required fields;
  coverage cannot become greener by deleting a case; lock/JSON hashes remain
  unchanged.
- Validation: Python contract unit tests; Lua catalog tests; isolated no-fold and
  manual-fold contract runs; exact expected failure-ID assertion; pre/post
  SHA-256 comparison; `git diff --check`.

### OBS-002: Implement The Dependency-Free Diagnostic Core

- Status: done — 2026-07-10; schema, ring, persistence, rotation, redaction, guard, and writer-failure tests pass
- Depends on: OBS-001
- Files: `nvim/lua/config/diagnostics.lua`,
  `tests/lua/test_diagnostics.lua`, diagnostic contract/fixtures,
  `scripts/run_clarity_lua_tests.py`
- Change: implement schema-versioned events, 200-entry in-memory ring, WARN/ERROR
  JSONL persistence, 1 MiB rotation with two retained files, allowlist
  normalization/redaction, narrow action guard, query/export primitives, and a
  non-recursive in-memory/native-message fallback. Support injected clock,
  session ID, writer, path, and size only through explicit test construction;
  normal user configuration cannot enable fault injection.
- Acceptance: event order and sequence are deterministic; INFO remains memory-
  only by default; ERROR survives restart; rotation preserves complete JSONL
  records; writer and encoder failures do not break editing or recurse; export
  contains no fixture secret, buffer text, environment value, or raw HOME path;
  no new plugin or lockfile change.
- Validation: clean-Neovim diagnostics suite; writer/encoder/rotation/redaction/
  Unicode/Windows-path fixtures; JSONL parse; permission assertion where
  supported; Ruff/StyLua; accepted authority hashes.

### OBS-003: Replace Raw Fold Execution With A Typed Action

- Status: done locally — 2026-07-10; automated acceptance passes, owner INFO-copy review is the batch gate
- Depends on: OBS-002
- Files: `nvim/lua/config/actions/fold.lua`,
  `nvim/lua/config/keymaps.lua`, `nvim/lua/config/i18n.lua`,
  `tests/lua/test_fold_action.lua`, fold fixtures and contract catalog
- Change: implement provider-neutral fold detection and return `toggled`,
  `no_fold`, `unsupported_buffer`, `degraded`, or `failed`; bind `<leader>cz` to
  the action. Expected outcomes leave state unchanged when no toggle applies and
  emit localized INFO feedback without ERROR events. Unexpected failures pass
  through the diagnostic guard and retain full structured evidence. Preserve the
  public mapping and LazyVim fold lifecycle ownership.
- Acceptance: manual closed/open and supported expr folds toggle; plain lines,
  unavailable providers, and unsupported buffers never emit `E490/E5108`; every
  outcome has English/Chinese copy parity; an injected exception yields exactly
  one ERROR event and one repair message; cursor/window/buffer/options restore;
  keymap provenance remains Clarity-owned.
- Validation: fold action Lua suite; isolated positive/no-fold/provider/
  unsupported/injected-error fixtures; legacy validation; natural runtime
  contracts; i18n parity; Ruff/StyLua; short owner copy/interaction review.

### OBS-004: Add The Clarity Log Recovery Commands

- Status: done locally — 2026-07-10; command, 60x16/80x24 view, export, idempotence, and cleanup evidence pass
- Depends on: OBS-002
- Files: `nvim/lua/config/commands.lua`, `nvim/lua/config/i18n.lua`,
  diagnostics module query/export surface, `tests/lua/test_diagnostics.lua`,
  attached-UI fixtures
- Change: register `:ClarityLog`, `:ClarityLog tail`, `:ClarityLog path`, and
  `:ClarityLog export [path]`. Default/tail open a read-only scratch buffer;
  path prints the local file; export writes a sanitized bundle and refuses an
  invalid/unwritable target with a bounded repair message. Repeated invocation
  reuses or safely replaces Clarity-owned views without disturbing user windows.
- Acceptance: completion and arguments are deterministic; views are read-only,
  localized, and usable at 60x16/80x24; export redaction is idempotent; repeated
  calls create no duplicate commands/autocmds and restore focus; writer/view
  failure does not recurse or modify user buffers.
- Validation: command Lua tests; isolated attached-UI command scenarios;
  before/after session equality; export parsing/redaction fixtures; short owner
  readability review.

### OBS-005: Make Attached UI Prove Real Fold Input And Error Channels

- Status: done locally — 2026-07-10; real `Space c z` input and error-channel evidence pass
- Depends on: OBS-003
- Files: `scripts/run_clarity_contracts.py`, `tests/lua/runtime_probe.lua`,
  `tests/python/test_runtime_contracts.py`, `tests/fixtures/runtime/`
- Change: extend the attached-UI driver to send real `<leader>cz` input through
  Neovim rather than treating direct callback invocation as user evidence.
  Record typed outcome, fold state, `vim.v.errmsg`, messages delta, RPC errors,
  diagnostic event IDs, and complete before/after state. Add bounded readiness
  predicates for keymaps, provider state, and UI attachment.
- Acceptance: every required fold case reports a stable scenario/case/check ID;
  no-fold passes with no error channel; injected callback failure fails exactly
  the intended check; callback-only evidence cannot satisfy real-input
  coverage; timeouts contain bounded command/log context; cleanup succeeds after
  both pass and failure.
- Validation: Python driver tests; attached UI at 60x16 and 80x24 using
  `pynvim==0.6.0`; deliberate timeout/RPC/failure fixtures; repeat each core case
  twice and compare normalized output.

### OBS-006: Add The Unified Test Router And Artifact Contract

- Status: done locally — 2026-07-10; fast/contracts/behavior/faults/release routing and bounded artifacts pass
- Depends on: OBS-001, OBS-002
- Files: `scripts/run_clarity_tests.py`, `scripts/clarity_runtime.py`,
  `tests/python/test_clarity_tests.py`, artifact schema/fixtures,
  `.gitignore` only if the CI/temp artifact path is not already excluded
- Change: implement the thin `fast`, `contracts`, `behavior`, `faults`, and
  `release` router with `--json`, `--artifact-dir`, `--feature`, and
  `--scenario`. Compose existing runners through stable subprocess/result
  adapters; do not copy their test logic. Emit the specified manifest, checks,
  events, snapshots, bounded raw streams, and JUnit. Reject unknown suites,
  features, scenarios, malformed child output, and artifact overflow with stable
  exit semantics.
- Acceptance: each suite routes only to its declared owners; `--json` keeps
  stdout machine-readable; stderr/log truncation is explicit; artifacts bind the
  exact commit/platform/tool versions/hashes; one child failure cannot be hidden
  by later passes; paths work with spaces, Unicode, Windows separators, and
  isolated roots.
- Validation: Python unit suite; fake child pass/fail/timeout/malformed/oversize
  fixtures; run every router suite locally where supported; parse JSON, JSONL,
  and JUnit; verify no tracked artifact output.

### OBS-007: Complete Fault, Privacy, And Restoration Hardening

- Status: done locally — 2026-07-10; full fold outcome, writer, path, secret, lifecycle, and restoration matrix passes
- Depends on: OBS-004, OBS-005, OBS-006
- Files: diagnostic/fold/runtime fixtures, Lua and Python tests, contract catalog,
  legacy-to-new check map under `tests/contracts/`
- Change: complete manual-open/closed, plain no-fold, expr-ready, missing parser/
  provider, fold disabled, Neo-tree/help/terminal, callback throw, cleanup
  failure, duplicate lifecycle, writer failure, Unicode/Windows path, and secret
  redaction cases. Give every injected failure one expected stable ID. Require
  success, expected-edge, failure-detection, and restoration evidence before
  returning `code_fold` to `covered`.
- Acceptance: every fault turns only its intended required check red or lists a
  documented causal cascade; unchanged candidate passes; no secret/HOME/buffer
  text appears in persisted or CI artifacts; diagnostics/actions remain
  idempotent; deleting a fixture or check cannot increase coverage; repeated
  normalized artifacts are deterministic.
- Validation: `run_clarity_tests.py faults --feature fold`; full Lua/Python
  suites; mutation/coverage guard twice; secret scan over artifacts; complete
  before/after equality; accepted authority hashes.

### OBS-008: Integrate The Test Surface Into Required CI

- Status: in progress — 2026-07-10; workflow integration and Actionlint pass locally, remote matrix pending
- Depends on: OBS-007
- Files: `.github/workflows/clarity-validate.yml`, CI helper/tests, artifact
  upload configuration
- Change: run fast/contracts/full faults in the Linux PR tier; run core attached-
  UI fold/error behavior and release evidence on Ubuntu 24.04, Windows 2022, and
  macOS 14 with pinned `pynvim==0.6.0`. Preserve official checksummed Neovim,
  immutable action SHAs, least privilege, concurrency cancellation, platform-
  native isolated roots, and existing hard timeouts. Upload bounded artifacts on
  success and failure with 14-day retention.
- Acceptance: Actionlint passes; every platform reaches real-input behavior;
  artifacts bind exact commit and accepted hashes; Windows paths need no
  hard-coded install directory; no Ubuntu result is labeled WSL; failure still
  uploads bounded evidence; each runtime job remains within 20 minutes.
- Validation: Actionlint and workflow helper tests; manual dispatch or PR-bound
  three-platform run; download and schema/hash/commit-verify each artifact. This
  task remains incomplete until remote matrix evidence exists.

### OBS-009: Migrate Legacy Fold Checks And Close The Workstream

- Status: pending
- Depends on: OBS-008
- Files: `scripts/run_clarity_validate.py`, runtime/test contract catalog,
  `README.md`, `doc/clarity_lazyvim_complete_guide_zh.md`,
  `docs/ai/current-reality.md`, `docs/DOCUMENT_INDEX.md`,
  `docs/decisions/`, parent/runtime PLAN+TASK files, dated closeout
- Change: remove or map the duplicated callback-only fold fixture after new
  positive/negative parity; retain stable public validation IDs or publish an
  explicit old-to-new mapping. Document `:ClarityLog` and the unified commands;
  write the approved diagnostics, real-input evidence, and test-router ADRs;
  update current state and parent plan pointers; record remote evidence and
  known limits without claiming WSL or release readiness beyond artifacts.
- Acceptance: no duplicate authority for fold behavior; public docs match actual
  commands and privacy behavior; AI-facing docs point to the active plan and
  evidence; ADRs contain adopted decisions/revisit triggers; all local and
  remote required gates pass; `RUNTIME-005` may resume only after this closeout
  or an explicit owner-approved overlap decision.
- Validation: full `run_clarity_tests.py release`; legacy audit/validation and
  smoke; documentation link/path checks; Markdown diff review; `git diff
  --check`; verify task/evidence status against downloaded platform artifacts.

## Migration Order

1. Contract and proof baseline: `OBS-001`.
2. Diagnostic foundation: `OBS-002`.
3. First vertical slice and bug repair: `OBS-003`.
4. Stop for owner evidence review before expanding the workstream.
5. Recovery UI and real-input evidence: `OBS-004` and `OBS-005` may proceed in
   parallel after their dependencies because their primary files are disjoint.
6. Unified orchestration: `OBS-006` may proceed after the diagnostic contract is
   stable; merge sequencing must serialize overlap in Python helpers.
7. Hardening: `OBS-007`.
8. Required remote CI: `OBS-008`.
9. Legacy migration and durable closeout: `OBS-009`.
10. Resume `RUNTIME-005` only after the observability/test evidence gate, unless
    the owner explicitly approves a non-overlapping runtime-matrix task.

The first approved execution batch is `OBS-001` through `OBS-003` and stops at
its evidence gate. Each task must leave the repository runnable and independently
reviewable.

## Rollout, Compatibility, And Rollback Notes

- Preserve `<leader>cz`, all existing public commands, and LazyVim lifecycle
  ownership.
- Keep old and new fold checks together only until negative-control parity; do
  not maintain two permanent behavior authorities.
- Diagnostic state is additive. Never delete, migrate destructively, or use real
  user logs as a test fixture.
- `CLARITY_LOG_LEVEL=off` disables persistence while keeping the in-memory error
  ring; it is a rollback switch, not a way to make required tests green.
- Revert individual task commits in reverse dependency order. Reverting the fold
  action also restores its matching catalog status and test expectation.
- Keep `lazy-lock.json` and `lazyvim.json` at their accepted hashes throughout.
- Roll back immediately on recursive errors, editing blocked by log I/O, privacy
  leakage, user-state mutation, false green against injected `E490`, incomplete
  cleanup, nondeterministic artifacts, or required platform failure.
- Release rollback uses the prior green commit and matching artifacts; no local
  audit alone certifies release quality.

## Handoff

### First Batch Evidence — 2026-07-10

- Confirmed baseline: raw `normal! za` on a no-fold line produces `E490`, exposed
  through the mapping as `E5108`. The isolated `raw_fold_action` fault returns
  exactly `CLARITY_RUNTIME_KEYMAP_CONTRACT` and no unrelated failure ID.
- Positive attached UI: manual fold open/close returns `toggled`; a no-fold line
  returns `no_fold`; `pcall` succeeds; `vim.v.errmsg` remains empty.
- Diagnostic core: schema v1, privacy allowlist, 200-event bounded ring,
  WARN/ERROR JSONL, 1 MiB/two-file rotation, HOME normalization, writer failure,
  and non-recursive guarded error tests pass.
- Fold action: `toggled`, `no_fold`, `unsupported_buffer`, `degraded`, and
  `failed` paths have unit evidence. Expected states do not emit an ERROR;
  injected toggle failure returns `failed` with the stable failure event.
- Catalog: 12 config/action modules classified, zero missing/unclassified.
  `code_fold` is deliberately `planned` under `OBS-007`; it will not return to
  `covered` before real-input, full fault, privacy, and restoration evidence.
- Regression: 26 Python tests, 6 Lua policy tests, Ruff, StyLua, Actionlint,
  51-check legacy validation, three natural contract scenarios, 27-plugin
  first/restart smoke, 12/12 core audit, Markdown links, and `git diff --check`
  pass locally.
- Authority files are unchanged at lock
  `79e5323b3074c5f6434a708a7c209c84f41b1bcb97541af512bfb069929b710a`
  and JSON
  `3911b0251e3c51aa127f937aa5de323dba1eb6227636549264bde36e1674ad02`.
- First-gate dependency warning: check-only normalization reported
  `nvim-lspconfig` drift (`d224a192` → `d6ac7a0d`). The first batch did not apply
  it; the owner-approved atomic resolution is recorded in the second batch.
- First stop gate: satisfied by owner approval before `OBS-004` and the separate
  dependency transaction began.

### Second Batch Evidence — 2026-07-10

- Dependency transaction: the `nvim-lspconfig` candidate drift was backed up and
  atomically applied; check-only revalidation is clean at lock hash
  `af8ad1dff2b125573e19a37c3a30af25a152450d2b9b1d0320ee78fd35db04d7`;
  first boot and restart both resolve 27 plugins with core audit ready.
- Recovery UI: `:ClarityLog`, `tail`, `path`, and sanitized `export` exist;
  repeated setup is idempotent; attached 60x16 and 80x24 views are readable,
  read-only, tail correctly, and restore the prior buffer.
- Real input: attached UI sends `Space c z`. Manual open/close produces
  `toggled`; a plain line produces `CLARITY_FOLD_NO_FOLD`; there is no RPC error,
  `vim.v.errmsg`, or cleanup drift.
- Unified router: `fast`, `behavior --feature fold`, `faults --feature fold`, and
  local `release` pass. Artifacts include manifest, checks, JSONL events,
  before/after snapshots, bounded stdout/stderr/messages, and JUnit.
- Hardening: expression fold, missing/invalid provider, fold no-op, nofile/help/
  terminal, partial toggle failure restoration, duplicate setup, writer failure,
  rotation, HOME/explicit-secret redaction, and Unicode/Windows path cases pass.
- Coverage: all 13 config/action modules are classified; `code_fold` returns to
  `covered` only after success, expected-edge, injected-failure, restoration,
  and real-input evidence.
- Local release report passes seven child gates: Python, Lua, natural contracts,
  raw-fold fault, legacy validation, smoke, and audit. Ruff, StyLua, Actionlint,
  docs links, and diff checks also pass.
- CI: the pinned matrix now runs fast Linux evidence plus headless contracts,
  real-input fold behavior, and fold fault controls on Ubuntu, Windows, and
  macOS, uploading 14-day artifacts on success or failure. `OBS-008` remains in
  progress until exact commit-bound remote jobs are green.
- Platform note: Ubuntu CI evidence is currently actionable. A GitHub-hosted
  Windows job does not replace the planned real remote Windows/server check;
  that environment stays explicitly pending until owner-provided root access is
  available.
- Stop gate: do not mark `OBS-008` done or begin final `OBS-009` ADR/legacy
  closeout without remote matrix evidence.

- Assumptions/defaults: INFO feedback for `no_fold`; WARN persistence threshold;
  200 memory records; 1 MiB active file plus two rotations; 14-day CI retention;
  `pynvim==0.6.0` only for behavior/release tiers; no new Lua test framework
  until case complexity materially exceeds the current harness.
- Non-goals: global error interception, telemetry, new plugins, exhaustive
  upstream testing, screenshot-text assertions, terminal automation beyond
  embedded UI, destructive user-state tests, or WSL claims from Ubuntu.
- Rollback note: each OBS task is a separate review unit; restore code, contract,
  and coverage status together. Never normalize or replace authority files as a
  side effect of test execution.
- Status line: product intent written to
  `docs/product/clarity-diagnostics-and-test-experience-pm.md`; implementation
  plan written to
  `progress/2026-07-10-observability-and-test-system-plan.md`; `OBS-001` through
  `OBS-001` through `OBS-007` are complete locally. `OBS-008` is locally
  integrated but awaits remote evidence; `OBS-009` remains pending.
