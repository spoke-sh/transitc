# transitc

The Transit language compiler, being prepared for extraction from
[Transit](https://github.com/spoke-sh/transit).

This repository currently contains the development environment, a CLI scaffold,
package boundaries, documentation, and an extraction plan. The CLI supports
`--help` and `--version`; it does not compile Transit source yet.

Consumers can use the packaged executable without installing a Zig toolchain:

```sh
nix build .#transitc
./result/bin/transitc --version
nix run .#transitc -- --help
```

The flake exports `packages.<system>.transitc` and `packages.<system>.default`
for x86_64/aarch64 Linux and Darwin. Downstream flakes should pin this repository
to an exact commit and consume that package output. Zig is a build dependency;
it is not included in the executable's runtime closure.

## Develop

```sh
nix develop
zig build
zig build run -- --help
just check
just test-integration
```

The flake pins the same Zig **0.17.0-dev.2267+48abf1a34** toolchain and Nix inputs
as the source repository, including its Linux loader fixes. See
[toolchain notes](nix/README.md). An optional `.envrc` supports direnv.
The default shell also provides the upstream `transit` executable pinned to
`c1f2680d9353175e58ad503e750e7b4da76a84c5`, plus Python for integration tests.
No sibling checkout is required. The upstream package is a development/test
dependency; it is not part of the packaged transitc executable's runtime closure.

```sh
nix develop .#docs --command just docs-install
nix develop .#docs --command just docs-dev
```

Open `http://localhost:3000/transitc/`. Run `just docs-check` in either shell to
typecheck and build the handbook. `nix flake check` builds and smoke-checks the CLI
and runs the [upstream integration suite](tests/integration/README.md) in a sandbox.
The suite establishes upstream compiler/runtime behavior for later extraction;
it does not establish transitc compiler parity, since that implementation has not moved.

## Layout

```text
apps/transitc-cli/          executable and command-line integration
packages/transitc-compiler/ pure compiler (planned)
packages/transitc-workspace/ source capture, dependencies, artifacts (planned)
packages/transitc-diagnostics/ shared diagnostic values (planned)
packages/transitc-sql/      SQL frontend boundary (proposed)
docs/handbook/             Docusaurus guides, reference, and internals
docs/roadmap/              extraction milestones and acceptance criteria
nix/                      pinned toolchain support
tests/integration/        upstream compiler/runtime fixtures and checks
```

The [package plan](packages/README.md) explains why these boundaries are useful
and which dependencies still need an ownership decision. Package directories
reserve destinations; they contain no placeholder library APIs.

Start with the [documentation index](docs/README.md),
[contributor guide](CONTRIBUTING.md), and [extraction roadmap](docs/roadmap/README.md).
