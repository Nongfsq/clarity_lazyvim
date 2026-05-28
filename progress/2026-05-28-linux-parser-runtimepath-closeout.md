# 2026-05-28 Linux Parser Runtimepath Closeout

## Summary

Backported the Linux Neovim parser runtimepath fix validated on a remote Ubuntu server.

## Files Changed

- `nvim/lua/config/lazy.lua`
- `scripts/clarity_doctor.py`
- `README.md`
- `docs/ai/current-reality.md`
- `progress/2026-05-28-linux-parser-runtimepath-closeout.md`

## Validation

Commands run:

```sh
python scripts/clarity_doctor.py
python scripts/clarity_doctor.py --json
python scripts/run_clarity_audit.py
python scripts/run_clarity_validate.py
nvim --headless -u .\init.lua "+qall"
python3 scripts/clarity_doctor.py
python3 scripts/run_clarity_validate.py
CLARITY_NONINTERACTIVE=1 nvim --headless -u ./init.lua "+lua <vim parser probe>" +qall
```

## Result

The fix preserves packaged Neovim parser runtime roots such as `/usr/lib/x86_64-linux-gnu/nvim` after `lazy.nvim` runtimepath reset.

Windows validation passed with required failures `0`; audit readiness was `98/100` because `htop` / `btop` is optional and missing.

Remote Linux validation passed with required failures `0`; optional warnings remained for clipboard provider, global npm `neovim`, and `tree-sitter` CLI.

The Linux parser probe confirmed `/usr/lib/x86_64-linux-gnu/nvim/parser/vim.so`, `inspect_ok=true`, `query_ok=true`, and `parser_ok=true`.

## Follow-Ups

- Do not backport unrelated remote `lazy-lock.json` changes.
