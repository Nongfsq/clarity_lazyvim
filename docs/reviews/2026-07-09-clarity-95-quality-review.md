# Clarity LazyVim 95+ Quality Review

Date: 2026-07-09
Scope: existing-system product, runtime, architecture, verification, release,
and documentation review
Status: evidence baseline for the approved refactor; no implementation implied

> Historical baseline: this review intentionally remains the 58/100 starting
> point. The implemented observation-surface result and current 92/100 local
> assessment are recorded in
> [`2026-07-11-observation-surface-implementation-review.md`](2026-07-11-observation-surface-implementation-review.md).

## Executive Conclusion

Clarity LazyVim has a clear product direction and a good daily-work core, but it
is not yet a trustworthy 95+ release. The evidence-weighted baseline is
**58/100**.

The largest gap is not missing features. It is the mismatch between local
success and reproducible product quality:

1. the committed repository is not proven to be the runtime source of truth;
2. Clarity replaces several LazyVim/plugin lifecycle owners instead of extending
   them;
3. the public `100/100` score and CI claims exceed the available evidence;
4. first-run, recovery, and cross-platform guidance are not yet a closed,
   testable experience.

The correct strategy is to keep LazyVim, make Clarity a thin product-policy
layer, repair the trust foundation first, then improve the newcomer experience.

## Review Method

The assessment combined:

- repository and Git state inspection;
- startup, resolved-plugin, mapping, audit, and isolated-config probes;
- GitHub Actions run history and failure-log inspection;
- comparison with current LazyVim, lazy.nvim, Neo-tree, Tree-sitter, and plugin
  behavior;
- three independent read-only review lanes: runtime architecture, product/UX,
  and engineering quality/release;
- contradiction checks against README, current-state, historical reports, and
  progress closeouts.

The previously cancelled research attempt was not used as authority. Existing
user changes to `lazy-lock.json` and the untracked root `lazyvim.json` were
preserved.

## Scorecard

| Dimension | Score | Assessment |
| --- | ---: | --- |
| User experience | 23/35 | Strong core workflow; weak safe install, error states, small-terminal support, and platform handoff |
| Runtime correctness | 13/20 | Multiple validated plugin-ownership and behavior defects |
| Architecture and maintainability | 9/15 | Product-layer direction is right; lifecycle replacement and monolithic services create upgrade risk |
| Reproducibility and platform fidelity | 5/15 | Lock/config paths, committed state, and CI environment are inconsistent |
| Verification and release | 4/10 | Useful probes exist, but clean-release evidence, branch gates, and rollback are absent |
| Documentation and governance | 4/5 | Rich documentation, but stale scores and validation claims reduce trust |
| **Total** | **58/100** | Product potential is real; release evidence is not yet sufficient |

Independent lane reference scores were UX 65/100, runtime architecture 60/100,
and engineering verification/release 44/100.

## What Is Already Strong

- The product promise is coherent: legible, calm, terminal-first, and less
  overwhelming than a maximal Neovim setup.
- File search, text search, LSP navigation, terminal use, and Git hunk workflows
  form a good daily-work skeleton.
- `ClarityStart`, audit, validation, and doctor tools create an unusually useful
  recovery model.
- English source governance with localized Clarity-owned UI is a sound boundary.
- The single-explorer fix and fold/wrap controls have targeted behavioral probes.
- Local headless startup is approximately 29 ms; startup performance is not the
  first optimization target.

## P0 Release Blockers

### P0-1: Configuration And Dependency Source Of Truth Is Split

README declares root `lazy-lock.json` authoritative, but `lazy.setup()` does not
set `lockfile`. lazy.nvim therefore uses `stdpath("config")/lazy-lock.json`.
LazyVim resolves `lazyvim.json` from the same configuration root.

Observed state:

- root `lazyvim.json` is active locally but untracked;
- tracked `nvim/lazyvim.json` is not active in the documented root install;
- CI invokes the repository `init.lua` with `-u`, which does not make the
  checkout `stdpath("config")`;
- committed and dirty lockfiles represent materially different plugin
  generations.

Impact: a green local run may validate user cache and dirty local state instead
of the committed release candidate.

Required outcome: one tracked configuration root, explicit lock/config paths,
and clean-archive validation that proves those exact files were consumed and
unchanged.

### P0-2: CI Has No Trustworthy Green Baseline

The visible `clarity-validate` history contains ten failures and one cancelled
run, with zero successful completions.

Validated causes include:

- Windows installs Neovim under `C:\tools\neovim`, while the workflow only
  exports a `C:\Program Files\Neovim` path;
- Ubuntu installed Neovim 0.9.5, below the supported LazyVim/Clarity floor;
- subprocess calls have no timeout, allowing a job to hang until cancellation;
- current `origin/main` and local HEAD have no successful matching run.

Impact: Ubuntu/Windows reproducibility claims and the validation badge do not
currently represent release evidence.

Required outcome: exact supported Neovim versions, working executable
resolution, bounded jobs, clean config/data/state directories, and green
Ubuntu/Windows/macOS artifacts.

### P0-3: `100/100` Is A Host Score Presented As Product Quality

The current overall formula is:

- required executables: 50%;
- optional executables: 20%;
- directory layout: 30%.

The separately computed integration score does not affect overall. Neovim
version, Tree-sitter health, plugin behavior, CI state, lockfile fidelity,
tests, and release governance are also excluded. The Python wrapper returns zero
after parsing a report regardless of the headline score.

Impact: Clarity can display perfect readiness while a supported integration or
release gate is broken.

Required outcome: separate host capability, feature readiness, and release
quality. A required failure must never coexist with a perfect headline.

### P0-4: The Clean-Machine Experience Is Not Closed

Quick Start clones into the normal Neovim config location and launches without
an existing-config migration, dependency preflight, progress contract, network
failure recovery, or tested rollback. `ripgrep` powers a primary advertised job
but is classified as optional without a tested fallback.

Required outcome: safe backup/installation, profile-aware prerequisites,
actionable progress/error states, and a no-optional-tools degradation test.

## P1 Runtime And Experience Findings

### Plugin Ownership

- Neo-tree defines a private `config()` and ignores merged LazyVim opts. Its
  event handler is nested under `default_component_configs`, so it is not
  registered. LazyVim file-move/file-rename propagation is lost.
- Mason installation policy is attached to `LazyVim/LazyVim.opts.mason` instead
  of the owning `mason.nvim`, `mason-lspconfig`, and LSP server contracts.
- Conform returns a replacement opts table, filters executables at option-build
  time, and discards LazyVim's LSP fallback.
- The dirty lockfile advances Tree-sitter to the new API generation while local
  configuration still uses the older configuration shape.
- Gitsigns diff navigation returns `[h`/`]h` from callbacks without expression
  mappings, so the return value is ignored.
- The custom colorscheme is declared as `habamax` and later loaded with
  `dofile`, bypassing normal `ColorScheme` ownership.

### Validation Fidelity

- Audit and validation manually fire global `VeryLazy` lifecycle events.
- Interactive validation edits README and opens/closes Neo-tree without a
  guaranteed full session restore.
- Some critical mappings are checked only for existence; one check targets
  `<leader>gd` while the Clarity mapping is `gd`.
- Bilingual parity and recovery mapping checks are optional despite being
  marketed product invariants.
- No unit/spec test suite, missing-tool fixture, lock drift check, or offline
  restart proof exists.

### Product And Accessibility

- First-run help has an 84-column minimum, disables wrapping, and records the
  guide as seen before successful rendering.
- `ClaritySync` treats every non-Windows system as WSL/Linux mirror behavior,
  which is inaccurate for supported macOS and native Linux users.
- The `h` key namespace mixes hunks, help/health, and system monitor concepts.
- Audit/validation output remains English-only even though it is Clarity-owned.
- Accessibility claims have no enforceable contrast or non-color redundancy
  gate; sampled resolved colors include values below the proposed acceptance
  threshold.
- Multiple terminal layouts, system monitor, and default Copilot add newcomer
  explanation cost without strengthening the core promise.

## Target Product Promise

Clarity must be:

> A legible, calm, trustworthy terminal editor that gives GUI-editor migrants
> one obvious path from file to edit to search to run, plus a built-in way home
> when configuration or environment state drifts.

The emotional promise is confidence: users should not need to understand plugin
ownership, cache paths, Windows/WSL mirroring, or dependency internals to know
what is happening and what to do next.

## Minimum Lovable Scope

Keep as primary product surfaces:

- safe install/preflight and responsive first-run help;
- one file search, one text search, one explorer, and one terminal;
- edit/save, LSP navigation, diagnostics, and formatting;
- basic Git status/diff/hunk workflow;
- platform-aware clipboard and update help;
- honest diagnose, repair, and recheck flow;
- tested accessible theme and full localization of Clarity-owned surfaces.

Deliberately demote or exclude from the newcomer surface:

- full localization of upstream plugins;
- multiple promoted terminal layouts and system monitor;
- the full inherited LazyVim command surface;
- shell-framework ownership;
- Copilot as a required/default onboarding dependency.

## 95+ Acceptance Bar

A release may claim 95+ only when all of the following are true:

- no open P0 or P1 findings;
- one canonical tracked lock/config source, consumed in local and CI runtime;
- clean `git archive` first boot and network-blocked second boot succeed without
  modifying lock/config files;
- required Ubuntu, Windows, and macOS jobs use an explicit supported Neovim
  version and are green;
- WSL is claimed only after a real Windows 11 + WSL2 validation path is green;
- user-critical mappings execute behavior rather than only existing;
- missing optional tools produce tested, actionable degradation states;
- first-run help has no clipping at 60x16 and 80x24;
- normal text contrast is at least 4.5:1, meaningful non-text contrast is at
  least 3:1, and color is not the sole signal;
- installation, update, and rollback are documented and rehearsed;
- branch protection requires the release matrix;
- public validation statements are bound to a commit, date, and CI artifact.

## Evidence And Known Gaps

Evidence collected:

- local doctor, audit, validation, startup, resolved-spec, and isolated-config
  probes;
- GitHub workflow YAML, run history, and failure logs;
- source comparison with installed current and committed-generation upstream
  plugins;
- documentation and progress-history consistency checks;
- Python AST parsing, JSON parsing, and `git diff --check`.

Not yet proven:

- clean Windows, WSL, and Linux runtime behavior;
- real cold-network first boot duration;
- offline restart and rollback;
- interactive screenshots and terminal color reproduction;
- moderated newcomer comprehension tests.

These gaps are execution work and are tracked in the active PLAN+TASK document.
