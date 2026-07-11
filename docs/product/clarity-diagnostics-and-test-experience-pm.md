# Clarity Diagnostics And Test Experience PM

Date: 2026-07-10
Status: historical approved product baseline; local implementation followed;
current truth is in `docs/ai/current-reality.md` and the active PLAN+TASK
Architecture:
[`../architecture/2026-07-10-observability-and-test-system-blueprint.md`](../architecture/2026-07-10-observability-and-test-system-blueprint.md)

## Problem And Product Intent

Clarity currently advertises `<leader>cz` as a primary code-fold action. The
mapping works only when a fold already exists under the cursor. On an ordinary
line it throws `E490`, which reaches the user as a large, truncated `E5108`
popup. Automated validation remains green because it creates a guaranteed
manual fold before calling the callback.

This is not merely one missing `pcall`. It exposes a product trust failure:
normal edge states look like crashes, the visible error hides the useful tail,
and the test suite proves a laboratory success path rather than the action the
user actually performs.

The product intent is to make Clarity-owned actions predictable in three states:

1. the action applies and completes;
2. the action cannot apply in the current context and explains that calmly;
3. the action unexpectedly fails and leaves durable, privacy-safe evidence with
   one obvious recovery path.

## Target Users And Jobs

- GUI-editor migrants need a fold command that never turns an ordinary cursor
  location into a frightening stack trace.
- Terminal-first developers need exact event IDs, context, and reproduction
  commands rather than screenshots of truncated popups.
- The project owner needs automated evidence across promoted workflows instead
  of manually retesting every keymap after each change.
- Future implementation agents need one command surface that distinguishes
  static, contract, behavior, fault, and release evidence.

## Jobs-Caliber PM Judgment

### Essential Promise

When a Clarity action cannot do what the user asked, the editor remains calm and
clear; when the product truly breaks, Clarity preserves enough structured
evidence to reproduce and repair it without making the user become the tester.

### Taste Bar

- Normal edge states never appear as red error cards.
- User messages state what happened in one sentence and avoid Lua/Vim internals.
- Logs are invisible until needed, bounded, local-only, readable, and exportable.
- The recovery path is memorable: `:ClarityLog` for evidence and one documented
  test command for reproduction.
- Automation types real keys for promoted interactive behavior; callback
  existence or synthetic happy paths are insufficient.
- Test output leads with stable check/event IDs, expected versus actual state,
  and a repair/recheck path.

### Product Narrative

Clarity should feel less like a configurable pile of plugins and more like a
well-made editor: an action either works, gently says why it does not apply, or
creates evidence that makes the failure straightforward to diagnose. The user
should not need to understand `vim/_core/editor`, Noice routing, fold providers,
or CI fixtures to recover.

### Minimum Lovable Scope

- `<leader>cz` handles existing folds, no-fold lines, unavailable providers, and
  unsupported buffers without an uncaught error or state pollution.
- Unexpected Clarity-owned action failures produce a structured diagnostic event
  and concise localized repair message.
- `:ClarityLog` exposes recent events, the local log path, and sanitized export.
- A thin command router can run fast, contract, behavior, fault, and release
  suites without hiding ownership inside another monolith.
- Fold behavior is proven through real attached-UI key input, including success,
  expected edge, injected failure, and cleanup branches.
- CI publishes bounded, commit-bound artifacts on Ubuntu, Windows, and macOS.

### Rejected Compromises

- A broad `pcall` around `normal! za`: removes the popup but also hides real
  defects and supplies no product outcome.
- Silent failure everywhere: calmer, but leaves users unsure whether the key was
  recognized.
- Logging all Neovim/plugin messages: high noise, privacy risk, and false Clarity
  ownership.
- Treating Noice history as durable evidence: presentation can truncate or
  disappear and is not a stable contract.
- Adding a logging/test plugin before the current small Lua surface needs one:
  unnecessary dependency and startup ownership.
- More callback-only validation: repeats the exact mechanism that produced the
  current false green.

## Current Reality

- `<leader>cz` is Clarity-owned and directly executes `normal! za`.
- A no-fold line deterministically returns `E490: No fold found`; Lua exposes it
  as `E5108` at `vim/_core/editor:355`.
- No mapping conflict, Noice defect, Tree-sitter corruption, or Neovim core
  failure is required to explain the screenshot.
- Both existing fold behavior paths create a manual fold before invoking the
  callback. The attached-UI path calls the callback directly instead of sending
  the user's keys.
- Runtime probes do not own a structured Clarity error channel.
- Native `nvim.log`, `:messages`, Noice, and Snacks each provide partial or
  presentation-focused history, but no durable Clarity event contract.
- CI installs `pynvim` but does not currently run the natural runtime-contract
  runner or required attached-UI behavior suite.
- `code_fold` is marked `covered` even though the expected no-fold and injected
  failure branches are absent.

## Proposed Behavior

### Fold Action

The fold action returns one stable outcome:

- `toggled`: an existing fold opened or closed;
- `no_fold`: the current line has no fold; editor state is unchanged and the
  user sees a concise INFO message;
- `unsupported_buffer`: the current surface is not an editing buffer; editor
  state is unchanged and the user sees a concise INFO message;
- `degraded`: a fold provider is unavailable or not ready; the user receives an
  actionable non-error explanation;
- `failed`: an unexpected exception occurred; the user receives a bounded repair
  message and the structured event contains the technical evidence.

No expected outcome emits an ERROR event. An unexpected failure emits exactly
one ERROR event and must not recursively fail if persistence is unavailable.

### Diagnostic Experience

- `:ClarityLog` opens recent structured events in a read-only scratch buffer.
- `:ClarityLog tail` focuses the latest events.
- `:ClarityLog path` prints the active local JSONL path.
- `:ClarityLog export [path]` writes a sanitized evidence bundle.
- Events remain local. There is no upload, analytics, or telemetry.
- Buffer contents, clipboard data, environment values, tokens, command
  arguments, and raw provider payloads are never captured.
- Default persistence is WARN/ERROR; lower levels are opt-in for diagnosis and
  tests.

### Test Experience

The stable command surface is:

```sh
python3 scripts/run_clarity_tests.py fast
python3 scripts/run_clarity_tests.py contracts --json
uv run --with pynvim==0.6.0 python scripts/run_clarity_tests.py behavior --feature fold
python3 scripts/run_clarity_tests.py faults --feature fold
python3 scripts/run_clarity_tests.py release --artifact-dir <dir>
```

Every promoted critical behavior must have:

- a success case;
- an expected-edge case;
- a targeted injected failure that turns the intended check ID red;
- before/after state restoration evidence;
- an owner and a machine-readable artifact.

Manual review remains limited to copy clarity, visual noise, and perceived
interaction quality. Deterministic correctness belongs to automation.

## Success Criteria

- Pressing `<leader>cz` on a plain line produces no `E490`, `E5108`, RPC
  exception, ERROR event, or state change.
- Existing manual and real Tree-sitter/LSP folds still toggle correctly.
- Neo-tree, help, terminal, dashboard, and other unsupported buffers do not
  throw or mutate editor state.
- An injected callback exception produces exactly one stable structured ERROR
  event and one bounded repair message.
- An injected log-writer failure does not break editing or recurse.
- Sanitized export contains no fixture secret, buffer contents, raw HOME path,
  or environment value.
- Fold coverage cannot be reported as `covered` without success, expected-edge,
  fault, and restoration evidence.
- Fast tests target under two minutes; headless contracts under three minutes;
  attached fold/error cases add under two minutes per platform; existing runtime
  jobs retain a 20-minute hard bound.
- Required Ubuntu, Windows, and macOS jobs publish evidence for the exact commit
  before the feature is considered release-ready.

## Non-Goals

- Capturing every upstream plugin or Neovim exception.
- Replacing `:messages`, Noice, Snacks, or native `nvim.log`.
- Hosted logging, telemetry, analytics, or crash upload.
- Recording user text, secrets, provider prompts/responses, or shell history.
- A permanent diagnostics dashboard or complex log-query language.
- Rewriting all existing validation in one batch.
- Introducing Busted, Plenary logging, tmux/Expect E2E, or another task runner
  without a later measured need.
- Claiming WSL coverage from an Ubuntu runner.

## Risks And Open Questions

- A logger can become a new failure source. Default: a narrow dependency-free
  module with injected I/O failures and a non-recursive in-memory fallback.
- INFO feedback for `no_fold` may become noisy. Default: retain it for the first
  usability review; make silence a later evidence-based copy/presentation change.
- Attached UI may be timing-sensitive. Default: bounded state predicates, never
  fixed sleeps as the acceptance mechanism.
- Schema growth can turn a small module into infrastructure. Default: only
  Clarity-owned promoted actions use it; no global interception.
- No blocking product questions remain.
