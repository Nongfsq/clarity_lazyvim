# Clarity Interaction And Dependency Simplification PLAN+TASK

Date: 2026-07-10  
Status: all five implementation batches complete locally and on manual Ubuntu;
Windows/release evidence remains pending — 2026-07-10  
Evidence review: `docs/reviews/2026-07-10-interaction-dependency-modernization-review.md`

## Summary

Reduce Clarity to one obvious path per core job while preserving LazyVim as the
runtime foundation. Repair current keymap and lifecycle defects before pruning
dependencies. Never remove a plugin or compatibility alias solely from static
opinion; require resolved-spec, behavior, clean-archive, and rollback evidence.

This plan is an execution overlay. It reuses stable task IDs from
`progress/2026-07-09-clarity-95-refactor-plan.md` instead of duplicating or
renumbering them, and introduces only the missing task IDs.

## Current Reality

- Review baseline is clean commit `b072da5` on `main`.
- Ubuntu core behavior and the release router pass manually on Neovim 0.12.4.
- Windows remains unverified. GitHub Actions must not be triggered without an
  explicit future request from the owner.
- The active observability work has local implementation through `OBS-007`;
  `OBS-008` remote evidence and `OBS-009` closeout remain open.
- Existing pending tasks already cover Neo-tree, Mason, Conform, Gitsigns,
  passive validation, theme, Tree-sitter, onboarding, i18n, and surface
  simplification.

## Product Decisions

- Essential promise: Clarity feels calm and obvious; advanced power remains
  discoverable without dominating the primary workflow.
- One promoted path each: files, project text, explorer, format, Git change,
  terminal, fold, wrap, help, and diagnosis.
- No new plugin is approved by this plan.
- Upstream lifecycle ownership is the default. Clarity owns product deltas,
  typed actions, copy, recovery, and acceptance contracts.
- Optional features must not affect core startup, key ownership, readiness, or
  release truth.
- Removal follows proof and a compatibility window; lock changes remain isolated.

## Architecture Decisions

1. **Resolved runtime spec is dependency authority.** Static lock presence alone
   is insufficient. Rejected: manual lock deletion. Revisit when lazy.nvim
   provides an official equivalent manifest and drift gate.
2. **LazyVim owns plugin setup lifecycles.** Clarity mutates opts and composes
   handlers. Rejected: copied full `config` functions. Revisit only when an
   upstream lifecycle cannot satisfy a documented product contract.
3. **Behavior contracts own promoted features.** Existence checks remain
   diagnostics only. Rejected: keymap-presence certification. Revisit when
   Neovim exposes equivalent provenance and action assertions.
4. **One terminal implementation is selected by parity evidence.** Snacks may
   replace ToggleTerm only if it removes a dependency and passes all product
   behavior. Rejected: running both permanently. Revisit if the selected owner
   loses required cross-platform behavior.
5. **Host evidence and release evidence remain separate.** Local macOS and remote
   Ubuntu work may support development; Windows and release claims remain
   pending. No GitHub Actions run is implicit in this plan.

## Test And QA Plan

### Static And Unit

- Exact keymap manifest: lhs, mode, scope, owner, source, description, and options.
- Resolved plugin manifest: enabled, lazy handlers, dependencies, setup owner.
- No duplicate setup owner for LazyVim-owned plugins.
- i18n label changes preserve callback/rhs/mode/scope/options.
- Python and Lua suites, Ruff, StyLua, documentation link/path checks.

### Isolated Behavior

- LSP maps absent before capability and buffer-local after attach.
- `[h`/`]h` work in normal and diff modes; `[c`/`]c` retain Tree-sitter ownership.
- Directory startup creates one Neo-tree; rename/move propagation fires once.
- Formatter present, missing, installed-after-start, and LSP-fallback cases.
- One promoted terminal opens/closes, preserves cwd and shell, restores state, and
  fits 60x16/80x24.
- Help rendering writes seen state only after successful display.
- Audit/validation invoked twice preserve tab, windows, buffers, modified text,
  cursor, cwd, options, mappings, autocmds, and event counts.
- Copilot-disabled startup leaves `<Tab>`, `<C-n>`, `<C-p>`, and `<C-e>` unchanged.

### Performance And Dependency Failure

- Measure clean empty/file/directory startup median and p95, loaded plugins before
  `VeryLazy`, and first picker/terminal/help/insert latency.
- Missing Git/ripgrep remains an actionable core failure.
- Missing Node/Copilot, providers, language tools, and system monitor degrade only
  their optional profiles.
- Noninteractive startup performs no background Mason/parser installation.

### Release Boundary

- Every implementation batch runs local macOS and available Ubuntu isolated gates.
- Windows is explicitly pending until the owner supplies the environment.
- GitHub Actions is not triggered by approval of this plan.
- No 95+ cross-platform or release claim until required platform evidence exists.

## Tasks

### EVIDENCE-001: Reconcile The Manual Host Evidence Gate

- Status: done — 2026-07-10; merged commit, manual Ubuntu/macOS boundary,
  pending Windows/release evidence, and no-implicit-Actions rule recorded
- Depends on: none
- Files: `docs/ai/current-reality.md`, relevant active PLAN+TASK status sections,
  and a decision record only if the durable evidence policy changes
- Change: record that GitHub Actions is not implicitly authorized; distinguish
  manual macOS/Ubuntu evidence from pending Windows and release evidence; remove
  stale text that says the branch is unmerged or Ubuntu is untested. Do not mark
  `CI-002` or `OBS-008` complete without their stated platform evidence.
- Acceptance: every active ledger names the same commit, available host evidence,
  pending platforms, and authorization boundary; no document treats Ubuntu as WSL
  or local results as release certification.
- Validation: documentation path/link scan; cross-document status search;
  `git diff --check`.

### KEYMAP-001: Establish One Owned Interaction Manifest

- Status: done — 2026-07-10; duplicate global LSP/diagnostic maps removed,
  correct `gd` contract and non-mutating which-key metadata covered by tests
- Depends on: EVIDENCE-001, QA-001
- Files: `nvim/lua/config/keymaps.lua`, `nvim/lua/config/menu_i18n.lua`,
  `nvim/lua/config/validation.lua`, keymap/i18n tests, user docs
- Change: generate/assert the effective promoted-key manifest; remove duplicate
  global LSP and diagnostic maps in favor of LazyVim capability-scoped ownership;
  correct the `gd` validation contract; stop rebuilding callbacks merely to
  translate descriptions; define truthful Clarity, Git, terminal, and toggle
  groups. Preserve `<leader>cz`, `<leader>fw`, `<leader>uw`, `<leader>wo`,
  `<leader>e/E`, and `<leader>hh` unless a later deprecation task proves a better
  user outcome.
- Acceptance: no promoted lhs has two owners; LSP maps are capability-scoped;
  locale changes never change callback/rhs/options; which-key labels match actual
  jobs; validation executes or inspects the correct contract.
- Validation: static/resolved keymap manifest; LSP attach/no-attach fixtures;
  English/Chinese namespace snapshots; mapping metadata equality test.

### NVIM-006: Repair Gitsigns Ownership And Diff Navigation

- Status: done — 2026-07-10; upstream on_attach composed, polling/setup removed,
  diff navigation fixed, Tree-sitter `[c`/`]c` ownership restored
- Depends on: KEYMAP-001
- Files: `nvim/lua/plugins/git.lua`, Git fixtures/tests, compatibility notes
- Change: execute native diff motion correctly; remove `[c`/`]c` hunk aliases;
  compose the upstream `on_attach`; remove private setup, retry polling, focus
  autocmds, global scan, and duplicated signs; migrate hunk actions into the
  approved truthful namespace with a documented alias window if required.
- Acceptance: `[h`/`]h` navigate in normal and diff buffers; Tree-sitter retains
  `[c`/`]c`; mappings attach once; non-Git buffers create no retry timers; all
  hunk actions still work.
- Validation: two-hunk repository fixture; diff-mode cursor assertions; resolved
  on_attach owner; timer/autocmd count; real key input.

### UX-002: Make First-Run Help Responsive And Reliable

- Status: done — 2026-07-10; bounded responsive float, calm action failures,
  and render-before-seen persistence covered at 60x16/80x24/large layouts
- Depends on: KEYMAP-001
- Files: `nvim/lua/config/help.lua`, i18n strings, UI state/layout tests
- Change: clamp the panel to the active UI, wrap and scroll content, expose visible
  navigation, route actions through stable product actions, and persist onboarding
  state only after successful rendering.
- Acceptance: 60x16, 80x24, and large UIs open without clipping; failed/deferred
  rendering does not mark the guide seen; all actions fail calmly and restore the
  previous state.
- Validation: attached-UI size matrix; persistence success/failure tests;
  English/Chinese snapshots; action failure fixtures.

### VALIDATE-003: Make Audit And Validation Passive

- Status: done — 2026-07-10; lifecycle replay and live probes removed, legacy
  behavior IDs delegated, repeat/failure state restoration proven
- Depends on: KEYMAP-001, UX-002, OBS-009 or an owner-approved non-overlap decision
- Files: `nvim/lua/config/audit.lua`, `nvim/lua/config/validation.lua`, CLI
  adapters, runtime contracts, session-state tests
- Change: remove lifecycle replay and live-session feature probing from collection;
  move behavior to isolated scenarios; keep UI rendering separate from the report
  model; guarantee restoration on success and injected failure.
- Acceptance: two invocations from a modified buffer cause no state or lifecycle
  change; every promoted behavior has one authoritative test; reports retain stable
  IDs, impact, repair, and recheck paths.
- Validation: serialized before/after state; repeat invocation; cleanup fault;
  release router and legacy-ID mapping.

### NVIM-003: Restore Merge-Only Neo-tree Ownership

- Status: done — 2026-07-10; upstream setup/load/dependency ownership restored,
  top-level handlers composed and explorer behavior retained
- Depends on: KEYMAP-001, available-host evidence gate
- Files: `nvim/lua/plugins/neo-tree.lua`, resolved-spec and explorer tests
- Change: retain Neo-tree as the sole explorer while replacing eager private setup
  with merged opts and composed top-level handlers; preserve LazyVim rename/move
  propagation, root/cwd semantics, open-file protections, and lazy handlers.
- Acceptance: one Neo-tree and zero Snacks Explorer windows on directory startup;
  rename propagation fires once; width/line-number behavior remains; upstream
  handlers and mappings survive.
- Validation: resolved owner/spec; directory startup; rename/move spy; root/cwd
  behavior; small-screen explorer check.

### NVIM-004: Separate Mason, LSP, Parser, And Tool Ownership

- Status: done — 2026-07-10; explicit core/development profile separates LSP
  servers, Mason tools, Rust toolchain ownership, and noninteractive behavior
- Depends on: EVIDENCE-001
- Files: `nvim/lua/config/lazy.lua`, capability/profile modules, tests and docs
- Change: replace the mixed package list with typed core, language, Copilot, and
  provider profiles; use the correct namespace owner for every server/package;
  keep external system tools in preflight guidance; prohibit background install
  in noninteractive mode.
- Acceptance: every ID resolves in exactly one namespace; core starts without
  optional profiles; first-session status is actionable; no test launch installs.
- Validation: resolved package manifest; invalid-ID fixture; no-tools smoke;
  noninteractive process/install assertion.

### NVIM-005: Restore Conform Merge And Runtime Discovery

- Status: done — 2026-07-10; inherited opts/LSP fallback preserved and runtime
  availability no longer frozen at startup
- Depends on: NVIM-004
- Files: `nvim/lua/plugins/formatting.lua`, capability policy, formatter tests
- Change: mutate inherited opts; preserve LazyVim defaults and LSP fallback;
  configure formatter names independently of startup PATH; query runtime
  availability when formatting occurs; keep argument overrides narrow.
- Acceptance: late-installed formatter is discoverable where supported; missing
  formatter uses LSP fallback; no formatter yields actionable status; inherited
  format options remain.
- Validation: formatter present/missing/late fixtures; LSP fallback spy;
  resolved opts and `:ConformInfo` evidence.

### THEME-001: Establish One Accessible Colorscheme Lifecycle

- Status: done — 2026-07-10; one standard custom colorscheme lifecycle with
  explicit Habamax failure fallback; Lush retained because the theme uses it
- Depends on: EVIDENCE-001
- Files: `nvim/lua/plugins/colorscheme.lua`, `nvim/init.lua`, theme source,
  Copilot highlights, accessibility tests
- Change: make the custom theme one standard colorscheme owner; remove direct
  `dofile` and contradictory Habamax ownership; retain Lush only if the theme
  implementation requires it; refresh dependent highlights on `ColorScheme`.
- Acceptance: one colorscheme name/event owns final state; reload is stable;
  contrast and non-color signals meet the existing accessibility contract.
- Validation: event/name probe; resolved highlight and contrast tests; terminal
  visual review; Lush-present versus removed decision evidence.

### NVIM-007: Migrate Tree-sitter And Lock Atomically

- Status: done — 2026-07-10; legacy options removed, LazyVim main-generation
  lifecycle retained, parser profile typed; check-only lock transaction clean
- Depends on: NVIM-003, NVIM-004, NVIM-005, NVIM-006, VALIDATE-003, THEME-001
- Files: `nvim/lua/plugins/treesitter.lua`, `lazy-lock.json`, parser/fold/select
  tests, migration note
- Change: choose one supported Tree-sitter generation; migrate setup, parser
  installation, queries, folding, selection, textobjects, and autotag contracts;
  change the lock only in this independently reviewable task.
- Acceptance: no mixed APIs; required language fixtures highlight/indent/fold;
  missing/stale parser failures are actionable; authority hashes stay stable
  after validation and offline restart.
- Validation: parser/query suite; LSP/Tree-sitter/plain fold fixtures; selection
  real input; clean first boot and offline restart; lock transaction rollback.

### PERF-001: Restore Explicit Lazy-Loading Ownership

- Status: done — 2026-07-10; lazy default restored, explicit ToggleTerm handler
  added, empty-headless loaded plugin count reduced from 10 to 4
- Depends on: NVIM-003, NVIM-005, NVIM-006, THEME-001
- Files: `nvim/lua/config/lazy.lua`, affected plugin specs, resolved-spec and
  performance tests
- Change: replace blanket `defaults.lazy = false` with upstream semantics and
  explicit handlers/eager exceptions; fix every hidden dependency exposed by the
  change; establish empty/file/directory and first-action budgets.
- Acceptance: no promoted action fails on first use; eager plugin count decreases
  or every retained eager plugin has documented product justification; median/p95
  startup and first-action budgets do not regress.
- Validation: isolated cold/warm profiles; resolved handler manifest; first
  picker/terminal/help/insert behavior; missing-dependency fixtures.

### TERM-001: Collapse Terminal To One Product Path

- Status: done — 2026-07-10; one reusable `<leader>tf` float remains, generic
  terminal mappings, secondary layouts, system monitor, and devicons setup removed
- Depends on: PERF-001, KEYMAP-001
- Files: `nvim/lua/plugins/toggleterm.lua` or a measured Snacks-terminal delta,
  help/i18n/docs, terminal tests, lock only if the owner changes
- Change: keep `<leader>tf` as the promoted floating terminal; remove system
  monitor from the product surface; deprecate `<leader>tr/tv/th` for one documented
  compatibility window; scope terminal-mode policy to the selected owner. Compare
  Snacks against ToggleTerm for cwd, shell, persistence, Windows, navigation,
  layout, and restoration. Replace ToggleTerm only if all parity gates pass.
- Acceptance: exactly one promoted terminal path; plain `:terminal` is not
  unexpectedly remapped; repeated toggles reuse the intended instance; optional
  utility absence creates no core warning; selected owner is justified by evidence.
- Validation: 60x16/80x24 attached UI; cwd/shell/open-close/reuse/restoration;
  plain terminal comparison; Windows pending marker; lock rollback if replaced.

### COPILOT-001: Make Copilot An Explicit Conflict-Free Profile

- Status: done — 2026-07-10; explicit `CLARITY_COPILOT=1` profile, PATH-only
  Node resolution, no core completion/code key ownership
- Depends on: KEYMAP-001, NVIM-004, PERF-001
- Files: `nvim/lua/plugins/copilot.lua`, capability/profile policy, help/docs,
  key and startup tests
- Change: disable Copilot by default for the core profile; load only when opted in;
  replace the large host-specific Node scan with the shared capability resolver;
  avoid claiming core insert/completion keys unless the owner chooses that policy.
- Acceptance: core startup has no Node/Copilot dependency and no insert-key
  changes; enabled profile has actionable Node/auth health and explicit keys;
  first insert remains within budget.
- Validation: enabled/disabled profile matrix; key ownership snapshots; missing
  Node and auth fixtures; first-insert latency.

### CLIP-001: Define Native And SSH Clipboard Truth

- Status: done — 2026-07-10; desktop/WSL/SSH/missing classifications, early
  OSC52 copy-only setup, unnamedplus mode, bilingual recovery and redaction tests
- Depends on: I18N-002, VALIDATE-003
- Files: capability/audit/help/i18n modules, clipboard tests and user docs
- Change: document and detect desktop providers, WSL, terminal paste, and SSH
  OSC52 separately; promise OSC52 copy only where proven and state that paste/read
  may be unsupported or terminal-disabled; do not add a clipboard plugin.
- Acceptance: each platform/session reports the actual provider and exact copy/
  paste recovery path; headless absence is not confused with product failure;
  secrets and clipboard contents never enter logs/artifacts.
- Validation: provider fixtures; real available Ubuntu SSH OSC52 provider check;
  macOS provider check; Windows/WSL pending evidence; redaction scan.

### DEPS-001: Prune Proven Dead Dependency Surface

- Status: done — 2026-07-10; devicons removed by validated atomic lock
  transaction; policy tombstones and optional Copilot retention documented;
  exact backup and clean post-transaction normalization verified
- Depends on: NVIM-007, TERM-001, COPILOT-001, THEME-001
- Files: `nvim/lua/plugins/minimal.lua`, affected specs, `lazy-lock.json`,
  dependency manifest, migration/rollback note
- Change: prove whether real devicons, Lush, inherited textobjects/autotag/Noice,
  and each disabled plugin is active or transitive; remove only proven dead specs;
  normalize the lock through `update_clarity_lock.py --apply` in a dedicated
  transaction; record before/after active and locked sets.
- Acceptance: zero unexplained disabled lock entries; every retained dependency
  owns a named user job or required transitive contract; clean first boot and
  offline restart pass; rollback restores exact previous bytes and behavior.
- Validation: resolved dependency manifest; clean archive; offline restart;
  authority hash and lock diff review; rollback rehearsal; full release router.

### UX-003: Reconcile The Final Primary Surface

- Status: done — 2026-07-10; one path per core job, truthful Git/Clarity groups,
  explicit profiles, public English/Chinese copy, and final manifests reconciled
- Depends on: NVIM-006, UX-002, TERM-001, COPILOT-001, CLIP-001, DEPS-001
- Files: keymaps, which-key labels, help/i18n, README, Chinese guide, latency tests
- Change: remove expired aliases, present one path per core job, label visual wrap
  precisely, keep advanced actions searchable, and reconcile all public copy with
  the resolved runtime manifest.
- Acceptance: newcomer surfaces contain no conflicting mental model; every
  promoted action has behavior evidence and recovery; advanced/optional features
  do not affect core readiness or first-run latency.
- Validation: primary-surface snapshot; newcomer task walkthrough; i18n parity;
  performance budgets; documentation/runtime drift scan.

## Migration Order And Approval Gates

1. **Batch 1 — interaction truth:** `EVIDENCE-001`, `KEYMAP-001`, `NVIM-006`,
   `UX-002`. Stop and present keymap, Git, and small-screen evidence.
2. **Batch 2 — passive ownership:** `VALIDATE-003`, `NVIM-003`, `NVIM-004`,
   `NVIM-005`, `THEME-001`. Stop and present resolved-spec/session evidence.
3. **Batch 3 — compatibility migration:** `NVIM-007`, then `PERF-001`. Stop and
   present lock, parser, startup, and rollback evidence.
4. **Batch 4 — product cuts:** `TERM-001`, `COPILOT-001`, `CLIP-001`. Stop and
   present behavior/parity decisions before dependency removal.
5. **Batch 5 — pruning and reconciliation:** `DEPS-001`, `UX-003`, then existing
   release/QA/documentation closeout tasks when platform evidence permits.

No later batch is implicitly approved by approval of an earlier batch.

## Analytics, Observability, And Security

- No hosted analytics or telemetry.
- Add typed diagnostics only for meaningful action failure/recovery, not every
  keypress.
- Never persist buffer text, clipboard contents, environment values, tokens, or
  raw provider output.
- Dependency review records exact repositories/commits and host package versions;
  security/advisory scanning is evidence, not an auto-update authority.

## Frontend Workstream

N/A — this is a terminal Neovim product; attached-UI behavior tests own visual
and interaction verification.

## Backend/API/Data Workstream

N/A — there is no service API or product datastore. User state is backup-first
and must not be migrated destructively.

## Rollout, Compatibility, And Rollback

- Each task is independently reviewable and leaves the repository runnable.
- Alias removals receive one documented compatibility window unless they
  currently overwrite an upstream mapping, in which case correctness wins and
  the migration note is immediate.
- Lock changes occur only in `NVIM-007` and `DEPS-001`.
- Every lock task stores exact old bytes and rehearses rollback in isolated roots.
- GitHub CI, pushing, merging, tagging, and releases require separate explicit
  authorization; the completed approval covered all five local/manual-Ubuntu
  implementation batches, not those external integration actions.

## Handoff

- Assumptions: LazyVim remains the foundation; Neo-tree remains the explorer;
  Snacks remains the picker; one terminal remains a core job; Copilot remains
  available only as optional profile; GitHub Actions is not implicitly authorized.
- Non-goals: new plugins, full rewrite, vim.pack migration, a second picker,
  explorer, terminal, clipboard plugin, AI pane, hosted telemetry, or manual lock
  editing.
- Open questions: none blocking. Terminal implementation defaults to retaining a
  simplified ToggleTerm unless Snacks passes every parity gate.
- Approval: all five batches approved by the owner on 2026-07-10. GitHub Actions,
  pushing, merging, tagging, and release remain separately gated.
- Status line: review written to
  `docs/reviews/2026-07-10-interaction-dependency-modernization-review.md`; this
  PLAN+TASK written to
  `progress/2026-07-10-interaction-dependency-simplification-plan.md`;
  Batch 1 implementation is active on
  `codex/20260710-clarity-simplification` from base `b072da5`.
