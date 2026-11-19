# Package boundaries

These are extraction destinations, not implemented packages. Keep packages
directly under `packages/`; add independent Zig manifests and root build wiring
when real code moves. Avoid empty public modules or dependency pins into a sibling
working tree. The initial four boundaries are:

| Package | Responsibility | Source in Transit |
| --- | --- | --- |
| [transitc-compiler](transitc-compiler/README.md) | Parse `.transit`, resolve an immutable module graph, typecheck, lower, and emit verified SQL | `packages/zig/transit-compiler/src/` |
| [transitc-workspace](transitc-workspace/README.md) | Capture source files, resolve pinned dependencies, manage locks, publish artifacts | `apps/transit-cli/BuildSources.zig`, I/O portions of `Build.zig` and `BuildMigration.zig` |
| [transitc-diagnostics](transitc-diagnostics/README.md) | Bounded diagnostic values, source spans, codes, and machine-readable contract | `SourceDiagnostic.zig`, `packages/zig/transit-protocol/src/Diagnostic.zig`, `contracts/diagnostics/` |
| [transitc-sql](transitc-sql/README.md) | Pure SQL parsing, schema/type binding, and validation needed by compilation | Selected owners in `packages/zig/transit-fuze/src/`; exact closure still to be audited |

The compiler depends on the SQL frontend and diagnostic values. Workspace
adapters supply captured inputs and publish successful compiler products. The CLI
composes them and owns terminal rendering. Dependencies must point inward toward
pure values and compilation; compiler code must never import the CLI or workspace.

## Dependencies to resolve before moving code

The current `transit-compiler` manifest imports `transit_fuze`, `transit_memory`,
and `transit_protocol`. Fuze in turn imports bitmap, spatial, protocol, memory,
Zarrow, and Zarrow Compute packages. Copying Fuze wholesale would bring a query
execution dependency tree into this repository. Audit the actual symbols used by
syntax, templates, binders, program checks, and migration synthesis first.

`transitc-sql` is the proposed shared frontend boundary, not authorization to
duplicate Fuze semantics. Decide whether it is extracted here and consumed by
Transit or supplied as a separately versioned dependency before implementing it.
Treat SQL parsing, typed statements, scalar/program validation, schema evolution,
and emitted-SQL equivalence as a unit until the dependency audit proves otherwise.

Reuse `transit-memory` as a pinned shared package, or extract it without changing
its API if it has no independent distribution. It has no dependencies today.
Do not create a second allocator implementation. Protocol imports require more
than diagnostics: JSON encoding, definition identity, and catalog/resource values
must each receive an explicit owner.

Keep syntax, graph, formatting, lowering, migrations, and test-product compilation
inside `transitc-compiler` initially. Split only for demonstrated independent
consumers or dependency constraints. Defer language servers, editor packages,
alternate backends, and SDKs until there is a stable compiler API.

Transit's `transit-source-import` is an HTTP capture/runtime adapter; despite its
name, it is unrelated to compiler source resolution. `transit-test`, `TestHost.zig`,
and service/storage packages execute SQL and remain separate from pure test-suite
compilation. An eventual runtime test adapter needs its own explicit dependency
and compatibility contract.

The [dependency milestone](../docs/roadmap/02-dependency-boundaries.md) owns these
decisions and their acceptance gates.
