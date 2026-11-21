# 5. Typed composition and executable SQL

Status: In Progress

Prerequisites: [compiler extraction](03-compiler-and-cli.md); each new emitted
operation needs its ordinary Transit SQL contract and executable owner.

Let authors compose a complete application from typed modules and inspect SQL
that runs independently of the source tree. This expands Transit's former M12
P0–P3 and completion-plan B.2b into compiler-owned delivery units. The
[roadmap index](README.md#source-and-ownership) records the extraction basis.

## Delivered foundation

The [source contract](../../contracts/APPLICATION_SOURCE_V1.md) covers recursive
constructors, module interfaces and instances, delegated targets, concrete schema
binding, nominal scalar domains, compile-time variants and exhaustive matching.
Public Table/Stream/Queue handles and restricted reference exports have explicit
types. Pure functions, ordered guards and hygienic atomic procedures, including
value-returning calls, lower through the production SQL frontend.

These are bounded source features. Compile-time matching does not establish
dynamic dispatch, source visibility does not establish runtime-private storage,
and reference-only exports do not grant row access. The independent grammar and
selected Lean/SQL comparisons cover the admitted profile; they do not prove the
whole compiler correct. The progress table separates delivered increments from
the remaining milestone gates.

## Delivery units

| Unit | Contract and implementation | Acceptance |
| --- | --- | --- |
| 5.1 — Dynamic representations | Specify runtime variant tags/payloads, nominal identity, external-input validation and compatible SQL encodings before adding syntax. Extend symbolic program specialization. | A command selecting either of two resource kinds rejects wrong IDs, invalid tags and missing arms; raw SQL inputs receive the same required runtime validation. |
| 5.2 — Cardinality and refinements | Distinguish one/optional/many rows from nullable values and the five cell states. Admit a bounded refinement subset with explicit proof or runtime-validation obligations. | Empty/multiple results, NULL, missing, type errors, conflicts and invalid refinements preserve exact errors and evaluation order through lowering. Unknown obligations reject. |
| 5.3 — Behavioral composition | Extend typed query/predicate/command constructors and callable module interfaces. Track resource bindings, effect signatures and pre/postconditions through higher-order arguments. | Imported and nested helpers cannot widen effects, erase authority requirements, duplicate argument evaluation or capture caller locals; repeated instances preserve explicit identity. |
| 5.4 — SQL and scalar coverage | Add reviewed scalar/composite types such as NUMERIC, JSON, INTERVAL and DATE, then views and additional declarations as their upstream owners permit. | Each type preserves collation, precision, nullability and errors; each declaration reparses/rebinds and executes without source. Unsupported declarations fail before publication. |

Start with 5.1's representation and independent test cases. Develop 5.2 against
that representation; 5.3 composes only admitted types/effects. Unit 5.4 proceeds
per operation, rather than waiting for every Transit milestone. Runtime closures,
unrestricted dependent types, runtime recursion and implicit parallel effect
dispatch remain outside these units; any extension needs a separate contract.

## Current implementation progress

The first implementation increments add closed-record runtime MATCH, all-arm
program specialization, ONE/OPTIONAL query results, bounded whole-row presence
refinement, ordered helper pre/postconditions, exact callable/effect signatures,
DATE/NUMERIC/JSON/INTERVAL source values and native scalar qualification.
Contracts, independent grammar/type comparisons, failure cases and guides ship
with each increment. These additions do not close this milestone.

| Plan unit | Delivered increment | Remaining gate |
| --- | --- | --- |
| A/B | Explicit tag/payload encoding, exhaustive runtime MATCH, nominal payload checks, hygienic lowering and all-arm program/control checking; whole-input ROW specialization with a separate bounded scalar environment | Whole-row unit, independent field/domain and candidate runtime checks pass; the pure upstream API merge and complete candidate runtime qualification remain open |
| C | ONE and OPTIONAL SELECT results, ordered ONE assertion, guarded optional projection, preserved nominal fields and nullable cells | Installed ONE/OPTIONAL generated/oracle and restart checks pass; isolated completion, bounded many and state-carrying values remain open |
| D | Direct immutable row-presence facts plus ordered non-nullness, same-type equality and constant BIGINT bounds in explicit REQUIRES/ENSURES contracts; installed refusal/rollback journey passes | Isolated runtime qualification; general implication solving and resource-derived facts remain outside the bounded profile |
| E | Exact FUNCTION/GUARD/PROCEDURE OF module arguments and resource effects; nested inlining, explicit instances, installed oracle/rollback/restart/current-rights denial pass | Isolated runtime qualification; callable row/many returns and implicit signature subtyping remain unsupported |
| F | DATE/NUMERIC/JSON/INTERVAL source values, exact Table cells, DECIMAL_ADD/DECIMAL_RESCALE and NULL/error checks; JSON runtime helper transport/extraction; creation/add-column descriptors | Native program-value, symbolic prepared-parameter, relational-profile and view gates; JSON helper installed and isolated checks pass |

See the [runtime handoff](05-runtime-handoff.md) for exact upstream boundaries and
separately listed compiler work. The support matrix in
[SQL surfaces](../../contracts/application-source/SQL_SURFACES_V1.md) distinguishes
literal/codec qualification from query operators and program values. Runtime
reports that hit a deadline remain failures, even when compile-time checks pass.

## Next slice: complete the existing composition profile

**Status: Implementation in progress.** Basis: the merge of
[PR #5](https://github.com/spoke-sh/transitc/pull/5) at transitc
`391ef54024aefe1eb23885962d920b57d6b07485`, inspected on 2026-11-21.
This slice closes the isolated-execution and symbolic-input gaps in the delivered
A–E profile. Its outcome is a composition profile that authors can both build and
test reliably, with a precise boundary for whole-input ROW helpers.

### Starting evidence and scope

The [qualification record](../qualification/typed-composition.md) retains passing
installed generated/independent SQL journeys and failing isolated cases. The
flat-encoding suite stops at missing active payload; cardinality stops at absent
OPTIONAL; focused refinement and callable suites stop at their first case. An
existing typed-Queue case has also timed out locally. These observations do not
identify a common cause or establish a compiler regression.

At the planning check, all four native compiler/archive jobs and the handbook job
in [PR run 44948950220](https://github.com/spoke-sh/transitc/actions/runs/44948950220)
passed. Its compiler job subsequently finished successfully, including Nix,
independent source verification, release, clean-build and combined
process/integration steps. All six jobs passed at the merged PR revision.
The [completion qualification](../qualification/composition-completion.md)
retains the subsequent baseline reproduction and investigation.
Successful native compiler jobs do not qualify database execution on those hosts.

Keep shared packages and the compiled-case host at
`f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6` while reproducing failures, and the old
compiler comparison at `e7434306334e3692c6f3e123cba0d278fa412196` throughout.
Upstream `main` was `aa52980ad93b5e32bee2c543c9f82bc3ab4f162a` at inspection.
Its TestHost/TestCaseHost, test Runner, ApplicationSchema/ApplicationValue and
ApplicationData files are unchanged from the pin. Other runtime components may
differ; updating to `main` alone is not evidence of a fix.

Include runtime failure diagnosis and its owning fix, whole-input ROW checking,
complete regression schedules and qualification. New many-row syntax,
state-carrying cells, scalar program representations, views, general refinement
solving and callable row/many returns remain subsequent delivery units. Keep their
obligations in the [runtime handoff](05-runtime-handoff.md); this slice does not
close all of 5.2/5.4 or revise milestone scope.

### 1. Make isolated failures attributable

Owners: transitc's `tests/integration`, `tests/runner`,
`packages/transitc-workspace/src/Test.zig` and `TestProcessHost.zig`; Transit's
`apps/transit-cli/TestHost.zig`, `TestCaseHost.zig` and
`packages/zig/transit-test/src/Runner.zig` for native execution evidence.

- Capture a fixed compiler/host pair, compiled-case definition, exact SQL and
  expectations, case/action identity, host load and elapsed phase times. Execute
  the baseline typed-Queue fixture and the failing new fixtures sequentially on a
  quiet host. Keep the first failure and every subsequent diagnostic run.
- Reduce each failure to ordinary SQL plus typed expectations using the upstream
  host qualification harness. Compare the same operations with the installed
  server. Preserve the failing action, resource bindings and rollback assertion
  while reducing; record setup and Queue lease differences explicitly.
- Retain bounded timings/work counts for process/bootstrap, DDL, authorization,
  activation, Queue claim, program progress, terminal publication, observation
  and joined cleanup. Distinguish a worker error, stalled work, observation
  contention, expired lease and actual budget exhaustion from a missing report.
- Use the native test harness/diagnostic seam for instrumentation. Preserve the
  strict host stdout response and empty-stderr contract. Any necessary wire change
  belongs upstream with coordinated definition/consumer checks; diagnostic output
  cannot simply be added to the production response. Publish reviewed counters
  and identities, excluding installation credentials and runtime configuration.

**Gate:** a retained minimal reproducer and evidence assigning the failure to
compiler output, workspace scheduling, native execution/observation, or an
explicitly identified environmental limit. A quiet-host pass alone does not
explain the earlier failure. Diagnose distinct failures separately.

### 2. Fix completion at its owning boundary

Use step 1 to select the owner. Fix incorrect SQL/evaluation or deadline handling
in transitc if demonstrated. For native progress, wakeup, contention, lease or
observation defects, add the failing SQL regression and fix in a separate Transit
PR before updating the pinned host. Do not move database execution into transitc.

Preserve the 30-second case, five-minute suite and five-second cleanup budgets.
Check trusted-clock behavior, accepted-operation identity, current authority and
first-error order. Regression tests must exercise the identified failure schedule
and verify joined cleanup, no late success, no duplicate effects and exact rollback.
Use the upstream deterministic/fault harness where available; larger timeouts,
retry-until-pass schedules and success inferred from partial rows are not fixes.
Keep the installed combined journeys alongside the focused isolated cases.

**Gate:** the minimal reproducer fails before the fix and passes after it, existing
host refusal/timeout controls still fail as intended, and the full affected
fixtures complete within their original budgets. If a separate cause remains,
retain it as an open acceptance item rather than broadening this slice silently.

### 3. Finish whole-input ROW specialization

Owners: `SymbolicProgram.zig`, `ProgramLowering.zig`, `ProgramAnnotations.zig`,
`Compiler.zig`, their tests and `tests/query/application_source/symbolic_program_types.py`.

The present checker adds type-only scalar fields to a temporary input catalog.
The public guide excludes whole-input ROW helpers with symbolic scalar holes, but
planning probes on the `7e57ba1` Nix compiler accepted direct functions, guards and
procedures receiving `request` together with a symbolic SiteId argument. Explicit
`ROW(request.id)` also compiled. These probes establish acceptance only, not
complete typing, bounds, hygiene or runtime correspondence.

A boundary probe did reproduce a concrete problem: extend the input Queue in
`application-symbolic-program` to 64 BIGINT columns and pass `request` to a ROW
helper in the Site program. A concrete Site specialization compiles, while
checking the compile-time MATCH fails with `ProgramTooComplex`; the same symbolic
case with four columns compiles. `SymbolicProgram.catalog` appends its checking
fields to the real Queue shape, consuming the native input-field budget. Preserve
this small concrete/symbolic comparison as the first regression; the problem is
broader than whether a helper accepts ROW syntax.

Turn those cases into an independent matrix and identify any additional
unsupported combinations. Cover selected and unselected arms, direct/imported/
nested/callable helpers, aliasing of the input row, nullable and nominal fields,
Queue predicates, repeated/unused arguments and schemas at native field limits.
Keep existing named-field and positional ROW rules; require a whole optional row
to be present before projection where the current contract requires it.

Where synthetic fields affect authored row semantics or consume the real input's
schema budget, separate the type-only scalar environment from the authored input
shape. Prefer a compiler-local checking projection/environment using the shared
binder. Review its concrete representation against the failing cases before
implementing it. Do not replace unknown values with sample literals, remove
nominal checks, relax the native binder or publish synthetic fields.
If the shared binder lacks the necessary typed-input seam, propose the smallest
pure API extension upstream with its own bounded tests, then merge and qualify
that dependency before consuming it here. Preserve real runtime schema/depth
limits while budgeting the separate checking environment explicitly.

Retain positive selected SQL and independent typed projections, plus failures for
foreign domains, missing/wrong fields, unsafe optional projection, forged internal
names, capture and invalid unselected arms. Test single evaluation, nested helper
effects, source locations, allocation failure and work/depth/output exhaustion.
Compare definition fingerprints and emitted SQL for already-supported inputs.
Unsupported JSON source program literals must still reject in unselected arms.

**Gate:** the admitted ROW combinations have executable positive/negative and
independent evidence; no checking fields escape into SQL, checked public shapes,
catalog identity or migrations. Narrow or remove the guide's blanket exclusion
according to that evidence. Change only the representation/checking paths needed
by the retained failures; already-accepted forms primarily need regression and
documentation coverage.

### 4. Integrate a qualified runtime fix when needed

A Transit runtime or pure binder fix must merge and pass its owning checks first.
Compare the exact candidate against the retained pinned reproducer before selecting it.
Update the `transit` flake input and compatible shared distribution deliberately;
if exported packages change, regenerate the upstream archive and update Nix/Zig
hashes, manifests and attribution together. Qualify the selected combination even
if the shared archive or compiled-case definition remains byte-identical.

Keep the frozen compiler comparison unchanged. Run protocol mismatch, changed/
missing host, late completion, quota and cleanup controls along with compiler
parity. Record compiler, shared-package, host and definition identities separately.
No pin update is needed if the demonstrated fix is entirely compiler-owned.

### 5. Qualify the complete slice and update guides

Add a `test::composition` subtask within the existing test module and reuse it from
`test::integration`. It should retain a result for each independent fixture suite
even if an earlier suite fails, then fail the aggregate. Preserve the host's
abort-on-error behavior within a suite and keep not-run cases visible. Run each
installed/isolated phase independently where its setup permits it; an encoding
failure must not prevent collecting the separate dynamic-MATCH report. Keep the
root task count unchanged and avoid replacing executables during process tests.

The immediate completion matrix is 34 existing isolated cases: five typed-Queue,
seven flat encoding, seven generated runtime-MATCH, eight cardinality, five
refinement and two callable cases, plus the new ROW cases. Require every expected
case, not just a successful process exit. Run three predeclared complete local
passes with fresh databases and the full schedule once in CI; retain every result
and do not restart the count after a failure. These repetitions supplement the
root-cause regression, not a claim of general timing guarantees.

Re-run installed generated/handwritten SQL, exact rows/refusals, source removal,
restart and current-rights denial. Preserve DATE/scalar/JSON regressions and the
host protocol boundary suite. Extend the specialization/reusable-behavior guides
with a whole-row example, an invalid unselected-arm example and its correction;
update `tests/documentation.json`, grammar/type inventories and diagnostic mappings
only where their owned surfaces change.

Use the existing `check`, `test::unit`, `test::grammar`, `test::types`, `test::fmt`,
`test::workspace`, `test::examples`, `test::documentation`, `test::integration`,
`test::build-command` and `test::command` gates. Before slice closeout, repeat the
clean-cache/embedding, Nix package and explicit source checks, release tests, four
native compiler/archive jobs and handbook/browser checks at both base paths.
Append a new dated qualification section with actual revisions and retained
results; preserve the earlier failures as history.

### Logical commits and PR boundaries

| Order | Change | Acceptance before the dependent change |
| --- | --- | --- |
| 1 | Capture baseline failures, minimal SQL cases and bounded phase evidence | Failure ownership is demonstrated; wire/output assertions remain strict |
| 2 | Fix the demonstrated completion defect in Transit or transitc | Reproducer and relevant fault/timeout/cleanup controls pass; upstream fix merges if applicable |
| 3 | Fix symbolic input-budget contamination and complete ROW coverage | Independent types/SQL, negative controls, bounds and allocation failures pass; can proceed independently of 2, subject to any required pure binder API |
| 4 | Qualify and update the runtime/shared pins if required | Exact candidate reproduces the fix; compatible protocol and old compiler comparison pass |
| 5 | Add the complete composition schedule and runnable guide corrections | All expected installed and isolated cases execute and pass |
| 6 | Record final qualification and update milestone progress | Local/CI evidence names exact revisions; no failed or not-run required case is hidden |

Use one compiler PR for the slice with these logical commits; keep an owning
runtime fix and any pure binder extension in focused Transit PRs and link their
merge dependencies. A compiler-only ROW improvement may land independently if
runtime work remains open, but it does
not complete this slice. This plan changes documentation only; implementation and
pin changes follow review.

### Slice exit and remaining path

The slice is complete when isolated completion has an explained, tested fix; all
34 existing cases and the new ROW cases pass; whole-input helper admission is
documented precisely; and the final regression/packaging/guide evidence is recorded.
That resolves the current A–E qualification gaps for their bounded profile.

Milestone 5 still needs the native-dependent increments: bounded many and explicit
cell-state conversions, remaining scalar program/prepared/relational surfaces,
and ordinary views. Plan each against an upstream contract and independent SQL
journey, then qualify its compiler implementation. Views remain a required gate;
the closed STRUCT variant encoding does not require a switch to native UNION.
Keep M5 **In Progress** until all required units have their own completion evidence.

## Initial implementation plan

Reviewed implementation basis, recorded on 2026-11-21 after the milestone 3/4
qualification merge at transitc
`66a54e303eece69945453d2e29576b2af171c70a`. The plan below preserves its original
acceptance obligations. The progress table above and the
[qualification record](../qualification/typed-composition.md) identify implemented
surfaces and executed checks; the plan itself is not evidence of completion.

Use the [qualified extraction](../qualification/extraction.md) as the baseline:
shared pure packages and the compiled-case host at Transit
`f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6`, with the old compiler comparison frozen
at `e7434306334e3692c6f3e123cba0d278fa412196`. Newer upstream work is not implicitly
available through those pins.

### Review decisions and recommended scope

1. **Prove the dynamic SQL representation first.** Prefer the shared logical
   tagged union if its ordinary runtime operations can support the whole journey.
   Otherwise review an explicit tag plus per-arm payload encoding. Choose between
   them using executable SQL probes before committing to source syntax. Neither
   an opaque JSON payload nor an executable compiler sidecar is a substitute for
   typed, independently validated runtime operations.
2. **Keep the first runtime variant profile closed and nonrecursive.** Use the
   existing scalar/domain payload subset, explicit stable tags and immutable
   resource bindings. Specify inactive fields, invalid tags and evolution before
   emission. Add optional payloads only after the cardinality/nullability rules
   are settled in 5.2. Keep catalog shape concrete during specialization.
3. **Start refinements and callable contracts with a bounded checker.** Admit a
   small, enumerated predicate set and exact callable-signature matching first.
   Reject unproved obligations or emit an explicit ordered validation operation
   where the contract permits it. General theorem proving, implicit signature
   subtyping and arbitrary user predicates are separate extensions.
4. **Deliver SQL coverage by executable surface.** A type may be supported in a
   Table without being supported as a source parameter or program value. Keep a
   matrix of those distinctions. Views remain an upstream dependency in this
   milestone; closing M5 without them requires an explicit scope decision rather
   than treating parser acceptance as delivery.

### Gaps at the qualified baseline

| Area | Current implementation | Work required |
| --- | --- | --- |
| Dynamic values | `SourceTypes.Value.variant` holds a selected constructor; symbolic values carry only a scalar type. `Compiler.zig` specializes concrete matches and rejects symbolic program forms. | Represent checked runtime variants and symbolic branches without changing durable catalog shape. |
| Nominal evidence | `TypedOperands.zig` and `ProgramAnnotations.zig` check domain identities before scalar erasure. | Preserve domain/tag/field obligations through dynamic selection and explicit input validation. |
| Cardinality | The upstream ordered-program contract returns a nullable record for zero/one rows and errors on multiple rows. | Distinguish result cardinality from field nullability; define bounded many-row consumption and state-preserving conversions. |
| Behavioral interfaces | `Graph.zig` checks module interfaces; `ProgramLowering.zig` checks and inlines functions, guards and procedures. | Carry callable signatures, resource/effect requirements and bounded pre/postconditions through imported and higher-order arguments. |
| Scalar coverage | Source scalar arguments admit BIGINT, TEXT, BOOLEAN, UUID, TIMESTAMPTZ and BINARY. The shared logical type set is broader. | Extend literals, source typing, program binding, test values and declarations only where their individual execution contracts exist. |

The pinned shared frontend already describes `tagged_union`, decimal, date and
interval logical types, but its
[ordered-program schema binder](https://github.com/spoke-sh/transit/blob/f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6/packages/zig/transit-sql-frontend/src/ApplicationSchema.zig)
rejects them. Its
[runtime values](https://github.com/spoke-sh/transit/blob/f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6/packages/zig/transit-sql-frontend/src/ApplicationValue.zig)
also lack those representations. JSON is admitted there, but this does not make
JSON a lossless substitute for every logical value or cell state. SQL
[`CREATE VIEW` and `CREATE MATERIALIZED VIEW` are unavailable](https://github.com/spoke-sh/transit/blob/f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6/docs/handbook/reference/sql.md).
These are execution boundaries to resolve, not compiler checks to remove.

### A. Settle contracts with independent SQL probes — 5.1

Author the two-resource application in ordinary SQL first. Extend the existing
[typed-target](../../tests/fixtures/application-typed-targets/README.md) and
[typed-Queue](../../tests/fixtures/application-typed-queue/README.md) journeys:
Machine and Site IDs deliberately share raw value `7`, while one runtime request
chooses the resource kind. Use the existing public Queue/Table/Stream operations;
the word “command” here does not introduce a native `CREATE COMMAND` declaration.

Probe both the native union and explicit tag/payload candidates. Record accepted
DDL, input operations, bound descriptors, branch execution and exact failure
boundaries. Specify stable tags independently of constructor order, source paths
and import aliases; payload types and inactive-field rules; NULL/missing/error
handling; and what changing an arm or domain does to definition compatibility.
Do not choose an encoding that silently discards a cell state.

Separate admission from processing: a Table constraint can refuse its write,
whereas a Queue consumer guard may refuse processing after ENQUEUE has succeeded.
The chosen contract must identify where invalid input fails and prove that no
application effect survives. Raw SQL callers must pass through the same required
validation and current runtime authorization.

Nominal IDs retain their static identities, but a raw integer does not prove its
domain of origin. Tests must distinguish a source-level swapped-domain rejection
from runtime tag, shape, selected-resource and existence checks. If both resources
contain ID `7`, scalar erasure cannot authenticate which source constructor a
caller intended. Runtime privacy and stronger authority remain M8 work.

**Gate:** retain independently authored valid/refused SQL cases and a reviewed
encoding/validation contract. For missing runtime behavior, prepare an upstream
handoff naming the ordinary operation, representation, error, bounds and tests.
Merge that behavior upstream and qualify the shared-package/host pin update
before admitting dependent source forms. Keep the frozen old compiler pin.

### B. Implement dynamic source values and dispatch — 5.1

Extend syntax and `SourceTypes.zig` with the reviewed dynamic representation;
keep compile-time variants and runtime values distinguishable. Carry domain,
tag, payload and source-origin evidence through `TypedOperands.zig`,
`ProgramAnnotations.zig` and `ProgramLowering.zig`. Extend symbolic checking in
`Compiler.zig` without permitting dynamic schemas, exports or object identities.

Check exhaustiveness and payload types before emission, preserve evaluation
multiplicity, and emit ordinary runtime branches and validation. Every reached
arm must satisfy its typing obligations even when a particular test input chooses
another arm. Reparse and rebind the result through `WorkingCatalog.zig` and
`ProgramCheck.zig`; leave unsupported native operations rejected.

**Gate:** the source version agrees with A's independent SQL. Cover both kinds,
invalid tags/payloads, wrong nominal IDs, missing/duplicate arms, an invalid
unselected arm, nested imports and two explicitly named instances. Remove the
source tree before execution and check exact rows, ordered refusals, rollback,
restart and current-rights denial. Keep the existing concrete-match behavior.

### C. Make result cardinality explicit — 5.2

Define separate checked types for exactly one, optional and bounded many results.
An optional row is distinct from a present row containing NULL; neither is a
generic container for missing, type-error or conflict cells. Specify the row
presence test, projection, narrowing, explicit cardinality assertions and the
error produced for zero or multiple rows at each conversion.

Use the upstream nullable-record behavior only where it preserves the declared
semantics. Where the program value model cannot carry a required cell state,
reject that boundary until an upstream operation can preserve it. Do not infer
row absence by checking an arbitrary nullable field. Bounded many needs an owned
runtime query/consumption contract with row and work limits; introduce no implicit
loop, ordering guarantee or unbounded materialization in compiler lowering.

**Gate:** independent source/SQL comparisons cover zero, one and multiple rows;
present NULL versus absent row; each admitted cell state; bounds; and first-error
order. Projections and inlined helpers preserve both cardinality and domain
identity. Unsupported conversions fail before artifact publication.

### D. Add bounded refinements and validation obligations — 5.2

Propose an initial predicate set of constructor/tag membership, non-nullness,
same-domain scalar equality and constant integer bounds. Each predicate needs
explicit rules for introduction, use, invalidation and runtime validation, using
the shared scalar/error semantics. Do not admit a predicate merely because a
general SQL expression can parse it.

Carry discharged and pending obligations in the checked representation. Use
explicit validation at external-input boundaries and prove that a refusal occurs
before dependent effects. Treat resource existence as a runtime observation;
evidence derived from state must name its object/definition and transaction or
read basis. A write, suspension or new observation cannot silently preserve stale
evidence. If the upstream contract cannot establish that basis, require a fresh
check rather than treating the fact as proved. A guard does not establish rights.

**Gate:** valid narrowing succeeds; unknown obligations, incompatible domains and
invalid returns reject. Compare early/late refusals and rollback with hand SQL,
including mutation between checks and use. Extend selected finite/Lean evidence
only with explicit premises and an axiom audit.

### E. Check callable contracts, then compose behavior — 5.3

First introduce one checked signature for query, predicate and command behavior:
parameter/result types and cardinality, explicit resource bindings, permitted
reads/writes/appends, purity/atomic requirements, required runtime authority and
the admitted pre/postconditions from D. Use exact signature matching initially;
no implicit widening through imports, aliases or module arguments. Static
requirements describe obligations; the runtime still decides current rights.

Then admit callable module arguments and typed behavior constructors. Specialize
them into ordinary checked SQL with stable explicit instance bindings, bounded
specialization and hygienic local identities. Preserve single argument evaluation,
guard order, the caller's transaction and value returns only on successful atomic
completion. External effects, runtime closures and implicit privilege remain
outside this profile.

**Gate:** compare direct, imported, nested and higher-order calls against the same
independent expectations. Reject hidden effects, authority/contract widening,
foreign resource bindings, capture, recursion and budget exhaustion. Two instances
must remain distinct. A failure after a staged write must roll back all writes and
outputs, including through a returning helper.

### F. Expand scalar and declaration coverage — 5.4

Maintain a support table for each type across source literals/parameters, domain
bases, resource columns, query expressions, ordered programs, test expected values
and migration products. Start with DATE and NUMERIC, then JSON and INTERVAL; ship
one type/surface increment at a time. Existing ordinary SQL acceptance is useful
evidence but does not automatically admit that type at every source boundary.

| Increment | Required semantic checks |
| --- | --- |
| DATE | Exact date literals and boundaries; no implicit timezone or timestamp conversion. |
| NUMERIC | Declared precision/scale, exact decimal values, overflow and explicit rounding; no intermediate floating-point conversion. |
| JSON | Lossless numeric values, duplicate-key rejection and explicit extraction semantics; do not invent equality, hashing or ordering traits. Distinguish SQL NULL from JSON null and document any extraction that collapses absence. |
| INTERVAL | Preserve months, days and sub-day components. Do not equate SQL intervals with the ordered-program microsecond duration or invent total duration ordering. |
| Views | Wait for upstream ordinary DDL, binding, executable queries, definition identity and authorization. Typed query inspection alone is insufficient. Start with ordinary views; materialized views need a separate maintenance contract. |

For each increment update `Syntax.zig`, `SourceTypes.zig`, typed operands,
`Template.zig`/lowering and canonical catalog binding as needed. Check test-value
encoding in `Test.zig` and the shared compiled-case protocol, plus supported
creation/diff behavior in `CatalogDiff.zig`. Unsupported migration transitions
must refuse explicitly; broader evolution policies remain M7. Shared codecs,
traits and runtime semantics stay upstream.

**Gate:** source checks, independent SQL execution and exact test-value round trips
agree for each advertised surface, including boundary/error cases. Capture
unsupported surfaces explicitly. Views remain open until their upstream gate
passes or a reviewed milestone scope change records their new owner.

### Commit and PR sequence

Keep each feature increment reviewable with its contract, implementation,
independent tests and guide changes together. The following are logical PR units;
upstream runtime changes land separately before their dependent compiler PR.

| Order | Proposed change | Depends on | Acceptance gate |
| --- | --- | --- | --- |
| 1 | Encoding decision, SQL probes and support matrix (A) | Qualified baseline | Executable ordinary-SQL journey or an explicit upstream blocker; reviewed representation before source changes. |
| 2 | Runtime variant typing and dispatch (B) | 1 and any required upstream pin update | Two-resource positive/negative journey, static nominal evidence and runtime validation. |
| 3 | Cardinality types and conversions (C) | 2; bounded-query runtime support for many | Zero/one/many and distinct cell-state evidence. |
| 4 | Refinements and ordered validation (D) | 3 | Sound bounded discharge/refusal and stale-evidence rejection. |
| 5 | Callable signatures and effect checking (first part of E) | 4 | Existing helpers retain behavior; imported signatures cannot widen obligations. |
| 6 | Higher-order behavior constructors (second part of E) | 5 | Hygienic, bounded specialization with exact resource bindings and atomic behavior. |
| 7 | Scalar coverage, one PR per admitted type/surface (F) | 1's matrix and each upstream owner | Exact values and errors through all newly advertised surfaces. |
| 8 | Ordinary view composition (F) | Upstream view contract and execution | Source-free execution, binding, identity and authorization checks. |
| 9 | Integrated qualification and completed guides | All required increments | Completion matrix below, with exact revisions and retained results. |

Scalar work can proceed independently after the support matrix is reviewed.
Query behavior in E can use admitted Tables while views wait on upstream. If an
upstream operation is unavailable, continue independent increments, keep the
dependent unit open and report the exact missing contract. Do not defer a required
unit silently and mark the milestone complete.

### Verification and closeout gates

Before changing language behavior, reconcile the grammar/model inventories with
the qualified baseline: `contracts/application-source/README.md` still describes
eleven laws and an old task name, while the qualification records fourteen laws
and the current tasks are `test::grammar` and `test::types`. Keep the invariant
inventory, diagnostic inventory and support table aligned with executed checks.

For each slice run the affected compiler/workspace tests and independent grammar,
typed and formatter checks. Extend the existing fixture and process harnesses;
add no new root task. Use the existing entry points:

```sh
nix develop --command just check test::unit test::fmt test::grammar test::types
nix develop --command just test::workspace test::examples test::documentation test::integration test::build-command test::command
nix flake check --print-build-logs
nix build .#checks.x86_64-linux.source --no-link --print-build-logs
nix develop .#docs --command just docs::install docs::check
```

Use the frozen compiler comparison for the old admitted profile; new features
need independent SQL and typed expectations, not acceptance by the old compiler.
Keep the existing 30-second compiled-case and five-minute suite budgets. Split
focused cases rather than extending timeouts to hide regressions. Retain the
installed combined journey as well as isolated cases. Do not run builds that
replace the same executable while process suites are using it.

At closeout repeat the extraction record's clean-cache, embedding, release and
four-native-host compiler gates, and handbook browser checks at both base paths.
Runtime execution evidence continues to name its actual host platform separately.
Record results in a new `docs/qualification/typed-composition.md`, with compiler,
shared-package, host and compiled-case identities, commands, retained artifacts
and unsupported surfaces. Do not populate it with assumed passes.

| Completion obligation | Required retained evidence |
| --- | --- |
| 5.1 | Runtime two-resource dispatch, swapped source domains, malformed raw inputs, exhaustive arms, separate instances and source-free execution. |
| 5.2 | Zero/one/many results, distinct admitted cell states, ordered errors, refinement discharge/refusal and invalidated observations. |
| 5.3 | Direct/imported/higher-order correspondence, effect and authority requirements, single evaluation, hygiene, atomic rollback and stable bindings. |
| 5.4 | Per-surface type matrix, exact values/errors, executable declarations and explicit refusals; no unresolved required view gate. |
| Documentation | Runnable domain-modeling, optional-result, reusable-behavior and failed-specialization guides; each includes a failure and correction, tracked by `tests/documentation.json`. |
| Regression | Existing extraction profile, bounded failures, formatter/diagnostic compatibility and qualified packaging/handbook gates remain passing. |

## Implementation boundaries

Keep syntax, source types, typed origins, working catalogs and lowering in
[transitc-compiler](../../packages/transitc-compiler/README.md). Its input is a
resolved graph; filesystem access, Git, time and database execution stay outside.
Reuse the pinned Transit SQL frontend for logical types, scalar semantics and
canonical statements. Do not create a second runtime SQL dialect.

Every language increment updates the source contract, independent ANTLR grammar,
positive/negative corpus, production parser, typed representation, diagnostics,
formatter and lowering together. Fully parse unused bodies and unselected
branches, retaining the contract's distinction between syntax checks and reached
semantic checks. Source/build/test stages remain distinct from runtime SQL.

Preserve function purity, ordered guard refusals and a procedure's single caller
transaction. External dispatch and observation waits remain outside inline atomic
procedures. Imports and inlining confer no privilege. Runtime module protection
belongs to [milestone 8](08-protected-workflows.md).

Use stable explicit object and domain bindings, independent of source paths and
import aliases. Separate logical types, semantic descriptors and physical codecs.
Budget whole-program graphs, recursion, specialization and output independently;
exhaustion must produce attributable failure without complete-looking artifacts.

Preserve compound SQL framing above 50 KiB with nested atomic, failure, IF, CASE
and FOR blocks as each form becomes executable. Internal semicolons must never
become migration-step boundaries. Keep source, statement, migration-file and
editor limits separate; new syntax cannot silently widen an upstream bound.

## Verification and documentation

For every unit, compare independent syntax/locations, normalized typed projections
and generated SQL with hand-expanded equivalents. Include malformed nesting,
precedence, quoted/commented holes, foreign nominal types, hidden effects, ordered
refusals, allocation failures and boundary exhaustion. Formatter idempotence and
comment/literal preservation accompany semantic round trips.

Use pinned ANTLR generation with warnings as errors, full input consumption and
exact ambiguity diagnostics on the corpus. Runtime SQL must reject source-only
forms. A clean corpus establishes neither global grammar unambiguity nor general
semantic correctness.

Extend selected Lean laws with explicit premises and audited axioms. Independent
finite comparisons and real SQL execution remain necessary even when model and
SQL generation share a typed graph. Keep parsed, checked, executed and proved
results distinct; missing evidence cannot pass.

Add guides for domain modeling, optional query results, reusable helpers and
diagnosing failed specialization. Each guide needs a runnable example, a deliberate
failure and its correction. Update the source reference and supported-type table
in the same change; proposed spellings are not tutorials.

## Completion

All four units have contracts and executed positive/negative evidence. The
two-resource command case works from source through ordinary runtime operations;
generated SQL preserves identities, cell states, ordered failures and current
authorization. Qualification names both compiler and runtime revisions and the
remaining unsupported profile. The broader application workload is closed in
[milestone 10](10-application-qualification.md).
