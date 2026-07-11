# Observation Surface Closeout

Date: 2026-07-11

Status: implementation complete; clean release rerun and authorized branch push pending

Clarity now exposes a cataloged bilingual review surface, five read-only Git
observations, curated components, one Health facade, project-owned formatting,
and 18 parity-gated dependencies.

Runtime boundaries are in `9a69835`/`57328ae`; `596cffa` hardened natural
contracts; `21f8d29` adds exact 39-key i18n, pinned `pynvim==0.6.0`, process-tree
cleanup, and the 28+7+4 real-input matrix. Representative evidence lives in
`scripts/run_clarity_action_matrix.py`, `tests/lua/real_input_action_matrix.lua`,
and `tests/python/test_action_matrix.py`.

Fast (60 Python/26 Lua), contracts, behavior, faults, Ruff, StyLua, lock, SVG,
relative-link, and diff checks pass locally. Exact-commit Ubuntu, Windows, WSL,
hosted CI, cold-network install/rollback, and moderated newcomer evidence remain
pending; the evidence supports 92/100, not a cross-platform 95+ release claim.
