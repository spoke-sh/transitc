# 4. Documentation and qualification

Status: In Progress

Prerequisites: [compiler and CLI extraction](03-compiler-and-cli.md). Write docs
with each earlier slice; this milestone closes coverage and release qualification.

## Required user documentation

| Reader task | Guide/reference to complete | Executable evidence |
| --- | --- | --- |
| Install or upgrade | Supported hosts, toolchain/runtime compatibility, release verification | Clean installation and version checks |
| Compile a first application | Small source project, target selection, inspect SQL/provenance | Golden example built in CI |
| Compose modules | Imports, visibility, parameters, types, resource interfaces | Accepted/rejected source fixtures |
| Manage dependencies | Fetch, lock, offline build, overrides, cache recovery | Clean/offline runs and digest mismatch rejection |
| Check and debug source | Human/JSON errors, locations, notes, color, exit codes | Diagnostic snapshots with exact spans |
| Inspect outputs | SQL/maps/provenance identities, reuse and publication rules | Deterministic rebuild and partial-write checks |
| Generate migrations | Immutable basis/history, supported changes, rejected changes | Old/new schema comparisons without execution |
| Author tests | Compile-only versus runtime execution, expectations, isolation | Compiler products and separately qualified runtime adapter |
| Embed the compiler | Allocators, lifetimes, options, limits, ownership | Small consumer built against public API |
| Integrate CI/editors | Noninteractive commands, reproducible inputs, failure handling | Checked automation examples |
| Understand the language | Exact syntax, types, names, lowering and supported SQL | Grammar/type corpus and emitted-SQL parity |
| Troubleshoot limits | Memory, depth, input/output bounds and dependency failures | Boundary/negative tests |

All guides need prerequisites, complete runnable examples, expected results,
failure/correction paths, and links to exact reference owners. Do not publish
speculative commands as working tutorials. Extend or replace the bootstrap
source-basis pages as their own implementation lands.

## Qualification and publication

Move and run the source verification suite, retaining premises and limits of
formal/independent comparisons. Add a fixture-to-guide coverage map so examples
cannot silently drift. Record commands, source/compiler/runtime revisions, host
platforms, raw results, and gaps in checked evidence.

Before release, verify help/reference parity, every published page's navigation,
broken links/anchors, keyboard/mobile navigation, readable code and light/dark
themes. Add local search when content volume warrants it. Validate the selected
hosting base path and configure publishing separately. A successful site build
does not establish compiler correctness or a live deployment.

## Acceptance

Every task above has an owning page and executed evidence or an explicit
unsupported boundary. Clean-checkout builds, the supported host matrix, public
API consumption, and compiler/runtime compatibility pass. Examples and contracts
have one source of truth. Release artifacts and documentation identify the same
compiler version; no inherited Transit result is labeled as a transitc run.

## Extraction implementation update

The handbook now describes build/check/fetch, `transitc test`, source language,
dependencies, diagnostics, artifacts, migration proposals and the embedding API.
Three build projects are checked against their source snippets and exact emitted
artifacts; a fourth checks isolated test cases and a deliberate assertion failure.
The embedding example
releases its source before inspecting the compiler-owned product.

On x86_64 Linux, the sandboxed Nix package, unit/ownership tests, workspace
journeys, upstream baseline, parity cases and emitted-SQL/restart proof passed.
The compiler source basis was
[`aeefd7f4bfa7b457749749aea786917794d794d8`](https://github.com/spoke-sh/transitc/commit/aeefd7f4bfa7b457749749aea786917794d794d8),
with the frozen runtime and shared frontend revisions recorded in the
[roadmap index](README.md#implementation-status). This record predates the
standalone test command; its host-boundary qualification is recorded separately.
Independent source verification executed 192 cases, 134 formatting roundtrips
and 10 grammar negative controls. Typed correspondence executed 14 Lean laws,
136 finite equalities, 16 typed and 21 program comparisons, four refusals and
21 negative controls. These are transitc runs, not inherited Transit evidence.

Handbook strict TypeScript and production builds, including broken-link and
anchor rejection, passed at both `/transitc/` and `/`. The CLI, libraries and
embedding consumer cross-compiled for `aarch64-linux-gnu`, `aarch64-macos` and
`x86_64-macos`.
Cross-compilation does not establish native execution on those hosts.

This milestone remains In Progress: native ARM/Darwin execution, visual/browser
release qualification, signed release archives and live documentation hosting
have not been qualified. Transit consumer runtime checks are recorded with the
coordinated extraction PR; they do not extend these standalone host claims.
