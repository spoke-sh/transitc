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
inspected on 2026-11-18. The source checkout was clean.

The upstream integration pin and proposed extraction basis were refreshed on
2026-11-19 to
[`e7434306334e3692c6f3e123cba0d278fa412196`](https://github.com/spoke-sh/transit/tree/e7434306334e3692c6f3e123cba0d278fa412196),
the verified upstream `main` at that time. The compiler manifest still depends
on `transit_fuze`, `transit_memory`, and `transit_protocol`; the toolchain pins
and CLI build/source/migration adapters are unchanged. The source contract,
compiler, grammar and verification corpus now include:

- `UUID`, `TIMESTAMPTZ` and `BINARY` source scalars, plus `ROW(...)` helper parameters.
- Concrete `BIND SCHEMA` specialization and schema-qualified catalogs/programs.
- Restricted `EXPORT REFERENCE TABLE` handles, reference non-escalation and
  catalog-tracked `NOT ENFORCED` foreign keys.
- Multi-schema Table migration synthesis and its revised explicit basis fields.

Extraction must preserve these additions and the current definition identity;
the original inventory is not the full parity target. The seven upstream
integration cases cover the existing small Table fixture, not all of these new
features. Move their upstream positive/negative and independent verification
coverage with the compiler. Dependency ownership remains unresolved and
milestones 2–4 remain Planned. Freeze this exact basis when implementation starts,
or explicitly review and record another update before comparing outputs.

Maintain one numbered file per independently reviewable milestone. Use `Planned`,
`In Progress`, or `Completed` in both its header and this index. Completion
requires the listed checks and evidence, not just a file move. Preserve completed
milestones and update dependency links when changing sequence. Current behavior
belongs in the [handbook](../handbook/guides/introduction.md), not only here.

## Proposed implementation sequence for review

These are reviewable slices within milestones 2–4, not additional milestones or
completed work. Keep language changes separate from extraction and use the
frozen revision above as the comparison target.

| Slice | Deliverable | Acceptance before proceeding |
| --- | --- | --- |
| 1 — Dependency boundaries (M2) | Inventory imported symbols and their transitive owners; settle shared SQL, diagnostic, protocol-value and memory packages, exact pins, attribution and identity rules. Include CLI helpers such as artifact hashing and reporting. | A minimal pure compilation and Transit-consumer proof uses one implementation of shared semantics, with no sibling checkout or circular repository/build dependency. |
| 2 — Comparison harness (M3) | Bring over the source contract, independent grammar/corpus, verification adapters and fixture families. Establish the upstream baseline before changing compiler ownership. | Golden SQL, source maps, diagnostics and positive/negative cases cover the frozen profile, including multi-schema isolation, reference non-escalation, new scalars, helpers and migrations. |
| 3 — Pure compiler (M3) | Move the compiler and bounded diagnostic owners into real packages with manifests, public APIs and root build/check wiring. Preserve parsing, typing, lowering, formatting, migrations and test-product compilation together initially. | Old/new semantic parity, independent SQL verification, allocation-failure cleanup and input/output/budget limits pass without filesystem, network or runtime services in the compiler. |
| 4 — Workspace and CLI (M3) | Move source capture/resolution, locks, explicit fetch, overrides, provenance and artifact publication into `transitc-workspace`; compose them through the CLI. | Offline builds, lock/digest failures, invalid paths, human/JSON diagnostics, deterministic reuse, corruption rejection and incomplete-publication failures pass from a standalone checkout. |
| 5 — Migration/test adapters and Transit cutover (M3) | Wire immutable migration basis/history I/O and compile-only test products; migrate Transit consumers to the agreed shared packages and retire superseded ownership together. | Migration history bytes and definition checks survive; emitted SQL executes against the pinned runtime; runtime test execution is separately qualified or explicitly unavailable. Required Transit gates pass before updating its PR. |
| 6 — Documentation and release qualification (M4) | Complete installation, build/dependency, diagnostic, artifact, migration, test and embedding guides with runnable examples and recorded compatibility. | Clean-checkout package builds, supported-host checks, example coverage, both handbook base paths and compiler/runtime compatibility pass with revisions and limitations recorded. |

The first review decision is shared SQL ownership: `transitc-sql` may live here
and be consumed by Transit, or be supplied by an independently pinned owner.
The dependency proof must settle this before the compiler moves. In particular,
moving SQL here must not leave it importing Transit-owned protocol values that
in turn depend on it; the development/test Transit flake input also needs an
acyclic distribution strategy if Transit starts consuming this flake.

Proposed CLI mapping for slice 4: `transitc build`, `transitc build --check` and
`transitc build --fetch`, preserving the existing entry, target, output,
override, format and color options. These are review proposals, not commands
implemented by the scaffold. Runtime execution stays with Transit initially;
do not expose `transitc test` until its execution adapter is qualified. Decide
how Transit's existing build/test commands migrate as part of the consumer
contract, before removing their implementation.

Parity must distinguish semantic output from tool identity. The existing CLI
includes its executable digest and revision in provenance and input/cache
identity, so independently built executables need not have identical build
digests. Compare exact SQL, maps and diagnostics; require deterministic rebuilds
per compiler; enumerate and test the expected identity differences. Never mask
definition mismatches or rewrite accepted migration history to make comparisons
pass.
