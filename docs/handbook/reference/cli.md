# CLI reference

`transitc`, `transitc --help` and `transitc -h` print help to stdout.
`transitc --version` prints the compiler version and build revision.

```text
transitc build [options]
transitc test [options]
```

| Option | Meaning |
| --- | --- |
| `-f FILE` | Entry file; default `build.transit` |
| `--target NAME` | Select a declared target; otherwise use the entry's declared default or `default` |
| `--out DIRECTORY` | Publish to a new explicit directory |
| `--check` | Validate without artifact publication |
| `--fetch` | Fetch exact dependency revisions, verify content and publish `transit.lock` |
| `--override NAME=DIR` | Explicit local dependency override; repeat for different names |
| `--format text\|json` | Human or machine output; default text |
| `--color auto\|off\|on` | Human color; default auto |
| `--help` | Display help |
| `--runtime FILE` | Select a compatible Transit test host; test only |

Fetch cannot combine with check, output or overrides. Check cannot combine with
output. Other options may appear once, except distinct overrides. Invalid names,
missing option values and unknown options reject. No connection settings or
credentials are accepted.

For `test`, selection prefers a target named `tests`, then the entry's unique
test target. Multiple test targets require `--target NAME`.
`--out`, `--check` and `--fetch` are rejected. Source resolution remains
offline; fetch missing dependencies explicitly with `transitc build --fetch`.
The whole suite compiles before any case executes. Each case uses fresh private
database state, with no connection to an existing installation.

The test host is selected by `--runtime`, then `TRANSIT_TEST_RUNTIME`, then the
executable's build-time default. The Nix package and development shell provide
an exact compatible runtime. A plain Zig build can use `-Dtest-runtime=FILE`;
without a configured default it resolves `transit` on PATH. An unavailable or
incompatible host fails explicitly; the command never downloads one or falls
back to recompiling through `transit test`.

Status 0 means the requested operation completed successfully, 1 means compilation,
workspace, assertion or runtime failure, and 2 means invalid invocation or
unsupported command. Human results/errors use stderr; JSON reports use stdout.
Help/version use stdout. A test report distinguishes completed assertion failures
from incomplete execution and records the compiler and actual runtime identities.
See [testing](../guides/testing.md) for isolation and limits.

Build commands never submit SQL. Test commands execute only their isolated
cases. There is no formatter CLI, language server, package publisher or command
for applying SQL to an existing installation.
