# Architecture Blueprint: Agent-Era Clarity Editor Surface

## Summary

- Product goal: reshape Clarity for a workflow in which AI agents perform most
  code generation and broad refactors while people use Neovim to inspect,
  navigate, review diffs, diagnose failures, and make precise corrections.
- Architecture type: existing-system product-surface and dependency refactor.
- Selected stack: retain Neovim 0.12+, LazyVim, lazy.nvim, Snacks, Tree-sitter,
  LSP, Gitsigns, Conform, Neo-tree, which-key, and the Clarity accessibility and
  verification layer; remove editor-embedded AI and redundant provisioning/UI
  implementations.
- Primary constraints: accessibility and high contrast remain product features;
  one obvious path per job; Windows/WSL/Linux/macOS behavior must stay explicit;
  user state is never overwritten; release truth remains evidence-based; no
  hosted telemetry or agent vendor integration enters the runtime.
- Non-goals: no AI chat pane, inline code generation, autonomous editor agent,
  shell framework, maximal language-tool installer, or second explorer/search/
  diagnostics implementation.

## Decisions

- Product role: optimize Neovim as an agent-output review and precision-edit
  console. Why: search, semantic navigation, diff inspection, diagnostics,
  folding, wrapping, and formatting remain valuable after code generation moves
  to agents. Rejected: reducing Clarity to a plain text viewer (loses safe local
  correction and diagnosis); keeping a traditional IDE feature checklist
  (maintains workflows the owner no longer uses). Revisit when: measured use
  shows humans again perform substantial in-editor code generation.
- Embedded AI: remove `copilot.lua`, `CLARITY_COPILOT`, its Node readiness
  profile, documentation, tests, and lock entry. Why: it duplicates the external
  agent workflow and imposes runtime, CI, dependency, key-ownership, and support
  cost without a target user job. Rejected: retaining it as an optional profile
  (an unused option still requires compatibility and security maintenance).
  Revisit when: a concrete offline or latency-sensitive editing job cannot be
  served by the external agent workflow.
- Code intelligence: keep LazyVim-owned LSP, Tree-sitter, completion, snippets,
  and Tree-sitter textobjects, but keep Clarity's customization thin. Why:
  semantic navigation, symbol rename, diagnostics, syntax structure, and small
  corrections are central to reviewing agent output. Rejected: removing all IDE
  intelligence because generation is external (review quality would fall).
  Revisit when: native Neovim/LazyVim replaces a dependency with proven parity.
- Tool provisioning: remove the `CLARITY_PROFILE=development` Mason/parser
  auto-install policy and its curated language lists; retain runtime discovery
  and actionable health reporting. Why: agents and project toolchains should own
  language dependencies, while an editor distribution should report what is
  available without silently changing the host. Rejected: expanding Mason into
  an all-language manager (host mutation and cross-platform burden). Revisit
  when: Clarity ships as a controlled development image with owned toolchains.
- Change review: keep and promote Gitsigns, project search, diagnostics, fold,
  wrap, and formatting as the primary surface. Why: these directly support
  understanding and validating agent changes. Rejected: adding a second diff UI
  or Git client (duplicate mental model). Revisit when: the selected components
  cannot display a required review state accessibly.
- File topology: keep Neo-tree as the sole explorer and Snacks as the sole
  picker. Why: agent-produced changes often span unfamiliar files and require
  both topology and fast query navigation. Rejected: file-tree removal (hurts
  structural review) and adding Oil/Snacks Explorer (duplicates ownership).
  Revisit when: usage evidence proves one of the two navigation models unused.
- Terminal: preserve one floating terminal job but remove the dedicated
  ToggleTerm dependency if the already-required Snacks terminal passes shell,
  cwd, sizing, reuse, terminal-map, and platform parity. Why: occasional test,
  Git, and recovery commands remain necessary, but a second terminal framework
  is unjustified. Rejected: no in-editor terminal (weakens recovery) and keeping
  ToggleTerm by default (extra lifecycle and dependency). Revisit when: Snacks
  loses required Windows/WSL/SSH behavior.
- Presentation: remove Noice if native Neovim messages plus Clarity's structured
  diagnostic log pass notification, command-line, long-message, and error
  visibility tests. Why: Noice is a second presentation layer and pulls `nui`;
  structured diagnostics already own truth. Rejected: immediate deletion without
  attached-UI parity evidence. Revisit when: native rendering creates a proven
  accessibility regression.
- Markup automation: disable `nvim-ts-autotag` unless repository evidence shows
  it serves a promoted review or precision-edit job. Why: automatic tag mutation
  targets sustained manual web authoring, not review-first work. Rejected:
  retaining inherited plugins without a named job. Revisit when: Clarity adopts
  manual HTML/JSX authoring as a primary workflow.
- Human guidance: retain bilingual, accessible help but consolidate the current
  `ClarityStart`, `ClaritySync`, `ClarityClipboard`, `ClarityAudit`,
  `ClarityValidate`, and `ClarityLog` surface into one user-facing health/help
  entry with subviews; keep CLI verification commands for agents and automation.
  Why: the current concepts span more than 2,000 Lua lines and expose maintainer
  mechanics to users. Rejected: deleting recovery and Chinese UI (contradicts
  accessibility and product identity). Revisit when: usability tests show
  separate commands are faster or clearer.
- Localization implementation: retain English/Chinese output but replace
  callback-rewriting and duplicated prose structures with declarative message
  catalogs and stable action IDs. Why: localization is user value; mapping
  recreation and large mirrored tables are maintenance cost. Rejected:
  English-only UI (product regression). Revisit when: another localization
  runtime can reduce code without changing startup or adding a heavy dependency.
- Agent contract: do not embed a model provider. Treat repository scripts,
  machine-readable JSON reports, stable failure IDs, repair commands, and
  `docs/ai` as the agent API. Why: this is provider-neutral, testable, and useful
  to Codex or future agents. Rejected: MCP/model SDK inside Neovim (lock-in and
  runtime complexity). Revisit when: an editor-local protocol has a concrete,
  provider-neutral job and security model.
- Testing: retain behavior-first copied-candidate tests and add removal parity
  contracts for every deleted surface. Why: an agent-era editor must make broad
  automated changes safe to review. Rejected: plugin-count or mapping-existence
  tests alone (do not prove experience). Revisit when: Neovim exposes stronger
  native interaction contracts.
- CI/CD and deploy: after Copilot removal, remove Node installation and Node
  provider expectations from the required matrix unless another promoted job
  needs them; keep pinned Neovim, Python test tooling, clean roots, immutable
  actions, and platform-separated evidence. Why: CI should model the product,
  not optional historical integrations. Rejected: weakening platform gates to
  make removal green. Revisit when: a required feature gains a Node runtime.
- Observability: keep bounded local structured diagnostics, redaction, and JSON
  export; reduce duplicate audit/validation collectors rather than removing the
  trust layer. Why: agent-authored changes increase the need for deterministic
  evidence. Rejected: hosted telemetry (outside product boundary) and deleting
  diagnostics (makes regressions manual). Revisit when: one passive collector
  cannot support both human and automation views.
- Documentation: this blueprint becomes the authority for agent-era surface
  decisions after approval; implementation updates the product PM, current
  reality, dependency manifest, README, guide, ADR-0002/0005 successors, and a
  dated closeout. Why: runtime and product claims must agree. Rejected: editing
  only README marketing copy. Revisit when: the target user workflow changes.

## System Shape

- Runtime surfaces: a review-first editing UI; one file picker; one tree; one
  diff/hunk layer; one formatting path; one terminal; one help/health entry; and
  provider-neutral CLI verification for agents.
- Module boundaries: LazyVim owns plugin lifecycles; `plugins/` contains only
  product deltas and explicit exclusions; `config/actions/` owns typed user
  actions; one passive health model owns findings; renderers expose that model to
  Neovim, CLI JSON, and sanitized logs; localization maps stable IDs to text.
- Data flow: runtime facts and typed action outcomes enter the passive health/
  diagnostics model; Neovim and CLI render the same stable IDs; behavior tests
  exercise real input in isolated copies; no report mutates the inspected
  session.
- External integrations: Git and ripgrep remain core; compilers, language
  servers, formatters, clipboard providers, and Tree-sitter CLI are discovered
  capabilities; no Copilot/Node integration is supported by Clarity.
- Background jobs/events: lazy.nvim update checking remains interactive-only;
  no background Mason/parser installation, AI completion request, hosted
  telemetry, or validation lifecycle replay.

## Scaffold Plan

- Changed paths only: remove `nvim/lua/plugins/copilot.lua`; replace
  `plugins/toggleterm.lua` with a Snacks terminal delta after parity; simplify
  `plugins/tooling.lua` and `plugins/treesitter.lua` to ownership-only deltas or
  remove them if empty; add Noice/autotag exclusions only after their parity
  gates; consolidate health/help modules without changing stable report IDs.
- Required config files: root `init.lua`, `lazy-lock.json`, and `lazyvim.json`
  remain the only runtime authorities.
- Core modules: typed fold/wrap/terminal/search actions; passive capability and
  health model; structured diagnostics; declarative i18n catalogs and renderers.
- Contract/generated files: JSON report schema and stable finding/action IDs are
  handwritten authorities; no generated model-provider contract is introduced.
- Test locations: Lua policy tests in `tests/lua`; lifecycle/behavior fixtures in
  `tests/contracts`; orchestration and schema tests in `tests/python`.
- Local validation commands: `python3 scripts/run_clarity_tests.py fast`, copied
  candidate contracts/behavior/faults, check-only lock normalization, and the
  full local release router.
- CI workflows: keep `.github/workflows/clarity-validate.yml`, deleting Node
  setup only when the resolved runtime and audit contain no required Node job.
- Deployment artifacts: N/A — clone-based Neovim configuration; release
  artifacts remain machine-readable validation evidence.

## Migration and Rollout

- Current state → target state: 26 lock entries and several optional/historical
  workflows become a smaller review-first runtime with no embedded AI, no
  editor-owned language-tool provisioning, and fewer duplicate UI frameworks.
- Staged rollout plan with stage gates: first remove Copilot end to end; then
  remove development-profile provisioning; then replace ToggleTerm; then test
  and remove Noice/autotag; finally consolidate help/health/i18n. Each stage
  leaves the repository runnable and receives its own lock review where needed.
- Compatibility window: none for Copilot because the owner explicitly removes
  the product job; keep `<leader>tf` behavior while terminal ownership changes;
  keep stable health finding IDs and old command aliases for one documented
  release while the unified health/help entry is introduced.
- Data migration order and dry-run plan: no user data migration. Preserve
  onboarding, locale, and diagnostics state. Run every lock change against a
  copied candidate before source replacement and retain exact backup bytes.
- Rollback procedure per stage: restore the stage commit and lock backup, rerun
  copied-candidate first boot/restart and behavior contracts, and confirm user
  state roots were untouched.
- Kill switches or flags: no Copilot kill switch remains; terminal replacement
  may use a temporary implementation flag only during local parity testing and
  must not ship as two public paths.
- Observable signal that triggers rollback: startup failure; authority drift;
  required health failure; lost search/diff/LSP/format/fold/wrap behavior;
  inaccessible messages; terminal shell/cwd/reuse failure; or unexplained
  platform divergence.

## Implementation Sequence

- Foundation: adopt the review-first job inventory and measurable surface
  budgets; record resolved plugin/key/command ownership before removal.
- First vertical slice: remove Copilot, Node profile logic, documentation, test
  fixtures, CI setup, and lock pin in one atomic change. This exercises the
  riskiest rule: optional historical features must disappear end to end rather
  than leave readiness and documentation ghosts.
- Hardening: remove provisioning policy; prove Snacks terminal parity; evaluate
  Noice and autotag with attached-UI/markup fixtures; consolidate passive health
  and localization without changing stable evidence contracts.
- Launch gates: clean copied-candidate first boot and offline restart; unchanged
  authority hashes; macOS and available Ubuntu behavior evidence; Windows/WSL
  explicitly pending until actually tested; no GitHub Actions run without
  separate authorization; dependency manifest and rollback evidence current.

## Verification

- Unit/component tests: product exclusions, no Copilot/Node/profile references,
  stable action/finding IDs, declarative locale parity, terminal adapter policy,
  and dependency-lock separation.
- API/contract tests: JSON audit/diagnostic schemas; passive collection; exact
  runtime authority paths; no background installation or network AI requests.
- Integration/E2E tests: real search, diff/hunk navigation, LSP attach/no-attach,
  formatting/fallback, fold/wrap, one explorer, one terminal, native-message
  visibility, small-screen help, clipboard modes, and state restoration.
- Build/type/lint checks: Python unit tests and Ruff; Lua policy tests and
  StyLua; Actionlint; JSON parse; documentation path/link scan; `git diff
  --check`.
- Deployment smoke: copied clean candidate first boot, cache-backed offline
  restart, empty/file/directory/attached-UI scenarios, authority-hash immutability,
  and rollback rehearsal for lock changes.
- Observability checks: typed failures appear once with stable ID, impact,
  recovery, and recheck; logs remain bounded and redacted; removed profiles
  produce no warnings or readiness deductions.

## ADRs to Write

- ADR: External agents own code generation. Context/decision: Clarity removes
  embedded Copilot and exposes provider-neutral verification contracts.
  Rejected: optional Copilot and editor AI panes. Revisit when: a concrete job
  requires editor-local inference.
- ADR: Review-first core surface. Context/decision: search, topology, semantic
  navigation, diffs, diagnostics, folding, wrapping, formatting, and recovery
  define the core. Rejected: traditional IDE checklist and plain viewer.
  Revisit when: measured user work changes.
- ADR: Project toolchains own language provisioning. Context/decision: Clarity
  detects LSP/formatter/parser capabilities but does not auto-install curated
  development profiles. Rejected: Mason-managed global toolchain. Revisit when:
  Clarity owns a controlled development image.
- ADR: One presentation and terminal implementation. Context/decision: prefer
  native/required-stack capabilities after parity over Noice/ToggleTerm.
  Rejected: parallel implementations. Revisit when: accessibility or platform
  parity regresses.
- ADR: Unified passive health model. Context/decision: one model feeds human UI,
  CLI JSON, and logs while stable IDs remain compatible. Rejected: separate
  mutable Audit/Validate collectors. Revisit when: consumer requirements truly
  diverge.

## Risks And Assumptions

- Risks: “vibe coding” can be over-applied and remove review safeguards; inherited
  LazyVim dependencies may be transitive; native message/terminal behavior may
  differ on Windows/WSL/SSH; consolidating i18n/health can create a large-bang
  rewrite; plugin-count reduction alone can be mistaken for UX improvement.
- Assumptions: external agents remain the primary generation workflow; users
  still inspect and correct code in Neovim; Chinese UI and accessibility remain
  required; Git/ripgrep are core; release evidence rules remain unchanged; the
  default for uncertain removals is parity testing before deletion.
- Revisit triggers: agent workflow changes, target users request sustained manual
  authoring, LazyVim changes its core package model, native Neovim gains proven
  parity, or measured startup/interaction evidence contradicts the expected win.

## Handoff

- Assumptions with stated defaults: Copilot removal is approved by the owner;
  other removals require the blueprint sequence and parity gates; no GitHub CI is
  authorized; no user state migration is needed.
- Open questions: zero blocking. Default: keep review and accessibility features;
  remove generation/provisioning duplication; replace dependency-owning UI only
  after equivalent behavior is proven.
- Non-goals: no implementation, task IDs, lock mutation, or CI run occurs at this
  Architecture Gate.
- Status: approved and implemented locally through
  `progress/2026-07-10-agent-era-review-console-plan.md`; Noice remains under the
  blueprint's parity rule because native messages failed the attached fault gate;
  available-host and release evidence remain pending.
