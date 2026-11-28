# Milestone 5: bounded many-row results

Status: Completed

The [qualification record](../qualification/bounded-many.md) retains the completed
baseline schedules and records candidate gates separately. Native clean/hosted
qualification, the 22-case installed comparison and local CLI/package gates pass.
The three local isolated schedules retain deadline failures. Three hosted
49-case passes succeed with unchanged limits, and all four signed native archive
jobs pass, including the macOS retry after an identity-token timeout. The paired changes are
[Transit #480](https://github.com/spoke-sh/transit/pull/480) and
[transitc #7](https://github.com/spoke-sh/transitc/pull/7), both merged on 2026-11-27,
native owner first. The [M5 completion plan](05-completion-plan.md) now sequences
all remaining milestone work. The approved plan below preserves the original
proposal and acceptance inventory. The [query-results guide](../handbook/guides/query-results.md) describes
the implemented syntax and profile.

Implementation plan for review, 2026-11-23. This slice advances
[5.2](05-typed-composition-and-sql.md#delivery-units); milestone 5 remains
**In Progress** after it ships.

## Recommendation and starting point

Add a bounded, immutable query-result collection and explicit consumption of its
rows inside one atomic program. Implement and qualify the ordinary SQL operation
in Transit first, then add transitc's cardinality, nominal typing, lowering and
guides. This makes multi-row processing useful without conflating an empty
collection, an absent OPTIONAL row and a present row containing NULL.

The reviewed compiler basis is `b914de44bb596e6df4940120e4c583a8bf9ba101`, the
merge of [transitc #6](https://github.com/spoke-sh/transitc/pull/6).
[Transit #479](https://github.com/spoke-sh/transit/pull/479) merged at
`6201f4d5ffc5b1849888b396cc75503f10f073f2`. The compiler still deliberately pins
the shared archive and host to its included implementation revision,
`b58715bf4ef4e5236748547ce15e37a602c4b471`; a merge does not require a cosmetic
pin update. The old comparison compiler remains
`e7434306334e3692c6f3e123cba0d278fa412196`.

The [composition qualification record](../qualification/composition-completion.md)
separates merged implementation from executed evidence. At this planning check,
the PR's four native compiler/archive jobs and handbook job had passed; its main
compiler job and upstream storage/query lane were still running. The merge CI
runs were also in progress. Three complete local 42-case schedules have not been
recorded. Closing those gates is step 0, not an assumed consequence of merging.

At the pinned runtime, `ApplicationProgram.Select` has a target, projection and
predicate but no collection bound or ordering. `ApplicationProgramTypes.Kind`
and `ApplicationValue.Value` have records but no collection. Native
[`ApplicationData.select`](https://github.com/spoke-sh/transit/blob/b58715bf4ef4e5236748547ce15e37a602c4b471/packages/zig/transit-query-direct/src/ApplicationData.zig#L110)
scans a retained basis, returns a nullable record and
refuses a second match with `ProgramCardinalityMismatch`. It already accounts for
requests, scanned rows and result bytes. These are the owners to extend; adding
`MANY` to transitc's parser alone cannot supply the behavior.

## Proposed bounded profile

The spelling below is a **proposal**, not currently accepted source or SQL. Settle
the ordinary SQL spelling in the upstream contract before implementing source
admission; keep the emitted operation directly usable by SQL callers.

```sql
BEGIN ATOMIC
  LET selected MANY(16) = SELECT id, note FROM items
    WHERE batch = request.batch ORDER BY id;
  FOR item IN selected DO
    REQUIRE item.id > 0 ELSE 'InvalidItem';
    PRODUCE INTO processed VALUES (item.id, item.note);
  END FOR;
END;
```

This first profile has the following boundaries:

| Decision | Proposed contract |
| --- | --- |
| Collection | Immutable homogeneous rows; empty is a collection of length zero. Retain field names, physical descriptors, nullability and source nominal identities. No collection-to-row or collection-to-NULL coercion. |
| Row bound | Required compile-time integer `N`, initially 1–64. `N` is an assertion about the complete result, not SQL truncation. The `(N + 1)`th matching row refuses the read before any loop body runs. The cap is a proposed new native contract, subject to budget evidence before admission. |
| Query | One public Table, existing projection and predicate profile. Require explicit ascending order by its single BIGINT primary key, including nominal BIGINT keys. Start with this total order; refuse other orderings, joins and aggregates. Do not imply a general relational scalar expansion. |
| Observation | Read once from the caller's existing serializable transaction workspace. Finish selection, bounds checks and basis validation before consumption. Retain the original read dependencies through commit; a changed basis refuses through the native transaction owner. |
| Consumption | One level of explicit `FOR`, inside the same atomic block. The iterator is an immutable, present row. Allow existing scalar/ROW helpers, guards, conditional instructions and admitted transactional writes/appends. No nested iteration, reads inside the loop (including hidden helper reads), external effects, suspension or collection mutation. |
| Work | Enforce scanned-row, request, retained-byte, result-byte, iteration and transaction-statement bounds across the operation. A row bound alone does not bound a selective full-table scan. Include loop-body cost after helper expansion; no resetting a budget per iteration. |
| State boundary | Preserve SQL NULL in fields. Missing, type-error and conflict cells keep their existing native refusals and validation precedence until the separate state-carrying contract lands. A collection does not make these states representable. |
| Scope | Collections remain local to the atomic block; do not persist them as resource cells, export them, return them from callables or retain them across suspension. Existing ONE, OPTIONAL and unannotated SELECT semantics stay intact. |

Use the same native collation and key descriptor for ordering and uniqueness.
Either prove the native scan supplies this order or sort only the bounded
retained result within its explicit byte/work budget. Never sort an unbounded
intermediate. Duplicate values in non-key fields remain distinct rows.

Specify failure precedence in the contract: native schema/cell validation and row
conversion, predicate evaluation, matched-row bound, retained representation
bound, final basis validation, then ordered body execution. A refusal stops the
operation; it does not produce a partial collection. Do not reorder existing
ONE/OPTIONAL failures while sharing implementation. Body refusals preserve the
single caller transaction: writes and outputs from earlier iterations roll back.

## Implementation sequence

### 0. Finish qualification of the merged composition profile

Collect the final PR and merge CI outcomes and their retained phase reports;
record the actual tested revisions. Require a passing upstream clean storage/query
lane and complete compiler build-command, test-command and installed composition
schedules for the pinned pair. Run the predeclared three local passes with all
42 existing isolated cases per pass, fresh databases and no overlapping
storage-heavy qualification work. Keep failures and not-run entries visible.

Keep the 30-second case, 300-second suite and five-second cleanup limits. The
matched storage-latency diagnostics explain the reproduced failures; they do not
replace these gates. Investigate any new failure at its owner. Retain all three
predeclared outcomes rather than discarding a failed schedule and counting again.
Preserve earlier evidence under its original identities and append the new result.

This gate need not prevent independent contract/test design, but dependent
compiler admission must not build on an unresolved runtime regression. Successful
CI on the exact revision can satisfy its corresponding gate; repeat checks only
for changed code, missing coverage or an unresolved failure.

### 1. Define the native contract and independent SQL journey

In Transit, document collection shape, SQL grammar, order, overflow/error codes,
observation basis, scope and all numeric budgets. Extend the existing program
contract and diagnostic inventory; review definition/codec compatibility and
durable continuation changes before implementing them.

Author raw SQL independently of transitc: a batch selects several items, calls
a row-validation helper and produces one output per item. Retain empty, one,
multiple, nullable-field, over-bound and late-refusal counterparts. Use a unique
key with deliberately different insertion order. Verify execution order with an
ordered refusal/control trace, not only a multiset of output rows.

Add negative probes for invalid bounds, unsupported ordering, loop nesting,
collection projection/escape and hidden reads/effects. Specify how two independently
named instances bind the same helper without sharing resources. Establish the
expected typed rows, errors and transaction outcome before compiler generation.

**Gate:** reviewed ordinary SQL/representation contract and executable native
positive/negative tests. An upstream blocker stays explicit; no fallback through
JSON, generated offsets, repeated SELECTs or a compiler-side database loop.

### 2. Implement bounded native values, selection and iteration

Owners in Transit:

- `transit-sql-frontend`: `ApplicationProgram`, parser/codec, type binder and
  `ApplicationValue` own syntax, collection descriptors, validation and limits.
- `transit-fuze`: `ApplicationCursor`, `ApplicationEnvironment` and
  `ApplicationStep` own iteration scope, row binding and replayable advancement.
- `transit-query-direct`: `ApplicationData`, `ApplicationDeclaration`,
  `ApplicationInvocation`, `ApplicationExecution` and the transaction/read-set
  owners enforce actual reads, budgets, authority, staged effects and recovery.

Extend collection traversal, ownership, cloning, encoding and public-value checks
at every boundary. Budget cumulative row descriptors, payloads, scratch and
retained environments; check limits before allocating or retaining the next row.
Apply fault/allocation-failure coverage to partial selection and iterator setup.

The existing continuation checks bound a transaction step by `program.nodes * 3`.
Iteration changes that assumption. Derive a checked upper bound from the expanded
body and declared row cap; enforce it consistently in cursor advancement,
saved-state validation and execution. Preserve the existing global work ceilings
unless a separate, measured contract change justifies another value. Reject
overflow and over-budget programs before activation. Do not simply multiply a
timeout or weaken saved-state checks.

Bind each dynamic iteration to its original operation/step identity. Test refusal
after several staged writes, interruption before/after staging, restart and
duplicate completion. Recovery must neither repeat committed outputs nor skip an
iteration. Current rights still apply to each native operation and commit; a
collection or helper carries no grant.

**Gate:** direct SQL executes without transitc; exact bounds, error order,
transaction conflicts, revocation, recovery and cleanup pass. Existing singleton
reads and compiled-case protocol refusals remain passing. Regenerate the shared
archive from authoritative sources and run the required upstream checks before
merging the runtime PR.

### 3. Integrate the qualified runtime and add source typing

Update the shared distribution and compatible host together to the merged native
revision, with verified hashes and definition checks. Leave the frozen old compiler
unchanged. If native identities change, enumerate exact accepted differences in
parity; never normalize arbitrary definition mismatches. Change the compiled-case
protocol only if its payload actually changes, with explicit incompatible-host
tests where required.

In transitc, extend `Syntax.zig`/`Template.zig`, `ProgramLowering.zig`,
`ProgramAnnotations.zig`, typed operands and the working catalog as needed. Model
`many(row descriptor, bound, order)` separately from ONE/OPTIONAL and scalar
nullability. Check loop bodies once with a typed iterator, while separately
accounting for their bounded execution multiplicity. No synthetic sample rows.

Preserve nominal fields through aliases and direct/imported/nested ROW helpers.
Branch presence/refinement facts must remain scoped to the correct iterator and
branch. Reject a collection where a scalar or ROW is expected, a foreign-domain
field, iterator use after its scope and all excluded operations, including those
hidden by callable parameters. Extend all-arm symbolic checking with the same
rules; the separate 64-scalar analysis environment remains separate from authored
Queue fields and collection rows.

Emit the reviewed native operations, reparse/rebind through `ProgramCheck`, and
retain exact source origins. Update the source contract, independent ANTLR grammar,
positive/negative corpus, diagnostic mappings and formatter together. Add no root
task or CLI command.

**Gate:** independent typed projections and handwritten SQL agree; nominal,
scope, bound and effect mutation controls fail for the intended reason. Allocation
failure, formatting round trips and preexisting source correspondence remain
passing. Unsupported source forms fail before artifact publication.

### 4. Qualify the source-to-runtime journey and publish guides

Add an `application-bounded-many` fixture and installed generated/handwritten SQL
comparison. Extend `tests/integration/composition.json` with the complete case
inventory and reuse `test::composition`/`test::integration`. Retain every expected
case and phase; success is not inferred from process exit or partial output.

| Required coverage | Evidence |
| --- | --- |
| Cardinality and data | Zero, one, several, exact `N`, `N + 1`; duplicates outside the key; nullable field versus empty collection; same raw ID in different nominal domains. |
| Order and first error | Shuffled insertion order, exact key order, invalid cells/predicates, overflow, two differently failing loop rows and no body execution after selection failure. |
| Bounds | Row/byte/work/scan/request/transaction limits at and beyond boundaries; selective queries; many small reads cannot reset cumulative limits; allocation failures and forged collection/continuation shapes. |
| Composition | Direct/imported/nested helpers and exact callable effects; two instances; invalid unselected arm; no scope capture or repeated collection evaluation. |
| Atomic execution | Earlier writes/appends roll back on later refusal; changed read basis; current-rights denial; interruption, restart, duplicate completion and no surviving partial output. |
| Independence | Remove source before installed execution; compare generated and handwritten SQL and retain exact compiler/shared/host/definition identities. |

Use focused isolated cases that fit the existing budgets and retain a combined
installed journey. At closeout run the existing compiler/unit, grammar/type,
formatter, workspace, process/protocol and integration gates; clean-cache/public
embedding, explicit Nix source and package checks; release/four-native-archive
CI; and strict handbook/browser checks at both base paths. Record actual results
in a new qualification section. The three-pass composition schedule includes
the new inventory as well as the existing 42 cases.

Extend the cardinality guide with batch processing, an over-bound refusal and its
correction, empty versus nullable results, ordering and rollback. Add runnable
coverage to `tests/documentation.json`. Update the support matrix and runtime
handoff without claiming missing/type-error/conflict support.

## Logical commits and PRs

| Sequence | Commit scope | Repository / merge gate |
| --- | --- | --- |
| 0 | Record completed merged-profile qualification and any demonstrated owning fix | Respective owner; keep failures attributable |
| 1 | Native contract, independent SQL expectations and bounded value/parser tests | Transit PR A |
| 2 | Native selection, iteration, budgets and continuation/transaction behavior | Transit PR A |
| 3 | Native recovery/authority qualification, documentation and regenerated archive | Transit PR A; required checks pass and merge |
| 4 | Shared/host dependency integration and compatibility evidence | transitc PR B, depends on A |
| 5 | Source grammar, typed cardinality, iteration lowering, diagnostics and formatter | transitc PR B |
| 6 | Independent correspondence, installed/isolated fixtures and runnable guides | transitc PR B |
| 7 | Final qualification and roadmap status | transitc PR B; all slice gates pass |

Keep the native and compiler PRs linked. Commits 1–3 may split into additional
reviewable upstream PRs if continuation compatibility warrants it; no dependent
source admission ships before its runtime owner.

## Distance to milestone completion

This section preserves the estimate made before implementing bounded results.
The [current completion plan](05-completion-plan.md#delivery-order-commits-and-validation)
starts from the merged slice and breaks down all remaining work.

Milestone 5 has a substantial implemented foundation, but it is still in feature
delivery. The previous merge resolves the symbolic whole-ROW implementation gap;
it does not implement many-row values, cell states, scalar program types or views.

| Remaining delivery area | After this slice |
| --- | --- |
| Existing composition qualification | Closed only when step 0 and the final candidate checks have retained passing evidence. |
| Bounded many | This slice closes a deliberately limited local collection/iteration profile. |
| State-carrying values and conversions — 5.2 | Still needed: all five cell states, explicit conversions and their error precedence across rows/variants. |
| Query-result callable contracts — 5.3 | Explicitly settle and implement the required bounded query-signature/cardinality profile. Current scalar-returning callables and ROW arguments do not establish row/many returns. Those returns remain unsupported until their own contract; do not silently equate that with full 5.3 completion. |
| Scalar ordered-program surfaces — 5.4 | Still needed: DATE, exact NUMERIC, native INTERVAL and JSON literal/specialization gaps, one executable surface at a time. |
| Prepared and relational scalar surfaces — 5.4 | Still needed: typed symbolic JSON/INTERVAL Table binding and bounded relational transport of admitted scalars without invented comparison traits. |
| Ordinary views — 5.4 | Still needed: native DDL/binding/execution, identity/dependencies, authority and restart, followed by compiler admission. This remains required. |
| Final milestone qualification | Integrated cases, support matrix and guides across all required units, on an explicitly qualified compiler/runtime pair. |

For planning, budget **this slice plus roughly five further feature slices and a
final qualification pass**. That is a work breakdown, not a calendar or percentage
estimate: scalar surfaces may split further, and the query-signature review may
combine with cardinality work. Several slices require paired Transit/transitc
PRs. Ordinary views and durable bounded iteration carry the largest native design
uncertainty. Completing this slice alone will not make M5 ready for closeout.

Native UNION replacement, materialized views, general implication solving,
implicit callable subtyping, runtime closures and protected workflows are not
extra gates for this bounded M5 profile. Preserve the reviewed closed STRUCT
variant encoding and the separately owned later milestones.
