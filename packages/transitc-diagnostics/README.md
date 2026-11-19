# transitc-diagnostics

Reserved for bounded diagnostic values shared by the compiler and its adapters.
No implementation exists here yet.

Audit `transit-compiler/src/SourceDiagnostic.zig`, protocol `Diagnostic.zig`,
`contracts/diagnostic-v1.schema.json`, and `contracts/diagnostics/` together.
Preserve error identities, byte spans, call/definition origins, correction notes,
and the distinction between an unlocated filesystem failure and source syntax.

Data types and machine-readable encoding belong here; terminal colors and excerpt
rendering belong in the CLI. Decide ownership with Transit consumers before
moving shared protocol types. See the [package map](../README.md).
