# Milestone 5 runtime handoff

These gates are against Transit `f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6`,
which supplies both pure packages and the compiled-case host. The frozen compiler
comparison remains `e7434306334e3692c6f3e123cba0d278fa412196`. This document requests
ordinary runtime contracts; it does not authorize a compiler bypass or a pin
update without qualification.

| Gate | Observed boundary | Required upstream work and acceptance |
| --- | --- | --- |
| Native union programs | UNION Queue DDL succeeds; even a no-op consumer fails `ProgramTypeMismatch`. | Define program union values, tag/payload access, validation, codec and evolution. Execute both arms, reject malformed inputs, retain cell states, and qualify restart/authority. transitc currently uses the separately specified closed STRUCT encoding. |
| Bounded many | SELECT produces zero/one nullable records and refuses multiple rows with `ProgramCardinalityMismatch`. | Own an ordinary query/consumption operation and value representation with explicit row, byte and work limits. Specify order, snapshot/transaction basis, empty results, excess-row error and first-error order. Prove no implicit unbounded materialization; test exact limits and allocation failures. |
| Missing/type-error/conflict program cells | `ApplicationData.fromCell` validates schema/cell state, admits SQL NULL, and refuses otherwise valid non-value cells with `ProgramTypeMismatch`. Earlier validation errors retain precedence. | Define state-preserving program cells and explicit conversions before admitting them in source row/variant values. Test all five states, nested fields, ambiguous/conflicting payloads and unchanged error order. Never convert these states into NULL or an absent row. |
| DATE/NUMERIC/INTERVAL program values | `ApplicationSchema.requireType` and `ApplicationValue` do not admit these logical representations. | Add ordinary literals, binding, runtime values and codecs together. Preserve Gregorian days, exact decimal coefficient/precision/scale and signed interval months/days/nanoseconds. Test overflow/inexact values, explicit rounding and no implicit timestamp/float/duration conversions. |
| Views | CREATE VIEW returns `UnsupportedStatement`; materialized views have no admitted source/runtime contract. | Own ordinary DDL, concrete schema/dependencies, stable definition identity, executable queries, current authority and evolution. Ordinary views precede a separate materialization/maintenance contract. Test source-free execution, restart, changed dependencies and revoked rights. |
| Symbolic JSON/INTERVAL Table parameters | The native LogicalPrepared witness path refuses `UnsupportedComparison` for these descriptors. Concrete source parameters work. | Add typed prepared binding with exact JSON/interval representations, codec/bounds and no invented comparison traits. Test unselected specialization arms and exact descriptor/refusal behavior before enabling source symbolic Table holes. |
| Relational scalar projection | Direct projection of NUMERIC/JSON/INTERVAL succeeds. Adding ORDER BY id to that combined projection fails `UnsupportedRelationalType`. | Define which relational operators can carry these columns without inventing JSON equality or interval ordering. Test sorting by a separate integer key, projection, limits and unsupported traits independently. Literal/codec qualification does not qualify every query operator. |

The type gate is owned by
[`ApplicationSchema.zig`](https://github.com/spoke-sh/transit/blob/f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6/packages/zig/transit-sql-frontend/src/ApplicationSchema.zig)
and the value/SELECT boundary by
[`ApplicationData.zig`](https://github.com/spoke-sh/transit/blob/f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6/packages/zig/transit-query-direct/src/ApplicationData.zig).
The requests above need their own upstream design and implementation; no upstream
runtime files or pins have been modified in this compiler increment.

## Compiled-case deadline investigation

Keep the 30-second case and five-minute suite limits. Local runs of the dynamic
workflow and cardinality fixtures hit `TestDeadline` while observing completion.
An unchanged existing `application-typed-queue` success case also reaches that
limit on this host. Earlier successful runs and later failures are distinct
records; this does not establish that every failure has one cause.

Installed generated ONE programs and independent SQL both reached the expected
one completion/three refusals, including absent/multiple rows and late rollback.
The installed harness observes each request separately with the existing upstream
observation deadline. It uses the upstream `program_control` helper when suspending
a completed program: that helper settles each original control identity and
retries only a proved terminal rejection caused by a changing saved head.

An upstream investigation should retain phase timing/work counters for bootstrap,
DDL, authorization, Queue claim, each program instruction, completion publication
and joined cleanup. Compare the existing typed-Queue case with the new cases on a
quiet host before changing budgets. Neither successful compilation nor an
incomplete report qualifies runtime completion. Do not weaken assertions, admit
late success, disable trusted-clock checks or raise deadlines to manufacture a
passing result.

## Compiler work still owned here

Bounded scalar pre/postconditions, exact resource/effect signatures, callable module
arguments and JSON/INTERVAL source parameter/domain forms now have compiler
contracts and implementation. The qualification record separates their passing
installed journeys from isolated deadline failures. Fixing or investigating a
failing test remains work; a declared runtime dependency does not turn a failure
into a pass.

Whole-input ROW helpers with symbolic scalar holes now preserve the authored
Queue shape through a separate bounded analysis environment. The compiler and
independent hygiene/type/refusal tests are implemented; the supporting pure
Transit API and its candidate pin still require upstream merge and complete
qualification. This needs no new native ROW representation. See the
[completion record](../qualification/composition-completion.md) for actual
revisions and results.
Source callable row/many returns, general implication solving, implicit signature
subtyping and unrestricted predicates are not silently admitted by this increment.
New source forms that depend on the native gates above still need their own
compiler implementation after the upstream contracts and pins are qualified.

The [next slice plan](05-typed-composition-and-sql.md#next-slice-complete-the-existing-composition-profile)
sequences completion diagnosis, precise ROW admission, any owning fix/pin update
and full qualification. The [milestone plan](05-typed-composition-and-sql.md)
remains open. These handoffs do not close milestone 5 or transfer compiler-owned
work upstream.
