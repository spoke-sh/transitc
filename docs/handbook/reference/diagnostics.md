# Diagnostics

The bootstrap CLI reports only unsupported arguments; it has no source diagnostics
yet. The source compiler's current diagnostic basis is
[SourceDiagnostic.zig](https://github.com/spoke-sh/transit/blob/c1f2680d9353175e58ad503e750e7b4da76a84c5/packages/zig/transit-compiler/src/SourceDiagnostic.zig)
and the shared
[diagnostic schema](https://github.com/spoke-sh/transit/blob/c1f2680d9353175e58ad503e750e7b4da76a84c5/contracts/diagnostic-v1.schema.json).

The extraction must preserve bounded codes/messages and source byte spans, primary
and secondary locations, and definition/call origins during expansion. A path
failure must not invent source coordinates. Compiler diagnostic values must not
embed entire source buffers, operand values, or credentials; rendering a source
excerpt is a separate CLI concern using captured input.

When reporting a problem today, include the checkout revision, Zig version,
command, exit status, and observed output. After the source compiler moves, this
page will specify its human and machine formats, code families, color behavior,
location units, truncation, and correction examples from tested failures.
