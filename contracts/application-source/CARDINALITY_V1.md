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

## Bounded collections and iteration

```sql
BEGIN ATOMIC
  LET selected MANY(16) = SELECT id, note FROM items
    WHERE batch = request.batch ORDER BY id;
  LET batch = selected;
  FOR item IN batch DO
    CHECK GUARD Validate(item);
    PRODUCE INTO processed VALUES (item.id, item.note);
  END FOR;
END;
```

MANY requires a literal bound from 1 through 64 and ascending order by the
Table's single non-NULL BIGINT primary key. `ASC` is optional. Empty results are
empty, non-null collections; a row's nullable fields remain nullable. The entire
matching result must fit the bound. The next matching row causes native
`ProgramCardinalityMismatch`, without truncation or body execution. Bare MANY
without a bound, other ordering, joins, aggregates and Documents are unsupported.

The checked descriptor retains the bound, order and exact nominal row fields
through immutable aliases. The iterator is a present row. Direct, imported,
nested and callable ROW helpers receive that row with its original domains.
Collections cannot replace a scalar or ROW argument, become ROW members, take
part in scalar operators or conditional expressions, or escape their atomic
scope. Iterators and body locals are scoped to one iteration. A zero-row loop
establishes no facts after the loop. Every body and specialization arm is checked.

Lowering emits the native collection read and a single FOR body, with hygienic
local names. It does not unroll the loop or synthesize sample rows. The complete
read uses the caller's serializable workspace, followed by ordered iteration.
One loop level is admitted; sequential loops may reuse the frozen collection.
Reads, effects, suspension, response handoff and nested loops in the body are
rejected, including operations introduced by helpers. Scalar expressions, guards,
branches and existing transactional writes/appends retain their ordinary rules.

The native owner validates cells and converts each row before evaluating its
predicate, checks the matching-row cap before its retained-byte cap, validates
the read basis, then executes the body in signed-key order. A later body refusal
rolls back earlier writes and appends in that atomic block. Runtime authority
checks remain current; a collection or helper is not a grant.

The paired Transit contract owns cumulative MANY request/scan/result budgets,
continuation/retained bytes and transaction limits. Expanded cursor steps and
instruction/expression visits must each fit the existing 12,288-work ceiling.
Changing a row cap cannot bypass the work check. The shared frontend and host
must agree on the new current definition; old durable continuations are rejected.
The compiled-case protocol is unchanged.

The fixtures compare zero/one/multiple rows, present NULL, absent OPTIONAL values
and rollback after a Stream append with independently authored SQL. Unit and
finite checked-core comparisons cover nominal fields, guarded projection,
branch-local evidence, CASE joins and negative controls. Existing Lean laws are
unchanged and are not a proof of this new refinement checker.
