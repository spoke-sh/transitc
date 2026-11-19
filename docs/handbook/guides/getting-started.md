# Getting started

You can build and inspect the CLI scaffold today. You need Git and Nix with
flakes enabled. Run commands from the repository root after cloning
`https://github.com/spoke-sh/transitc.git`.

## Build the scaffold

```sh
nix develop
zig version
zig build
zig build run -- --help
zig build run -- --version
```

The pinned Zig version is `0.17.0-dev.2267+48abf1a34`. The executable is installed
at `zig-out/bin/transitc`. The version output is
`transitc 0.0.0-dev (bootstrap)`. Help states that compilation, dependency
resolution, and test execution are unavailable. No Transit runtime or sibling
checkout is needed for these commands.

## Validate your checkout

```sh
just check
nix flake check
just docs-install
just docs-check
```

The first two commands compile and smoke-check the scaffold. The docs commands
install the locked dependencies, typecheck the site, and build it with link
validation. These checks do not establish source-language conformance.

## Read and edit the handbook

```sh
just docs-dev
```

Open `http://localhost:3000/transitc/`. For documentation-only work, use
`nix develop .#docs`; that shell contains Node/npm and Just without Zig.
The [site tooling guide](https://github.com/spoke-sh/transitc/blob/main/docs/handbook/README.md)
explains navigation and hosting paths.

## Troubleshoot setup

If `zig version` differs, enter the Nix shell and inspect `command -v zig`.
Do not update Zig independently of the manifest and Linux patch. If Nix cannot
see a newly created flake file, make it known to Git before evaluating the Git
flake. For missing JavaScript modules, rerun `just docs-install` from the root.
An unsupported command error from `transitc build` is expected in this scaffold;
the [CLI reference](../reference/cli.md) lists its complete current interface.
