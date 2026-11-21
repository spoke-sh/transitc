# Package boundaries

| Package | Responsibility | Direct shared imports |
| --- | --- | --- |
| [transitc-compiler](transitc-compiler/README.md) | Source syntax, graphs, types, lowering, verified SQL, migrations and test products | `transit_sql_frontend`, `transit_protocol`, `transit_memory`, `transit_test_protocol` |
| [transitc-workspace](transitc-workspace/README.md) | Captured source, exact dependencies, locks, publication, test orchestration and reports | Compiler plus the same four shared modules |

The CLI composes these libraries. The compiler performs no filesystem, network,
service or runtime execution. Workspace I/O is explicit; repository access occurs
only during fetch. Test orchestration sends compiled cases through the
[test-host boundary](../contracts/TEST_HOST_V1.md); database execution stays in Transit.

Transit owns `transit-sql-frontend`, protocol values (including diagnostic envelopes,
JSON, definition identity and resource contracts), spatial values and the memory
budget allocator. No second SQL type system or allocator lives here. Compiler
`SourceDiagnostic` adds source failure families over the shared diagnostic values.
The reserved diagnostics/SQL packages were removed because these owners suffice.

Standalone manifests pin the generated pure source archive at
`5d13883116f5d9b8ef748625b47108a7ef9b3212` with its Zig content hash. The compiled-case
runtime uses the same Transit revision through the `transit` flake input. The comparison binary remains
independently frozen at `e7434306334e3692c6f3e123cba0d278fa412196`.
The archive contains only the five pure packages and a small composition manifest.
Its generator verifies exact source bytes and deterministic archive contents.
Runtime and Arrow packages are absent from the distribution.

Transit is upstream of transitc. Neither its runtime nor its build graph imports
this repository. The compiler and workspace consume the same exactly pinned SQL,
protocol, memory and neutral test-contract modules. There is no embedded mode
that injects a compiler into Transit. The packaged CLI independently selects a
compatible Transit executable for compiled-case execution. Remote source choices
are immutable; no sibling checkout is an input.

See [attribution](../NOTICE.md), [architecture](../docs/handbook/internals/architecture.md)
and the [embedding guide](../docs/handbook/guides/embedding.md).
