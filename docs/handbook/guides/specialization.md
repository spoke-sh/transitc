# Diagnose specialization failures

A compile-time MATCH chooses which program to emit. Every arm is type-checked,
including arms that the selected target does not execute. This catches a foreign
ID or invalid resource binding before another target later selects that arm.

Build the repository's complete example:

```sh
transitc build -f tests/fixtures/application-symbolic-program/build.transit --check
```

It declares MachineId and SiteId as separate nominal BIGINT domains, creates both
Tables and selects `Target.Machine(MachineId(7))`. The generated SQL contains the
Machine program alone. Changing the Site program from:

```sql
INSERT INTO sites VALUES ($value) ON CONFLICT (id) DO ASSERT SAME ROW;
```

to:

```sql
INSERT INTO machines VALUES ($value) ON CONFLICT (id) DO ASSERT SAME ROW;
```

fails with `SourceDomainMismatch`, even though the Site arm is unselected. Restore
the `sites` binding to fix it. Changing both IDs to raw BIGINT would erase the
static distinction that caught the mistake.

Unknown payloads are checked using their declared types, without choosing a
representative value. Concrete schema names, resource bindings and program
identities must still be known. A symbolic IF cannot introduce catalog objects or
exports. Program types unavailable in Transit remain unavailable in unselected
arms too. A helper can receive the complete input row and a symbolic scalar:

```sql
CREATE FUNCTION accepts_input(entry ROW(id BIGINT), expected SiteId)
RETURNS BOOLEAN AS BEGIN
  RETURN entry.id > 0 AND expected = expected;
END;
```

Inside `EmitSite`, use `REQUIRE accepts_input(request, $value) ELSE 'BadInput';`
before the write. Named ROW parameters require their declared fields and allow
additional input fields. `ROW(request.id)` supplies a positional row, whose field
count and order must match the parameter. Aliases of the input preserve its
fields, nullability and nominal domains through functions, guards and procedures.

The complete [whole-row example](../../../tests/fixtures/application-whole-row/build.transit)
passes a 64-column Queue row through imported and nested helpers:

```sh
transitc build -f tests/fixtures/application-whole-row/build.transit --check
transitc test -f tests/fixtures/application-whole-row/build.transit
```

Checking constants have a separate 64-parameter bound per lowered program; they
do not consume the Queue's field budget. Native row/depth limits still apply.
Internal checking names never appear in emitted SQL and cannot be named by
authored program SQL. Queue acquisition predicates retain the native bounded
predicate profile; type-only constants do not enable arbitrary predicate calls.

This checking establishes type and binding obligations. Runtime guards, row
existence, atomic outcomes and current permissions still belong to Transit.
