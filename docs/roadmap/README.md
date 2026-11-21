# Compiler roadmap

Deliver a standalone Transit language toolchain: compose typed `.transit`
applications, format and check source, emit independently executable SQL, propose
immutable migrations and test the same programs through a compatible Transit host.
Milestones 1–4 retain the extraction and release foundation; milestones 5–10
expand the compiler work transferred from Transit's milestone 12. Runtime SQL,
authorization, storage, migration application and durable execution stay upstream.

| Order | Milestone | Status | Prerequisites |
| --- | --- | --- | --- |
| 1 | [Repository bootstrap](01-repository-bootstrap.md) | Completed | None |
| 2 | [Dependency boundaries](02-dependency-boundaries.md) | Completed | 1 |
| 3 | [Compiler and CLI extraction](03-compiler-and-cli.md) | Completed | 2 |
| 4 | [Documentation and qualification](04-documentation-and-qualification.md) | Completed | 3; documentation grows throughout |
| 5 | [Typed composition and executable SQL](05-typed-composition-and-sql.md) | In Progress | 3; ordinary SQL contract for each new operation |
| 6 | [Reproducible workspaces and developer tooling](06-workspaces-and-developer-tooling.md) | In Progress | 3; 5 for new source forms |
| 7 | [Migration synthesis and definition evolution](07-migrations-and-definition-evolution.md) | In Progress | 3; admitted forms from 5 and per-kind Transit receipts; 8 for protected generations |
| 8 | [Protected workflows and runtime integration](08-protected-workflows.md) | Planned | 5; Transit module-authority, serving and managed-execution contracts |
| 9 | [Deterministic tests and replay](09-deterministic-tests-and-replay.md) | In Progress | 3 and compatible host; 7/8 for replacement/protected schedules |
| 10 | [Whole-application and performance qualification](10-application-qualification.md) | Planned | Required profiles of 5–9 and their Transit owners |

Numbering is a reading/delivery sequence, not a requirement to finish every earlier
milestone before starting independent work. In Progress includes an implemented
foundation with unfinished acceptance criteria; it does not assert completion of
the proposed units. The [extraction qualification](../qualification/extraction.md)
records executed foundation checks separately from the expanded feature and
performance work in milestones 5–10.
The [typed composition qualification](../qualification/typed-composition.md)
records milestone 5's delivered increments, passing evidence and open gates.
Its [next proposed slice](05-typed-composition-and-sql.md#next-slice-complete-the-existing-composition-profile)
finishes isolated execution and whole-input ROW specialization before further
runtime-dependent language expansion.

## Source and ownership

Extracted on 2026-11-20 from Transit
[`4e47372a2739444d30058934dd0bb8bd703ef65c`](https://github.com/spoke-sh/transit/tree/4e47372a2739444d30058934dd0bb8bd703ef65c):
the [original compiler milestone](https://github.com/spoke-sh/transit/blob/4e47372a2739444d30058934dd0bb8bd703ef65c/docs/roadmap/12-application-modules-compilation-and-testing.md)
and its [completion plan](https://github.com/spoke-sh/transit/blob/4e47372a2739444d30058934dd0bb8bd703ef65c/docs/roadmap/application-modules-completion.md).
Those records retain the D1–D6 rationale, P0–P6 journeys, earlier approved slices
and source-specific evidence. The local baseline is transitc
[`77c56a0dd1562fc1bbda070873c38817091ddd5a`](https://github.com/spoke-sh/transitc/tree/77c56a0dd1562fc1bbda070873c38817091ddd5a),
including `fmt`. Reading newer upstream plans does not change the dependency,
runtime or frozen-comparison pins below.

| Responsibility | Delivery owner | Required boundary |
| --- | --- | --- |
| Source grammar, typed core, lowering, formatting, pure migration/test products | `transitc-compiler` | Resolved bounded inputs; no filesystem, network or runtime services |
| Capture, exact dependencies/locks, explicit fetch, artifact publication, test orchestration | `transitc-workspace` | Explicit I/O; offline ordinary builds and no implicit migration application |
| Commands, help, reports and process exit behavior | `apps/transitc-cli` | Thin composition of the public packages |
| Shared SQL/scalar/protocol/memory and compiled-case definitions | Transit pure packages | One semantic owner, exact immutable distribution and definition checks |
| SQL execution, current rights, transactions, migration receipts, generations and test host | Transit | Ordinary executable operations; no dependency on transitc or source repositories |

The [package map](../../packages/README.md) and
[source contract](../../contracts/APPLICATION_SOURCE_V1.md) own implemented
boundaries. Transit retains [M12](https://github.com/spoke-sh/transit/blob/main/docs/roadmap/12-application-modules-compilation-and-testing.md)
as its integration/dependency milestone. New package directories are justified by
actual independent code/dependencies, not by a planning topic alone.

## Original scope mapped to the new sequence

| Original scope | Current plan | Preserved obligation |
| --- | --- | --- |
| D1/D4; P0 — one dialect, stages, grammar, bounds and shared checking | 5, 6 | `build.transit` uses the same module semantics; independent grammar, full body parsing, typed origins and executable SQL; upstream owns SQL framing/limits |
| D2; P1 — recursive packages, instances and encapsulation | 5, 6, 8 | Exact offline dependencies, stable explicit bindings, typed exports and separately enforced runtime privacy |
| D3; P2 — profiles, functions, guards and procedures | 5, 8 | Typed hygienic composition, ordered refusals, single atomic caller transaction and no implicit privilege |
| P3 — whole-program types, effects, capabilities, secrets and activation | 5, 8 | Explicit external-input validation, complete settlement paths, protected disclosure and current runtime authority |
| D5; P4; completion C/F — migrations and replacement | 7 | Explicit basis, immutable history, independent final-definition equivalence and all three generation policies |
| D6; P5; completion G — tests, simulation and formal evidence | 9; feature-local checks in 5/8 | Production emitter/real host, bounded deterministic schedules, uncertainty, selected TLA+/Lean evidence and native correspondence |
| P6; completion A/H — reconciliation, full workload, performance and handbook | 4, 10 | Exact evidence revisions, complete inventory, retained failures, measured targets and runnable user documentation |

## Next implementation order

1. Use the qualified compiler/runtime pair and explicit support boundaries in the
   [extraction record](../qualification/extraction.md) as the baseline. Keep its
   clean-cache, native archive, compatibility and handbook gates passing as the
   later milestones extend the supported profile.
2. Review the [milestone 5 implementation plan](05-typed-composition-and-sql.md#implementation-plan-for-review),
   starting with 5.1's dynamic SQL representation, alongside 8.1's runtime
   privilege contract. Extend recursive-package/formatter/diagnostic evidence
   in 6 independently.
3. Extend 7.1 per available runtime kind and measure 7.4 capacity without changing
   limits implicitly. Start 9.1 when real subject/grant controls exist upstream.
4. Add profiles, effect/ownership/disclosure and transition checks in 8 as their
   ordinary runtime operations become executable. Qualify 7.3's replacement
   policies incrementally; extend 9 with virtual time, effects and replay.
5. Close the complete application/performance matrix in 10, feeding supported
   profiles and compatibility into 4's handbook/host/release process.

Each implementation slice must name its contract, runtime prerequisite, accepted
and rejected examples, diagnostic/formatting changes, independent evidence and
guide updates. A per-operation upstream handoff suffices; an entire adjacent
Transit milestone is not an implicit prerequisite. Optional AOT integration with
Transit M17 reuses this graph and bound SQL semantics after artifact/ABI review.

## Extraction basis and preserved history

The sections below retain the original extraction sequence and evidence. They
explain the implemented foundation; the sequence above owns subsequent language
and tooling work.

Source inventory basis: Transit commit
[`c1f2680d9353175e58ad503e750e7b4da76a84c5`](https://github.com/spoke-sh/transit/tree/c1f2680d9353175e58ad503e750e7b4da76a84c5),
inspected on 2026-11-18. The source checkout was clean.

The upstream integration pin and proposed extraction basis were refreshed on
2026-11-19 to
[`e7434306334e3692c6f3e123cba0d278fa412196`](https://github.com/spoke-sh/transit/tree/e7434306334e3692c6f3e123cba0d278fa412196),
the verified upstream `main` at that time. At that basis the compiler manifest depended
on `transit_fuze`, `transit_memory`, and `transit_protocol`; the toolchain pins
and the CLI build/source/migration adapters were unchanged. The source contract,
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
coverage with the compiler. At that review point dependency ownership was
unresolved and milestones 2–4 were Planned. Freeze this exact basis when implementation starts,
or explicitly review and record another update before comparing outputs.

Maintain one numbered file per independently reviewable milestone. Use `Planned`,
`In Progress`, or `Completed` in both its header and this index. Completion
requires the listed checks and evidence, not just a file move. Preserve completed
milestones and update dependency links when changing sequence. Current behavior
belongs in the [handbook](../handbook/guides/introduction.md), not only here.

## Reviewed implementation sequence

The implementation follows these slices within milestones 2–4. The acceptance
criteria below remain the basis for qualification. Keep language changes separate from extraction and use the
frozen revision above as the comparison target.

| Slice | Deliverable | Acceptance before proceeding |
| --- | --- | --- |
| 1 — Dependency boundaries (M2) | Inventory imported symbols and their transitive owners; settle shared SQL, diagnostic, protocol-value and memory packages, exact pins, attribution and identity rules. Include CLI helpers such as artifact hashing and reporting. | A minimal pure compilation and Transit-consumer proof uses one implementation of shared semantics, with no sibling checkout or circular repository/build dependency. |
| 2 — Comparison harness (M3) | Bring over the source contract, independent grammar/corpus, verification adapters and fixture families. Establish the upstream baseline before changing compiler ownership. | Golden SQL, source maps, diagnostics and positive/negative cases cover the frozen profile, including multi-schema isolation, reference non-escalation, new scalars, helpers and migrations. |
| 3 — Pure compiler (M3) | Move the compiler and bounded diagnostic owners into real packages with manifests, public APIs and root build/check wiring. Preserve parsing, typing, lowering, formatting, migrations and test-product compilation together initially. | Old/new semantic parity, independent SQL verification, allocation-failure cleanup and input/output/budget limits pass without filesystem, network or runtime services in the compiler. |
| 4 — Workspace and CLI (M3) | Move source capture/resolution, locks, explicit fetch, overrides, provenance and artifact publication into `transitc-workspace`; compose them through the CLI. | Offline builds, lock/digest failures, invalid paths, human/JSON diagnostics, deterministic reuse, corruption rejection and incomplete-publication failures pass from a standalone checkout. |
| 5 — Migration/test adapters and Transit cutover (M3) | Wire immutable migration basis/history I/O and `transitc test` orchestration over a compiled-case host; migrate Transit consumers to shared packages and retire superseded ownership together. | Migration history bytes and definition checks survive; emitted SQL and application tests execute against the pinned runtime. Required Transit gates pass before updating its PR. |
| 6 — Documentation and release qualification (M4) | Complete installation, build/dependency, diagnostic, artifact, migration, test and embedding guides with runnable examples and recorded compatibility. | Clean-checkout package builds, supported-host checks, example coverage, both handbook base paths and compiler/runtime compatibility pass with revisions and limitations recorded. |

The first review decision was shared SQL ownership: `transitc-sql` could live here
and be consumed by Transit, or be supplied by an independently pinned owner.
The dependency proof must settle this before the compiler moves. In particular,
moving SQL here must not leave it importing Transit-owned protocol values that
in turn depend on it; the development/test Transit flake input also needs an
acyclic distribution strategy if Transit starts consuming this flake.

The reviewed CLI mapping for slice 4 was `transitc build`, `transitc build --check` and
`transitc build --fetch`, preserving the existing entry, target, output,
override, format and color options. These commands are now implemented and
documented in the handbook. The extraction scope also includes `transitc test`:
source resolution, compilation, orchestration and reports move here, while a
bounded compiled-case host in Transit retains database execution. Transit's
source commands are removed; its native host executes compiled test cases.

Parity must distinguish semantic output from tool identity. The existing CLI
includes its executable digest and revision in provenance and input/cache
identity, so independently built executables need not have identical build
digests. Compare exact SQL, maps and diagnostics; require deterministic rebuilds
per compiler; enumerate and test the expected identity differences. Never mask
definition mismatches or rewrite accepted migration history to make comparisons
pass.

## Implementation status

Compiler and workspace sources, source contracts, diagnostics, grammar/model
proofs and build/test command schedules live here. The CLI supports
`transitc build`, `transitc fmt` and `transitc test`. Transit is the upstream owner of shared SQL,
protocol, memory and compiled-case test types, plus native database execution.
Transit contains no compiler snapshot or dependency on transitc.

Standalone manifests pin the deterministic five-package pure source archive at
Transit `f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6`, with both Zig content hash and
Nix SHA256. The comparison binary remains frozen at
`e7434306334e3692c6f3e123cba0d278fa412196`; the compatible compiled-case host is
selected separately by the `transit` flake input. The
[one-way Transit cutover](https://github.com/spoke-sh/transit/pull/474) is merged.
The [qualification record](../qualification/extraction.md) identifies standalone
compiler, emitted-SQL and compiled-case host checks; previous embedded-consumer
results are not substituted for that evidence.
