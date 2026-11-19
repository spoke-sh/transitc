# Understanding a source build

This guide describes the compiler inspected in Transit at commit
`c1f2680d9353175e58ad503e750e7b4da76a84c5`. These stages are not implemented in
this transitc checkout yet. To use the existing tool, follow Transit's
[application source build reference](https://github.com/spoke-sh/transit/blob/c1f2680d9353175e58ad503e750e7b4da76a84c5/docs/handbook/reference/cli.md#application-source-builds)
with the matching Transit checkout and runtime where required.

## Capture inputs

The tool selects a build entry and target, captures immutable `.transit` source
buffers, and verifies dependency revisions and digests. Normal builds use the
frozen local dependency state; fetching is an explicit operation. A dependency
override changes the recorded input provenance. Source path, encoding, count,
and aggregate byte limits are checked before compilation.

## Compile and inspect

The pure compiler resolves the captured graph, checks source types and embedded
SQL, expands selected targets, emits ordinary SQL, and verifies the emitted result
again against shared SQL owners. It returns an owned product with statement maps
and digests, or a bounded diagnostic. Compilation executes no SQL.

A check operation validates the product without publishing artifacts. A build
adapter can publish SQL and provenance after successful compilation. Read the
[artifact reference](../reference/artifacts.md) before treating those files as a
deployable or trusted application.

## Correct failures

Use the primary location, notes, and call/definition locations to identify the
source responsible for a failure. Filesystem failures may have a path without
line/column coordinates. Correct the input or dependency problem and rebuild;
a failed build does not produce a successful compiler product. See
[diagnostics](../reference/diagnostics.md).

## Keep execution separate

Migration synthesis reads an explicit immutable basis/history and proposes SQL;
it does not apply schema changes. Test-suite compilation produces SQL cases and
typed expectations. The existing Transit runner executes those cases against
isolated runtime owners. Moving a test compiler does not move that runner or
establish runtime compatibility.
