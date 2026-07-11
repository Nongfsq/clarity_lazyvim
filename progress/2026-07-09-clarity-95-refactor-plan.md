# Clarity LazyVim 95+ Refactor PLAN+TASK

Date: 2026-07-09
Status: runtime-contract first batch complete locally; evidence review pending
Architecture:
[`../docs/architecture/2026-07-09-clarity-95-refactor-blueprint.md`](../docs/architecture/2026-07-09-clarity-95-refactor-blueprint.md)
Runtime verification architecture:
[`../docs/architecture/2026-07-09-runtime-contract-verification-blueprint.md`](../docs/architecture/2026-07-09-runtime-contract-verification-blueprint.md)
Runtime verification PLAN+TASK:
[`2026-07-09-runtime-contract-verification-plan.md`](2026-07-09-runtime-contract-verification-plan.md)
Product intent:
[`../docs/product/clarity-95-experience-pm.md`](../docs/product/clarity-95-experience-pm.md)
Evidence baseline:
[`../docs/reviews/2026-07-09-clarity-95-quality-review.md`](../docs/reviews/2026-07-09-clarity-95-quality-review.md)

> **Historical / superseded:** this document records the state and decisions at
> the stated date or commit. It is not current runtime, dependency, release,
> CI, or task-status authority. Use
> [`../docs/ai/current-reality.md`](../docs/ai/current-reality.md) and the active
> PLAN+TASK linked there.

## Summary

Refactor Clarity into a thin, reproducible, UX-first product layer over LazyVim.
The work begins with trustworthy configuration and verification, proves the new
ownership rule through Neo-tree, repairs core runtime behavior, then closes the
first-run/accessibility/platform and release experience.

Target outcome: an evidence-backed score of at least 95/100 with no open P0/P1,
not a revised self-scoring formula.

### Execution Rules

- Preserve the accepted root `lazy-lock.json` and `lazyvim.json` hashes; runtime
  contract work must not change either authority file.
- Do not stage, clean, overwrite, or normalize unrelated user files.
- Keep the repository buildable after every task.
- Do not combine a plugin lock update with unrelated behavior work.
- Update task status in this file as `pending`, `in progress`, `done`, or
  `blocked`, with a date and evidence link/command.
- A failed required gate blocks subsequent release phases; it must not be
  reclassified as optional merely to make CI green.

## Current Reality

- Local branch is `codex/20260709-clarity-trust-foundation` at committed baseline
  `6e6112a`, with the runtime-contract planning and line-number repair still
  local/uncommitted.
- Root lock/JSON authority, honest readiness signals, and the local CI toolchain
  are implemented; remote Ubuntu/Windows/macOS evidence is still absent.
- Real file startup exposed a false-green validation gap: Clarity options did not
  load naturally, while validation replayed `VeryLazy` and later passed.
- Audit/validation still replay lifecycle events and can alter the state they
  inspect; the new runtime-contract plan owns the passive replacement foundation.
- Neo-tree, Mason, Conform, Gitsigns, Tree-sitter, validation, and colorscheme
  ownership have validated defects or migration risks.
- Core local headless startup is fast; optimization work must be driven by
  measured user journeys, not an arbitrary lower startup number.

## Architecture Decisions

1. LazyVim remains the runtime foundation and retains upstream plugin lifecycle
   ownership.
2. Root `init.lua`, `lazy-lock.json`, and `lazyvim.json` become the sole tracked
   runtime contract.
3. Clarity config extends upstream opts and handlers; it does not copy complete
   `setup()` lifecycles unless a tested exception is documented.
4. Host capability, feature readiness, and release quality are separate signals.
5. Interactive diagnostic commands must be repeatable and non-destructive.
6. Tests use isolated config/data/state/cache roots and a clean archive.
7. Tree-sitter configuration and its lockfile generation move atomically.
8. The minimum lovable product promotes one path per core job; optional power
   features do not define core readiness.
9. Release claims require commit-bound platform artifacts and tested rollback.

## Frontend Workstream

N/A — this repository has no browser frontend. Neovim floating UI, keymaps,
colors, and localized messages are covered by the UX, i18n, and theme tasks.

## Backend/API/Data Workstream

N/A — there is no backend service, public API, database, or application data
migration. Local Neovim state is treated as user-owned data and must be
backup-first and non-destructive.

## Analytics, Observability, And Security Considerations

- No hosted analytics or telemetry will be added.
- Verification emits stable check IDs, machine-readable JSON/JUnit where useful,
  bounded logs, exact versions, and lock/config hashes.
- CI uses least-privilege permissions and pinned supported tool artifacts.
- Plugin and tool dependency changes remain visible in lock/manifests.
- No task may print secrets or upload user config/state; CI fixtures contain only
  repository and generated test data.
- Offline restart is a supply-chain/reproducibility gate.

## Migration Order

1. Trust foundation: `NVIM-002`, `QA-001`, `VALIDATE-002`.
2. Runtime-contract hardening: `RUNTIME-001` through `RUNTIME-008`, with
   `VALIDATE-003` integrated after the passive runner exists.
3. Close the trust gate: `CI-002` remote Ubuntu/Windows/macOS evidence.
4. First ownership slice: `NVIM-003`.
5. Runtime correctness: `NVIM-004`, `NVIM-005`, `NVIM-006`,
   `THEME-001`.
6. Compatibility: `NVIM-007`.
7. Experience: `UX-001`, `UX-002`, `I18N-002`, `UX-003`.
8. Release and truth closeout: `RELEASE-001`, `QA-002`, `DOCS-002`.

Tasks inside a phase may run in parallel only when their dependencies say so.
The first approved execution batch stops after the trust-foundation gate for
review before the first plugin migration.

## Rollout, Compatibility, And Rollback Notes

- Existing public commands and primary keymaps remain compatible until a task
  explicitly defines a product-approved replacement.
- Every phase is a separately reviewable commit/PR-sized unit.
- Rollback a phase by reverting its commit and restoring the matching lockfile;
  never mix lockfiles from different configuration generations.
- Tests never repair or delete real user data. Any future local-state migration
  must create a backup and require explicit action.
- Release rollback checks out the previous tag and restores its matching data
  snapshot in an isolated rehearsal.
- Roll back immediately on config/lock mutation, startup error, loss of a primary
  job, unsupported platform toolchain, failed state restoration, contrast
  regression, or a required matrix failure.

## Test And QA Plan

### Static Layer

- Lua formatting and lint.
- Python lint and unit tests.
- GitHub Actions lint.
- JSON/YAML parse and Markdown link/path checks.
- one canonical lock/config file and no generated drift.
- `git diff --check`.

### Unit Layer

- platform classification and executable resolution;
- version/profile semantics;
- score and severity behavior;
- timeout/error handling and JSON extraction;
- i18n parity/fallback;
- onboarding persistence;
- pure audit/validation models.

### Isolated Integration Layer

- clean archive first boot and offline second boot;
- resolved lock/config paths and unchanged hashes;
- sole explorer and rename propagation;
- real search, fold/wrap, formatter/LSP fallback, Git diff navigation;
- repeated diagnostics with complete session restoration;
- missing optional tool degradation;
- help layout at 60x16 and 80x24;
- resolved theme contrast and redundant Git/diagnostic signals.

### Release Layer

- exact supported Neovim on Ubuntu, Windows, and macOS;
- real Windows 11 + WSL2 evidence before publishing WSL support;
- previous-tag upgrade and rollback rehearsal;
- commit/tag-bound manifest, logs, reports, hashes, and known optional limits;
- branch protection requires the release matrix.

## Tasks

### NVIM-002: Canonicalize Runtime Configuration And Lock Authority

- Status: done — 2026-07-09; normalized snapshot accepted after the validated,
  backed-up, atomic lock transaction was added and passed
- Depends on: none
- Files: `init.lua`, `nvim/init.lua`, `nvim/lua/config/lazy.lua`,
  `lazy-lock.json`, `lazyvim.json`, `nvim/lazyvim.json`, test fixtures under
  `tests/`
- Change: snapshot the committed and user-dirty dependency generations; define
  root `lazy-lock.json` and root `lazyvim.json` as the only tracked contract;
  explicitly pass/declare their paths before LazyVim import; remove the dead
  nested JSON only after parity review; fail clearly when bootstrap prerequisites
  or lazy.nvim clone fail. Do not silently accept the dirty lockfile as the
  release target.
- Acceptance: local root install, arbitrary checkout path, and isolated archive
  all report the same repository lock/config paths; exactly one tracked
  `lazyvim.json` and one lockfile exist; startup leaves both hashes unchanged;
  missing Git/network produces an actionable bootstrap failure.
- Validation: run a headless path probe in isolated `XDG_*` roots; run the clean
  archive smoke from `QA-001`; run `git diff --check`; compare pre/post SHA-256 of
  root lock/config files.

### QA-001: Establish The Layered Verification Harness

- Status: done — 2026-07-09; Python/Lua/static/isolated pipeline evidence recorded below
- Depends on: NVIM-002
- Files: `tests/python/`, `tests/lua/`, `scripts/run_clarity_audit.py`,
  `scripts/run_clarity_validate.py`, new isolated archive/fixture helpers under
  `scripts/` or `tests/`, project lint configuration as required
- Change: split reusable pure logic from CLI orchestration; add bounded subprocess
  helpers, isolated `config/data/state/cache` fixtures, clean-archive preparation,
  stable check IDs, machine-readable reports, and the smallest maintained Lua and
  Python test/lint stack. Tests must never use or mutate the user's Neovim roots.
- Acceptance: unit tests cover platform/version/executable/timeout/JSON logic;
  the harness proves isolation before launching Neovim; a forced hang terminates
  within the configured budget; artifacts identify expected versus actual state.
- Validation: `python3 -m unittest discover -s tests/python -v`; the selected Lua
  test command documented by this task; a forced-timeout fixture; `git diff
  --check`.

### VALIDATE-002: Replace The False-Perfect Readiness Model

- Status: done — 2026-07-09; core/profile/release signals and exit semantics verified
- Depends on: QA-001
- Files: `nvim/lua/config/audit.lua`, `nvim/lua/config/validation.lua`,
  `scripts/run_clarity_audit.py`, `scripts/run_clarity_validate.py`,
  `tests/python/`, `tests/lua/`
- Change: define host capability, core feature readiness, optional profile
  readiness, and release evidence as separate outputs. Introduce explicit
  severity and ownership for every check. Core search and supported Neovim
  version become required; optional feature absence does not reduce core quality.
  CLI exits non-zero on required failures. Remove the ambiguous overall score or
  ensure it cannot be perfect when any required gate fails.
- Acceptance: table-driven tests independently fail every required capability and
  prove the headline/exit code changes; optional Copilot/provider absence is
  clearly degraded but does not block core; every failure includes check ID,
  impact, repair, and recheck.
- Validation: Python and Lua unit suites; run audit with a missing required-tool
  fixture and an optional-tool fixture; assert exit codes and JSON schema.

### CI-002: Make CI Hermetic, Supported, And Bounded

- Status: in progress — local workflow/action/toolchain checks pass 2026-07-09; remote Ubuntu/Windows/macOS run required
- Depends on: NVIM-002, QA-001, VALIDATE-002, RUNTIME-008
- Files: `.github/workflows/clarity-validate.yml`, CI helper scripts,
  version/checksum manifests, test fixtures
- Change: use an explicit supported Neovim version on Ubuntu, Windows, and macOS;
  resolve the actual installed binary; validate a clean archive in isolated
  platform-native roots; add job/subprocess timeouts, concurrency cancellation,
  least-privilege permissions, static gates, lock/config drift checks, and upload
  JSON/JUnit/log/environment manifests on failure and success.
- Acceptance: all required matrix jobs reach runtime validation and upload the
  runtime-contract coverage/scenario artifacts; Windows does not
  depend on one hard-coded install directory; no job uses unsupported Neovim;
  hangs terminate within budget; checked-out config/lock hashes remain unchanged.
- Validation: `actionlint`; local workflow/helper tests; successful manually
  dispatched Ubuntu/Windows/macOS run with downloadable manifests. The task
  remains incomplete until remote matrix evidence exists.

### NVIM-003: Prove Merge-Only Ownership With Neo-tree

- Status: pending
- Depends on: CI-002
- Files: `nvim/lua/plugins/neo-tree.lua`, Neo-tree/LazyVim contract tests under
  `tests/lua/`, isolated integration fixtures
- Change: remove Clarity's private Neo-tree lifecycle and forced eager ownership;
  mutate merged opts, append handlers at the correct top level, preserve upstream
  mappings and LazyVim file rename/move integration, and keep Neo-tree as the sole
  explorer. Use explicit Clarity ownership only for product-specific mappings and
  presentation deltas.
- Acceptance: directory startup opens exactly one Neo-tree and no Snacks Explorer;
  file rename/move invokes the upstream rename propagation once; line numbers and
  configured width behave correctly; upstream mappings/config remain present.
- Validation: resolved-spec contract test; isolated directory-start behavior;
  rename/move spy; required CI matrix.

### NVIM-004: Separate Mason, LSP, And Tool Installation Ownership

- Status: pending
- Depends on: QA-001
- Files: `nvim/lua/config/lazy.lua`, relevant new capability/policy module,
  `nvim/lua/plugins/` LSP/tool specs as needed, tests and docs fixtures
- Change: replace the mixed `mason_packages` list with typed ownership: LSP server
  IDs to LSP/mason-lspconfig, Mason package IDs to `mason.nvim`, and external
  system tools to preflight guidance. Define core versus language-development
  profiles. Noninteractive tests must not start background installs.
- Acceptance: resolved specs contain the exact expected server and Mason package
  sets; IDs are valid in their namespace; fresh first-session behavior explains
  installing/ready/unavailable states; core startup works without optional
  language profiles.
- Validation: resolved-spec tests in isolated roots; invalid-ID unit fixture;
  fresh profile smoke; no-optional-tools smoke.

### NVIM-005: Restore Conform Runtime Discovery And LSP Fallback

- Status: pending
- Depends on: NVIM-004
- Files: `nvim/lua/plugins/formatting.lua`, capability policy, formatter/LSP
  integration tests
- Change: mutate incoming Conform opts instead of replacing them; retain LazyVim
  default format options and LSP fallback; configure formatter names regardless
  of startup-time executable state; let runtime availability decide; keep
  formatter-specific argument deltas narrow.
- Acceptance: a formatter installed after startup becomes discoverable without a
  full restart where the plugin supports it; missing formatter falls back to LSP
  when available; no formatter produces a clear actionable state; inherited
  LazyVim format options remain present.
- Validation: missing-formatter and late-availability fixtures; LSP fallback spy;
  resolved Conform opts test; required CI matrix.

### NVIM-006: Repair Gitsigns Ownership And Diff Navigation

- Status: pending
- Depends on: QA-001
- Files: `nvim/lua/plugins/git.lua`, Git integration fixtures/tests
- Change: preserve upstream Gitsigns lifecycle; make hunk mappings attach once via
  `on_attach`; execute native diff navigation directly rather than returning
  ignored strings; remove retry polling not supported by measured failures;
  retain the product-approved repository-versus-hunk namespace separation.
- Acceptance: `[h`/`]h` move between changes in normal and diff modes; mappings
  attach once per buffer; non-Git buffers do not schedule repeated polling;
  existing hunk actions still work.
- Validation: two-hunk repository fixture; cursor-position assertions in normal
  and diff mode; autocmd/timer count assertion; required CI matrix.

### VALIDATE-003: Make Diagnostics Passive And Session-Safe

- Status: pending
- Depends on: QA-001, VALIDATE-002, RUNTIME-003, RUNTIME-006
- Files: `nvim/lua/config/audit.lua`, `nvim/lua/config/validation.lua`, CLI
  adapters, session-state tests
- Change: stop re-firing global `VeryLazy`; separate pure collection from UI;
  inspect resolved state passively; run UI probes in disposable tabs/windows;
  guarantee restoration of current tab, windows, buffers, cursor, options, and
  modified content on success or failure. Correct key assertions and execute
  advertised callbacks instead of only checking mapping existence.
- Acceptance: running audit/validation twice after normal startup from a modified
  buffer produces no errors or state change; `gd`, search, terminal, explorer,
  fold/wrap, and Git assertions target the real contract; intentional failures
  remain diagnosable.
- Validation: before/after serialized session-state test; modified-buffer test;
  repeat invocation; failure-injection cleanup test; required CI matrix.

### THEME-001: Establish One Accessible Colorscheme Contract

- Status: pending
- Depends on: QA-001
- Files: `nvim/lua/plugins/colorscheme.lua`, `nvim/init.lua`,
  `nvim/colors/custom_colorblind_theme.lua`, `nvim/lua/plugins/copilot.lua`,
  theme/accessibility tests
- Change: declare `custom_colorblind_theme` as the sole LazyVim colorscheme and
  load it through the standard command; remove direct theme sourcing; link or
  refresh plugin highlights through semantic groups/`ColorScheme`; add resolved
  contrast and non-color redundancy checks for normal, selection, diagnostics,
  separators, Git signs, and Copilot suggestion text.
- Acceptance: exactly one `ColorScheme` event establishes final colors; theme
  reload is stable; text reaches 4.5:1 and meaningful non-text reaches 3:1 unless
  an explicitly documented large-text exception applies; Git/diagnostic states
  are distinguishable without color alone.
- Validation: headless resolved-highlight probe; contrast test; terminal visual
  review on representative light/dark terminal settings; required CI matrix.

### NVIM-007: Migrate Tree-sitter And Lockfile Atomically

- Status: pending
- Depends on: NVIM-003, NVIM-004, NVIM-005, NVIM-006, VALIDATE-003, THEME-001
- Files: `lazy-lock.json`, `nvim/lua/plugins/treesitter.lua`, related LazyVim
  compatibility specs, parser/behavior tests, migration note
- Change: choose the current supported LazyVim/Tree-sitter generation; rewrite
  local configuration as a merge-compatible delta; remove dead old-API options;
  update the lockfile only in this task; record the pre/post plugin set and
  compatibility rationale. Never combine unrelated dependency updates.
- Acceptance: clean first boot installs/locates required parsers; highlight,
  indent, LSP fold, and supported selection behavior work; inherited LazyVim
  parser/fold defaults remain intact; lockfile is stable after validation.
- Validation: parser/query health suite; language fixtures; resolved opts/specs;
  clean archive and offline restart; required platform matrix; lock hash drift
  check.

### UX-001: Define A Safe Install, Update, And Recovery Journey

- Status: pending
- Depends on: CI-002, VALIDATE-002
- Files: new or existing preflight/install helpers under `scripts/`, `README.md`,
  `doc/clarity_lazyvim_complete_guide_zh.md`, tests and platform fixtures
- Change: document and automate only the safe parts of preflight: supported
  versions, existing-config detection, backup instructions, core prerequisites,
  bootstrap stages, expected duration/state, failed-network recovery, update,
  and rollback. Do not delete or replace user state automatically. Decide whether
  `ripgrep` is core-required or supply and test an acceptable fallback.
- Acceptance: clean users and users with existing config receive distinct safe
  paths; every failure states impact/action/recheck; update and rollback use a
  matching config/lock generation; no command mutates real user state in dry-run.
- Validation: platform/path unit fixtures; clean install dry-run; existing-config
  dry-run; forced missing Git/rg/network; documented rollback rehearsal in an
  isolated HOME.

### UX-002: Make First-run Help Responsive And Reliable

- Status: pending
- Depends on: VALIDATE-003
- Files: `nvim/lua/config/help.lua`, i18n strings, help layout/state tests
- Change: clamp the float to available UI dimensions, wrap and scroll content,
  expose visible navigation/close affordances, reduce the first page to minimum
  lovable actions, and persist onboarding state only after successful rendering.
  Handle the deferred buffer-change race without losing future onboarding.
- Acceptance: no clipping/error at 60x16 and 80x24; content remains navigable;
  failed or skipped rendering does not mark the guide seen; manual `ClarityStart`
  is always recoverable.
- Validation: headless UI/layout probes for 60x16, 80x24, and large UI; deferred
  race test; successful/failed persistence tests; English/Chinese snapshots.

### I18N-002: Localize Recovery And Make Platform Guidance Accurate

- Status: pending
- Depends on: VALIDATE-002, UX-002
- Files: `nvim/lua/config/i18n.lua`, `nvim/lua/config/help.lua`,
  `nvim/lua/config/audit.lua`, `nvim/lua/config/validation.lua`, platform/i18n
  tests and user docs
- Change: move all Clarity-owned audit, validation, bootstrap, help, and recovery
  copy to semantic i18n keys; classify Windows, WSL, Linux, and macOS separately;
  provide platform-specific clipboard/update recipes; replace exact upstream
  English-string translation where Clarity can own stable semantic IDs.
- Acceptance: English and Chinese parity covers every Clarity-owned surface;
  macOS/native Linux are never labeled WSL mirrors; changing locale produces
  consistent product-owned output after the documented refresh boundary;
  unknown upstream strings degrade safely.
- Validation: i18n key parity and fallback tests; platform matrix fixtures;
  English/Chinese command snapshots; manual platform-copy review.

### UX-003: Simplify Primary Surfaces And Protect Perceived Performance

- Status: pending
- Depends on: NVIM-004, NVIM-006, UX-002, I18N-002, THEME-001
- Files: `nvim/lua/config/keymaps.lua`, `nvim/lua/config/menu_i18n.lua`,
  `nvim/lua/plugins/toggleterm.lua`, `nvim/lua/plugins/copilot.lua`, help/product
  docs, latency tests
- Change: promote one path for each core job; give Git hunks and product
  help/health truthful groups; demote secondary terminal layouts/system monitor
  from newcomer surfaces; treat Copilot as optional; label visual wrapping as
  display-only; scope terminal mappings to the intended terminal ownership;
  cache/defer Node discovery to protect first insert.
- Acceptance: onboarding and which-key primary groups contain no conflicting
  mental models; one floating terminal is the promoted path; optional power paths
  do not affect core readiness; plain `:terminal` does not receive undocumented
  ToggleTerm-only policy; startup/first-insert/help/search/terminal latency stays
  within baselines agreed in this task.
- Validation: keymap/group contract tests; core-without-Copilot smoke; plain
  terminal versus ToggleTerm mapping test; startup and first-action benchmark on
  macOS plus available Windows/WSL evidence.

### RELEASE-001: Establish Protected, Reversible Releases

- Status: pending
- Depends on: NVIM-007, UX-001, UX-003, CI-002
- Files: GitHub branch/repository settings, workflow/release helper files,
  `docs/decisions/`, release/rollback documentation
- Change: require the green platform/static/integration matrix on `main`; define
  an immutable tag/release process; attach commit, config/lock hashes, tool
  versions, run URLs, optional limitations, and known issues; rehearse upgrade
  from the previous release and rollback to the previous tag/data snapshot.
- Acceptance: protected `main` cannot merge without required checks; a candidate
  tag has complete evidence; failed release gates prevent the 95+ claim; rollback
  completes in the isolated rehearsal and is understandable without chat history;
  runtime-contract coverage has zero unclassified and zero planned core entries.
- Validation: GitHub API/settings inspection; release-candidate workflow;
  manifest schema/hash verification; upgrade and rollback rehearsal with logs.

### QA-002: Run The 95+ Acceptance And Newcomer Evaluation

- Status: pending
- Depends on: RELEASE-001
- Files: acceptance reports/artifacts under `docs/reviews/` or CI artifacts,
  usability test protocol/results, active plan status
- Change: run the complete rubric against a clean release candidate; conduct a
  small moderated study with 3–5 GUI-editor migrants covering install, edit/save,
  search, terminal, help, and recovery; log defects without coaching away product
  problems; recalculate the evidence score.
- Acceptance: no open P0/P1; overall evidence score at least 95; at least 90% of
  target participants complete the core five-minute journey and find recovery
  within 30 seconds, or remaining failures become blocking tasks rather than
  exceptions.
- Validation: signed/datestamped rubric with CI artifact links; usability protocol
  and anonymized results; rerun all release gates against the exact candidate.

### DOCS-002: Reconcile Public Truth And Close The Refactor

- Status: pending
- Depends on: QA-002
- Files: `README.md`, `docs/README.md`, `docs/DOCUMENT_INDEX.md`,
  `docs/ai/current-reality.md`, product/architecture docs, Chinese guide,
  `doc/assets/clarity-hero.svg`, this plan, concise progress closeout, ADRs
- Change: update public claims only from final artifacts; remove stale self-scores
  and platform claims; record adopted ADRs; update current reality, task statuses,
  install/update/rollback guidance, and documentation pointers; retain old
  reports as clearly labeled history.
- Acceptance: every current validation/platform/accessibility claim has a matching
  commit/tag and artifact; no stale active path or score remains; this plan marks
  all completed work and deviations; AGENTS contains only durable rules/pointers,
  not the session log.
- Validation: Markdown formatting/link/path check; stale-string/path searches;
  repository AI-doc check if one exists; `git diff --check`; final clean status
  review with user-owned files explicitly accounted for.

## Handoff

### Trust-Foundation Evidence — 2026-07-09

- Branch: `codex/20260709-clarity-trust-foundation`, base `9b030f6`.
- Root lock/config paths resolve correctly in the live checkout and copied
  candidate; nested `nvim/lazyvim.json` is removed.
- Clean candidate first boot and restart pass with 27 resolved plugins.
- Stable candidate hashes: lock
  `79e5323b3074c5f6434a708a7c209c84f41b1bcb97541af512bfb069929b710a`,
  JSON `3911b0251e3c51aa127f937aa5de323dba1eb6227636549264bde36e1674ad02`.
- Audit result: `core=ready (12/12)`, `release=unverified`; required-tool fixture
  exits 1, optional-profile fixture exits 0.
- Behavior validation: required failures 0; Python provider remains an optional
  local warning.
- Python unit tests, Lua policy tests, Ruff, StyLua, actionlint, official macOS
  Neovim installer/checksum, bootstrap failure paths, and `git diff --check` pass.
- Deviation: the first smoke-harness version ran against the source repository
  and lazy.nvim normalized the pre-existing lock from hash
  `1140d485bc1c957371b4774585c7a9aa00472f294c9d54fcb6fa40e2e54fe4ef`
  to the stable candidate hash above. No pre-write content copy was retained.
  The harness now always copies the candidate and verifies source hashes. The
  owner accepted the normalized snapshot after an explicit check-only lock
  transaction was added; `--apply` requires a stable, core-ready candidate,
  backs up the exact prior bytes, and atomically replaces the source. `NVIM-002`
  is done.
- Remote matrix is not run because the branch has not been pushed; `CI-002`
  remains in progress.
- Local review exposed a natural-startup false green: `config.options` was absent
  during file startup even though later validation passed after lifecycle replay.
  The approved verification architecture and decision-complete `RUNTIME-001`
  through `RUNTIME-008` plan reopen the trust gate before remote certification.

### Next Execution Batch

After runtime-contract plan approval, execute only:

1. `RUNTIME-001`
2. `RUNTIME-002`
3. `RUNTIME-003`
4. `RUNTIME-004`

Stop after the line-number lifecycle positive/negative proof and present evidence
before expanding to `RUNTIME-005`.

### Assumptions And Defaults

- LazyVim remains the foundation.
- Root clone/config layout remains the public distribution shape.
- Copilot is optional and not part of core readiness.
- Existing user state is backup-only and never auto-deleted.
- Historical documents remain for traceability.
- Exact Lua lint/test tooling defaults to the smallest maintained option selected
  in `QA-001`; this is non-blocking because the contract and acceptance behavior
  are fixed.

### Non-goals And Out Of Scope

- New plugins or feature expansion.
- From-scratch distribution architecture.
- Full upstream plugin localization.
- Hosted telemetry.
- Destructive local repair.
- WSL compatibility claims without real WSL evidence.
- Performance optimization without a measured product budget.

### Rollback Note

Every implementation phase must be independently revertible and must retain its
matching lockfile. If a task changes runtime state contracts, its tests must first
prove backup and rollback in isolated directories.

### Status

PM document written to `docs/product/clarity-95-experience-pm.md`; approved
architecture written to
`docs/architecture/2026-07-09-clarity-95-refactor-blueprint.md`; this decision-
complete PLAN+TASK is written to
`progress/2026-07-09-clarity-95-refactor-plan.md`. The runtime-contract PM/TASK is
written to `progress/2026-07-09-runtime-contract-verification-plan.md` and awaits
approval. `CI-002` and later tasks remain gated.
