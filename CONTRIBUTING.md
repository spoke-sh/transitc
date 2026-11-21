# Contributing

This repository owns the standalone source compiler and workspace tools. Keep extraction
changes separate from language changes so behavior can be compared against the
source revision. Start with the [package map](packages/README.md) and
[roadmap](docs/roadmap/README.md).

## Local workflow

Use `nix develop` at the root. The shell supplies pinned Zig, upstream Transit,
Python, Node 24/npm, Just, and nixfmt. Use Git from your host environment.
No sibling checkout is required.

Run `just` for the root task list, and `just docs` or `just test` for their
subtasks. The root exposes `build`, `check`, `docs`, and `test`; keep it to at most
five entries and add docs/test tasks to [their modules](tasks/). Invoke a subtask
with `just docs::check` or `just test::unit`. Multiple suites can share one
invocation, for example `just test::workspace test::examples`, so their shared
build prerequisite runs once. All tasks run from the repository root, including
when invoked from a subdirectory.

```sh
zig build
zig build run -- --version
just check
just test::unit
just test::clean-build
just test::fmt
just test::workspace
just test::examples
just test::documentation
just test::release
just test::build-command
just test::command
just test::grammar
just test::types
just test::integration
nix flake check
just docs::install
just docs::check
```

`just check` validates Zig/Nix formatting, the dependency inventory and CLI/library
compilation. `just test::unit` runs compiler/workspace unit checks, including allocation
failure coverage. The workspace suite requires Linux for seccomp failure controls.
Grammar/type suites use the pinned ANTLR/Python/Lean tools. Integration separates
upstream runtime smoke tests, exact compiler parity, and emitted SQL execution
with retained restart. `just test::examples` checks the handbook code against
runnable projects and inspects their published SQL/artifacts. `nix flake check` also
builds the package and runs unit, source verification and parity checks in sandboxes.
See the [integration guide](tests/integration/README.md) for fixtures, isolation,
failure cases, and updating the upstream pin.
`just test::fmt` checks formatter output, comment/literal preservation, recursive
discovery and safe file replacement. Format application sources with
`transitc fmt PATH...`; select project paths explicitly when working near
deliberately invalid parser fixtures.
`just docs::install` uses `npm ci` with the root lockfile. After intentionally
editing a JavaScript manifest, run `npm install`, then rerun the docs check.

Format Zig with `zig fmt build.zig build.zig.zon apps packages tests/query/application_source/driver.zig` and Nix with
`nixfmt flake.nix nix/*.nix`. Include new Zig package directories in checks when
they acquire source. New flake files must be known to Git (`git add`) for a Git
flake to see them; `path:.` can be used to inspect an untracked bootstrap.

## Documentation

Keep current behavior in handbook guides/reference, mechanisms in internals,
and planned work in the roadmap. Add every handbook page to `sidebars.ts`.
Use relative Markdown links between published pages, and GitHub links for
repository-only material. Never describe a reserved package or proposed command
as implemented. User guides land with the capability they explain.

The [handbook tooling guide](docs/handbook/README.md) covers previewing and
hosting paths. [CI](.github/workflows/ci.yml) validates both `/transitc/` and `/`.
The separate [handbook workflow](.github/workflows/handbook.yml) builds pull requests
and publishes the current `main` revision to GitHub Pages.

Run browser checks with `nix develop .#docs-browser --command just docs::browser`
on Linux. CI installs Playwright's Chromium and checks every published page at both
hosting paths, with desktop/mobile viewports and light/dark themes. Reports and
screenshots live in `.cache/handbook-report-*` and `.cache/handbook-browser-*`.
Keep the thirteen reader tasks in [the coverage map](tests/documentation.json)
aligned with milestone 4; `just test::documentation` checks the map, public CLI
options, version and the automation/dependency guide examples.

The `toolchain` shell omits Transit and documentation tooling for native compiler
checks. CI builds and executes portable archives on x86_64/ARM64 Linux and macOS,
then signs their bytes with GitHub build provenance. To build a local unsigned
candidate from a clean committed tree, run
`nix develop .#toolchain --command python3 tasks/archive.py`. Local archives are
not signed CI results. See [release qualification](docs/qualification/extraction.md)
for the support boundary and the draft-release promotion workflow.

## Extracting code

Record the source commit, preserve attribution, move its tests and contract
references, and update consumers together. Preserve allocation limits, diagnostic
coordinates, deterministic output, and failure behavior. Do not pull runtime
services into a pure compiler to satisfy a convenience import. Each extraction
PR should state the parity checks run and the remaining limitations.
