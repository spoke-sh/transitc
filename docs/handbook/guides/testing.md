# Run application tests

Use the Nix package or development shell from [getting started](getting-started.md).
They supply the compatible Transit test host. No running service or existing
database installation is needed. Put this complete suite in `build.transit`:

```sql
CREATE TEST TARGET tests AS BEGIN
  TEST 'rows and counts' USING MODULES () AS BEGIN
    CREATE PUBLIC TABLE items (id BIGINT PRIMARY KEY, label TEXT);
    ASSERT COMMAND (INSERT INTO items VALUES (7, 'ready')) MATCHED 1 CHANGED 1;
    ASSERT ROWS (SELECT * FROM items) EQUAL ((7, 'ready'));
    ASSERT STATEMENT (INSERT INTO items VALUES (7, 'duplicate')) FAILS WITH 'duplicate_key';
  END;
  TEST 'fresh state' USING MODULES () AS BEGIN
    CREATE PUBLIC TABLE items (id BIGINT PRIMARY KEY, label TEXT);
    ASSERT ROWS (SELECT * FROM items) EQUAL ();
  END;
END;
```

Run the suite:

```sh
transitc test --format json
```

The command returns status 0 with `ok: true`, `complete: true`, and two `passed`
cases. The first case observes one row; the second observes none because each
case has its own fresh database. The report records case/SQL identities, source
locations, compiler and runtime identities, observations and resource bounds.
Without `--format json`, successful case names and human failures use stderr.

Change the first row expectation to `((8, 'ready'))`. The command now returns
status 1 with `complete: true`, `ok: false`, a `rows` assertion failure in the
first case, and a passed second case. Correct the expectation before continuing.
Initialization, deadline, transport, result-limit or cleanup failures instead
produce an incomplete report; later cases remain `not_run`. Missing output or a
successful process exit alone cannot establish a passed suite.

Tests use the same module graph, type checker and SQL emitter as ordinary builds.
All cases compile before the first runtime starts. A source error in a later case
therefore prevents every case from executing. `-f`, `--target`, `--override`,
`--color` and `--format` work as described in the [CLI reference](../reference/cli.md).
Tests resolve locked dependencies offline. Run `transitc build --fetch` separately
when an exact dependency is missing; `test` does not accept `--fetch` or publish
build artifacts. No connection settings or existing installation credentials are
accepted.

Each case runs real statement owners in a listener-free local Transit database.
The compiler sends compiled SQL and typed expectations, without source files or
repository access. Normal success and failure join the host and remove its owned
temporary state. A failed deletion is reported; abrupt termination of the compiler
can leave its private temporary directory. The host retains its own deadline even
if the compiler terminates. Do not replay uncertain SQL into another installation.

The current bounds are 128 cases, 1,024 actions per case, 10,000 observed rows,
16 MiB of result bytes, 30 seconds per case, 300 seconds per suite, and five seconds
for cleanup. Compiler products have a 64 MiB budget; tooling, transport and native
host allocations are bounded separately. The native host retains 256 MiB memory
and storage caps. Source code and command options cannot raise these limits.
These local tests establish application behavior in this profile, not distributed
provider or production deployment qualification.

To select a locally built compatible host, use `transitc test --runtime /path/to/transit`.
The host must implement the current compiled-case definition. The report identifies
the actual runtime revision and executable digest; changing runtimes during a suite
fails. An older host without this boundary cannot substitute for the pinned host.
