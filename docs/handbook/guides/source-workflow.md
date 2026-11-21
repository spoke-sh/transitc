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

The compiled SQL creates `items`, inserts the value `7`, and selects its rows.
Change `Rows` to a non-exported or unknown name to see a source diagnostic and no
published product; restore the exact exported interface to correct it. Parameter
`NAME 'items'` supplies an identifier and `7` supplies `BIGINT`; substituting a
text value for the integer rejects. Resource interfaces and references are
checked capabilities within the compiler, and do not grant runtime privileges.

Run `transitc fmt` to apply the [standard source style](formatting.md),
then `transitc build --check` and `transitc build`. Imports resolve explicit
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

## Exercise the locked dependency workflow

With Git and transitc on PATH, run the following in an empty temporary directory.
It creates its own local Git repository, pins a full commit and removes the origin
after fetch to demonstrate an ordinary cached build:

```sh
#!/bin/sh
# Run in an empty temporary directory with Git and transitc on PATH.
set -eu
compiler=${TRANSITC:-transitc}
mkdir library application
cat > library/build.transit <<'SQL'
CREATE PUBLIC MODULE Rows() AS BEGIN
  CREATE PUBLIC TABLE items (id BIGINT);
END;
SQL
git -C library init --quiet
git -C library add build.transit
git -C library -c user.name=Example -c user.email=example@example.invalid commit --quiet -m 'Pin example module'
revision=$(git -C library rev-parse HEAD)
repository=$(cd library && pwd -P)
cat > application/build.transit <<SQL
DEPENDENCY common FROM '$repository' REVISION '$revision';
IMPORT shared FROM PACKAGE common FILE 'build.transit';
CREATE TARGET default AS BEGIN
  USE shared.Rows();
END;
SQL
cd application
"$compiler" build --fetch
"$compiler" build --check
mv ../library ../library-unavailable
# The origin is now unavailable; the lock and verified cache suffice.
"$compiler" build --out reviewed
```

The final build returns zero and publishes `application/reviewed/application.sql`
containing `CREATE TABLE ITEMS ( ID BIGINT );`. The lock is
`application/transit.lock`; verified dependency bytes live below
`application/.transit/packages`. Commit the lock with the application. Replace the
local repository path with a reviewed remote URL for a real shared dependency.

To exercise recovery, remove `.transit/packages` inside the disposable application
and run `transitc build --check`: the missing cache rejects. Restore the origin by
renaming `library-unavailable` to `library`, then run `transitc build --fetch` from
`application` and repeat the check. It succeeds with the same lock content.
For a local override, use `transitc build --override common=../library`; inspect
the explicit override in provenance before returning to the locked build.
