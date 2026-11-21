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
