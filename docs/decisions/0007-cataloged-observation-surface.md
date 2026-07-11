# ADR-0007: Cataloged Observation Surface

Status: accepted locally; cross-platform evidence pending
Date: 2026-07-11

## Context

Clarity had a small plugin set but still exposed the inherited LazyVim menu,
English-only contextual descriptions, and Git views whose local controls could
mutate the repository. Plugin count did not represent product complexity.

## Decision

- `config.actions.catalog` is the authority for promoted action identity,
  ownership, scope, mutability, bindings, and English/Chinese labels.
- The normal leader budget is exactly 28 global actions and seven additional
  context-scoped actions: five LSP, one Git hunk preview, and one editable-
  buffer formatting recovery.
- Git is observation-only. Status, changes, history, branch graph, and line
  provenance use bounded fixed arguments and read-only views; Gitsigns owns hunk
  navigation and inline preview. Agents own staging, reset, checkout, commit,
  and other repository writes.
- `User ClarityLocaleChanged` refreshes Clarity-owned global and contextual
  metadata without changing callbacks, rhs, modes, scopes, or mapping options.
- Neo-tree, Snacks Picker, dashboard, and Health use complete curated profiles;
  hidden component mutation and maintenance aliases are product behavior and
  must be removed rather than merely hidden from which-key.
- Health is the promoted human facade. Legacy view commands remain one-release
  compatibility routes; machine IDs, bang JSON, and log path/export stay stable.

## Rejected Alternatives

- Hiding inherited keys only in which-key: rejected because aliases remain
  callable and can reappear after lazy attachment.
- Reusing Snacks Git pickers or Neo-tree Git source: rejected because confirm and
  local mappings can mutate tracked state.
- Treating disabled lock entries as policy: rejected because lock state has no
  product rationale and can include unrelated conditional plugins.
- Restart-only localization: rejected because language is a runtime product
  choice, not a bootstrap profile.

## Consequences

- Surface regressions fail independent runtime contract IDs instead of one
  aggregate keymap check.
- Component budgets and repository immutability are verified through natural
  attached-UI input in copied candidates.
- Adding an action or dependency requires a named product job, owner, locale,
  mutation classification, behavior test, and revisit rule.
- Local evidence does not certify Ubuntu, Windows, WSL, or hosted CI.

## Revisit Trigger

Revisit when measured user work requires a new primary job, LazyVim changes
mapping lifecycle ownership, or agents no longer own broad file/repository
mutation. Preserve the catalog, mutability, and evidence model even if exact keys
or budgets change.
