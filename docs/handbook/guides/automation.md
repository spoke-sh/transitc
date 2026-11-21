# Use transitc in CI and editors

Start with an installed, verified compiler on PATH, Python 3, a formatted
[application](getting-started.md) and its committed `transit.lock` when it uses
repository dependencies. Restore the verified dependency cache or explicitly run
`transitc build --fetch` in a separate network-enabled preparation step. An
ordinary build cannot repair a missing cache by accessing the network.

## Check before publishing artifacts

Save this as `check.sh` in the application directory:

```sh
#!/bin/sh
# Run from an application directory; the output directory must be new.
set -eu
compiler=${TRANSITC:-transitc}
mkdir -p .transit/reports
"$compiler" fmt --check
"$compiler" build --check --color off --format json > .transit/reports/check.json
python3 - <<'PY'
import json
from pathlib import Path
report = json.loads(Path('.transit/reports/check.json').read_text())
assert report['ok'] and report['action'] == 'check'
PY
"$compiler" build --out "${1:?select a new output directory}"
```

Run `sh check.sh reviewed`. It returns zero, leaves a successful check report in
`.transit/reports/check.json`, and publishes SQL/provenance together in `reviewed`.
The script stops on formatting or compilation failure. Repeating it with the same
explicit output directory fails rather than replacing retained artifacts. Choose
a new output directory after inspecting the previous result.

To exercise the failure path, remove the final semicolon from `build.transit` and
run the script with a new output path. It returns nonzero and does not publish that
directory. Restore the semicolon, run `transitc fmt`, review the change and retry.
Treat process status as authoritative; a missing, malformed or partial JSON file
is not a successful check. Archive a complete test report separately when running
`transitc test --format json`, and require both status zero and `complete: true`.

CI should pin the compiler and host revisions, retain their version strings and
the lockfile, and upload only completed artifacts. Record intentional overrides
and inspect their provenance. A build check does not execute application assertions
or approve a deployment. See [testing](testing.md) and
[artifacts](../reference/artifacts.md) for those separate operations.

## Editor integration

Configure a save action to run `transitc fmt PATH` for the saved file. Pass paths as
separate process arguments, placing `--` before a path beginning with `-`. For an
unsaved buffer, send its bytes to `transitc fmt --stdin` and replace the buffer
only after status zero; preserve it on any failure. The formatter supports
comments and does not require imports to exist, but malformed syntax rejects.

Use `transitc build --check --color off` for a project check and its one-based
line/byte-column diagnostics for navigation. JSON is available for a build/test
integration; formatting uses plain diagnostics. Byte columns are not Unicode
display columns. Do not rewrite coordinates to a different source snapshot.
There is no language server, watch command or incremental editor protocol in this
profile. See [formatting](formatting.md), [CLI](../reference/cli.md) and
[diagnostics](../reference/diagnostics.md) for exact process contracts.
