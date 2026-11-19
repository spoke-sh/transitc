# transitc-workspace

Reserved for compiler I/O adapters. No implementation exists here yet.

Extract source capture and package resolution from `BuildSources.zig`, artifact
publication/provenance from `Build.zig`, and immutable migration-basis loading
from `BuildMigration.zig`. Keep command-line parsing and terminal rendering in
`apps/transitc-cli`.

The boundary must preserve offline normal builds, explicit dependency fetching,
frozen revisions/digests, source path and byte limits, override provenance, and
complete artifact publication. Capture immutable buffers before invoking the
compiler. Compilation success is not deployment or runtime authorization.

See the [package map](../README.md) before moving convenience imports from the
runtime CLI.
