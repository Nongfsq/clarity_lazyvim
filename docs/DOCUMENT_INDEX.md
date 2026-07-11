# Documentation Index

## Canonical Documents

| Purpose | Document | Authority |
| --- | --- | --- |
| Current repository state | [`ai/current-reality.md`](ai/current-reality.md) | Current facts, known gaps, active-plan pointer |
| Delivery workflow | [`ai/default-agent-delivery-workflow.md`](ai/default-agent-delivery-workflow.md) | Detailed planning, execution, and closeout workflow |
| Historical 95+ baseline | [`reviews/2026-07-09-clarity-95-quality-review.md`](reviews/2026-07-09-clarity-95-quality-review.md) | Preserved 58/100 pre-refactor evidence baseline |
| Current implementation review | [`reviews/2026-07-11-observation-surface-implementation-review.md`](reviews/2026-07-11-observation-surface-implementation-review.md) | Implemented behavior, local 92/100 score, and remaining evidence gates |
| Foundational refactor architecture | [`architecture/2026-07-09-clarity-95-refactor-blueprint.md`](architecture/2026-07-09-clarity-95-refactor-blueprint.md) | Historical approved target boundaries and migration sequence |
| Historical runtime verification architecture | [`architecture/2026-07-09-runtime-contract-verification-blueprint.md`](architecture/2026-07-09-runtime-contract-verification-blueprint.md) | Implemented natural-lifecycle contract model and fault boundary |
| Historical observability/test architecture | [`architecture/2026-07-10-observability-and-test-system-blueprint.md`](architecture/2026-07-10-observability-and-test-system-blueprint.md) | Implemented typed actions, structured diagnostics, and test routing |
| Foundational product/UX intent | [`product/clarity-95-experience-pm.md`](product/clarity-95-experience-pm.md) | Historical user promise, minimum lovable scope, and 95+ bar |
| Historical runtime trust PM | [`product/clarity-runtime-trust-pm.md`](product/clarity-runtime-trust-pm.md) | Implemented runtime-trust goals and acceptance outcomes |
| Historical diagnostics/test PM | [`product/clarity-diagnostics-and-test-experience-pm.md`](product/clarity-diagnostics-and-test-experience-pm.md) | Implemented action failure, recovery, privacy, and test experience |
| Active PLAN+TASK | [`../progress/2026-07-11-agent-era-observation-surface-plan.md`](../progress/2026-07-11-agent-era-observation-surface-plan.md) | Current task IDs, execution evidence, remaining gates, and delivery status |
| Historical runtime verification PLAN+TASK | [`../progress/2026-07-09-runtime-contract-verification-plan.md`](../progress/2026-07-09-runtime-contract-verification-plan.md) | Completed runtime-contract task status and evidence |
| Historical observability/test PLAN+TASK | [`../progress/2026-07-10-observability-and-test-system-plan.md`](../progress/2026-07-10-observability-and-test-system-plan.md) | Completed diagnostic, fold-action, and test-router ledger |
| Historical interaction/dependency review | [`reviews/2026-07-10-interaction-dependency-modernization-review.md`](reviews/2026-07-10-interaction-dependency-modernization-review.md) | Pre-agent-era evidence; its optional-Copilot and dependency recommendations were superseded by ADR-0006/0007 |
| Resolved dependency manifest | [`reviews/2026-07-10-resolved-dependency-manifest.md`](reviews/2026-07-10-resolved-dependency-manifest.md) | Active/locked set, retention rationale, lock rollback evidence |
| Historical simplification PLAN+TASK | [`../progress/2026-07-10-interaction-dependency-simplification-plan.md`](../progress/2026-07-10-interaction-dependency-simplification-plan.md) | Completed local/manual-Ubuntu execution ledger |
| Historical agent-era product intent | [`product/clarity-agent-era-review-console-pm.md`](product/clarity-agent-era-review-console-pm.md) | Implemented review-first product boundary and success criteria |
| Historical agent-era architecture | [`architecture/2026-07-10-agent-era-editor-surface-blueprint.md`](architecture/2026-07-10-agent-era-editor-surface-blueprint.md) | Implemented dependency, ownership, migration, and verification decisions |
| Historical agent-era PLAN+TASK | [`../progress/2026-07-10-agent-era-review-console-plan.md`](../progress/2026-07-10-agent-era-review-console-plan.md) | Completed review-console execution ledger |
| Observation-surface architecture | [`architecture/2026-07-11-agent-era-observation-surface-blueprint.md`](architecture/2026-07-11-agent-era-observation-surface-blueprint.md) | Approved interaction, localization, Git-observation, and dependency target |
| Keymap decision report | [`reviews/2026-07-11-keymap-surface-decision-report.md`](reviews/2026-07-11-keymap-surface-decision-report.md) | Per-key leader/context/component audit, hidden-mutation counter-evidence, and target manifest |
| Observation-surface product intent | [`product/clarity-observation-surface-pm.md`](product/clarity-observation-surface-pm.md) | Approved observation-first experience, scope, success criteria, and dependency gates |
| Local agent contract | `AGENTS.md` at repository root | Durable local implementation rules; intentionally ignored by Git and therefore not a public repository link |

## Accepted Decisions

- [`decisions/0001-root-runtime-authority.md`](decisions/0001-root-runtime-authority.md)
- [`decisions/0002-readiness-signals.md`](decisions/0002-readiness-signals.md)
- [`decisions/0003-ci-evidence-boundary.md`](decisions/0003-ci-evidence-boundary.md)
- [`decisions/0004-natural-lifecycle-runtime-contracts.md`](decisions/0004-natural-lifecycle-runtime-contracts.md)
- [`decisions/0005-thin-upstream-ownership-and-explicit-profiles.md`](decisions/0005-thin-upstream-ownership-and-explicit-profiles.md)
- [`decisions/0006-agent-era-review-console.md`](decisions/0006-agent-era-review-console.md)
- [`decisions/0007-cataloged-observation-surface.md`](decisions/0007-cataloged-observation-surface.md)

## Public Product Documentation

- [`../README.md`](../README.md): public product entry point and setup.
- [`../doc/clarity_lazyvim_complete_guide_zh.md`](../doc/clarity_lazyvim_complete_guide_zh.md): Chinese end-user guide.

## Historical And Reference Material

- [`../doc/clarity_architecture_governance.md`](../doc/clarity_architecture_governance.md):
  older product/architecture evaluation. Retained for history; its scores and
  validation snapshots are not current authority.
- [`../progress/`](../progress/): dated plans and closeouts. Completed closeouts
  are evidence of past work, not proof of current runtime or CI health.
- [`../progress/2026-07-11-observation-surface-closeout.md`](../progress/2026-07-11-observation-surface-closeout.md):
  local implementation closeout and remaining platform evidence boundary.

## Maintenance Rules

1. Update the current-state ledger when repository facts or active pointers
   change.
2. Update the PLAN+TASK status during execution; do not use chat as the status
   ledger.
3. Add a dated review only when new evidence materially changes the assessment.
4. Add ADRs during implementation/closeout when a durable decision is adopted.
5. Keep historical documents, but label them clearly and do not copy their
   scores into current marketing without fresh evidence.
