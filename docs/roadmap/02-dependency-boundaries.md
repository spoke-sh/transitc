# 2. Dependency boundaries

Status: Planned

Prerequisites: [repository bootstrap](01-repository-bootstrap.md).

## Inventory and decisions

Use the [package map](../../packages/README.md) as the initial scope. Audit actual
imports and public symbols in the compiler, source resolver, diagnostics, build
publisher, and migration adapter, including their transitive closure.

| Current dependency | Required decision |
| --- | --- |
| `transit_fuze` | Extract/share the pure SQL frontend and typed owners; identify scalar, program, schema-evolution, bitmap/spatial/Arrow dependencies explicitly |
| `transit_protocol` | Separate diagnostic values from JSON, definition identity, and catalog/resource types; retain one authoritative contract per shared type |
| `transit_memory` | Pin a shared distribution or extract without duplicating its budget allocator |
| `transit_query` convenience imports in CLI tooling | Replace with the smallest approved public value owners |
| `transit_test`, `TestHost.zig`, `transit_io` | Keep runtime execution separate; define an optional test-host boundary only when needed |

Do not copy the whole Fuze/query/runtime tree to satisfy imports. Do not create
an alternate SQL type system. Resolve whether `transitc-sql` is owned here and
consumed by Transit, or supplied externally, before moving it. Avoid circular
repository dependencies.

## Acceptance

- A checked dependency inventory identifies each imported symbol and proposed
  owner, package manifests, allowed I/O, and runtime exclusions.
- Both compiler and Transit consumers have a concrete migration path to shared
  SQL and diagnostic contracts, with exact version/revision pins.
- The resulting graph is acyclic and does not depend on `../transit` paths.
- A minimal compilation proof establishes the chosen closure without live services.
- Artifact/definition identity, release versioning, and license attribution
  decisions are recorded before downstream formats or consumers change.
