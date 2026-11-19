# Compiler architecture

The source account here is based on Transit commit
`e7434306334e3692c6f3e123cba0d278fa412196`. Only the CLI scaffold and build tooling
exist in this repository today.

## Existing separation

The
[pure compiler](https://github.com/spoke-sh/transit/blob/e7434306334e3692c6f3e123cba0d278fa412196/packages/zig/transit-compiler/src/root.zig)
accepts immutable source buffers and options. Syntax/templates and the module
graph feed source typing, proposed catalogs, program lowering, and SQL emission.
Fuze's public typed owners validate expanded statements and verify emitted SQL.
Migration synthesis works from an explicit immutable basis; test compilation
returns cases and expectations without running them.

The CLI's
[BuildSources adapter](https://github.com/spoke-sh/transit/blob/e7434306334e3692c6f3e123cba0d278fa412196/apps/transit-cli/BuildSources.zig)
owns file capture and frozen dependency resolution. Build adapters own artifact
publication. This is the seam that allows compilation to remain deterministic
with respect to captured inputs and options while tools perform I/O explicitly.

## Extraction boundaries

| Boundary | Intended responsibility |
| --- | --- |
| CLI | Arguments, terminal output, exit status, composition |
| Workspace | Filesystem/network adapters, locks, provenance, artifact publication |
| Compiler | Immutable graph, source semantics, lowering, verified products |
| SQL frontend | Shared SQL parsing, typed statement/schema/program validation |
| Diagnostics | Bounded values and locations shared across those layers |

The SQL frontend remains a proposal: Fuze's exact transitive closure and shared
ownership must be resolved before a package is extracted. Memory budgeting should
reuse the existing dependency. Do not independently reimplement shared SQL or
protocol semantics to make imports compile.

## Invariants and verification

Preserve input and product bounds, cleanup after allocation failure, immutable
captured inputs, deterministic output ordering, source-coordinate fidelity, and
the independent emitted-SQL verification step. Returned product ownership and
diagnostic lifetimes must remain explicit in the public API.

The scaffold checks establish that the CLI builds/runs and documentation renders.
The separate
[upstream integration suite](https://github.com/spoke-sh/transitc/blob/main/tests/integration/README.md)
invokes the pinned Transit compiler and runtime to verify SQL output, reproducible
artifacts, provenance, diagnostic coordinates, and passing/failing isolated tests.
It supplies a baseline for extraction; it does not prove transitc compiler parity.
The source repository's
[verification account](https://github.com/spoke-sh/transit/blob/e7434306334e3692c6f3e123cba0d278fa412196/tests/query/application_source/README.md)
identifies grammar comparisons, scoped formal checks, and independent SQL tests.
Those checks and their fixtures have not moved; their results must not be
represented as executed transitc evidence.
