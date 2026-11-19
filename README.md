# transitc

The Transit language compiler, being prepared for extraction from
[Transit](https://github.com/spoke-sh/transit).

This repository currently contains the development environment, a CLI scaffold,
package boundaries, documentation, and an extraction plan. The CLI supports
`--help` and `--version`; it does not compile Transit source yet.

## Develop

```sh
nix develop
zig build
zig build run -- --help
just check
```

The flake pins the same Zig **0.17.0-dev.2267+48abf1a34** toolchain and Nix inputs
as the source repository, including its Linux loader fixes. See
[toolchain notes](nix/README.md). An optional `.envrc` supports direnv.

```sh
nix develop .#docs --command just docs-install
nix develop .#docs --command just docs-dev
```

Open `http://localhost:3000/transitc/`. Run `just docs-check` in either shell to
typecheck and build the handbook. `nix flake check` builds and smoke-checks the CLI
in a sandbox; it does not run compiler conformance tests, which have not moved.

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
```

The [package plan](packages/README.md) explains why these boundaries are useful
and which dependencies still need an ownership decision. Package directories
reserve destinations; they contain no placeholder library APIs.

Start with the [documentation index](docs/README.md),
[contributor guide](CONTRIBUTING.md), and [extraction roadmap](docs/roadmap/README.md).
