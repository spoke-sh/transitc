# Result cardinality and row presence v1

Ordered programs, guards and procedures may declare query-result cardinality:

```sql
LET required ONE = SELECT id, note FROM items WHERE id = request.id;
LET possible OPTIONAL = SELECT id, note FROM items WHERE id = request.id;
```

Only SELECT is admitted on these right-hand sides. ONE and OPTIONAL describe the
number of rows, independently of column nullability. They do not describe the
five logical cell states and do not turn a bad cell into an absent row.

| Read | Zero rows | One row, including nullable fields | More than one row |
| --- | --- | --- | --- |
| ONE | Ordered refusal `ExpectedOneRow` | Present record | Native `ProgramCardinalityMismatch` |
| OPTIONAL | Absent record | Present record | Native `ProgramCardinalityMismatch` |

ONE lowers to a single native SELECT into an inaccessible hygienic variable, a
whole-record `IS NOT NULL` REQUIRE, and a public lexical alias after validation.
The alias carries one-row evidence and the original nominal fields. No dependent
effect or argument evaluation moves before this validation. An enclosing atomic
block retains rollback semantics.

OPTIONAL preserves the native optional record and requires a whole-row presence
check before field projection or a ROW helper argument. A direct
`REQUIRE possible IS NOT NULL ELSE 'Absent';` narrows the immutable binding for
subsequent instructions. `IF possible IS NOT NULL THEN ...` narrows only its true
arm; `IF possible IS NULL THEN ... ELSE ...` narrows only its false arm. Branch
facts do not escape. Aliases preserve cardinality, and CASE joins cannot turn a
possibly absent record into a one-row record. A nullable field is never a test
for row absence. Other predicates do not discharge the obligation; use without
the admitted check fails with `OptionalRowRequiresPresence` before publication.

This evidence is about the captured immutable record. It does not prove that a
resource row still exists, that its contents remain current, or that the caller
has authority. A later existence-sensitive operation must make its own ordinary
runtime observation. No state-dependent proof survives a write or suspension by
implication. Helper calls after narrowing preserve domain/cardinality evidence;
this increment does not add optional-row helper signatures.

Unannotated `LET row = SELECT ...` retains the existing nullable-record source
profile for compatibility. Explicit ONE/OPTIONAL opts into the checked presence
rules. No new implicit conversions are added to legacy reads.

## Native boundaries and evaluation order

Transit at `f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6` owns SELECT scanning, row
conversion, predicate evaluation, cardinality checks, consistency and work/result
limits. Lowering introduces no LIMIT, sorting, early exit or materialization.
Errors while scanning/converting rows occur before the post-read ONE assertion;
multiple-row refusal precedes dependent application effects.

SQL NULL remains a valid nullable field in a present record. The native program
value model cannot carry missing, type-error or conflict cells. Its cell/schema
validation errors propagate; otherwise its conversion rejects non-value cells
with `ProgramTypeMismatch`. These states are never silently mapped to NULL or
row absence. Qualification does not claim a new runtime representation for them.

Bounded many-row results remain an upstream gate: ordinary owned query/consumption
operations, a program value representation, explicit row/work limits and ordering
semantics must exist before source admission. `LET rows MANY = ...` is rejected.

The fixtures compare zero/one/multiple rows, present NULL, absent OPTIONAL values
and rollback after a Stream append with independently authored SQL. Unit and
finite checked-core comparisons cover nominal fields, guarded projection,
branch-local evidence, CASE joins and negative controls. Existing Lean laws are
unchanged and are not a proof of this new refinement checker.
