# transitc-cli

The standalone `transitc` executable. Its bootstrap implements `--help`, `-h`, and
`--version`; no arguments print help. Unsupported arguments fail with exit code 2
and a message on stderr. Build from the repository root with `zig build` or run
with `zig build run -- --help`.

After extraction, this app should own argument parsing, terminal presentation,
and wiring compiler/workspace packages together. It must not own parser or type
checking semantics. The initial source candidates are Transit's
`apps/transit-cli/BuildOptions.zig`, `Build.zig`, `BuildReport.zig`, and relevant
diagnostic rendering. Do not copy the existing CLI's server or console entrypoint.

See the [package map](../../packages/README.md) and
[CLI extraction milestone](../../docs/roadmap/03-compiler-and-cli.md).
