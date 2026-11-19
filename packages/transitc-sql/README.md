# transitc-sql

Proposed boundary for the pure SQL frontend used by the source compiler. This is
the least settled package; its final scope and distribution owner require an audit.
No implementation exists here yet.

The compiler currently calls Fuze for embedded SQL parsing, typed statements,
schema/type binding, scalar/program checks, Table evolution, and verification of
emitted SQL. Preserve one implementation of those semantics for compiler and
runtime consumers. Avoid bringing query execution, storage, networking, or service
startup into the compiler just to expose a parser.

Record the transitive import closure, the value types crossing it, and a shared
consumer strategy in the [dependency milestone](../../docs/roadmap/02-dependency-boundaries.md)
before extracting. A thin facade that still imports the entire runtime is not a
completed boundary. See the [package map](../README.md).
