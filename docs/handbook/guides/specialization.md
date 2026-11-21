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
arms too. Whole-input ROW helpers with symbolic scalar holes remain outside this
bounded profile; pass the needed fields explicitly. Internal checking fields are
never published and cannot be named by authored program SQL.

This checking establishes type and binding obligations. Runtime guards, row
existence, atomic outcomes and current permissions still belong to Transit.
