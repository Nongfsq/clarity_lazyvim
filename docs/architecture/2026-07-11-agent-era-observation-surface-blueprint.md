# Architecture Blueprint: Agent-Era Observation Surface

Date: 2026-07-11

Status: approved and implemented locally on 2026-07-11; execution evidence and
remaining platform gates are tracked in
`progress/2026-07-11-agent-era-observation-surface-plan.md`.

## Summary

- Product goal: make Clarity a calm, bilingual review and precision-edit console
  for code produced primarily by external agents. The editor should reveal files,
  structure, diagnostics, diffs, history, and recovery without advertising
  repository mutation or maintainer workflows.
- Architecture type: existing-system product-surface, interaction, and dependency
  refactor.
- Selected stack: retain Neovim 0.12+, LazyVim, lazy.nvim, Snacks, Neo-tree,
  Tree-sitter, LSP, blink.cmp, Conform, Gitsigns, which-key, lualine, and the
  Clarity accessibility/diagnostic layer. Add no Git client or AI provider.
- Primary constraints: external agents own broad code and repository mutation;
  Clarity owns observation, navigation, small code corrections, accessibility,
  bilingual presentation, and deterministic evidence. LazyVim keeps lifecycle
  ownership. User state and unrelated lock changes are never overwritten.
- Non-goals: no staging, resetting, committing, pushing, pulling, merging,
  rebasing, stashing, PR/issue management, lazygit, embedded AI generation,
  editor-owned global toolchain, background update checking, second explorer,
  second picker, or second diagnostics dashboard.

The central approval-time conclusion was not that every inherited feature was
bad. It was that the reviewed runtime dependency set was already relatively
small while the public
interaction surface still behaves like full LazyVim. Clarity cannot meet a 95+
experience bar while an attached file can expose roughly 144 normal-mode leader
actions before a fully capable LSP is added, live language switching leaves menu
metadata stale, Git mutation remains one keystroke away, and project formatting
policy can be overridden globally.

### Approval-Time Evidence Boundary

All uses of “current” in the baseline and decision analysis below refer to the
review commit, not the implemented runtime. Implementation truth lives in the
active PLAN+TASK and dated implementation review.

- Review commit: `c7f80052362860c2500327cb00365754c5f7997e` on `main`.
- Review method: source inspection, locked-upstream inspection, headless runtime
  probes, natural attached-UI probes, Git-buffer probes, and existing contract
  test review.
- The source tree already had an unrelated `lazy-lock.json` drift before this
  document was written. The drift changes only `gitsigns.nvim`
  (`25050e4` -> `eb60cc7`) and `neo-tree.nvim` (`a3adf0a` -> `b01ee17`).
  This blueprint does not accept, restore, normalize, stage, or otherwise modify
  those bytes.
- Current results are local macOS evidence. They do not certify Windows, WSL,
  GitHub Actions, or a release artifact.
- The exact per-key and component-local decisions are recorded in
  [`../reviews/2026-07-11-keymap-surface-decision-report.md`](../reviews/2026-07-11-keymap-surface-decision-report.md).
  Its counter-audit found that the locked Snacks Git pickers and Neo-tree Git
  source expose mutation controls internally. This blueprint incorporates that
  correction; a view is not read-only merely because its opening key is named
  status, diff, log, blame, or branches.

### Approval-Time Runtime Surface Evidence

| Observation | Approval-time result | Product implication |
| --- | ---: | --- |
| Locked and resolved enabled plugins | 23 / 23 | Plugin count is not the main UX problem |
| Plugins loaded during empty headless startup | 4 | Lazy loading is materially improved |
| Empty attached UI, normal global leader maps | 132 | Still far above a curated product surface |
| Tracked-file attached UI, normal global leader maps | 133 | File startup adds another global path |
| Tracked Git buffer, buffer-local leader maps | 11 | The effective union reaches 144 |
| Lua Git+`lua_ls` buffer, buffer-local leader maps | 20 | The observed effective union reaches 153 |
| Largest global groups in the file lifecycle | search 31, toggle 25, Git 17, find 15 | Most menu density is inherited utility surface |
| Prior full-capability LSP/Git probe | approximately 152 normal leader entries | Independent context evidence agrees that capability makes the menu denser |
| Neo-tree / one files picker local map rows | 70 / 134 | Hidden component context is larger than the curated target |
| Clarity runtime service code | 2,651 lines across 8 modules | Human recovery and localization remain fragmented |

The 2,651-line service surface is composed of `audit.lua` (690), `i18n.lua`
(626), `help.lua` (504), `diagnostics.lua` (287), `menu_i18n.lua` (233),
`validation.lua` (149), `commands.lua` (119), and `health.lua` (43). Line count
alone is not a deletion reason; it shows that one human entry still routes to
several separately rendered concepts.

### Interaction Findings

1. **The menu is inherited-first rather than product-first.** Search has 31
   actions, toggles have 25, Git has 17, and find has 15. Profiler, scratch,
   tabs, plugin management, changelog, colorschemes, internal inspection,
   notification history, specialist lists, GitHub workflows, and multiple
   duplicate search/explorer/terminal paths are all discoverable beside daily
   work.
2. **Duplicate paths weaken memory.** File search, text search, buffers,
   explorer, terminal, diagnostics, quickfix/location lists, zoom, and messages
   each have multiple aliases. A newcomer cannot know which path is the product
   contract and which is inherited compatibility.
3. **The empty-start dashboard is maintainer-oriented.** It still promotes
   Config and Lazy Extras even though editor configuration and dependency work
   now belong to agents. The dashboard adds little dependency cost because
   Snacks is required, but it adds visible product noise.
4. **Clarity exposes eight human commands.** `ClarityHealth` is currently a thin
   router to Start, Audit, Validate, Clipboard, Log, Sync, and Language rather
   than one model with one renderer. Machine-readable CLI/report contracts are
   valuable; seven overlapping human concepts are not.

### Git Findings And Approved Product Boundary

The owner does not intend to mutate repositories from Neovim. Codex or another
external agent normally owns staging, resets, commits, branches, pushes, pulls,
merges, rebases, and PR work. Clarity's Git job is therefore observation only:

- inspect working-tree status and changed files;
- inspect a diff and navigate/preview hunks;
- inspect recent commits;
- inspect a decorated branch graph;
- inspect blame/provenance when useful.

The current `nvim/lua/plugins/git.lua` extends upstream `on_attach` and installs
stage hunk, reset hunk, stage buffer, reset buffer, and undo-stage mappings. It
also duplicates several mappings already supplied by LazyVim's Gitsigns
attachment. LazyVim contributes GitHub, browse, status, log, stash, and related
entries. Keeping all of these contradicts the approved workflow even when the
underlying Gitsigns dependency remains valuable.

The product boundary applies to promoted mappings, menus, dashboard actions,
help, and Clarity-owned commands. It does not attempt to censor arbitrary Ex
commands exposed by upstream plugins or prevent an expert from opening a shell.
Git also remains an installation transport for lazy.nvim and plugin checkouts;
that infrastructure role is distinct from repository-authoring UX.

### Localization Findings

- Chinese startup can translate most inherited menu metadata, but the current
  approach keys translations by exact upstream English descriptions. An
  upstream wording change silently creates an English leak.
- `config.i18n.set_choice()` recomputes locale state but emits no locale-change
  event. A direct probe changed the effective locale to `zh` and observed zero
  `User ClarityLocaleChanged` events.
- `config.menu_i18n.setup()` applies only on `User VeryLazy`; it does not respond
  to `:ClarityLanguage zh` during the same session.
- `register_keymap_labels()` scans only global normal/visual maps. It does not
  cover buffer-local LSP and Gitsigns maps, which are exactly where contextual
  Code and Git menus grow.
- Command descriptions and already-open help buffers are created in the old
  locale. Switching back to English can also leave Chinese which-key metadata
  behind.

The correct fix is not a larger English-to-Chinese string table. It is a smaller
public action catalog keyed by stable action IDs, plus a locale-change event and
scope-aware presentation adapters.

### Dependency And Policy Findings

| Surface | Evidence | Decision |
| --- | --- | --- |
| Mason + mason-lspconfig | Both remain resolved. Clearing `mason.nvim.ensure_installed` removes Stylua/Shfmt defaults but LazyVim still derives `lua_ls` for mason-lspconfig installation. | Remove only after system/project-owned LSP attach and missing-server recovery parity pass. |
| Tree-sitter policy file | `ensure_installed = {}` prevents LazyVim's curated parser installation list. | Keep the policy, but move it into a declarative no-provisioning registry; deleting it alone would restore background installs. |
| Gitsigns delta | 63 lines duplicate upstream attach mappings and add mutation actions. | Keep Gitsigns; delete duplicate/mutating Clarity ownership. |
| Conform delta | Runtime discovery and LSP fallback are sound, but global 4-space, 120-column, LF, Black/isort, and Prettier arguments override project taste. | Keep formatter routing; remove global style arguments and honor project configs/tool defaults. |
| lazy.nvim checker | Enabled for real UI startup. Checking performs background maintenance work unrelated to review. | Default off; dependency updates are explicit agent/maintainer transactions. |
| Lush | Eager and used only to generate roughly 25 highlight groups. | Convert accepted colors to static `nvim_set_hl`/colorscheme definitions with contrast parity, then remove Lush. |
| Noice | Native-message removal already failed the attached raw-fold fault visibility gate. | Keep until the known fault gate passes; plugin-count pressure is not evidence. |
| `nui.nvim` / `plenary.nvim` | Transitive requirements of retained UI/explorer functionality. | Keep while their owners remain. |
| friendly-snippets | About 2.9 MB in this local checkout and loaded only for insertion/completion work. | A/B test completion and small-edit quality; remove if LSP snippet expansion remains sufficient. |
| lazydev.nvim | Narrow Lua/Neovim development value. | Keep only if Clarity explicitly supports editing Neovim Lua as a promoted precision-edit job; otherwise make it an external profile or remove. |
| mini.pairs / ts-comments | Small, lazy, and useful during precision correction. | Keep unless real edit fixtures show unwanted mutation. |

Local checkout size is diagnostic context, not a runtime-cost score. Snacks is
the largest checkout but owns several retained jobs; deleting it because of disk
size would increase duplication elsewhere.

### Keep, Remove, And Gate

| Classification | Surface |
| --- | --- |
| Keep as core | LazyVim/lazy.nvim; Snacks picker/terminal; Neo-tree; Tree-sitter and textobjects; LSP; blink completion; Conform; Gitsigns signs/navigation/preview; which-key; lualine; mini.icons; fold/wrap; absolute line-number default; bilingual health/recovery |
| Remove from the public surface | Git stage/reset/undo/commit/push/pull/merge/rebase/stash/PR/issue/browse/lazygit paths; profiler; scratch; full tab group; Lazy/Changelog/Mason shortcuts; plugin-spec/autocmd/highlight/icon/man/inspect utilities; most toggle and specialist search menus; duplicate explorer/search/buffer/terminal/list/message aliases |
| Fix before removal | live locale switching; action identity; buffer-local translations; project formatting ownership; Mason auto-install path; background checker; current lock drift diagnosis |
| Remove after parity | Mason and mason-lspconfig; Lush; friendly-snippets and lazydev only if their named behavior gates pass |
| Keep behind a known blocker | Noice; `nui.nvim` while Neo-tree/Noice require it; any review/accessibility dependency whose native replacement fails attached UI |

## Decisions

- Product role: Clarity is an observation-first review and precision-edit console.
  Why: agents perform broad mutation while humans still need a trustworthy place
  to understand and correct output. Rejected: a traditional in-editor IDE/Git
  workstation (duplicates Codex) and a plain viewer (loses diagnostics and safe
  correction). Revisit when: sustained human authoring or repository mutation in
  Neovim becomes a measured primary job.
- Git contract: public Git actions are read-only observations. Why: status,
  diffs, history, branch topology, and provenance help review; stage/reset/
  commit/push/pull/merge/rebase/stash and forge workflows do not. Rejected:
  hiding mutation under an "advanced" group (still discoverable and maintained)
  and removing all Git awareness (weakens review). Revisit when: the owner adopts
  a concrete in-editor repository-mutation workflow.
- Git implementation: retain Gitsigns for signs, hunk navigation, preview, and
  blame; wrap or replace Snacks status/diff/log pickers so confirm and local
  keys cannot stage, restore, or checkout; disable Neo-tree's Git source; and
  add one typed, bounded branch-graph action implemented with argument-vector
  `git log --graph --decorate --oneline --all`. Why: it covers the approved job
  without a new client or hidden write path. Rejected: using the locked Snacks
  Git pickers or branch picker unchanged;
  lazygit/gitui/Fugitive (new mutation-heavy surface) and raw shell strings
  (quoting, security, and testability cost). Revisit when: accessible branch
  topology cannot be rendered with the retained stack.
- Git execution policy: Clarity-owned read actions use explicit argv, repository
  cwd, bounded output, no shell interpolation, and `GIT_OPTIONAL_LOCKS=0` where
  supported. Why: a read-only product should avoid optional index refresh writes
  and command injection. Rejected: accepting arbitrary Git subcommands from a UI
  prompt. Revisit when: Git changes the relevant portable invocation contract.
- Action source of truth: add one declarative product-action catalog with stable
  ID, job, modes, scope, keys, owner, mutability class, English/Chinese label
  keys, and public/compatibility status. Why: mappings, which-key, help, tests,
  and localization currently infer product intent independently. Rejected:
  translating exact upstream descriptions and maintaining unrelated allow/deny
  lists. Revisit when: LazyVim exposes a stable semantic action registry.
- Keymap policy: explicitly disable inherited keys that are outside the catalog;
  do not merely hide them from which-key. Target at most 35 global normal leader
  actions and at most 45 in the fullest Git+LSP buffer; the per-key audit's
  current concrete target is 28 and 35 respectively. Why: hidden callable
  aliases still create collisions and maintenance. Rejected: retaining all
  LazyVim keys and curating only labels. Revisit when: observed user jobs require
  a larger surface and can name the added value.
- Localization: emit `User ClarityLocaleChanged` after a successful choice,
  re-render which-key metadata and open Clarity views immediately, and attach
  buffer-local labels from stable action IDs. Why: language selection must work
  without restart and must include contextual Code/Git entries. Rejected:
  restart-only semantics and English-description lookup. Revisit when: Neovim/
  which-key provides a stronger native locale contract.
- Human command surface: promote only `:ClarityHealth` and
  `:ClarityLanguage`; expose overview, recovery, clipboard, diagnostics, and log
  views inside Health. Preserve machine CLI/JSON contracts and keep old Ex
  commands as thin, unpromoted compatibility aliases for one release. Why:
  humans need one memorable recovery path while agents need stable IDs. Rejected:
  deleting evidence systems and continuing to advertise eight peer commands.
  Revisit when: measured navigation shows a separate command is faster and more
  understandable.
- Formatting policy: keep Conform routing and LSP fallback, but allow project
  configuration and formatter defaults to own style. Why: global 4-space and
  120-column arguments can create large unrelated agent-review diffs. Rejected:
  editor-wide style enforcement. Revisit when: Clarity owns a single repository
  with an explicit formatter policy.
- Toolchain policy: project environments and agents install language servers,
  formatters, and parsers; Clarity detects and reports. Disable Mason and
  mason-lspconfig only after direct system-server attach/no-attach parity is
  proven. Keep the Tree-sitter no-install override. Why: current Mason policy
  does not completely stop LSP installation. Rejected: background global
  provisioning and removing LSP intelligence. Revisit when: Clarity ships an
  owned development image.
- Product exclusions: preserve LazyVim `enabled = false` sentinels because they
  are the correct override mechanism, but generate them from one reviewed policy
  registry with reason and revisit trigger. Why: the mechanism is necessary;
  scattered anonymous entries are not. Rejected: deleting sentinels (re-enables
  inherited products) and carrying disabled lock pins (false runtime authority).
  Revisit when: upstream no longer imports a listed plugin.
- Dashboard and maintenance: reduce empty-start actions to files, text search,
  recent files, new file, Health, and quit; remove Config and Lazy Extras
  promotion. Disable the lazy.nvim checker by default and remove maintenance
  shortcuts from the product menu. Why: agents own configuration and dependency
  updates. Rejected: removing Snacks solely to remove its dashboard. Revisit
  when: maintainers become a first-class runtime audience.
- Dependency selection: remove a dependency only when its named job disappears
  or an existing/native implementation passes behavior and accessibility parity.
  Why: plugin-count theater can make a smaller but worse product. Rejected:
  deleting Noice despite a reproduced fault-visibility failure. Revisit when:
  the blocking fixture passes on required hosts.
- Testing: treat the action catalog, mutability classification, surface budgets,
  locale refresh, and read-only Git fixture as release contracts. Why: source
  review alone cannot catch lifecycle growth or upstream key changes. Rejected:
  mapping-existence and plugin-count tests alone. Revisit when: stronger native
  semantic contracts become available.
- Documentation: this blueprint supersedes the Git-mutation and broad-menu parts
  of the 2026-07-10 agent-era blueprint after approval. Product PM, PLAN+TASK,
  current reality, README, Chinese guide, dependency manifest, ADR-0006, and the
  documentation index update during planning/execution rather than being
  retroactively marked implemented now. Why: proposed behavior and current
  behavior must remain distinguishable. Rejected: editing public claims before
  runtime parity exists. Revisit when: the blueprint is rejected or materially
  changed.

## System Shape

- Runtime surfaces:
  - one file picker and one explorer;
  - one project-text search path;
  - one code-review surface for diagnostics, symbols, format, fold, and wrap;
  - one Git observation surface for status, diff, recent history, branch graph,
    blame, hunk navigation, and preview;
  - one terminal escape hatch;
  - one human Health entry and one Language command;
  - provider-neutral CLI/JSON evidence for agents.
- Module boundaries:
  - `config.product_policy`: plugin exclusions, public action budget, and
    product-level non-goals;
  - `config.actions.catalog`: stable action metadata, keys, locale keys, scope,
    owner, and mutability;
  - `config.actions.git`: bounded read-only Git observations and typed outcomes;
  - `config.keymaps`: materializes only Clarity-owned actions and explicit
    upstream disable specs;
  - `config.menu_i18n`: presentation adapter over action IDs, not English prose;
  - `config.i18n`: locale state, catalogs, and `ClarityLocaleChanged` event;
  - `config.health`: one human router over passive findings and diagnostics;
  - LazyVim/upstream remains lifecycle owner for retained plugins.
- Data flow: catalog entries materialize key specs and help/menu labels; a locale
  change re-renders presentation without changing callback identity; read-only
  Git actions produce typed results into scratch/picker views and diagnostics;
  tests compare repository refs/status before and after each observation.
- External integrations: Git and ripgrep remain required; language servers,
  formatters, parsers, compilers, and clipboard providers are discovered. No
  forge API, model provider, hosted telemetry, Mason registry mutation, or
  background update service is part of the product path.
- Background jobs/events: lazy plugin loading and passive diagnostics remain;
  locale refresh is event-driven; no lazy.nvim checker, Mason/parser installer,
  AI request, or repository-mutation job starts in normal use.

### Target Public Action Catalog

| Job | Promoted surface |
| --- | --- |
| Find/navigate | `<leader>ff`, `fw`, `fb`, `fr`, `e`, `E` |
| Review/edit | `<leader>cf`, `cz`, `uw`, `sd`; dynamic `uF`, `uh`, `ca`, `cr`, `ss`, `sS`; native `gd`, `gr`, `K`, `[d`, `]d`, `gc`, `gcc` |
| Git observation | `<leader>gs`, `gd`, `gl`, `gt`, `gb`, `ghp`; `[h`, `]h` |
| Windows | `<leader>-`, `|`, `wd`, `wm`, `wo`; `Ctrl-h/j/k/l` |
| Session/recovery | `<leader>tf`, `hh`, `?`, `sk`, `qq`, `xq`, `fn`; `Ctrl-s` |
| Wrapped editing | visual-line-aware `j`/`k`; absolute line numbers and visual wrap remain defaults |

Exact keys remain subject to collision tests, but the jobs and one-path rule are
fixed. Native Neovim 0.12 LSP actions such as `gra`, `grn`, and `grr` remain
available without being duplicated into the leader menu.

### Explicit Default-Key Removals

- Code: injected-language format, line-diagnostic alias, Mason, LSP info,
  codelens, source action, organize imports, and other capability-specific
  expert entries unless they receive a named job.
- Git: all mutation, GitHub, remote browse/copy, lazygit, stash, and duplicate
  hunk actions; all mutation keys and checkout confirms inside retained Git
  views; the Neo-tree Git source itself.
- Search: all specialist `s*` entries except diagnostics/keymap discovery and a
  deliberately selected list path.
- Toggle: all `u*` entries except wrap and the one buffer-local autoformat
  recovery toggle if testing proves it necessary. Line-number toggles conflict
  with the absolute-number product contract.
- Maintenance: profiler, Lazy, changelog, plugin spec, autocmd, highlight, icons,
  man pages, syntax-tree inspection, colorscheme switching, config search,
  dashboard Lazy Extras, and notification internals.
- Layout: the full leader Tab group, duplicate buffer navigation, scratch
  buffers, duplicate terminal layouts, and duplicate zoom/list/message paths.

## Scaffold Plan

- Directory structure: preserve the current root/nested runtime layout until the
  already-approved root-runtime migration closes. Add no new top-level package.
- Required changed/new runtime paths after approval:
  - `nvim/lua/config/product_policy.lua`: declarative plugin exclusions and
    surface budgets;
  - `nvim/lua/config/actions/catalog.lua`: stable action metadata;
  - `nvim/lua/config/actions/git.lua`: read-only Git observation actions;
  - `nvim/lua/config/{keymaps,menu_i18n,i18n,commands,health,help,lazy}.lua`:
    consume the new contracts and remove duplicate presentation;
  - `nvim/lua/plugins/{git,formatting,minimal,tooling,treesitter,colorscheme,ui}.lua`:
    thin ownership, exclusions, formatting policy, dependency gates, and a calm
    dashboard;
  - `nvim/colors/custom_colorblind_theme.lua`: static highlights after contrast
    parity, enabling Lush removal.
- Contract files:
  - action IDs and mutability classes are handwritten source of truth;
  - localized label keys must have exact English/Chinese parity;
  - product exclusions must resolve to upstream specs or be deleted as stale;
  - `lazy-lock.json` changes only in isolated, backup-first dependency commits.
- Test locations:
  - `tests/lua/test_action_catalog.lua` for uniqueness, budgets, key collisions,
    mutability, locale parity, and exclusion policy;
  - `tests/lua/test_menu_i18n.lua` for live `en -> zh -> en`, callback identity,
    and global/buffer metadata refresh;
  - `tests/lua/test_git_observation.lua` for argv allowlist and typed outcomes;
  - update `test_gitsigns_config.lua`, `test_keymap_ownership.lua`,
    `test_external_toolchain_policy.lua`, `test_formatting_ownership.lua`,
    `test_theme_contract.lua`, and dependency policy tests;
  - add disposable Git/LSP/attached-UI behavior fixtures under existing contract
    and Python orchestration locations.
- Local validation commands: `python3 scripts/run_clarity_tests.py fast`, then
  `contracts`, `behavior`, `faults`, and `release`; check-only lock
  normalization; direct Markdown path/link scan; `git diff --check`.
- CI workflows: no change or execution is implicit. Existing workflow updates
  only if implementation removes a runtime requirement. GitHub Actions remains
  separately authorized.
- Deployment artifacts: N/A — Clarity is clone-distributed. Copied-candidate
  evidence and exact lock backups remain the release artifacts.

## Migration and Rollout

- Current state -> target state: a 23-plugin, 133-global-key file lifecycle with
  broad inherited menus becomes an observation-first product with at most 35
  global and 45 full-context leader actions, immediate bilingual presentation,
  no promoted Git mutation, project-owned formatting style, no background update
  checker, and fewer dependencies only where parity passes.
- Stage 0, evidence quarantine: preserve the current `lazy-lock.json` bytes;
  record its two-pin drift separately; generate reproducible empty/file/Git/LSP
  surface manifests without normalizing or updating dependencies.
- Stage 1, contract first: introduce the action/product-policy catalogs, stable
  IDs, budgets, mutability classes, and live locale event while preserving
  existing callbacks.
- Stage 2, first vertical slice: implement the complete Git observation job,
  including branch graph, then remove all promoted Git mutation and duplicate
  Gitsigns mappings. This exercises the riskiest product decision end to end.
- Stage 3, interaction reduction: explicitly disable inherited key noise,
  simplify dashboard and human commands, and remove global formatter style
  arguments. Verify daily jobs after each batch.
- Stage 4, dependency reduction: disable Mason/mason-lspconfig after direct LSP
  parity; convert the theme and remove Lush; run completion A/B before deciding
  friendly-snippets/lazydev. Keep Noice while the known failure remains.
- Stage 5, truth and release: perform each accepted lock transaction separately,
  update public/AI docs and ADRs, run copied-candidate local evidence, deploy to
  available Ubuntu only when requested, and leave Windows/WSL explicit.
- Compatibility window: old Clarity human commands remain unpromoted aliases
  for one release; public Git mutation mappings have no compatibility window
  because the owner explicitly removed that job. Machine IDs and CLIs remain.
- Data migration order and dry run: no repository or user-data migration.
  Locale/onboarding/log state remains user-owned. Any lock replacement is first
  rehearsed in an isolated copy with exact source-byte backup.
- Rollback procedure: revert one stage at a time; restore the exact lock backup
  only for the dependency stage that changed it; never delete user config/data/
  state/cache. The Git stage rolls back by restoring key/action specs, not by
  running compensating Git commands.
- Kill switches: dependency removals remain separate commits; old command aliases
  can be retained for one more release if a real user dependency appears. There
  is no feature flag that re-enables Git mutation or Copilot in the shipped
  product.
- Rollback signals: lost file/search/LSP/format/fold/wrap/terminal behavior;
  inaccessible errors; locale switch requiring restart; any public repo-mutating
  action; Git observation changing refs/index/worktree; surface budget breach;
  unexpected tool install; authority hash drift; or platform divergence.

## Implementation Sequence

- Foundation: freeze current surface/lock evidence and introduce declarative
  product/action contracts without deleting behavior.
- First vertical slice: branch graph plus status/diff/log/blame/hunk observation,
  verified read-only, followed by removal of Git mutation and duplicate attach
  ownership.
- Hardening: live bilingual refresh, explicit key allowlist/deny specs, calm
  dashboard, unified Health surface, project formatting policy, and background
  maintenance removal.
- Dependency pass: Mason parity/removal, static theme/Lush removal, and narrowly
  gated completion/edit utility decisions; Noice remains until its blocker
  clears.
- Launch gates: behavior budgets and fault tests pass in clean copied candidates;
  lock changes are isolated; current docs match runtime; macOS and authorized
  available-host evidence are honest; no 95+ claim while any P0/P1 or release
  evidence gap remains.

## Verification

- Unit/component tests:
  - every public action has one stable ID, job, owner, mutability class, English
    label, and Chinese label;
  - no duplicate `(mode, scope, lhs)` entry and no product key collision;
  - global normal leader count <= 35 and fullest Git+LSP union <= 45;
  - Neo-tree exposes at most 24 curated actions, each core picker at most 20,
    and the dashboard at most 6;
  - zero public Git action is classified or implemented as repository mutation;
  - zero retained Git picker/tree view exposes a mutation key or checkout
    confirm;
  - product exclusions are resolved, justified, unlocked when disabled, and
    removed when upstream no longer imports them;
  - formatter args contain no Clarity-wide indentation/line-width/EOL policy.
- API/contract tests:
  - `ClarityLocaleChanged` fires exactly once for an effective language change;
  - `en -> zh -> en` refreshes global and buffer-local which-key labels without
    changing callback/rhs/options or requiring restart;
  - already-open Health/help views rerender in place with cursor/view preserved;
  - Git actions accept no shell string or arbitrary subcommand and return typed
    success, not-repo, missing-git, timeout, and bounded-output outcomes;
  - system-installed LSP attaches without Mason; missing server is actionable and
    schedules no installation.
- Integration/E2E tests:
  - natural empty, file, directory, tracked-Git, LSP attach/no-attach, 60x16, and
    80x24 attached-UI scenarios;
  - real input for every promoted action and negative input for every removed
    Git/key path;
  - disposable Git fixture records refs, index hash, worktree status, and
    optional-lock artifacts before/after status, diff, log, graph, blame, hunk
    navigation, and preview; real input includes `<Tab>`, `<C-r>`, and `<CR>`
    inside each retained Git view;
  - formatting fixtures with project Prettier/Black/Stylua configs prove project
    authority and no unrelated diff;
  - theme contrast/reload parity before Lush removal; completion/edit parity
    before optional dependency removal; injected raw-fold fault before any Noice
    reconsideration.
- Build/type/lint checks: Python tests and Ruff; Lua policy tests and StyLua;
  Actionlint only if workflow files change; JSON parse; check-only lock
  normalization; documentation path/link scan; `git diff --check`.
- Deployment smoke: copied clean candidate first boot and cache-backed offline
  restart; authority hashes unchanged; no background `git`, Mason, or parser
  maintenance after normal startup; exact rollback rehearsal for lock changes.
- Observability checks: removed paths produce no menu/help/readiness ghosts;
  typed failures have stable IDs and sanitized context; no source text, Git diff,
  credentials, clipboard contents, or arbitrary paths enter persistent logs.

## Implemented ADR Consolidation

- [ADR-0005](../decisions/0005-thin-upstream-ownership-and-explicit-profiles.md)
  records thin upstream lifecycle ownership and project/system-owned toolchains.
- [ADR-0006](../decisions/0006-agent-era-review-console.md) records agent-owned
  repository mutation and maintenance, removal of Copilot/Node provisioning, and
  the review-console product boundary.
- [ADR-0007](../decisions/0007-cataloged-observation-surface.md) records the
  declarative action/exclusion authorities, read-only Git observation, live
  bilingual mapping/component/open-view refresh, curated component profiles,
  Health consolidation, and project-owned formatting style.

## Risks And Assumptions

- Risks:
  - upstream LazyVim can add new keys or auto-install behavior after a lock
    update;
  - an allowlist implemented only in which-key would hide rather than remove
    collisions;
  - read-only Git commands can perform optional index refresh work unless invoked
    carefully;
  - disabling Mason can expose that only explicitly configured servers attach;
  - command consolidation can become a large rewrite if model and renderer are
    not separated first;
  - aggressive dependency removal can reduce precision-edit quality;
  - current lock drift can contaminate dependency evidence if mixed into a
    feature commit.
- Assumptions:
  - external agents remain the normal generation and repository-mutation path;
  - users still inspect and occasionally correct code in Neovim;
  - Chinese UI, accessibility, absolute line numbers, wrapping, folding,
    diagnostics, and recovery remain core;
  - Git observation and ripgrep are required; forge integration is not;
  - no GitHub Actions execution is authorized by blueprint approval;
  - uncertain dependency removal defaults to keep until parity, not delete.
- Revisit triggers: sustained manual authoring, a concrete in-editor Git mutation
  job, upstream semantic action/i18n contracts, owned development images, native
  message parity, changed target hosts, or measured behavior showing that a
  removed action is essential.

## Implementation Handoff

- The owner approved the blueprint and the local implementation completed on
  2026-07-11. The bounded branch graph uses `<leader>gt`; collision, action,
  localization, dependency, migration, and verification contracts pass locally.
- Execution status, deviations, rollback, and evidence live in
  `progress/2026-07-11-agent-era-observation-surface-plan.md`.
- The dated implementation assessment is
  `docs/reviews/2026-07-11-observation-surface-implementation-review.md`.
- Exact-commit remote Ubuntu/Windows/macOS and real-WSL evidence remains a
  separate authorization boundary. This blueprint does not claim those gates.
