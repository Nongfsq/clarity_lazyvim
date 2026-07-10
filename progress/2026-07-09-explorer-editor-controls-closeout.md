# 2026-07-09 Explorer And Editor Controls Closeout

## Summary

- Selected Neo-tree as Clarity's sole LazyVim explorer and removed the redundant directory-start `VimEnter` opener.
- Added `<leader>cz` for the current code fold and made `<leader>uw` an explicit Clarity-owned line-wrap toggle.
- Added runtime regression coverage for directory startup, folding, wrapping, and bilingual key descriptions.

## Files Changed

- `nvim/lua/config/{lazy,keymaps,i18n,validation}.lua`
- `nvim/lua/plugins/neo-tree.lua`
- `scripts/run_clarity_validate.py`
- `README.md`, `doc/clarity_lazyvim_complete_guide_zh.md`, and `docs/ai/current-reality.md`

## Validation

- `python3 -m py_compile scripts/run_clarity_validate.py scripts/run_clarity_audit.py scripts/clarity_doctor.py`
- `python3 scripts/run_clarity_validate.py`: required failures `0`; one unrelated optional `pynvim` warning.
- `python3 scripts/run_clarity_audit.py`: overall readiness `100/100`.
- `python3 scripts/clarity_doctor.py`: required checks passed; optional `pynvim` warning.
- `CLARITY_NONINTERACTIVE=1 nvim --headless -u ./init.lua '+qall'` and `git diff --check`: passed.
- No dedicated documentation check is configured in the repository.

## Follow-Up

- Resolve the root `lazyvim.json` versus tracked `nvim/lazyvim.json` source-of-truth split during the planned refactor.
