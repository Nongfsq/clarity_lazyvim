# Clarity Runtime Trust PM

Date: 2026-07-09
Status: historical approved product baseline; local implementation followed;
current truth is in `docs/ai/current-reality.md` and the active PLAN+TASK
Architecture:
[`../architecture/2026-07-09-runtime-contract-verification-blueprint.md`](../architecture/2026-07-09-runtime-contract-verification-blueprint.md)

## Problem And Product Intent

Clarity cannot call itself trustworthy if the owner must manually discover that
a configuration file exists but never loaded, an upstream default silently won,
or a validation command repaired the lifecycle before inspecting it.

The line-number regression made the trust failure concrete: real file startup
showed LazyVim relative numbering, while automated validation passed because it
replayed `VeryLazy` and observed a later, different state. The visible symptom
was small; the underlying product problem was that automation and users did not
exercise the same editor.

The product intent is to move deterministic correctness responsibility from the
owner to the repository. The owner should experience and judge Clarity, not
serve as its regression suite.

## Target Users And Jobs

Primary users:

- the project owner reviewing local changes before publication;
- contributors changing Lua modules, plugin specs, validation, or CI;
- GUI-editor migrants who expect opening a file or folder to produce the same
  tested product state;
- future maintainers upgrading LazyVim or Neovim without memorizing hidden load
  ordering.

Primary jobs:

1. change configuration and know which real startup paths are affected;
2. detect orphaned, late, duplicate, or upstream-overwritten configuration in
   code review and CI;
3. prove promoted workflows by behavior rather than mapping existence;
4. diagnose a failure from one stable check with expected, actual, owner, phase,
   and repair evidence;
5. reserve human review for visual taste, language clarity, and perceived feel.

## Jobs-Caliber PM Judgment

### Essential Promise

> If Clarity says a promoted workflow is ready, the same configuration loaded
> naturally in the same startup shape a user runs, and the behavior was executed
> without mutating the repository or user session.

### Emotional Promise

The owner should feel relief, not vigilance. A green result should mean there is
no need to remember which event, cache, file argument, or plugin default might
have produced a different editor.

### Taste Bar

- One contract catalog, not scattered copies of expected behavior.
- Observe real lifecycle; never manufacture readiness by replaying startup
  events.
- Every promoted capability has an owner and a behavior check.
- Every critical check proves it can fail through a negative control.
- No authority-file or live-session mutation during diagnosis.
- Failures explain the broken boundary in product language.
- CI exposes uncovered areas instead of hiding them inside one score.
- Manual review is short, qualitative, and meaningful.

### Product Narrative

1. A contributor adds or changes a module.
2. Static contract checks classify its intended lifecycle and owner.
3. Real empty/file/directory or other applicable startup scenarios run in an
   isolated copied candidate.
4. A passive probe records what naturally loaded and the final owned state.
5. Behavior fixtures execute the affected promoted workflow.
6. Negative controls prove the gate detects the defect class.
7. CI presents precise evidence or a precise repair path.
8. The owner reviews only visual and experiential quality before approval.

### Rejected Compromises

- Reject asking the owner to click through every feature after each change.
- Reject existence-only checks for Clarity-owned options, maps, commands, or
  plugin behavior.
- Reject replaying `VeryLazy`, `VimEnter`, `BufEnter`, or `FileType` to make a
  runtime appear complete.
- Reject treating an untested promoted capability as implicitly covered by
  upstream.
- Reject testing against developer cache as release evidence.
- Reject a new framework that replaces LazyVim lifecycle ownership.
- Reject weakening a red gate because it exposes a pre-existing defect.

## Current Reality

- Runtime/config and plugin surfaces contain 20 primary Lua modules and roughly
  3,533 lines.
- The Lua unit layer has one small capability-policy test; Python unit tests
  focus mainly on orchestration and platform helpers.
- The current validator has 51 checks, including 18 locale checks, but no
  completeness rule for new configuration modules or promoted capabilities.
- Python validation replays `VeryLazy` in five places; runtime audit/validation
  replay it in two more places.
- The smoke runner proves source paths, two boots, plugin count, and authority
  hashes, but not module phases or state ownership.
- The local uncommitted line-number/wrap fix proves that preserving the nested
  runtime during lazy.nvim runtimepath rebuilding restores natural loading of
  options, autocmds, and keymaps.
- Remote Ubuntu/Windows/macOS evidence remains pending for the trust-foundation
  branch.

## Proposed Behavior

### Contributor Experience

- A new `config/*.lua` file fails contract validation until it is classified as
  pre-plugin, lifecycle, eager service, on-demand, or test-only.
- A promoted command, mapping, or option fails coverage until it has a declared
  owner, startup scenarios, final-state contract, and behavior check.
- A known future migration may be `planned` only when it names its existing task
  owner. Unowned is always a failure; release gates reject remaining planned core
  capabilities.
- Failure output names scenario, phase, owner, expected, actual, severity,
  repair, and evidence source.

### Runtime Verification

- Empty, file, directory, stdin, arbitrary checkout, symlink, clean first boot,
  offline restart, and attached-UI scenarios observe natural startup.
- Tests wait for documented events but never fire lifecycle events to complete
  the runtime.
- Every scenario hashes root authority files before and after execution.
- Active behavior checks run only in disposable candidates, buffers, windows,
  tabs, and fixtures.
- In-editor audit and validation remain passive and restore serialized session
  state exactly.

### Human Review Boundary

The owner reviews:

- color, contrast, spacing, typography, and terminal rendering;
- clarity and tone of onboarding/help/recovery copy;
- whether primary workflows feel coherent and immediate;
- subjective motion and latency.

Automation reviews everything deterministic, including configuration loading,
ownership, startup, behavior, state restoration, platform results, and file
drift.

## Success Criteria

- 100% of `config/*.lua` modules are classified and observed in every required
  startup scenario or explicitly declared on-demand.
- 100% of promoted core capabilities have a declared owner, final-state check,
  behavior check, and platform scope.
- No validator or audit path replays startup lifecycle events.
- The line-number fault injection fails for unloaded `config.options`, relative
  numbering, missing autocmd ownership, and wrong phase; the real fix passes.
- Empty, file, directory, stdin, arbitrary checkout, symlink, clean first boot,
  and offline restart scenarios leave authority hashes unchanged.
- Critical negative controls fail their intended stable check IDs.
- Audit/validation invoked twice from a modified live buffer preserves tab,
  windows, buffers, cursor, options, modified content, and event counts.
- CI artifacts contain per-scenario snapshots and a zero-unclassified coverage
  manifest.
- Remote required Ubuntu, Windows, and macOS jobs pass before cross-platform
  release claims.
- Release acceptance has zero unowned and zero planned core capabilities.
- Owner acceptance can be completed with a short qualitative review rather than
  a full functional walkthrough.

## Non-Goals

- Re-testing every inherited LazyVim feature.
- Replacing LazyVim, lazy.nvim, or Neovim lifecycle.
- Visual snapshots for every terminal/font combination.
- Making optional Copilot/provider capabilities core.
- Adding plugins or new end-user features.
- Running tests against user-owned config/data/state/cache.
- Using local macOS evidence as Windows, Ubuntu, or WSL proof.
- Claiming a perfect coverage percentage for intentionally inherited,
  non-promoted upstream features.

## Risks And Open Questions

Risks:

- brittle contracts could overfit upstream implementation details;
- attached-UI automation may increase CI complexity;
- scenario coverage increases runtime;
- introducing the gate will surface additional existing defects;
- migrating the monolithic validator can accidentally lose stable diagnostic
  IDs or user-facing repair details.

Mitigations:

- assert Clarity-owned and promoted contracts, not arbitrary upstream internals;
- split fast PR and full release tiers;
- retain legacy checks until positive and negative replacement evidence passes;
- map every uncovered core behavior to an existing or new owner task;
- preserve stable IDs or document explicit replacements.

Open questions: none blocking.

Defaults for non-blocking choices:

- use `pynvim` only for the attached-UI full CI tier;
- keep the current 10-minute static and 20-minute per-platform runtime bounds;
- allow `planned` coverage during refactor only with a named task owner;
- reject all remaining planned core coverage at release;
- treat inherited non-promoted behavior as upstream responsibility.
