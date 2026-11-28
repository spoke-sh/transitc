# Milestone 5 runtime handoff

These gates were established against Transit `f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6`,
the previous shared-package and compiled-case host pin. The
[completion record](../qualification/composition-completion.md) tracks the
merged scalar-analysis API and host qualification at
`b58715bf4ef4e5236748547ce15e37a602c4b471`. The
[bounded-result record](../qualification/bounded-many.md) tracks the paired
implementation now pinned at `d65f7c656c8e311806132ca894059b43b52051ee`.
The frozen compiler
comparison remains `e7434306334e3692c6f3e123cba0d278fa412196`. This document requests
ordinary runtime contracts; it does not authorize a compiler bypass or a pin
update without qualification. The [completion plan](05-completion-plan.md),
based on inspection of both merged repositories on 2026-11-27, sequences the remaining
native and compiler work and defines its acceptance gates.

| Gate | Observed boundary | Required upstream work and acceptance |
| --- | --- | --- |
| Native union programs | UNION Queue DDL succeeds; even a no-op consumer fails `ProgramTypeMismatch`. | Define program union values, tag/payload access, validation, codec and evolution. Execute both arms, reject malformed inputs, retain cell states, and qualify restart/authority. transitc currently uses the separately specified closed STRUCT encoding. |
| Bounded many | Transit #480 and transitc #7 are merged: MANY(1..64), immutable row collections and one atomic FOR level over a Table's single BIGINT primary key. Unannotated SELECT retains its singleton behavior. Native clean/hosted lanes, the final installed comparison and three hosted 49-case passes succeed. | Delivered regression baseline. Retain cumulative budgets, first-error order, changed-basis/rights checks, recovery and exact compiler/shared/host identities. Query-result contracts extend helper-local returns separately; nested/read-bearing loops remain excluded. |
| Missing/type-error/conflict program cells | `ApplicationData.fromCell` validates schema/cell state, admits SQL NULL, and refuses otherwise valid non-value cells with `ProgramTypeMismatch`. Earlier validation errors retain precedence. | Define state-preserving program cells and explicit conversions before admitting them in source row/variant values. Test all five states, nested fields, ambiguous/conflicting payloads and unchanged error order. Never convert these states into NULL or an absent row. |
| DATE/NUMERIC/INTERVAL program values | `ApplicationSchema.requireType` and `ApplicationValue` do not admit these logical representations. | Add ordinary literals, binding, runtime values and codecs together. Preserve Gregorian days, exact decimal coefficient/precision/scale and signed interval months/days/nanoseconds. Test overflow/inexact values, explicit rounding and no implicit timestamp/float/duration conversions. |
| Views | CREATE VIEW returns `UnsupportedStatement`. Native accepted single-Table views already have catalog definitions/dependencies and query expansion; transaction-bound preparation is refused. | Expose ordinary DDL and compiler binding through the existing native owners. Qualify exact schemas, stable identity, filtering/error order, current authority, dependency changes and restart. Keep unsupported transaction/migration forms explicit; materialization/maintenance remain separate. |
| Symbolic JSON/INTERVAL Table parameters | The native LogicalPrepared witness path refuses `UnsupportedComparison` for these descriptors. Concrete source parameters work. | Add typed prepared binding with exact JSON/interval representations, codec/bounds and no invented comparison traits. Test unselected specialization arms and exact descriptor/refusal behavior before enabling source symbolic Table holes. |
| Relational scalar projection | Direct projection of NUMERIC/JSON/INTERVAL succeeds. Adding ORDER BY id to that combined projection fails `UnsupportedRelationalType`. | Define which relational operators can carry these columns without inventing JSON equality or interval ordering. Test sorting by a separate integer key, projection, limits and unsupported traits independently. Literal/codec qualification does not qualify every query operator. |

The type gate is owned by
[`ApplicationSchema.zig`](https://github.com/spoke-sh/transit/blob/f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6/packages/zig/transit-sql-frontend/src/ApplicationSchema.zig)
and the value/SELECT boundary by
[`ApplicationData.zig`](https://github.com/spoke-sh/transit/blob/f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6/packages/zig/transit-query-direct/src/ApplicationData.zig).
The other requests above still need their own upstream design and implementation.
The merged completion slice adds scalar analysis APIs; the
[bounded many-row plan](05-bounded-many-results.md) now has paired implementation
and a separate qualification record for its local atomic profile. Native UNION is an
optional alternative to the current closed STRUCT encoding, not an additional
M5 completion requirement.

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
independent hygiene/type/refusal tests are implemented. The supporting pure
Transit API is merged in [Transit #479](https://github.com/spoke-sh/transit/pull/479);
current-profile hosted runtime qualification passes with the bounded-result
candidate. This needs no new native ROW representation. See the
[completion record](../qualification/composition-completion.md) and subsequent
[bounded-result record](../qualification/bounded-many.md) for exact revisions,
passing hosted schedules and retained local failures.
Source callable row/many returns, general implication solving, implicit signature
subtyping and unrestricted predicates are not silently admitted by this increment.
New source forms that depend on the native gates above still need their own
compiler implementation after the upstream contracts and pins are qualified.

The [previous slice plan](05-typed-composition-and-sql.md#previous-slice-complete-the-existing-composition-profile)
retains the composition qualification obligations. The
[bounded-result plan](05-bounded-many-results.md) records the merged slice, and
the [completion plan](05-completion-plan.md) sequences the remaining features and
integrated qualification. The [milestone](05-typed-composition-and-sql.md) remains
open. These handoffs do not close milestone 5 or transfer compiler-owned work upstream.
