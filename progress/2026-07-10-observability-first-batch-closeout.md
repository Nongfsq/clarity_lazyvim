# Observability First Batch Closeout

Date: 2026-07-10

> **Historical closeout:** this file records commit-bound results from the
> stated date only. Counts, hashes, platform evidence, and pending tasks are not
> current authority; use
> [`../docs/ai/current-reality.md`](../docs/ai/current-reality.md) and its active
> PLAN+TASK.

- Completed `OBS-001` through `OBS-003`; stopped before `OBS-004`.
- Raw no-fold `za` deterministically reproduces `E490/E5108`.
- Added diagnostic schema v1, bounded JSONL/ring, rotation, redaction, and guard.
- Replaced raw `<leader>cz` execution with typed fold outcomes.
- Positive attached UI returns `toggled` and `no_fold` without an error channel.
- Raw-fold fault fails exactly `CLARITY_RUNTIME_KEYMAP_CONTRACT`.
- Passed 26 Python tests, 6 Lua tests, static checks, contracts, legacy validation,
  smoke, core audit, documentation links, and diff checks locally.
- Root lock/JSON hashes remain accepted and unchanged.
- Check-only lock normalization separately reports unaccepted `nvim-lspconfig`
  drift; no dependency change was applied in this batch.
- `code_fold` remains planned until `OBS-007` completes the full evidence set.

Follow-up after owner approval:

- The `nvim-lspconfig` drift was validated, backed up, atomically applied, and
  rechecked clean at lock hash `af8ad1dff2b125573e19a37c3a30af25a152450d2b9b1d0320ee78fd35db04d7`.
- `OBS-004` through `OBS-007` subsequently completed locally; `code_fold` is
  covered again. Remote `OBS-008` evidence remains pending.
