# 6. Reproducible workspaces and developer tooling

Status: In Progress

Prerequisites: [workspace and CLI extraction](03-compiler-and-cli.md). New
language forms additionally depend on [typed compilation](05-typed-composition-and-sql.md).

Let an author fetch dependencies deliberately, edit and format a project, inspect
diagnostics, and reproduce a build offline from a clean checkout. This expands
former M12 P1/P3/P6 with the standalone CLI and formatter requirements.

## Delivered foundation

`transitc build`, `transitc test` and `transitc fmt` exist. The workspace resolves
exact repository revisions and subdirectories, verifies content, records transitive
locks and explicit local overrides, and publishes deterministic artifacts.
Ordinary builds are offline. `fmt` formats paths in place or standard input and
supports check-only execution, preserving comments, literals and identifier case.
The [CLI reference](../handbook/reference/cli.md),
[source/dependency workflow](../handbook/guides/source-workflow.md) and
[formatting guide](../handbook/guides/formatting.md) own current behavior.

## Delivery units

1. **Qualify recursive packages and durable bindings.** Cover independently built
   child targets, exported constructors/instances, diamond dependencies, repository
   subdirectories and multiple explicit instances in one multi-schema fixture.
   Relocate source files and aliases while preserving durable object bindings.
   Reject cycles, undeclared imports, incompatible interfaces and conflicting
   dependency versions bound to one stateful instance.
2. **Exercise a reproducibility and failure matrix.** Compare clean-cache fetch,
   populated offline build, explicit overrides, changed transitive contents and
   changed compiler/contract/options/bindings. Check lock and digest mismatches,
   interrupted publication, corrupted artifacts and unavailable repositories.
   Record every identity input; never require different executables to have the
   same provenance digest merely because their SQL matches.
3. **Extend formatting with the language.** Define canonical layout for new
   variants, queries, profiles and workflow constructs in the source contract.
   Review long declarations and nested expressions against real applications;
   any layout change needs explicit fixtures and an idempotent migration of
   examples. Keep one fixed style, exact lexical preservation and atomic writes.
   Exercise stdin/check/in-place behavior, recursive discovery, permissions,
   links, concurrent edits and invalid input without corrupting source.
4. **Make failures actionable through the CLI and embedding API.** Preserve
   definition and invocation sites through imported helpers and specializations.
   Check stable failure families, notes, byte coordinates, bounded excerpts,
   color and machine output. Keep help concise and command-specific. Document
   the current plain-text formatter diagnostics separately from build/test JSON.
   An editor can invoke existing commands; a language server is a separate
   proposal, not a prerequisite or an implemented feature.

## Boundaries and evidence

[transitc-workspace](../../packages/transitc-workspace/README.md) owns I/O,
capture, dependencies, publication and reports; the
[CLI](../../apps/transitc-cli/README.md) composes it. Pure formatting and semantic
checks stay in the compiler. Test discovery/formatting must not fetch, initialize
a database or interpret build actions.

Extend the existing workspace, formatter, example and integration suites rather
than inventing another runner. Use temporary projects and injected failure
boundaries; preserve real user files and test partial output and cleanup. Package
tests must run without a sibling Transit checkout. Keep root Just tasks at five
or fewer; new checks belong in the docs/test modules.

## Documentation and completion

Publish a monorepo/dependency-upgrade walkthrough, offline CI workflow, formatter
guide, diagnostics troubleshooting and public-library consumer example. Explain
what fetch changes, how overrides affect provenance, how to correct invalid locks,
and which outputs are safe to reuse. Check examples against the actual CLI.

Complete when the recursive-package and failure matrix passes on the supported
host profile, source relocation preserves durable bindings, all new forms format
idempotently, and guide/help examples agree with observed outputs and exit codes.
Native host/distribution qualification remains with
[milestone 4](04-documentation-and-qualification.md).
