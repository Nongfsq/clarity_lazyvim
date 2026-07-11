# Observation Surface Closeout

Date: 2026-07-11

Status: complete for the authorized local boundary; branch pushed without CI

Clarity now exposes a cataloged bilingual review surface, five read-only Git
observations, curated components, one Health facade, and 18 gated dependencies.

Runtime boundaries are in `9a69835`/`57328ae`; `596cffa` hardened contracts;
`21f8d29` adds exact 39-key i18n, pinned `pynvim==0.6.0`, process-tree cleanup,
and the 28+7+4 matrix. Evidence lives in `scripts/run_clarity_action_matrix.py`,
`tests/lua/real_input_action_matrix.lua`, and `tests/python/test_action_matrix.py`.

A clean release for `69ecfbf` passed 60 Python/26 Lua tests, contracts, matrix,
faults, validate, smoke, and audit; owner-only evidence is at
`~/.local/state/clarity_lazyvim/release-evidence/20260711-69ecfbf`. Ruff, StyLua,
lock, SVG, link, and diff checks pass. Ubuntu, Windows, WSL, hosted CI, cold-
network rollback, and newcomer evidence remain pending: 92/100, not 95+.
