# Milestone 5 completion plan

Status: Planned

Implementation plan for review, 2026-11-27. This plan covers **all remaining work**
in [Typed composition and executable SQL](05-typed-composition-and-sql.md), not
just the next feature slice. M5 remains **In Progress** until the completion
matrix below has executed evidence. The earlier slice plans remain historical
acceptance inventories; this document owns the remaining implementation order.

## Starting point

[transitc #7](https://github.com/spoke-sh/transitc/pull/7) merged at
`a32b74e5a153db16ec0eeff5f3ef1a5e0b94b1d1` and
[Transit #480](https://github.com/spoke-sh/transit/pull/480) merged at
`f769f960618e53ce10ab3f1c016dc9f489b237e3`. Both checkouts were clean at inspection.
The compiler deliberately retains shared packages and host at
`d65f7c656c8e311806132ca894059b43b52051ee`; the merge alone does not require a pin
change. The old comparison compiler remains
`e7434306334e3692c6f3e123cba0d278fa412196`.

The final compiler PR [CI](https://github.com/spoke-sh/transitc/actions/runs/45351496750)
and [handbook workflow](https://github.com/spoke-sh/transitc/actions/runs/45351496709)
completed successfully. The [bounded-result qualification](../qualification/bounded-many.md)
retains the detailed feature evidence: ten installed phases, the 22-case
generated/independent SQL comparison and three hosted passes of 49 isolated cases.
It also retains the failed local schedules: 73 passes, 15 `TestDeadline` failures
and 59 unrun cases. Successful hosted results do not reclassify those failures.
These are PR/candidate results, not a claim about a newly executed merge campaign.

Dynamic closed-record variants, ONE/OPTIONAL, bounded MANY/FOR, whole-input ROW
specialization, ordered scalar obligations and exact scalar-returning callable
signatures are delivered. Keep their regression evidence and contracts; do not
restart those implementations.

| Remaining area | Inspected implementation boundary | Completion deliverable |
| --- | --- | --- |
| State-preserving values — 5.2 | Native `Values.Cell` already models all five states. `ApplicationData.fromCell` validates the cell, then program conversion admits only value/NULL. | Explicit state-preserving program/source values, inspection and checked conversions through rows, variants and helpers. |
| Query-result callable contracts — 5.3 | `Syntax.TypeRef` and helper returns are scalar/domain types. `ProgramAnnotations` already tracks ONE/OPTIONAL/MANY locals. | Exact row/optional/bounded-collection parameter and result contracts, with resource/effect identity and atomic lifetime preserved. |
| Scalar programs — 5.4 | `ApplicationSchema`/`ApplicationValue` lack DATE, NUMERIC and SQL INTERVAL representations. JSON runtime transport exists, but source program literals/symbolic holes remain refused. | Exact ordered-program representations and source admission for the four existing source scalar types. |
| Prepared/relational scalars — 5.4 | `LogicalPrepared.witness` refuses JSON/INTERVAL. The retained combined scalar projection with ORDER BY refuses `UnsupportedRelationalType`. | Typed symbolic Table parameters and bounded projection/filter/order/limit transport of the admitted scalars. |
| Ordinary views — 5.4 | Native accepted single-Table views already have catalog identity, dependencies and query expansion; SQL `CREATE VIEW` is unavailable. | Ordinary SQL declaration/binding and source composition over that native lifecycle, followed by source-free execution. |

The [runtime handoff](05-runtime-handoff.md) and
[surface matrix](../../contracts/application-source/SQL_SURFACES_V1.md) retain
the earlier probes. The view task must reuse `CatalogDefinition`,
`DirectDefinition`, `DirectTablePrepared` and `DirectView`; it is not a new view
engine. Existing typed views currently refuse transaction-bound preparation,
which must remain an explicit boundary unless separately extended and qualified.

## Completion scope and decisions

Use these defaults for the implementation. Contract commits must settle exact
source/SQL spellings before parser changes; the descriptions here are proposed
semantics, not newly accepted syntax.

- Represent a state-carrying cell explicitly, separately from an ordinary scalar,
  row absence and collection cardinality. Preserve the native descriptor and
  state payload; require an explicit checked conversion to use an ordinary value.
- Extend the existing helper/procedure and `PROCEDURE OF` machinery for query
  results. A read-only exact effect signature supplies query behavior; existing
  functions/guards and effectful procedures supply predicate/command behavior.
  A new runtime callable or closure protocol is unnecessary.
- Keep result collections immutable and within the caller's atomic transaction.
  Returning through an inlined helper is allowed; persistence, cross-transaction
  escape, suspension, nested loops and reads inside FOR remain excluded.
- Finish the listed scalar surfaces with exact native representations. Admit
  operations individually; JSON comparison traits, total interval ordering and
  implicit numeric/date/duration conversions remain excluded.
- Start ordinary views with the existing single-Table projection/filter profile,
  explicit names and invoker authority. Require executable DDL, dependency
  validation and restart behavior; materialization and maintenance are separate.

Native UNION replacement, general refinement implication, implicit callable
subtyping, arbitrary collections/joins/recursion, runtime closures and protected
workflows are outside this bounded M5 profile. Broader migration replacement is
M7, protection is M8, general deterministic replay is M9 and whole-application
performance is M10. None of those exclusions removes the required state, query,
scalar or ordinary-view work listed here.

## 1. Preserve cell states and define conversions — 5.2

**Transit owners:** `transit-sql-frontend` logical cells, program types/values,
parser/codec and schema binding; `transit-fuze` expression/environment handling;
`transit-query-direct/ApplicationData.zig` and saved application execution.
**Compiler owners:** `Syntax`, `SourceTypes`, `TypedOperands`,
`ProgramAnnotations`, `SymbolicProgram`, `ProgramLowering` and test-value encoding.

Specify a typed state-carrying value over an admitted descriptor, including
`value`, `null`, `missing`, `type_error` and `conflict`. Reuse native conflict
alternatives, their identity/order and declared bounds. Do not choose a winner,
erase type-error information or invent a second provenance encoding. Missing
remains legal only where the native field contract permits it; malformed cells,
invalid alternatives and constraint violations still fail validation.

Add explicit capture, state inspection and conversion operations to ordinary SQL
programs before source admission. Settle their exact error table against native
semantics. Existing strict reads retain their refusal order; opting into state
capture must be explicit. A checked extraction evaluates once and either yields
the exact scalar/domain value or refuses before dependent effects. No implicit
state-to-NULL, state-to-absent-row or conflict-resolution conversion is allowed.

Carry state descriptors through nested ROW fields, active variant payloads,
aliases, direct/imported helpers and ONE/OPTIONAL/MANY results. State inspection
may narrow an immutable value in its branch; it does not prove that a resource
still exists or that rights remain available. Retain strict variant tag and
active/inactive payload validation. Reuse the existing bounded obligation model
for explicit state checks and extracted scalar values; unknown predicates reject.

Extend cloning, validation, codecs, saved-state recovery and byte/depth/alternative
accounting together. Any incompatible native representation replaces the current
definition and generated consumers with explicit foreign-definition refusal.
No defaulted saved fields, JSON surrogate or legacy decoder may supply missing
semantics. Use the owning native fixture API to seed states that ordinary SQL
cannot yet construct; document that setup separately from the SQL under test.

**Exit gate:** independent native and generated SQL distinguish all five states,
absent OPTIONAL rows, empty MANY and present nullable rows. Test nested fields,
variants, malformed/conflicting payloads, exact conversions, two competing errors,
late rollback, allocation/budget boundaries and save/restart. Retain exact state
payloads in expected-value codecs; extend the compiled-case definition only if
its actual payload changes. Add a runnable state-inspection guide with a failed
conversion and explicit correction.

## 2. Complete typed query composition — 5.3

**Compiler owners:** helper signatures in `Syntax`/`SourceTypes`, exact matching
and specialization in `Compiler`, `Effects`, `Refinements`, `ProgramLowering`,
`ProgramAnnotations` and `SymbolicProgram`. **Native prerequisite:** the admitted
ROW/collection/state representations and their ordinary SQL operations, not a
new runtime function dispatcher.

Define one result descriptor containing ordered row fields, nominal identities,
physical descriptors, nullability/state policy, ONE/OPTIONAL/MANY cardinality and,
for MANY, exact bound/order. Extend parameters and procedure returns with those
descriptors. Keep existing scalar signatures compatible. Require exact matching
through interfaces, imports, aliases and callable module parameters; no implicit
bound widening, optional-to-one conversion or foreign-domain substitution.

Use read-only procedures as typed query constructors with explicit Table
bindings and READ effects. Check effects after complete inlining, including
unselected branches and nested callable arguments. Guard and command contracts
continue to carry their actual operations and ordered obligations. Supplying a
query cannot add captured resources, writes or authority. State/row-result
validation precedes every dependent use; error and postcondition order remain
explicit rather than inferred from a general solver.

Lower a call into the caller's existing atomic block with hygienic result locals.
Evaluate arguments and the query once, including unused or multiply referenced
results. Forward the original read basis and collection accounting through nested
helpers. A read hidden behind a query callable inside FOR must still reject.
Bound graph expansion, result retention and cumulative work before publication.

**Exit gate:** direct, imported, nested and higher-order ONE/OPTIONAL/MANY queries
agree with independent SQL for empty/one/multiple/excess results, nullable and
state-carrying fields, two named instances and symbolic/unselected branches.
Negative controls change field order/domain, cardinality, bound/order, resource
identity, effects and obligations independently. Verify no duplicate reads,
capture, resource escape or early commit, with rollback after a returning helper
and changed-basis/current-rights refusals. Extend the reusable-behavior and
query-results guides with a rejected signature and its correction.

## 3. Finish scalar ordered-program surfaces — 5.4

Ship four reviewable increments, sharing the state/row descriptor work from step 1.
Each extends the ordinary SQL parser/binder, `ApplicationSchema`,
`ApplicationProgramTypes`, `ApplicationValue`, native expression evaluation,
`ApplicationData` conversions and continuation codecs as needed. Then extend
compiler typing, lowering, symbolic checking and expected values. Existing Table
literal/codec tests are the baseline, not evidence for these new boundaries.

| Increment | Required program and source behavior | Required refusal/edge evidence |
| --- | --- | --- |
| DATE | Exact Gregorian-day literals, parameters/results, ROW/variant fields, reads/writes and native supported comparisons. | Leap/boundary dates; no implicit timestamp/timezone conversion; NULL/state behavior. |
| NUMERIC | Carry coefficient, precision and scale exactly through helpers and cells. Admit the existing DECIMAL_ADD/DECIMAL_RESCALE profile with explicit result descriptors and rounding. | Precision/scale mismatch, maximum coefficients, overflow, inexact rescale, HALF_EVEN ties and negative/zero values; no float intermediary. |
| JSON | Finish program literals and symbolic specialization while preserving runtime arguments/results and existing extraction. | Duplicate decoded keys, wide integers, escapes, depth/byte bounds, invalid unselected arms, JSON null versus SQL NULL and documented missing-member extraction. No equality/hash/order trait. |
| INTERVAL | Exact signed months/days/nanoseconds as a distinct program kind, including literals, parameters/results, nested fields and Table transport. | Mixed signs, component bounds, overflow and NULL/state behavior; no conversion to microsecond duration, implicit normalization or total ordering. |

All four increments must work through direct/imported/callable helpers, both
runtime variant arms, ONE/OPTIONAL and MANY iterators. Bind symbolic types without
executing or guessing unknown values. Preserve descriptor/nominal identity and
existing text collation through mixed rows. Unsupported operations reject before
publication, including in every branch the current all-arm checker owns.

**Exit gate per increment:** independent exact-value/type comparisons and ordinary
SQL agree at each newly admitted surface, including save/restart and late-error
rollback. Run native wire/caller checks where representations change. Creation
and existing add-column migration products retain exact descriptors; unsupported
conversions still refuse under M7's boundary. Update the support matrix and
typed-values guide with executable failure/correction examples as each type lands.

## 4. Finish prepared and relational scalar transport — 5.4

Split this area into prepared binding and relational execution increments.
**Transit owners:** `LogicalPrepared`, SQL parameter binding, logical values and
codecs, `RelationalValues`/Fuze relational execution and query-direct preparation.
**Compiler owners:** symbolic Table checking, typed operands, working catalogs
and independent scalar/specialization tests.

Replace the JSON/INTERVAL witness limitation with a typed preparation contract
for the operations that legitimately accept those values. The existing Atom
parameter path is not a representation for every logical value. Carry exact
descriptors and bounded values through binding/encoding; do not make a fabricated
comparison or sample value stand in for type checking. Source symbolic Table
holes, selected/unselected specializations and concrete parameters must agree.
Keep runtime parameter value/NULL rules distinct from source cell-state capture.

Extend the bounded relational transport profile to carry DATE, NUMERIC, JSON and
INTERVAL alongside other projected fields through projection, supported filters,
ORDER BY an independently comparable key and LIMIT. Reuse existing memory/work
limits and refusal behavior. Transporting JSON or INTERVAL does not grant them
comparison, hashing, grouping or ordering traits. Preserve five-state payloads,
nullability and evaluation/error order through materialization and copying.

**Exit gate:** turn the existing scalar ORDER BY and symbolic parameter refusals
into positive tests for the explicitly admitted operations. Keep adjacent invalid
trait uses negative. Compare exact values/descriptors with handwritten SQL under
shuffled insertion order, duplicate payloads, NULL/state cells, bound exhaustion,
allocation failures and invalidated schema/prepared identities. Preserve existing
parameter mismatch/definition refusal controls. Add prepared/ordered examples to
the source reference and typed-values/specialization guides.

## 5. Expose ordinary views through SQL and source — 5.4

**Transit owners:** SQL declaration parsing/binding plus existing
`CatalogDefinition`, `DirectDefinition`, `DirectTablePrepared` and `DirectView`.
**Compiler owners:** `WorkingCatalog`, resource/export binding, source SQL
templates, typed query inspection, `Compiler`, `CatalogDiff` and build products.

Expose ordinary CREATE VIEW and its native lifecycle using the accepted
single-Table projection/filter representation. Resolve schema-qualified source
identities, output names/types/collations and canonical dependencies before
publication. Store the checked native plan/definition rather than execute retained
source text. Specify create/drop and dependency refusal behavior; do not silently
substitute OR REPLACE, cascade, nested views or arbitrary SELECT features.

Use current invoker rights on the view and its base resource. Validate the stored
dependency identity before reads; changes, retirement or revocation must not
retarget a view by name. Preserve the native source-filter-before-outer-expression
ordering, including rows containing an error that the view excludes. Qualify
definition identity, inspection, restart and duplicate/lost declaration replies
through the existing operation owner.

Add source declaration, explicit module export/instance binding and typed query
inspection only for the admitted profile. The result schema must retain nominal
and physical descriptors through direct projections; a view handle confers no
Table write permission. Generate executable ordinary SQL in dependency order and
check it through the shared frontend. Initial creation is required; unsupported
replacement/diff transitions must fail explicitly before publishing a migration
product. General view evolution remains M7.

Transaction-bound view queries are currently refused. The completion profile
requires standalone SELECT over declared views, including prepared reads and the
admitted scalar transport. It does not quietly make a view an atomic Table handle
or admit query-callable reads through views. Keep that restriction explicit in
typing and documentation unless an additional native transaction contract ships.

**Exit gate:** two source instances and independently authored CREATE VIEW SQL
produce the same checked schema and rows after source removal. Verify exact
filter/error order, schema qualification, read-only handles, changed/dropped
dependencies, denied/revoked rights, restart and clean retirement. Test unsupported
DDL/profile/migration forms before publication. Publish a runnable view guide with
a failed binding or authority example and correction.

## 6. Integrate and close the milestone

Create one complete application journey combining the required profiles: two
nominal resource kinds and runtime dispatch; explicit cell-state inspection;
typed reusable queries returning ONE/OPTIONAL/MANY; all four scalar types;
bounded atomic writes/appends; and a declared view queried after completion.
Use two explicitly named instances and a separately authored SQL equivalent.
Remove source before execution, then test restart, current-rights denial, ordered
failure and full rollback. Keep focused isolated cases alongside this installed
journey so combined setup cannot hide which boundary failed.

Extend `tests/integration/composition.json` and the existing composition harness
with a predeclared complete case inventory. The starting inventory is 49 isolated
cases and ten installed phases; completion requires every retained and new case,
not a fixed old count or a successful process exit. Run three complete isolated
passes with fresh databases on a recorded qualification host, plus the installed
journeys and full integration schedule. Preserve the 30-second case, 300-second
suite and five-second cleanup budgets. Retain every failure and unrun case; do
not restart the pass count after a failure. A new candidate failure needs an
owning fix or evidenced environmental attribution and a separately identified
qualified run. Earlier local failures remain part of the history.

Record exact compiler/shared-package/host/definition revisions, executable and SQL
hashes, commands, platform, complete reports and original failures in a new
`docs/qualification/milestone-5.md`. Do not overwrite earlier qualification.
Successful hosted checks may satisfy their matching gates on the tested revision;
do not claim byte-identical binaries, runtime coverage on every archive platform
or a performance improvement from unrelated runs.

| Completion obligation | Evidence required before changing M5 to Completed |
| --- | --- |
| 5.1 | Both runtime dispatch arms, invalid raw tags/payloads, swapped nominal IDs, whole-input ROW specialization, independent instances and source-free execution still pass. |
| 5.2 | ONE/OPTIONAL/MANY distinctions; all five cell states and explicit conversions; bounded iteration; exact failure order, obligations, rollback and invalidated read bases. |
| 5.3 | Exact scalar/row/optional/many callable contracts; direct/imported/nested/higher-order correspondence; single evaluation, hygiene, bounded expansion, resource/effect identity and current authority. |
| 5.4 | Every required scalar surface above and ordinary SQL views execute independently. Per-surface supported/refused matrix is complete; no required gate remains labeled upstream-only. |
| Toolchain | Compiler/workspace, independent grammar/type/model controls, formatter, diagnostics, CLI/protocol, parity, clean-cache/public embedding, Nix source/packages and four native archive jobs pass. |
| Documentation | State, query, scalar and view guides contain runnable success, failure and correction cases in `tests/documentation.json`; strict build/browser checks pass at both base paths. |

Reconcile the source contract, invariant/law inventory, diagnostics, support matrix,
runtime handoff and roadmap status with the final evidence. State exactly which
laws are proved and which properties have bounded tests. Leave unrelated milestone
statuses unchanged. A required feature blocked upstream keeps M5 In Progress;
changing that scope requires an explicit reviewed roadmap change.

## Delivery order, commits and validation

There are **five remaining feature areas**, proposed as **nine feature increments
and one final qualification increment**. This is a substantial cross-repository
delivery, not just final documentation. It is a work breakdown rather than a
calendar or percentage estimate. State representation and view DDL have the most
contract uncertainty; scalar transport can expose additional shared-codec work.

| Order | Reviewable increment | Dependency / PR boundary |
| --- | --- | --- |
| 1 | State-carrying cells and explicit conversions | Native contract/runtime PR, then compiler/source PR. |
| 2 | Row/optional/many callable contracts | Step 1 and existing native collections; compiler PR, native extension only if a required pure checking seam is absent. |
| 3–6 | DATE, NUMERIC, JSON, INTERVAL program surfaces, separately | Each qualified native owner before its dependent compiler PR; share step 1's value/state rules. |
| 7 | Typed prepared JSON/INTERVAL binding | Native parameter owner before compiler symbolic admission. |
| 8 | Relational scalar transport | Native execution/codecs before compiler qualification; test with the admitted scalar descriptors. |
| 9 | Ordinary view SQL and source composition | Reuse native view ownership; qualify steps 7/8's admitted surfaces before final view acceptance. |
| 10 | Integrated application, complete evidence and milestone closeout | All required increments merged and qualified. |

Follow this order for implementation while allowing independent native contract
design and probes for scalar/view work. For each feature, make logical commits
for (a) contract plus independent failing/positive expectations, (b) owning native
implementation and regenerated artifacts, (c) qualified dependency integration,
(d) source typing/lowering/diagnostics/formatting and (e) correspondence, guides
and qualification. Keep each final PR coherent and passing; link paired PRs and
merge the native owner before the compiler consumer. Do not batch all runtime
changes behind one unreviewable compiler PR.

Preserve the frozen comparison compiler. Update shared distribution, host pins,
hashes and manifests together when behavior requires it; enumerate any changed
definition/plan identities exactly. A native definition cutover includes generated
bindings and saved-state refusal controls, not a cosmetic version-only update.

Use existing `test` and `docs` modules and keep the root task count unchanged.
During implementation run the affected owner tests and independent comparisons;
at integration run the complete required checks, including:

```sh
nix develop --command just check test::unit test::fmt test::grammar test::types
nix develop --command just test::workspace test::examples test::documentation
nix develop --command just test::integration test::build-command test::command
nix develop --command just test::composition 3
nix develop --command just test::clean-build test::release
nix flake check --print-build-logs
nix build .#checks.x86_64-linux.source --no-link --print-build-logs
nix develop .#docs --command just docs::install docs::check
```

Also run the existing public-embedding, signed four-platform archive and
root/prefixed handbook-browser CI gates. Native PRs follow Transit's baseline
checks, affected clean lanes, SQL interface validation and console budgets as
required by its repository instructions. Keep immutable executable paths while
process tests run; schedule storage-heavy qualification without competing builds.
Do not rerun unchanged expensive gates solely to refresh a timestamp, and do not
replace missing native execution evidence with compiler-only checks.
