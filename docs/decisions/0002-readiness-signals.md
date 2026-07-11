# ADR-0002: Separate Readiness Signals

Status: accepted
Date: 2026-07-09

## Context

The previous `Overall readiness` score weighted tools and layout while excluding
integration and release failures. It could display `100/100` when supported
behavior or CI was broken.

## Decision

Clarity reports three independent concepts:

- core/host readiness: whether the promoted local core can run;
- optional profile readiness: provider, clipboard, and utility availability;
- release quality: commit-bound CI/release evidence, always `unverified` in a
  local audit.

Every non-pass check carries a stable ID, impact, repair, and recheck path. CLI
audit exits non-zero for core failures and remains successful when only optional
profiles are unavailable.

## Rejected Alternatives

- One weighted headline score: rejected because weights can hide required
  failures.
- Treat every optional executable as a quality deduction: rejected because a
  deliberately disabled profile is not a broken core product.
- Let local audit certify a release: rejected because it cannot prove other
  platforms, clean archives, or rollback.

## Consequences

Documentation and UI must use readiness state names rather than old scores.
Release claims require external artifacts. Profile ownership must remain
explicit as new capabilities are added.

## Revisit Trigger

Revisit when supported product profiles materially change, while preserving the
rule that no required failure can coexist with a perfect/ready headline.
