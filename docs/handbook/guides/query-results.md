# Handle query results

Declare whether a program needs one row or can handle its absence:

```sql
LET account ONE = SELECT id, note FROM accounts WHERE id = request.id;
```

ONE refuses with `ExpectedOneRow` when the read finds no row. A successful read
can still contain NULL in a nullable column. Two matching rows cause Transit's
`ProgramCardinalityMismatch`; ONE never picks an arbitrary first row.

For an optional result, check the entire record before projecting a field:

```sql
LET account OPTIONAL = SELECT id, note FROM accounts WHERE id = request.id;
IF account IS NOT NULL THEN
  PRODUCE INTO account_events VALUES (account.id, account.note);
END IF;
```

Use this inside the program's atomic block. `account.note IS NOT NULL` is not a
row-presence test: an existing account can have a NULL note. Removing the whole-row
check produces `OptionalRowRequiresPresence`. Restore it, or use ONE when absence
should refuse the command. A direct `REQUIRE account IS NOT NULL ELSE 'Absent';`
also permits subsequent projection and helper calls.

Presence knowledge stays within the checked branch. It applies to the captured
record and does not promise the database row still exists after another write or
observation. Runtime operations continue to check their own state and authority.

Run the repository's examples with:

```sh
transitc test -f tests/fixtures/application-cardinality/build.transit
```

The eight cases cover both read forms with an absent row, a present NULL field,
multiple matching rows and refusal after a staged output. The `default` and
`optional` build targets produce ordinary SQL for independent installation.

## Process a bounded batch

Use MANY when one atomic decision needs several rows:

```sql
BEGIN ATOMIC
  LET selected MANY(3) = SELECT id, note FROM items
    WHERE batch = request.batch ORDER BY id;
  FOR item IN selected DO
    PRODUCE INTO processed VALUES (item.id, item.note);
  END FOR;
END;
```

The Table must have one non-null BIGINT primary key, named by `ORDER BY`.
Rows execute in ascending signed-key order, regardless of insertion order.
Duplicate notes remain separate rows. An empty collection executes no body;
a single row with a NULL note executes once and preserves that NULL. Each
iterator is a present, immutable row and can be passed to a compatible ROW helper.

The bound is a literal from 1 through 64. Four matching rows with `MANY(3)` refuse
with `ProgramCardinalityMismatch` before any output. If four rows are expected,
use `MANY(4)` after checking the expanded work and transaction limits. Otherwise
restrict the predicate to the intended batch. Raising the cap never silently
truncates results or raises Transit's other budgets.

Predicates use row fields, scalar expressions and existing bindings. Database
observation functions such as `CURRENT_REVISION` and `SECRET_CURRENT` are refused
inside a MANY predicate, including branches that would not execute.

Collection selection and all iterations share the caller's atomic transaction.
A refusal in a later iteration rolls back earlier outputs and writes. Keep
reads before the loop: its body admits guards, scalar/ROW helpers, branches and
transactional mutations, but no additional reads, nested loops or effects.
This includes operations hidden in helpers. The iterator and its local bindings
disappear at loop exit; the collection disappears at the atomic boundary.

Run the seven bounded-batch examples with:

```sh
transitc test -f tests/fixtures/application-bounded-many/build.transit
```

They cover empty, nullable, multiple and exact-bound results, overflow and
rollback. The `two` build target creates independent instances. The installed
comparison also executes separately authored SQL after removing the source.

Missing, type-error and conflict cells cannot enter the current program value
model. They retain native refusal behavior. Existing unannotated SELECT bindings
retain their previous nullable-record behavior; ONE and OPTIONAL enable explicit
presence checking. Read-only procedures can return these results to their atomic caller.
See [reusable behavior](reusable-behavior.md) for a callable MANY result.
