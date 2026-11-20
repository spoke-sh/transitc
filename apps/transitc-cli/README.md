# transitc CLI

Composes `transitc-workspace` and the pure compiler. Supports `build`, including
`--check` and `--fetch`, and `test` through a compatible Transit host. See the
[complete CLI contract](../../docs/handbook/reference/cli.md). Source report
rendering, option parsing, resolution, publication, and test orchestration belong
to the shared libraries.

`transitc --help` lists commands and global options. `transitc build --help` and
`transitc test --help` show only that command's options. Keep help concise, with
defaults and repeatability beside the option; explain workflows in the handbook.
Help and version print to stdout without reading source or starting a test host.
