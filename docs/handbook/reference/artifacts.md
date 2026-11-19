# Artifacts and compatibility

This checkout produces only the bootstrap executable. It does not create SQL,
locks, source maps, provenance, migration bases, or test products.

The existing compiler's `Product` owns SQL, statement maps, and digests separately
from its source buffers. Its caller must release the product. The Transit CLI
captures dependency resolution and compiler identity and publishes SQL with
provenance. The
[source contract](https://github.com/spoke-sh/transit/blob/e7434306334e3692c6f3e123cba0d278fa412196/contracts/APPLICATION_SOURCE_V1.md)
defines these fields and limits; extraction must preserve or explicitly migrate
them with consumers.

Source/input digests, output SQL digests, compiler revision/executable identity,
and contract definition identity answer different questions. A matching filename
or version label alone does not establish compatibility. Resolved source and a
successful build do not grant runtime permissions or establish artifact trust.

Before a standalone release, this reference must document exact paths and
schemas, deterministic ordering, incomplete-output handling, reuse rules,
dependency lock behavior, migration-basis identity, and a tested compiler/runtime
compatibility policy. Until those decisions are implemented, use the source
repository's matching compiler and consumers.
