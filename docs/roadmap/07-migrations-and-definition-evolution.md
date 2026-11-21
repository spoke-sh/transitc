# 7. Migration synthesis and definition evolution

Status: In Progress

Prerequisites: [compiler extraction](03-compiler-and-cli.md), admitted source
forms from [milestone 5](05-typed-composition-and-sql.md), and the per-kind
Transit migration/definition contracts. Protected-generation cases additionally
need [milestone 8](08-protected-workflows.md).

Let an author compare desired definitions with an explicit prior basis, review
immutable SQL, and apply it through Transit without reinterpreting accepted work.
This expands former M12 P4/D5 and completion-plan C/F. It does not move migration
application, receipts or generation management into transitc.

## Delivered foundation

The [Table migration contract](../../contracts/APPLICATION_SOURCE_V1.md#table-migration-targets)
and [migration reference](../handbook/reference/artifacts.md) cover explicit offline
bases, multi-schema Table creation, restricted foreign-key dependencies and safe
trailing column additions. Builds emit desired SQL, successor basis, provenance
and immutable migration history. Unsupported/destructive differences reject.

Conditional runtime-definition replacement, arbitrary transforms, Queue-program
migration coverage and every resource kind below remain separate delivery work.

## Delivery units

| Unit | Compiler deliverable | Transit prerequisite and acceptance |
| --- | --- | --- |
| 7.1 — Broader definition diff | Extend neutral desired/prior descriptors and dependency ordering per supported KV, Document, Stream, Queue, view, dataflow, source, sink or publication kind. Include domain/variant representations and behavioral contracts in definition analysis. | Ordinary SQL preparation, staged dependencies, fingerprints and durable step receipts exist for that kind. Fresh desired-state execution and replayed migration agree under identical bindings. |
| 7.2 — Explicit transforms | Specify user-authored transforms for destructive/ambiguous changes and classify online rewrites separately from additive DDL. | The runtime owns rewrite progress, isolation and recovery. Drop/type/collation/table-split changes never silently infer data loss or overwrite accepted history. |
| 7.3 — Conditional replacement | Emit a reviewed expected-prior-definition condition and explicit replacement policy; retain source provenance without making it runtime authority. | Qualify `require_idle`, then `pin_generation`, then `drain_active` through upstream definition/generation owners. All three policies remain completion criteria. |
| 7.4 — Capacity qualification | Measure emitted statement sizes, migration bytes, dependency graph work and proposal memory using real expanded modules. | Preserve 1 MiB statements, 2 MiB migration files and 64 steps at the reviewed basis. The proposed 256-step profile requires upstream receipt/wire/recovery qualification and a coordinated compatible pin before emission. |

Units 7.1 and 7.4 can proceed per runtime capability. Unit 7.2 requires an explicit
transform contract before syntax/adapters. Unit 7.3 follows the relevant kind's
receipts and lifecycle; public-data replacement need not wait for all protected
workflows, but protected cases must pass before claiming that profile.

## Safe replacement obligations

For each policy, specify new admission, in-flight leases/continuations, timeout,
cancellation, restart, retired generation retention and collection. Accepted
operations retain the definition under which they were admitted. A changed
source tree, compiler, dependency or policy cannot reinterpret that operation.
Drain/fencing and retained immutable plans are upstream runtime mechanisms.

Test stale replacement conditions, revoked access, lost apply replies, concurrent
admission, restart during drain, pinned old work and incomplete transformations.
An unknown result stays unknown until the owning operation resolves it; retrying
under a new token is not recovery. Revalidate affected proof obligations when a
representation, effect or transition contract changes.

## Ownership and independent checks

[CatalogDiff](../../packages/transitc-compiler/src/CatalogDiff.zig) owns pure
classification; [BuildMigration](../../packages/transitc-workspace/src/BuildMigration.zig)
owns confined basis/history I/O and publication. Transit owns
[migration execution](https://github.com/spoke-sh/transit/blob/main/contracts/MIGRATION_V1.md),
catalog definitions and accepted receipts. Builds neither query a live catalog
for an implicit basis nor apply, authorize or activate emitted changes.

Use an independent final-definition projection to compare fresh deployment and
history replay. Compare logical fingerprints and definition digests separately
from historical revisions. Run native plan/apply/resume with source absent,
modified history, corruption and live drift; preserve original SQL bytes and
operation identities. Shared generation of both sides is insufficient evidence.

## Documentation and completion

Publish walkthroughs for a safe additive upgrade, an explicitly rejected
destructive change, an admitted transform and each replacement policy once
implemented. Show proposed versus applied state and how to inspect or resume an
uncertain application through Transit's owning operations.

Complete when each admitted kind has independent diff/replay and native recovery
evidence, all three replacement policies preserve old work, and unsupported
changes fail before artifact completion. The capacity result must state the
qualified bound; the proposed larger limit cannot be claimed from a constant
change. The 256-step criterion stays open until qualified or explicitly revised
in review. Link exact compiler/runtime revisions and upstream lifecycle evidence.
