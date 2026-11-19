# CLI reference

`transitc`, `transitc --help` and `transitc -h` print help to stdout.
`transitc --version` prints the compiler version and build revision.

```text
transitc build [options]
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

Fetch cannot combine with check, output or overrides. Check cannot combine with
output. Other options may appear once, except distinct overrides. Invalid names,
missing option values and unknown options reject. No connection settings or
credentials are accepted.

Status 0 means the requested local operation completed, 1 means compilation or
workspace failure, and 2 means invalid invocation or unsupported command. Human
build results/errors use stderr; JSON reports use stdout. Help/version use stdout.
No SQL is submitted by these commands. There is no formatter CLI, language server,
package publisher, SQL executor or runtime test command in this release.
