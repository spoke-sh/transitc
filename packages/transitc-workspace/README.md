# transitc-workspace

`transitc_workspace` captures confined source files, resolves pinned repositories,
checks transitive locks and overrides, and publishes complete SQL/provenance or
migration artifacts. Build evaluation never opens a SQL client. Only explicit
fetch accesses repositories; ordinary builds use verified local caches.

`Sources` owns input I/O and resolution; `Migration` reads immutable prior basis
and history; `Build` composes these with the pure compiler. `Options`, `Report`,
`Style` and `Diagnostic` implement bounded invocation and human presentation.
The caller supplies its compiler revision. Executable identity is SHA-256 over
all executable bytes, separate from release version and contract definition.

`Format` owns formatter invocation, bounded recursive discovery, stdin/check
modes and per-file atomic replacement. It calls the compiler's pure formatter
without loading dependencies. Run `just test::fmt` for its CLI and filesystem
checks.

The public build adapter accepts a diagnostic context structurally. The compiler
never imports this package; Transit imports neither library. See the
[package map](../README.md) for the exact upstream pins.

Run `zig build test` here and root `just test::workspace`. The workspace suite
exercises actual subprocesses, offline socket refusal, locks, hashes, overrides,
path confinement, diagnostics, corrupted artifacts, interrupted publication and
immutable migration histories. Its seccomp controls currently require Linux.
`Test` owns suite compilation, deadlines, case scheduling, cleanup and reports.
`TestProcessHost` sends compiled cases to an explicitly selected Transit executable
through the bounded [test-host contract](../../contracts/TEST_HOST_V1.md).
The pure compiler does not import process or database code. Database execution
stays upstream in Transit. Run `just test::command` for the compiler-owned application schedule through
`transitc test` and negative controls for the compiled-case boundary.
