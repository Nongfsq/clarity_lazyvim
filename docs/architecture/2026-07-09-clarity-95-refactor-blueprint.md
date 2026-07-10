# Architecture Blueprint: Clarity LazyVim 95+ Refactor

Date: 2026-07-09
Architecture type: existing-system refactor
Status: approved direction; implementation is governed by the active PLAN+TASK

## Summary

- Product goal: make Clarity a trustworthy, accessible, low-friction Neovim
  product for GUI-editor migrants without rebuilding the capabilities already
  owned well by LazyVim.
- Architecture type: incremental existing-system refactor with compatibility and
  rollback gates.
- Selected stack: Neovim/Lua, lazy.nvim, LazyVim, a deliberately small plugin
  surface, Python verification tools, and GitHub Actions.
- Primary constraints: preserve user-owned dirty files; remain cross-platform;
  avoid startup regressions; do not expand the plugin surface without product
  evidence; make the committed repository reproducible in isolation.
- Non-goals: a from-scratch Neovim distribution, micro-framework abstractions,
  full upstream-plugin localization, automatic ownership of user machines, or a
  feature-count race.

## Decisions

- Runtime foundation: keep LazyVim as the runtime foundation and make Clarity a
  thin policy/product layer. Why: LazyVim already owns LSP, formatting, picker,
  plugin lifecycle, and upgrade infrastructure. Rejected: rewrite from scratch
  (large regression and maintenance surface); keep unrestricted overrides
  (continues upgrade drift). Revisit when: two consecutive supported LazyVim
  upgrade cycles require unavoidable lifecycle replacement for core product
  behavior.
- Configuration source of truth: root `init.lua`, `lazy-lock.json`, and
  `lazyvim.json` are the single tracked runtime contract, with explicit paths
  passed before LazyVim imports. Why: documented root clones and CI archives then
  consume identical state. Rejected: implicit `stdpath("config")` defaults
  (checkout and runtime paths diverge); dual root/nested copies (silent drift).
  Revisit when: the repository permanently adopts a conventional config-only
  layout with no wrapper root.
- Plugin ownership: LazyVim/upstream retains each core plugin's `config`
  lifecycle; Clarity extends through merged opts, handlers, and narrowly owned
  keymaps/autocmds. Why: upstream fixes and defaults remain intact. Rejected:
  copying complete setup tables (hidden drift); defensive polling around working
  callbacks (extra state and latency). Revisit when: an upstream plugin exposes
  no safe extension contract and a behavior test proves a custom lifecycle is
  required.
- Product services: keep only minimal i18n/bootstrap state eager; expose help,
  audit, and validation through lazy command adapters over pure report models.
  Why: diagnostics become testable and non-destructive while startup stays
  small. Rejected: monolithic eager service modules (coupling/startup cost); live
  session mutation as testing (damages the state being diagnosed). Revisit when:
  measured lazy-load latency harms the first help/diagnostic interaction.
- Capability model: define `core`, `development`, and optional feature profiles,
  each with typed ownership and explicit required/optional semantics. Why: a
  primary job cannot silently depend on a globally optional executable.
  Rejected: one flat executable score (false confidence); auto-installing every
  tool from one mixed list (Mason/LSP/system namespaces differ). Revisit when:
  user research supports additional officially maintained profiles.
- Theme lifecycle: make `custom_colorblind_theme` the only declared Clarity
  colorscheme and load it through `:colorscheme`; plugin highlights link to
  semantic groups or respond to `ColorScheme`. Why: one standard lifecycle and
  testable resolved colors. Rejected: `habamax` plus direct `dofile` (two owners,
  missing events). Revisit when: multiple supported themes become a real product
  requirement.
- Testing: use a pyramid of static invariants, unit tests for pure policy,
  isolated headless integration, and clean-archive release smoke. Why: fast
  failures plus behavior-level confidence. Rejected: one monolithic headless
  script (false positives and hard diagnosis); E2E-only (slow and fragile).
  Revisit when: suite duration exceeds the agreed CI budget and evidence shows a
  lower layer can safely replace expensive cases.
- CI/CD and distribution: validate an immutable archive in platform-native
  temporary config/data/state/cache roots on Ubuntu, Windows, and macOS; require
  green checks before a tagged release. Why: distribution is a Git clone, so the
  archive is the deployable artifact. Rejected: validating the developer's
  config/cache (not reproducible); unversioned OS Neovim packages (unsupported
  versions). Revisit when: Clarity gains a packaged installer or a different
  distribution artifact.
- Observability: every verification layer emits stable check IDs, human output,
  machine JSON, environment/version manifest, and bounded subprocess logs. Why:
  failures must explain what happened and what to do next. Rejected: a single
  opaque score (not diagnosable). Revisit when: external telemetry is explicitly
  desired and privacy implications are approved.
- Security and supply chain: pin the supported Neovim artifact and provider/tool
  versions used by CI, preserve the plugin lock, use least-privilege workflow
  permissions, and test offline restart. Why: configuration code executes with
  developer privileges. Rejected: unrestricted moving dependencies in release
  jobs (non-repeatable). Revisit when: an automated dependency updater is
  introduced with its own compatibility gate.
- Documentation: current reality, product intent, architecture, active plan, and
  historical progress have separate canonical owners. Why: future agents and
  users must distinguish plan, present fact, and history. Rejected: one large
  architecture/status essay (rapidly stale); self-scored marketing snapshots
  without artifacts. Revisit when: the repository adopts generated documentation
  with an equivalent authority model.

## System Shape

- Runtime surfaces:
  - root bootstrap and explicit repository paths;
  - LazyVim and upstream-owned plugin lifecycle;
  - Clarity policy deltas for plugins, keymaps, profiles, and platform behavior;
  - Clarity product UI: theme, localized help, actionable notifications;
  - diagnostic CLI/editor adapters;
  - isolated test and release runtime.
- Module boundaries:
  - `bootstrap`: prerequisite and path contracts only;
  - `policy`: product profiles, tool identifiers, platform classification;
  - `plugins`: merge-only plugin deltas and explicitly owned behavior;
  - `services`: pure audit/validation/help models;
  - `ui`: floats, notifications, colors, localization rendering;
  - `tests`: fixtures and behavioral assertions outside the live session.
- Data flow: repository config and lock feed lazy.nvim; resolved LazyVim specs
  receive Clarity deltas; runtime capabilities feed pure reports; UI/CLI adapters
  render reports; CI captures reports and manifests as release evidence.
- Contract sources:
  - plugin versions: tracked root `lazy-lock.json`;
  - LazyVim extras/state: tracked root `lazyvim.json`;
  - supported tool/profile semantics: one Clarity capability manifest/module;
  - translated Clarity strings: stable semantic i18n keys;
  - release claims: CI artifacts bound to a commit/tag.
- Contract drift checks: one-file uniqueness, resolved path assertions, lock
  immutability, resolved plugin spec tests, i18n parity, and docs-current-state
  checks.
- External integrations: Git, supported Neovim artifact, package providers,
  Mason registries, optional Copilot, and GitHub Actions. No application data,
  authentication, remote persistence, or background job system exists.

## Scaffold Plan

Only changed or new areas are listed; the established repository layout remains.

- `init.lua`: stable root entry and repository path contract. Validate with clean
  archive headless startup.
- `lazyvim.json`: tracked, canonical LazyVim state/extras. Validate uniqueness and
  `LazyVim.config.json.path`.
- `nvim/lua/config/lazy.lua`: explicit lock/config ownership and small bootstrap.
  Validate resolved paths and unchanged files.
- `nvim/lua/config/capabilities.lua` (new if implementation confirms the name):
  typed core/development/optional tool ownership. Validate with table-driven Lua
  tests and missing-tool fixtures.
- `nvim/lua/config/{audit,validation,help}.lua`: pure models plus non-destructive
  adapters. Validate repeat invocation and session-state restoration.
- `nvim/lua/plugins/{neo-tree,git,formatting,treesitter,colorscheme}.lua`:
  merge-only deltas. Validate resolved opts and real user behavior.
- `nvim/colors/custom_colorblind_theme.lua`: sole colorscheme lifecycle and
  semantic highlight definitions. Validate resolved contrast and one
  `ColorScheme` event.
- `scripts/`: thin CLI adapters, bounded subprocess execution, manifests, and
  archive harness. Validate Python unit tests and isolated smoke.
- `tests/python/`: Python policy, executable resolution, timeout, JSON, and
  archive-harness tests.
- `tests/lua/`: i18n, capability, scoring, resolved-spec, and state-restoration
  tests run under headless Neovim.
- `.github/workflows/clarity-validate.yml`: static checks and required platform
  matrix. Validate with `actionlint` and successful workflow artifacts.
- `docs/decisions/`: ADRs created as their implementation tasks adopt decisions.
- `docs/product/`, `docs/architecture/`, `docs/reviews/`, `progress/`: canonical
  product, blueprint, evidence, and execution status.

## Migration and Rollout

- Current state to target state: move from implicit local config/cache behavior
  and lifecycle replacement to explicit repository ownership and merged upstream
  contracts.
- Stage 0, evidence freeze: preserve user changes; record committed versus dirty
  lock generations; do not accept a plugin update without its migration tests.
- Stage 1, trust foundation: canonicalize root config/lock paths, introduce
  bounded isolated validation, and correct score semantics. Gate: clean archive
  uses the tracked files and leaves them unchanged.
- Stage 2, first vertical slice: migrate Neo-tree to merged opts while preserving
  the sole-explorer behavior and restoring upstream rename events. Gate: one
  explorer plus real rename propagation.
- Stage 3, core ownership: migrate Mason/LSP/formatter, Gitsigns, validation, and
  colorscheme. Gate: first-session tools, diff navigation, repeat diagnostics,
  and theme lifecycle pass.
- Stage 4, compatibility: choose the supported Tree-sitter generation and update
  configuration plus lockfile atomically. Gate: parser, highlight, indent, fold,
  and selection behavior pass on the required matrix.
- Stage 5, experience: safe install/update/rollback, responsive help,
  platform-aware guidance, accessibility, and primary-surface simplification.
- Stage 6, release: branch protection, green matrix, immutable tag, manifest,
  offline restart, upgrade, and rollback rehearsal.
- Compatibility window: each stage preserves existing public commands and
  primary mappings unless a task explicitly documents a product-approved rename;
  deprecated paths receive one release of guidance where practical.
- Data migration: no application data store exists. Local Neovim state/cache is
  never deleted automatically; tests use isolated directories. Any user-state
  migration must be backup-first and separately approved.
- Rollback: every stage is a reviewable commit/PR. Revert the stage and restore
  its matching lockfile. Release rollback checks out the previous tag and its
  matching local data snapshot.
- Kill switches: optional profiles such as Copilot remain disableable without
  affecting core readiness; release claims can be removed immediately if a
  required platform gate loses green status.
- Rollback signals: config/lock mutation, startup error, missing primary job,
  unsupported Neovim, state-restoration failure, platform matrix failure, or
  accessibility regression beyond the accepted thresholds.

## Implementation Sequence

- Foundation: canonical configuration, honest capability model, isolated test
  harness, exact toolchain, and CI timeouts.
- First vertical slice: Neo-tree ownership and rename behavior, because it proves
  the riskiest rule—extending LazyVim without replacing its lifecycle.
- Core correctness: Mason/LSP/Conform, Gitsigns, diagnostics, and theme ownership.
- Compatibility: Tree-sitter and lockfile migration as one atomic change.
- Experience hardening: safe install, loading/error states, small-terminal help,
  platform-specific guidance, namespace simplification, and accessibility.
- Launch gates: matrix green, offline restart, upgrade/rollback drill, branch
  protection, versioned evidence manifest, and current documentation.

## Verification

- Unit/component tests: platform detection, executable resolution, capability
  classification, score semantics, timeouts, JSON extraction, i18n parity,
  onboarding persistence, and pure report models.
- Contract tests: canonical path and one-file uniqueness, lock immutability,
  resolved plugin opts, upstream config preservation, semantic translation keys,
  and exact required profiles.
- Integration tests: clean first boot, offline restart, explorer count and rename,
  real search, formatter/LSP fallback, fold/wrap, Git diff navigation, repeated
  diagnostics with session restoration, and missing-tool degradation.
- Static checks: `stylua --check`, Lua lint, Python lint/unit tests, `actionlint`,
  JSON/YAML parse, Markdown/link check, and `git diff --check`.
- Platform smoke: explicit supported Neovim on Ubuntu, Windows, and macOS; real
  WSL evidence before WSL remains a release claim.
- Experience checks: help at 60x16 and 80x24; resolved contrast thresholds;
  no color-only Git meaning; measured startup and first-interaction budgets.
- Release smoke: clean tagged archive, zero config/lock mutation, network-blocked
  restart, previous-release upgrade, previous-tag rollback, and attached
  environment/lock/check manifest.

## ADRs to Write

- ADR: Root runtime configuration and lockfile authority. Context/decision: one
  tracked root contract with explicit paths. Rejected: implicit stdpath and dual
  copies. Revisit when: layout permanently becomes a conventional config root.
- ADR: LazyVim lifecycle ownership boundary. Context/decision: upstream owns
  config; Clarity owns mergeable policy deltas. Rejected: copied setup tables.
  Revisit when: an upstream plugin has no extension contract.
- ADR: Capability profiles and readiness semantics. Context/decision: core,
  development, and optional profiles with separate host/feature/release signals.
  Rejected: flat executable score. Revisit when: supported product profiles grow.
- ADR: Tree-sitter compatibility generation. Context/decision: adopt one tested
  generation with atomic lock migration. Rejected: indefinite freeze or mixed
  APIs. Revisit when: the next upstream API migration is required.
- ADR: Verification and release artifact model. Context/decision: clean archive,
  isolated roots, stable check IDs, JSON/JUnit/manifests, and required platform
  gates. Rejected: local-cache and monolithic smoke as release proof. Revisit
  when: distribution packaging changes.
- ADR: Single colorscheme and accessibility contract. Context/decision: standard
  colorscheme lifecycle plus enforceable contrast/non-color gates. Rejected:
  direct theme sourcing and subjective-only claims. Revisit when: multiple
  supported themes are product-approved.

## Risks And Assumptions

- Risks: local caches mask clean-install defects; dirty lock state crosses a major
  API boundary; Windows/WSL behavior is not dynamically available in the current
  workspace; stricter gates may temporarily reduce the list of support claims;
  simplifying surfaces may disrupt power-user habits.
- Assumptions: LazyVim remains the foundation; root install remains the public
  distribution model; macOS, Linux/WSL, and Windows remain desired platforms;
  user state must be backup-first; 95+ means repeatable evidence, not a revised
  scoring formula.
- Revisit triggers: two upgrade cycles require lifecycle replacement; startup or
  first-action latency exceeds budgets; a packaged installer replaces clone
  distribution; user research supports more primary profiles; supported platform
  scope changes.

## Handoff

- Assumptions with defaults: no destructive local-state migration (default:
  backup-only); Copilot is optional (default: not core); one promoted terminal
  path (default: floating terminal); historical docs remain for traceability.
- Open questions: zero blocking. Non-blocking: exact Lua test runner and linter
  may be selected during `QA-001`, defaulting to the smallest maintained tooling
  that works with the supported Neovim/Lua runtime without adding runtime
  dependencies.
- Non-goals: from-scratch distribution, full upstream localization, automatic
  user-state deletion, more plugins, hosted telemetry, or optimization without a
  measured user-facing budget.
- Status: blueprint written to
  `docs/architecture/2026-07-09-clarity-95-refactor-blueprint.md`; the user
  approved this direction on 2026-07-09; numbered execution is defined in
  `progress/2026-07-09-clarity-95-refactor-plan.md` and awaits plan approval.
