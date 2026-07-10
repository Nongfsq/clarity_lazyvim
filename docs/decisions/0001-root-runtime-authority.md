# ADR-0001: Root Runtime Authority

Status: accepted for the trust-foundation branch; release evidence pending
Date: 2026-07-09

## Context

The public repository uses a root entrypoint with a nested `nvim/` runtime, but
lazy.nvim and LazyVim previously defaulted to files under `stdpath("config")`.
CI checkouts therefore did not prove that the repository lock and LazyVim state
were consumed.

## Decision

The single runtime authority is:

- root `init.lua`;
- root `lazy-lock.json`, passed explicitly to lazy.nvim;
- root `lazyvim.json`, assigned through `vim.g.lazyvim_json` before LazyVim loads.

`nvim/lazyvim.json` is removed. Runtime smoke tests operate on a copied candidate
repository and must prove that source and candidate authority-file hashes remain
unchanged.

Lock normalization is an explicit transaction through
`scripts/update_clarity_lock.py`. Its default mode is read-only: normalize and
restart a copied candidate, require core audit readiness, and report drift. The
`--apply` mode stores the exact previous lock in the user state directory before
an atomic replacement. A resulting Git diff still requires normal review.

The current lock snapshot is a migration candidate, not release certification.
Its Tree-sitter/LazyVim compatibility remains governed by `NVIM-007`.

## Rejected Alternatives

- Implicit `stdpath("config")` files: rejected because checkout and runtime roots
  diverge.
- Dual root/nested JSON files: rejected because extras/news state silently drifts.
- Running clean-smoke directly against source authority files: rejected after it
  demonstrated that lazy.nvim can normalize the lockfile.

## Consequences

- Local root installs and arbitrary checkouts resolve the same repository files.
- Generated LazyVim state changes use a recoverable, reviewable Git transaction.
- Test harnesses must copy the candidate before first boot.
- Lock migration and release acceptance remain explicit review gates.

## Revisit Trigger

Revisit only if Clarity permanently adopts a conventional config-only repository
layout or a packaged distribution replaces the root-wrapper model.
