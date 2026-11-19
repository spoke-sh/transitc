# CLI reference

The executable name is `transitc`. The complete bootstrap interface is:

| Invocation | Result | Exit status |
| --- | --- | --- |
| `transitc` | Print help to stdout | 0 |
| `transitc --help` or `transitc -h` | Print help to stdout | 0 |
| `transitc --version` | Print `transitc 0.0.0-dev (bootstrap)` to stdout | 0 |
| Any other arguments, including extra arguments after an option | Print an unsupported-arguments message to stderr | 2 |

Build it using the [getting started guide](../guides/getting-started.md). This
checkout has no installable release bundle, compiler command, formatting command,
JSON diagnostic mode, dependency fetch command, or test runner. These interfaces
must be specified and checked when their implementations arrive.

The existing `transit build` and `transit test` commands belong to the Transit
repository. Do not assume that changing their executable name to `transitc`
preserves their flags or runtime requirements.
