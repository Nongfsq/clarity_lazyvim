# 2026-05-05 AI Collaboration Rules Closeout

## Summary

Created the local AI collaboration rule system for `clarity_lazyvim`.

The key rule is now explicit:

```text
AGENTS.md is stable rules, not project history; current-reality.md is project state.
```

## Files Changed

Created:

- `AGENTS.md`
- `docs/ai/default-agent-delivery-workflow.md`
- `docs/ai/current-reality.md`
- `progress/README.md`
- `scripts/session-prompt.md`
- `progress/2026-05-05-ai-collaboration-rules-closeout.md`

## Ignore Policy

`AGENTS.md` was already listed in `.gitignore`, so it remains local-only and should not be committed.

Thin pointer files such as `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`, and `.cursor/rules/project-workflow.mdc` were not created because this repository currently has no existing AI instruction pointer files and `AGENTS.md` is intentionally local-only.

## Validation

```sh
git status -sb
python3 scripts/run_clarity_audit.py
python3 scripts/run_clarity_validate.py
```

Results:

- `AGENTS.md` is ignored by `.gitignore`.
- `python3 scripts/run_clarity_audit.py` returned `Overall readiness: 100/100`.
- `python3 scripts/run_clarity_validate.py` returned `Required failures: 0`.
- Optional warning remains: local Python provider module `pynvim` is not installed.

## Follow-Ups

- Decide whether `docs/ai/`, `progress/`, and `scripts/session-prompt.md` should be public repository docs or local-only as well.
- If they should be local-only, add ignore rules before committing anything.
