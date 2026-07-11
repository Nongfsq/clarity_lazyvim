# Agent-Era Review Console Closeout

Date: 2026-07-10

- Removed Copilot, Node/npm product checks, development auto-install profiles,
  ToggleTerm, and autotag; Snacks now owns `<leader>tf`.
- Added `:ClarityHealth` and kept old commands as compatibility routes.
- Retained Noice after native messages blocked the attached raw-fold fault test.
- Active/locked plugins: 23/23; product exclusions: 13.
- Lock: `df9dfba9cabe6fef10ec93737c9de125621de01bc1d41f1c6491787f26f3e20b`.
- Validation: 36 Python tests, 20 Lua policy files, Ruff, StyLua, clean lock
  normalization, and all seven local release checks passed.
- Authority hashes remained unchanged during the successful release run.
- Manual Ubuntu deployment at `85d217029722d31e3b441ce5e9aa9410ad1becf1`
  passed the same seven release checks on Neovim 0.12.4 and Python 3.12.3.
- Backups: agent stages under
  `~/.local/state/clarity_lazyvim/lock-backups/20260710T-agent*-lazy-lock.json`.
- Pending: Windows/WSL and commit-bound release evidence; GitHub Actions was not
  manually triggered or rerun.
