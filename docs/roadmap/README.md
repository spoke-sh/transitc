# Extraction roadmap

Prepare transitc to receive the compiler without changing the language during
the move. This is a new roadmap using Transit's numbered milestone structure;
it does not copy the runtime product backlog or inherit its completion claims.

| Order | Milestone | Status | Prerequisites |
| --- | --- | --- | --- |
| 1 | [Repository bootstrap](01-repository-bootstrap.md) | Completed | None |
| 2 | [Dependency boundaries](02-dependency-boundaries.md) | Planned | 1 |
| 3 | [Compiler and CLI extraction](03-compiler-and-cli.md) | Planned | 2 |
| 4 | [Documentation and qualification](04-documentation-and-qualification.md) | Planned | 3; documentation grows throughout |

Source inventory basis: Transit commit
[`c1f2680d9353175e58ad503e750e7b4da76a84c5`](https://github.com/spoke-sh/transit/tree/c1f2680d9353175e58ad503e750e7b4da76a84c5),
inspected on 2026-11-18. The source checkout was clean. Freeze a fresh explicit
basis when extraction starts and record changes from this inventory.

Maintain one numbered file per independently reviewable milestone. Use `Planned`,
`In Progress`, or `Completed` in both its header and this index. Completion
requires the listed checks and evidence, not just a file move. Preserve completed
milestones and update dependency links when changing sequence. Current behavior
belongs in the [handbook](../handbook/guides/introduction.md), not only here.
