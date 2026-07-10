# Documentation Index

## Canonical Active Documents

| Purpose | Document | Authority |
| --- | --- | --- |
| Current repository state | [`ai/current-reality.md`](ai/current-reality.md) | Current facts, known gaps, active-plan pointer |
| Delivery workflow | [`ai/default-agent-delivery-workflow.md`](ai/default-agent-delivery-workflow.md) | Detailed planning, execution, and closeout workflow |
| 95+ quality review | [`reviews/2026-07-09-clarity-95-quality-review.md`](reviews/2026-07-09-clarity-95-quality-review.md) | Evidence inventory and baseline score |
| Refactor architecture | [`architecture/2026-07-09-clarity-95-refactor-blueprint.md`](architecture/2026-07-09-clarity-95-refactor-blueprint.md) | Approved target boundaries and migration sequence |
| Runtime verification architecture | [`architecture/2026-07-09-runtime-contract-verification-blueprint.md`](architecture/2026-07-09-runtime-contract-verification-blueprint.md) | Natural-lifecycle contract model, probes, and fault-injection boundary |
| Observability/test architecture | [`architecture/2026-07-10-observability-and-test-system-blueprint.md`](architecture/2026-07-10-observability-and-test-system-blueprint.md) | Typed actions, structured diagnostics, real-input evidence, and command-driven testing |
| Product/UX intent | [`product/clarity-95-experience-pm.md`](product/clarity-95-experience-pm.md) | User promise, minimum lovable scope, 95+ experience bar |
| Runtime trust PM | [`product/clarity-runtime-trust-pm.md`](product/clarity-runtime-trust-pm.md) | User-facing runtime trust goals and acceptance outcomes |
| Diagnostics/test PM | [`product/clarity-diagnostics-and-test-experience-pm.md`](product/clarity-diagnostics-and-test-experience-pm.md) | Calm action failure, recovery, privacy, and automated-test experience |
| Active PLAN+TASK | [`../progress/2026-07-09-clarity-95-refactor-plan.md`](../progress/2026-07-09-clarity-95-refactor-plan.md) | Task IDs, dependencies, status, acceptance, validation |
| Runtime verification PLAN+TASK | [`../progress/2026-07-09-runtime-contract-verification-plan.md`](../progress/2026-07-09-runtime-contract-verification-plan.md) | Runtime-contract task status, evidence, and phase gates |
| Observability/test PLAN+TASK | [`../progress/2026-07-10-observability-and-test-system-plan.md`](../progress/2026-07-10-observability-and-test-system-plan.md) | Active diagnostic, fold-action, test-router, and CI task ledger |
| Interaction/dependency review | [`reviews/2026-07-10-interaction-dependency-modernization-review.md`](reviews/2026-07-10-interaction-dependency-modernization-review.md) | Keymap, feature, dependency, and current-workflow evidence |
| Resolved dependency manifest | [`reviews/2026-07-10-resolved-dependency-manifest.md`](reviews/2026-07-10-resolved-dependency-manifest.md) | Active/locked set, retention rationale, lock rollback evidence |
| Simplification PLAN+TASK | [`../progress/2026-07-10-interaction-dependency-simplification-plan.md`](../progress/2026-07-10-interaction-dependency-simplification-plan.md) | Completed local/manual-Ubuntu execution ledger; Windows/release evidence pending |
| Local agent contract | `AGENTS.md` at repository root | Durable local implementation rules; intentionally ignored by Git and therefore not a public repository link |

## Accepted Decisions

- [`decisions/0001-root-runtime-authority.md`](decisions/0001-root-runtime-authority.md)
- [`decisions/0002-readiness-signals.md`](decisions/0002-readiness-signals.md)
- [`decisions/0003-ci-evidence-boundary.md`](decisions/0003-ci-evidence-boundary.md)
- [`decisions/0004-natural-lifecycle-runtime-contracts.md`](decisions/0004-natural-lifecycle-runtime-contracts.md)
- [`decisions/0005-thin-upstream-ownership-and-explicit-profiles.md`](decisions/0005-thin-upstream-ownership-and-explicit-profiles.md)

## Public Product Documentation

- [`../README.md`](../README.md): public product entry point and setup.
- [`../doc/clarity_lazyvim_complete_guide_zh.md`](../doc/clarity_lazyvim_complete_guide_zh.md): Chinese end-user guide.

## Historical And Reference Material

- [`../doc/clarity_architecture_governance.md`](../doc/clarity_architecture_governance.md):
  older product/architecture evaluation. Retained for history; its scores and
  validation snapshots are not current authority.
- [`../progress/`](../progress/): dated plans and closeouts. Completed closeouts
  are evidence of past work, not proof of current runtime or CI health.

## Maintenance Rules

1. Update the current-state ledger when repository facts or active pointers
   change.
2. Update the PLAN+TASK status during execution; do not use chat as the status
   ledger.
3. Add a dated review only when new evidence materially changes the assessment.
4. Add ADRs during implementation/closeout when a durable decision is adopted.
5. Keep historical documents, but label them clearly and do not copy their
   scores into current marketing without fresh evidence.
