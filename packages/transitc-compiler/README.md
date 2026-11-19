# transitc-compiler

Reserved for Transit's pure compiler. No Zig package or public API exists here yet.

Move the existing `packages/zig/transit-compiler` implementation with its tests:
syntax/templates, immutable graph, source types, typed operands, working catalog,
program lowering/checking, SQL emission, migration synthesis, formatting, and
test-suite products. Preserve owned product lifetimes and bounded allocation.

The existing API accepts resolved source buffers and returns an owned product or
a diagnostic. It performs no filesystem/network I/O or runtime execution. Preserve
that contract while resolving dependencies in the [package map](../README.md).
Do not split parser/AST/IR into additional packages during the first move.
