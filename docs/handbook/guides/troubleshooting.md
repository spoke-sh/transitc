# Diagnose failures and limits

Start with `transitc --version` and the command's `--help`. Keep the source,
lockfile and exact invocation that failed. A minimal reproduction should retain
the failing module interfaces without credentials or unrelated application data.
Use `--color off` for build/test logs or `--format json` for their bounded report.

## Correct a source error

Create `build.transit` containing `invalid source;` and run:

```sh
transitc build --check --format json
```

The process returns 1, reports a diagnostic with `outcome: "not_submitted"`, and
publishes no artifacts. Replace the file with the complete example in
[getting started](getting-started.md), then repeat the check. It now returns 0.
A source coordinate refers to captured bytes; inspect the reported file and both
definition/call sites for an expansion error. A missing file has a path fact and
does not invent a source span. Unknown command options return 2, not a source
diagnostic. Exact families and ownership are in [diagnostics](../reference/diagnostics.md).

## Restore dependencies and outputs

| Symptom | Correction |
| --- | --- |
| Missing dependency lock/cache | Review declared exact revisions, then run `transitc build --fetch` with Git available |
| Digest mismatch | Preserve the unexpected bytes, remove the affected cache in a disposable checkout and fetch the same reviewed revision; never edit the expected hash to match unknown content |
| Override differs from normal build | Remove the explicit `--override`, then use the locked dependency; review the provenance in either case |
| Existing explicit output | Choose a new `--out` path; publication never replaces an existing directory |
| Damaged default output | Preserve the damaged output for diagnosis and build to a new explicit path; default reuse validates retained bytes |
| Import path or symlink escape | Move the declared inputs inside the workspace and use direct confined paths |

An interrupted publication is not a complete product. Preserve its diagnostics
and retry into a fresh directory. Migration basis and history are inputs, so keep
their original identities and bytes when recovering a workspace. See
[modules and dependencies](source-workflow.md) and [artifacts](../reference/artifacts.md).

## Respect bounded profiles

Compiler input, evaluation depth, instantiations, type catalog, output and
allocations have explicit bounds in the
[source contract](https://github.com/spoke-sh/transitc/blob/main/contracts/APPLICATION_SOURCE_V1.md).
Splitting a file does not bypass a total workspace or product limit. Reduce the
project, simplify expansion or reduce generated SQL after identifying the
reported bound; command-line options cannot increase these limits.

The compiler product budget is 64 MiB. Application suites admit 128 cases and
1,024 actions per case, with 10,000 observed rows and 16 MiB of result bytes.
Cases have 30-second deadlines, suites 300 seconds, and cleanup five seconds.
These are separate from compiler evaluation and native host memory/storage caps.
See [testing](testing.md) for the full boundary and failure semantics.

`TestRuntimeUnavailable` means host selection failed; select the compatible
executable with `--runtime`. A definition mismatch, changed executable, malformed
response, process failure, deadline or cleanup failure produces an incomplete
suite. Fix that cause before retrying; later `not_run` cases have no assertion
result. Completed assertion failures instead identify the failed observation.
Do not replay uncertain execution into a production installation.

When reporting a bug, include compiler and host revisions, host OS/architecture,
exit status, the bounded diagnostic/report and a small source reproduction.
Allocation failure, timeout and interrupted writes are tested refusal paths;
they are not permission to report partial artifacts or incomplete tests as passed.
