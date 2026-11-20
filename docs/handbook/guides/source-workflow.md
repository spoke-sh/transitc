# Modules and dependencies

A build entry is source in the same language as its modules. For example,
`rows.transit` can export a typed module:

```sql
CREATE PUBLIC MODULE Rows(name IDENTIFIER, initial BIGINT) AS BEGIN
  CREATE PUBLIC TABLE $name (id BIGINT);
  INSERT INTO $name VALUES ($initial);
END;
```

Use it from `build.transit`:

```sql
IMPORT rows FROM 'rows.transit';
CREATE TARGET default AS BEGIN
  USE rows.Rows(NAME 'items', 7);
  SELECT * FROM items;
END;
```

Run `transitc build --check`, then `transitc build`. Imports resolve explicit
module interfaces. File paths and import aliases do not grant permissions or
replace explicit durable object identities. Missing imports, visibility failures,
cycles and exhausted evaluation budgets reject before publication.

Repository dependencies name an exact revision. Replace the placeholders below
with the repository's URL and full Git commit before using this declaration:

```sql
DEPENDENCY common FROM '<repository-url>' REVISION '<full-commit>';
IMPORT shared FROM PACKAGE common FILE 'build.transit';
```

Run `transitc build --fetch` after reviewing the declared repositories. Fetch is
the only repository-network operation and requires Git on PATH. It verifies
content and records transitive pins in `transit.lock`. Keep that lock with source.
Subsequent `transitc build` runs offline from the verified cache; a missing cache,
missing lock or digest mismatch fails. Restore the exact cache with fetch rather
than editing hashes to accept different content.

For local development, use `transitc build --override common=/absolute/path`.
Overrides are explicit provenance inputs and cannot combine with fetch. They do
not silently change repository pins. Remove the override to reproduce the locked
repository build. Paths are confined; symlink escapes and invalid subdirectories
are rejected. Never use build publication as a deployment approval.

See [language](../reference/language.md) for the exact source contract and
[artifacts](../reference/artifacts.md) for migration proposals.
