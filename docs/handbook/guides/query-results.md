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

Missing, type-error and conflict cells cannot enter the current program value
model. They retain native refusal behavior. Bounded many-row consumption is not
yet supported. Existing unannotated SELECT bindings retain their previous
nullable-record behavior; ONE and OPTIONAL enable explicit presence checking.
