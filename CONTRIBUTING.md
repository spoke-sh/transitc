# Contributing

The current task is to prepare a standalone compiler repository. Keep extraction
changes separate from language changes so behavior can be compared against the
source revision. Start with the [package map](packages/README.md) and
[roadmap](docs/roadmap/README.md).

## Local workflow

Use `nix develop` at the root. The shell supplies pinned Zig, Node 24/npm, Git,
Just, and nixfmt. No sibling checkout is required to build this scaffold.

```sh
zig build
zig build run -- --version
just check
nix flake check
just docs-install
just docs-check
```

`just check` checks Zig/Nix formatting and compiles the CLI. `nix flake check`
also runs help/version and checks rejection of an unavailable command. There is
no compiler test suite here yet; add its real tests with the extraction.
`just docs-install` uses `npm ci` with the root lockfile. After intentionally
editing a JavaScript manifest, run `npm install`, then rerun the docs check.

Format Zig with `zig fmt build.zig build.zig.zon apps` and Nix with
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
hosting paths. CI validates both `/transitc/` and `/`; it does not publish a site.

## Extracting code

Record the source commit, preserve attribution, move its tests and contract
references, and update consumers together. Preserve allocation limits, diagnostic
coordinates, deterministic output, and failure behavior. Do not pull runtime
services into a pure compiler to satisfy a convenience import. Each extraction
PR should state the parity checks run and the remaining limitations.
