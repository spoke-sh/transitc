"""Exact scalar surfaces through source, independent SQL and the pinned host."""
from datetime import date
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

from runner import capture

ROOT = Path(__file__).resolve().parents[2]


def build(compiler, workspace, output, expected=0):
    result = subprocess.run([str(compiler), 'build', '--out', str(output), '--format', 'json'],
                            cwd=workspace, text=True, capture_output=True, timeout=120)
    assert result.returncode == expected and not result.stderr, result
    return json.loads(result.stdout)


def main():
    compiler = Path(sys.argv[1] if len(sys.argv) > 1 else 'zig-out/bin/transitc').resolve()
    runtime = Path(os.environ['TRANSIT_TEST_RUNTIME']).resolve()
    parent = ROOT / '.cache/checks/scalar-surfaces'
    parent.mkdir(parents=True, exist_ok=True)
    destination = Path(tempfile.mkdtemp(prefix='run-', dir=parent))
    summary = {'provenance': capture.provenance(ROOT), 'complete': False}
    capture.write_json(destination / 'evidence.json', summary)
    print(f'Scalar surface evidence: {destination}', flush=True)
    capture.write_json(destination / 'evidence.json', summary)
    with tempfile.TemporaryDirectory(prefix='transitc-date-') as temporary:
        root = Path(temporary)
        workspace = root / 'source'
        workspace.mkdir()
        entry = workspace / 'build.transit'
        guide = (ROOT / 'docs/handbook/guides/typed-values.md').read_text()
        example = re.findall(r'^```sql\n(.*?)^```', guide, re.M | re.S)[0]
        entry.write_text(example)
        assert build(compiler, workspace, root / 'guide')['ok']
        entry.write_text(example.replace('2024-02-29', '2023-02-29'))
        report = build(compiler, workspace, root / 'invalid', expected=1)
        assert 'InvalidSourceOperand' in json.dumps(report) and not (root / 'invalid').exists(), report
        entry.write_text((ROOT / 'tests/fixtures/application-date/build.transit').read_text())
        assert build(compiler, workspace, root / 'artifact')['ok']
        sql = (root / 'artifact/application.sql').read_text()
        shutil.rmtree(workspace)
    oracle = (ROOT / 'tests/fixtures/application-date/expected.sql').read_text()
    (destination / 'date-generated.sql').write_text(sql)
    (destination / 'date-oracle.sql').write_text(oracle)
    sys.path.insert(0, str(Path(os.environ['TRANSIT_TEST_SOURCE']) / 'tests'))
    from harness import phases
    recorder = phases.Recorder(ROOT)
    phases.recorder = lambda: recorder
    from interfaces.installation.server import Fixture
    from interfaces.cli.table_console import records
    fixture = Fixture(runtime, parent='/var/tmp')
    fixture.use_private_runtime()
    passed = False
    try:
        fixture.start()
        fixture.ready()
        expected = [{'id': str(index), 'day': str((date.fromisoformat(day) - date(1970, 1, 1)).days), 'nullable_day': None} for index, day in
                    enumerate(('0001-01-01', '1970-01-01', '2024-02-29', '9999-12-31'), 1)]
        def rows():
            return records(fixture.console('SELECT id, day, nullable_day FROM dates ORDER BY id;')[-1])
        fixture.console(sql)
        generated = rows()
        assert generated == expected, generated
        fixture.stop()
        fixture.start()
        fixture.ready()
        assert rows() == expected
        fixture.console('DROP TABLE dates;')
        fixture.console(oracle)
        assert rows() == expected
        summary['date'] = {'rows': expected, 'source_removed': True, 'independent_sql': True,
                           'restart': True, 'guide_failure_and_correction': True}
        passed = True
    finally:
        fixture.cleanup()
        if passed:
            shutil.rmtree(fixture.root)
        else:
            print(f'Failed scalar runtime retained at {fixture.root}', file=sys.stderr)
    summary['complete'] = True
    capture.write_json(destination / 'evidence.json', summary)
    print('PASS DATE boundaries, NULL, compiled-case values, source-free SQL, independent oracle, restart and guide correction')


if __name__ == '__main__':
    main()
