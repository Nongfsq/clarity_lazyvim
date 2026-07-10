# ADR-0003: CI Evidence Boundary

Status: accepted locally; remote matrix evidence pending
Date: 2026-07-09

## Context

Historical CI used drifting OS packages, failed to resolve the Windows Neovim
binary, had no macOS job or subprocess timeout, and validated implicit user-style
paths rather than a clean candidate.

## Decision

Required runtime CI uses:

- official Neovim `v0.12.4` assets with recorded SHA-256 digests;
- pinned Python 3.12, Node 22, provider packages, and immutable action SHAs;
- Ubuntu 24.04, Windows 2022, and macOS 14;
- isolated config/data/state/cache roots;
- a copied candidate repository for first boot and restart;
- bounded processes/jobs, static contracts, unchanged authority files, and
  uploaded machine-readable evidence.

Workflow push economics remain unchanged: automatic push validation targets
`main`; task branches use pull requests or explicit `workflow_dispatch`.

## Rejected Alternatives

- apt/Chocolatey Neovim: rejected because versions and paths drift.
- Validating the developer cache: rejected because it masks clean-install bugs.
- Moving major action tags without immutable SHAs: rejected for supply-chain and
  reproducibility reasons.

## Consequences

CI setup is more explicit and downloads official artifacts, but failures become
repeatable and diagnosable. No platform is declared green until its remote job
completes for the exact commit.

## Revisit Trigger

Revisit when the supported Neovim floor changes, GitHub runner labels change, or
Clarity adopts a packaged distribution artifact.
