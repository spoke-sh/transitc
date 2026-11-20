# Artifacts and migrations

An ordinary build publishes `application.sql` and `provenance.json` together.
Provenance records completion, source identities, exact dependency resolutions,
selected target, limits, ordered SQL steps, source maps and digests. The default
output is `.transit/build/<target>/<input-digest>/`. An explicit `--out` must be
new. Publication uses a synced temporary directory and an atomic rename.

Rebuilding with identical inputs and the same executable produces identical
artifacts. Default-path reuse verifies retained bytes. Missing/corrupted content
refuses reuse; a partial or interrupted publication is never reported as complete.
`--check` validates without publishing. `--fetch` publishes dependency locks,
not compiled SQL.

Release version, compiler revision/executable digest, input digest, SQL digest and
protocol-definition identity answer different questions. The extracted executable
has a different compiler identity from Transit, so input/cache identity changes.
SQL, maps and the current contract definition remain equal for equivalent source.
Never rewrite accepted history to hide an identity mismatch.

## Generate a migration proposal

A migration target requires an explicit basis and database/schema identity:

```sql
CREATE MIGRATION TARGET default FROM EMPTY
FOR DATABASE 'transit' SCHEMA 'public' VERSION '0001' NAME 'tables'
AS BEGIN
  CREATE PUBLIC TABLE items (id BIGINT PRIMARY KEY);
END;
```

Run `transitc build --out migration-review`. Inspect `desired.sql`, `basis.json`,
`migrations/0001-tables.sql` and `provenance.json`. This is a proposal; no database was
contacted. To evolve it, refer to the retained `basis.json` from a later target
and choose a new ordered migration version. Keep the basis and immutable SQL
history available within the allowed workspace. Ambiguous/destructive changes
require explicit transforms and otherwise reject. Existing history bytes and
original identities remain unchanged; schema-qualified evolution is checked.

Applying reviewed SQL is the runtime owner's separate operation. Do not treat
compiler success, a generated file or a matching v1 label as runtime acceptance,
compatibility across different definitions, or migration completion.
