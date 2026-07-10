# ADR-0004: Natural-Lifecycle Runtime Contracts

Status: accepted locally; startup-matrix and remote evidence pending
Date: 2026-07-10

## Context

Real file startup failed to load Clarity options and autocmds, but validation
passed after replaying `User VeryLazy`. Existence checks and manufactured
lifecycle completion therefore did not represent the editor a user received.

## Decision

Clarity runtime contracts observe natural Neovim/LazyVim lifecycle events from a
copied candidate with isolated roots. A pre-init passive observer records module
load phases, final state, ownership, and authority paths. Headless and attached
UI scenarios are distinct because `VeryLazy` naturally depends on `UIEnter`.

Critical contracts include negative controls. The initial fixture removes the
nested runtime and must return exactly the options, autocmds, editing-defaults,
and keymap contract failures. Tests never replay lifecycle events to make an
inspected runtime complete.

## Rejected Alternatives

- Replaying `VeryLazy`: rejected because it changes the state being diagnosed.
- Empty-headless-only smoke: rejected because file arguments and attached UI use
  different lifecycle paths.
- Mapping/command existence only: rejected because the correct surface can come
  from the wrong owner with different behavior.

## Consequences

- New config modules require contract classification.
- Deterministic correctness moves from manual owner testing to automation.
- Attached UI uses ephemeral/CI `pynvim`; it is not a local core dependency.
- Existing validation remains until passive replacement reaches parity.

## Revisit Trigger

Revisit if LazyVim replaces these lifecycle events, Neovim provides stronger
built-in contract provenance, or Clarity changes from clone-based distribution.
