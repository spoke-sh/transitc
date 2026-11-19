# Architecture

The pure compiler consumes immutable source buffers and emits owned products. It
performs bounded parsing, graph composition, typing, hygienic lowering and SQL
verification. Workspace adapters own filesystem capture, exact repository fetch,
locks, migration-basis loading and atomic artifact publication. The executable
owns command dispatch. Execution and durable authority remain in Transit.

Transit owns the shared SQL frontend, protocol values, spatial values and memory
budget allocator. The compiler uses those public modules directly; it does not
import Fuze's Arrow or scan executor. Fuze uses the same moved language types.
The standalone manifest pins the frontend source distribution. Embedded builds
receive their host's canonical modules and do not fetch that standalone pin,
preserving one type identity and an acyclic selected package graph.

The compiler's scratch and retained allocations share one bounded budget.
Products own their arena and require `deinit`. Diagnostics are bounded value
contracts; rendering borrows their live storage. Compile-time work has explicit
source/depth/work/output bounds, independent of durable runtime cardinality.

Test products describe expected typed results, command counts, refusals and bounded
workflow observations. They carry no service implementation. The workspace owns
suite compilation, execution orchestration and reports. Transit embeds this
orchestration with its local host; `transitc test` sends compiled cases to a
separately pinned Transit process. Both use the same native statement owners and
assertion runner. Source is never sent to the runtime for recompilation.

The [compiled-case contract](https://github.com/spoke-sh/transitc/blob/main/contracts/TEST_HOST_V1.md)
requires both definitions, canonical SQL digests, bounded typed expectations and
responses bound to the exact request. The caller checks terminal coverage and
runtime identity, joins every child, and checks storage cleanup. Compiler,
transport and native-host allocations have separate bounded lifetimes. A child
failure or incomplete response cannot establish a passed case.
