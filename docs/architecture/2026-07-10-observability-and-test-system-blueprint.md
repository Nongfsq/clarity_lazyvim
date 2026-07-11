# Architecture Blueprint: Clarity Observability And Command-Driven Testing

Date: 2026-07-10

Status: historical approved blueprint; local implementation followed; current
truth is in `docs/ai/current-reality.md` and the active PLAN+TASK

## Summary

- Product goal: make every promoted Clarity action calm in normal edge states,
  diagnosable when it truly fails, and directly verifiable through one bounded
  command surface without asking the owner to manually retest the editor.
- Architecture type: existing-system module and validation-platform refactor.
- Selected stack: dependency-free Lua action/diagnostic modules, Neovim native
  APIs, bounded JSONL under `stdpath("state")`, Python standard-library test
  orchestration, optional pinned `pynvim==0.6.0` for attached-UI input, and the
  existing GitHub Actions matrix.
- Primary constraints: LazyVim retains lifecycle ownership; Noice/Snacks remain
  presentation layers; user config/data/state/cache is never deleted or
  overwritten; tests use copied candidates and isolated roots; Windows, WSL,
  Linux, and macOS paths must be portable; no hosted telemetry.
- Confirmed defect: `<leader>cz` calls `normal! za` unconditionally. On a line
  with no fold, Neovim raises `E490`, which escapes the Lua callback as the
  screenshot's `E5108` at `vim/_core/editor:355`. Existing tests manufacture a
  manual fold first, so they prove only the success branch.
- Non-goals: intercepting every plugin error, replacing `:messages`, replacing
  Noice, collecting buffer contents or secrets, adding a logging service,
  exhaustive upstream LazyVim testing, or growing the monolithic validator.

## Decisions

- Runtime/action boundary: move promoted interactive behavior behind small Lua
  actions returning typed outcomes such as `toggled`, `no_fold`,
  `unsupported_buffer`, `degraded`, and `failed`. Why: expected edge states must
  not become Lua exceptions, and tests need stable results independent of UI
  copy. Rejected: wrapping every mapping in a broad `pcall` (hides defects) and
  leaving raw Ex commands in keymaps (no contract boundary). Revisit when:
  Neovim exposes a stable typed action API that covers these cases.
- Fold UX contract: `no_fold` and `unsupported_buffer` are handled outcomes, not
  errors; they leave editor state unchanged and produce one concise localized
  informational message. Why: silence is ambiguous for GUI-editor migrants,
  while an error popup is disproportionate. Rejected: silent no-op (unclear) and
  error notification (normal state presented as failure). Revisit when: owner
  usability review shows the informational message is noisier than useful.
- Diagnostics runtime: add one dependency-free Clarity diagnostics module with
  an in-memory ring buffer and guarded JSONL append. Why: it loads before lazy
  plugins, remains available when providers fail, and is directly testable.
  Rejected: `plenary.log` (transitive/lazy dependency and lifecycle coupling),
  Noice history (in-memory presentation state), native `nvim.log` alone
  (low-level mixed stream with no Clarity event contract), and a new logging
  plugin (unnecessary surface). Revisit when: event volume, concurrency, or a
  stable upstream structured logging API exceeds the small module's scope.
- Persistence: write structured events to
  `stdpath("state")/clarity/events.jsonl`; keep at most 200 records in memory,
  rotate at startup or before append when the active file exceeds 1 MiB, and
  retain two rotated files. Persist WARN/ERROR and explicitly marked diagnostic
  spans by default; DEBUG/INFO persistence is opt-in through an environment or
  test option. Why: errors survive UI truncation and restart without meaningful
  startup or disk cost. Rejected: per-keypress logging (noise/privacy/perf) and
  shutdown-only flush (loses crash evidence). Revisit when: real evidence shows
  3 MiB is insufficient or synchronous error append affects interaction.
- Event contract: schema-versioned JSONL is the source of truth. Every record
  contains monotonically increasing `seq`, UTC timestamp, session ID, level,
  stable event ID, component, action, outcome, message key, safe structured
  context, and optional normalized error code/message/traceback. Python reads
  this contract; UI strings and `:messages` are supporting evidence only.
  Rejected: parsing localized notification text and mirrored Lua/Python event
  definitions. Revisit when: a generated schema becomes worthwhile after a
  second non-Python consumer appears.
- Error guarding: only Clarity-owned entrypoints use a narrow `xpcall` guard.
  Expected outcomes return normally; unexpected failures are logged with a
  traceback, mapped to a stable public repair message, and never recursively
  call the failing logger. Why: preserve evidence while keeping user-facing
  output calm. Rejected: overriding `vim.notify`, `vim._on_error`, or global
  handlers (captures upstream traffic and risks recursion). Revisit when:
  Neovim provides a supported scoped error hook with provenance.
- Privacy/security: allowlist context fields; never record buffer text,
  clipboard contents, environment values, command arguments, tokens, or raw
  provider payloads. Normalize repository paths relative to the root, collapse
  HOME to `~`, and redact absolute paths again during export. Create directories
  and files with user-only permissions where supported. Rejected: denylist-only
  redaction (unknown fields leak) and opaque binary logs (hard to inspect).
  Revisit when: enterprise compliance or multi-user hosts enter product scope.
- User access: provide `:ClarityLog`, `:ClarityLog tail`, `:ClarityLog path`, and
  `:ClarityLog export [path]`; default view opens a read-only scratch buffer and
  export writes a sanitized diagnostic bundle. Why: one obvious recovery path
  is more useful than asking users to find Noice/native files. Rejected: shell-
  only access and a permanent dashboard. Revisit when: help usability research
  supports a dedicated diagnostics panel.
- Testing: use a layered pyramid—pure Lua action/diagnostic tests, natural
  headless contracts, attached-UI real-input behavior, deterministic fault
  fixtures, and three-platform release evidence. Why: cheap tests isolate
  policy while real UI proves user input and error channels. Rejected: E2E-only
  (slow/flaky), callback-only UI tests (not user behavior), and screenshot text
  as the assertion source (truncation/localization instability). Revisit when:
  embedded UI cannot reproduce a terminal-specific defect.
- Test command surface: add a thin `scripts/run_clarity_tests.py` router with
  `fast`, `contracts`, `behavior`, `faults`, and `release` suites plus `--json`,
  `--artifact-dir`, `--feature`, and `--scenario`. It composes existing runners;
  it does not absorb their logic. Why: agents and humans get stable commands
  while modules retain ownership. Rejected: another shell/Make dependency and
  further expansion of `run_clarity_validate.py`. Revisit when: repository-wide
  build tooling is adopted for other reasons.
- CI/CD and distribution: Linux PR jobs run fast, contracts, and full faults;
  all three supported OS jobs run core attached-UI behavior and release suites.
  Machine-readable artifacts bind commit, platform, tool versions, authority
  hashes, checks, events, before/after snapshots, bounded raw output, and JUnit.
  Rejected: claiming coverage from macOS local evidence or uploading only raw
  console logs. Revisit when: matrix duration exceeds the agreed budget.
- Documentation: this blueprint is the architecture source; an ADR for the
  diagnostics/event contract is written only after implementation approval.
  Public docs expose recovery commands, not internal stack detail. Rejected:
  putting volatile event schemas in `AGENTS.md`. Revisit when: the contract or
  canonical pointers change.

## System Shape

- Runtime surfaces:
  - keymaps and commands call Clarity actions;
  - actions return typed outcomes and use diagnostics only for breadcrumbs or
    unexpected failures;
  - the diagnostics module retains a bounded ring, persists selected JSONL, and
    renders/exports through explicit commands;
  - Noice/Snacks/`vim.notify` render concise user messages but do not own truth.
- Module boundaries:
  - `config.actions.fold`: fold state detection and toggle outcome;
  - `config.diagnostics`: event schema, ring, append, rotation, redaction,
    guard, query, and export primitives;
  - `config.commands`: user command registration remains the command owner;
  - `config.keymaps`: declarative binding only, with no raw fold implementation;
  - test-owned Lua helpers exercise action and diagnostics contracts;
  - Python orchestration owns copied candidates, isolated roots, UI transport,
    artifacts, timeouts, and cross-platform evaluation.
- Data flow: user input → mapping → typed action → outcome; expected outcome →
  localized presentation and optional breadcrumb; unexpected exception → guard
  → structured event append → concise repair notification. Test runners read
  event JSONL plus before/after runtime snapshots and evaluate stable check IDs.
- External integrations: optional `pynvim==0.6.0` only in attached-UI/full CI;
  GitHub Actions stores artifacts. No network service or telemetry endpoint.
- Background jobs/events: no daemon. Rotation happens at bounded initialization
  or append boundaries; export is explicit. Scheduled flush is unnecessary.

## Scaffold Plan

- `nvim/lua/config/diagnostics.lua`: dependency-free schema, safe encoder,
  ring, persistence, rotation, redaction, guard, query, and export. Validate
  with clean-Neovim Lua tests and injected writer/rotation failures.
- `nvim/lua/config/actions/fold.lua`: typed fold action and provider-neutral
  state checks. Validate with manual, absent, expr-ready, missing-parser,
  disabled, and unsupported-buffer cases.
- `nvim/lua/config/keymaps.lua`: map `<leader>cz` to the fold action only.
  Validate mapping provenance plus real `nvim_input()` behavior.
- `nvim/lua/config/commands.lua`: register the `:ClarityLog` command family.
  Validate completion, read-only view, sanitized export, and failure fallback.
- `nvim/lua/config/i18n.lua`: message keys for handled fold outcomes and log
  recovery. Validate English/Chinese parity without using copy as event IDs.
- `tests/contracts/diagnostic_event.lua`: test-owned schema assertions and
  stable event/check IDs. Validate drift against emitted fixtures.
- `tests/lua/test_diagnostics.lua`: ring, levels, encoding, ordering, rotation,
  permissions where observable, redaction, recursion guard, and writer failure.
- `tests/lua/test_fold_action.lua`: typed outcome unit/component matrix.
- `tests/fixtures/runtime/`: plain line, manual folds, real syntax folds,
  unavailable provider, unsupported buffers, thrown callback, cleanup failure,
  writer failure, Unicode/space/Windows paths, and secret-redaction fixtures.
- `tests/python/test_clarity_tests.py`: command routing, budgets, schema,
  artifact truncation, exit codes, and platform path tests.
- `scripts/run_clarity_tests.py`: thin stable suite router. Validate each suite
  in `--json` mode and reject unknown feature/scenario names.
- `scripts/run_clarity_contracts.py`: extend attached UI to send real keys and
  capture event/message/error deltas plus complete restoration; do not duplicate
  action policy.
- `.github/workflows/clarity-validate.yml`: add fast/contracts/faults and pinned
  attached-UI invocation with artifact upload. Validate with Actionlint and a
  real workflow-dispatch matrix.
- `artifacts/clarity-tests/` (CI/temp only, Git-ignored): `manifest.json`,
  `checks.json`, `events.jsonl`, `snapshot-before.json`,
  `snapshot-after.json`, `messages.txt`, `stdout.txt`, `stderr.txt`, and
  `junit.xml`. Limit structured scenario output to 256 KiB, each raw stream to
  1 MiB with a truncation marker, and each platform aggregate to 10 MiB.

## Migration and Rollout

- Current state → target state: retain current commands and validators while
  introducing typed fold behavior, structured diagnostics, and one test router;
  then migrate duplicated fold assertions out of the legacy validator only
  after negative-control parity.
- Stage 1 — contract freeze: document current `<leader>cz` success and no-fold
  failure, stable outcome/event/check IDs, privacy allowlist, artifact schema,
  and runner exit semantics. Gate: schema tests reject missing/extra unsafe data.
- Stage 2 — first vertical slice: implement diagnostics plus the fold action;
  reproduce `E490/E5108` with the old action and prove `no_fold` is handled with
  the new action. Gate: unit, headless, attached real-input, and logger-writer
  fault cases pass without editor-state drift.
- Stage 3 — command and artifact surface: add `:ClarityLog` and the test router,
  emit bounded artifacts, and prove redaction/rotation/export. Gate: one command
  reproduces and diagnoses a sentinel callback error in an isolated candidate.
- Stage 4 — CI adoption: run fast/contracts/faults on Linux and core attached UI
  across Ubuntu, Windows, and macOS. Gate: commit-bound artifacts and exact
  accepted authority hashes.
- Stage 5 — migration: remove duplicated callback-only fold checks from the
  monolithic validator and restore `code_fold=covered` only when success,
  expected-edge, fault detection, and cleanup branches are all required.
- Compatibility window: public `<leader>cz`, existing Clarity commands, and
  stable validation IDs remain available. The legacy fold check and new check
  coexist for one implementation batch, then the old check is explicitly mapped
  or retired.
- Data migration: no application data. Existing user logs, if any, are never
  deleted; the new directory is additive. Schema changes create a new event
  version and readers accept the immediately previous version for one release.
- Rollback: each stage is independently reviewable. Revert action/keymap first,
  disable new persistence through a documented flag if writer behavior is
  implicated, retain legacy validation, and never use user-state deletion as
  rollback.
- Kill switches: `CLARITY_LOG_LEVEL=off` disables persistence but retains the
  in-memory error ring; test-only writer injection cannot be enabled from normal
  user configuration.
- Rollback signals: recursive error notification, startup regression, write
  failure affecting editing, secret/path leakage, state mutation after a failed
  action, false green against injected `E490`, nondeterministic artifacts, or CI
  budget overrun.

## Implementation Sequence

- Foundation: event/outcome contracts, privacy allowlist, diagnostics module,
  pure Lua tests, artifact schema, and stable runner exit semantics.
- First vertical slice: real `<leader>cz` input on an existing fold, no fold,
  unsupported buffer, and injected exception, with exact event and restoration
  assertions. This exercises the riskiest decision: distinguishing expected
  editor state from a true action failure without swallowing evidence.
- Hardening: rotation/redaction/writer failure, command UX, Unicode and Windows
  paths, parser/provider degradation, cleanup failure, duplicate lifecycle, raw
  output bounds, and legacy-check mapping.
- Launch gates: all local tiers green; each promoted critical behavior has a
  failing negative control; no uncaught UI error; no authority drift; remote
  Ubuntu/Windows/macOS attached-UI artifacts green for the exact commit.

## Verification

- Unit/component tests: action outcome matrix; diagnostics schema, ring,
  ordering, level filtering, guard, recursion fallback, redaction, rotation,
  export, and injected I/O failure.
- API/contract tests: event schema and stable IDs; action outcome schema; runner
  CLI/JSON/exit-code contract; coverage cannot be `covered` without success,
  expected-edge, injected-failure, and restoration evidence.
- Integration/E2E tests: copied candidate with isolated roots; natural file
  startup; real attached `nvim_input()` for `<leader>cz`; manual closed/open,
  plain no-fold, expr-ready, parser missing, fold disabled, Neo-tree/help/
  terminal, callback throw, cleanup failure, and logger writer failure.
- Build/type/lint checks: Ruff, StyLua, Python unit tests, Lua tests, Actionlint,
  JSON/JSONL parsing, Markdown link checks, authority hashes, and
  `git diff --check`.
- Deployment smoke: N/A — Clarity is distributed as a Git checkout. Release
  verification is clean-candidate first boot plus offline restart and attached
  UI on the supported platform matrix.
- Observability checks: every injected unexpected failure yields exactly one
  structured event and one bounded repair message; expected `no_fold` yields no
  ERROR event; writer failure uses a non-recursive in-memory/native-message
  fallback; export contains no fixture secret or unredacted HOME path.
- Command targets after implementation:
  - `python3 scripts/run_clarity_tests.py fast`
  - `python3 scripts/run_clarity_tests.py contracts --json`
  - `uv run --with pynvim==0.6.0 python scripts/run_clarity_tests.py behavior --feature fold`
  - `python3 scripts/run_clarity_tests.py faults --feature fold`
  - `python3 scripts/run_clarity_tests.py release --artifact-dir <dir>`

## ADRs to Write

- ADR: Clarity structured diagnostic boundary. Context/decision: typed
  Clarity-owned actions emit schema-versioned events to a bounded in-memory ring
  and state-directory JSONL while Noice/native messages remain presentation.
  Rejected: global notification interception, native log alone, Noice history,
  Plenary logging, and a new plugin. Revisit when: upstream structured logging
  supplies equivalent provenance, redaction, and persistence.
- ADR: Real-input behavior evidence. Context/decision: promoted interactive
  actions require typed outcomes plus attached-UI real-input success, expected
  edge, negative-control, and restoration evidence before `covered`. Rejected:
  callback-only happy paths and screenshot/message-text assertions. Revisit
  when: Neovim provides a stable headless input/UI error contract equivalent to
  attached UI.
- ADR: Unified test command router. Context/decision: one thin Python CLI
  composes existing owners and emits bounded artifacts without becoming another
  monolith. Rejected: expanding the legacy validator and adding a build-tool
  dependency. Revisit when: repository tooling standardizes on another task
  runner.

## Risks And Assumptions

- Risks: a custom logger can itself fail or recurse; overly broad context can
  leak user data; synchronous writes can add latency; real-input UI tests can be
  timing-sensitive; duplicate legacy/new checks can temporarily confuse owners;
  typed actions can become an unnecessary framework if applied indiscriminately.
- Mitigations: dependency-free narrow module, allowlist-only context, strict
  size/rotation limits, injected writer failures, bounded predicates instead of
  sleeps, stable check mapping, and use the action abstraction only for promoted
  workflows with meaningful edge states.
- Assumptions: single-user local editor; low event volume; local state is
  writable in normal installations; Neovim 0.12.4 and LazyVim remain the current
  baseline; `pynvim` remains CI/full-tier optional; the desired no-fold UX is a
  concise informational message with no error severity.
- Revisit triggers: measured action latency regression; logs exceed bounds;
  privacy requirements expand; event consumers exceed Lua/Python; Neovim adds
  scoped structured error hooks; embedded UI proves unreliable on a supported
  platform; Lua behavior cases exceed roughly 40–50 and need a test framework.

## Handoff

- Assumptions with stated defaults: persistence level defaults to WARN;
  in-memory capacity 200; active file 1 MiB plus two rotations; export redacts
  HOME/absolute paths; no-fold returns `no_fold` and a localized INFO message;
  `pynvim==0.6.0` is pinned only for behavior/release suites; artifacts retain
  14 days in CI.
- Open questions: zero blocking. Non-blocking: exact command aliases (default:
  the `:ClarityLog` family above); whether INFO no-fold feedback should later
  become silent (default: keep until owner UX evidence says otherwise).
- Non-goals: global plugin exception capture, telemetry, cloud logging,
  per-keystroke traces, buffer-content collection, new logging/test plugins,
  terminal screenshot baselines, or implementation during this gate.
- Status line: blueprint written to
  `docs/architecture/2026-07-10-observability-and-test-system-blueprint.md`;
  diagnostics, typed action, test command, artifact, privacy, rollout, and CI
  decisions await approval. Recommended next step: approve this blueprint, then
  use PM planning to write the product PM and dependency-ordered PLAN+TASK before
  changing runtime or test code.
