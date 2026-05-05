# 2026-05-05 Cross-Platform Doctor Closeout

## Summary

Added a cross-platform local diagnostics and safe repair path for clarity_lazyvim.

The main product gap was that local parser/cache/provider problems could require manual log inspection. The repository now has a first-class doctor command that reports platform-specific dependency status, Neovim runtime state, Tree-sitter parser health, and safe repair options.

## Files Changed

- `scripts/clarity_doctor.py`
- `scripts/run_clarity_validate.py`
- `scripts/session-prompt.md`
- `nvim/lua/config/audit.lua`
- `README.md`
- `docs/ai/current-reality.md`
- `progress/2026-05-05-cross-platform-doctor-closeout.md`

## Behavior

- `python3 scripts/clarity_doctor.py` runs dry-run diagnostics by default.
- `python3 scripts/clarity_doctor.py --apply` performs only conservative backup-based local repairs.
- Stale user-level `vim` Tree-sitter parser overrides are moved into `.clarity-backup-YYYYMMDD-HHMMSS/` directories instead of being deleted.
- `:ClarityAudit` now reports `tree-sitter` CLI availability and `vim` parser/query/highlighter health.
- `scripts/run_clarity_validate.py` now requires healthy `vim` Tree-sitter parser behavior and absence of stale user-level parser overrides.

## Validation

Commands run during implementation:

```sh
python3 scripts/clarity_doctor.py
python3 scripts/clarity_doctor.py --json
python3 scripts/run_clarity_audit.py
python3 scripts/run_clarity_validate.py
```

Result:

- doctor: no required failures
- audit: required tools present, overall `98/100` on current macOS because local `tree-sitter` CLI is optional and missing
- validation: required failures `0`

Optional local warnings remain:

- Python provider package `pynvim` is not installed for the current Python runtime.
- `tree-sitter` CLI is not installed locally; install with `npm install -g tree-sitter-cli` when parser diagnostics are needed.

## Follow-Ups

- Consider adding a Neovim command wrapper such as `:ClarityDoctor` if users should discover the terminal doctor from inside Neovim.
- Consider an explicit `--install` mode later, but keep it separate from safe local repair because dependency installation mutates system state.
