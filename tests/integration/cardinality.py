"""Installed zero/one/multiple-row and NULL journeys against independent SQL."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

from runner import capture
from integration.typed_composition import compiled_cases

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'tests/fixtures/application-cardinality'


def target(compiler, runtime, one, destination):
    with tempfile.TemporaryDirectory(prefix='transitc-cardinality-') as temporary:
        root = Path(temporary)
        workspace = root / 'source'
        workspace.mkdir()
        entry = workspace / 'build.transit'
        original = (SOURCE / 'build.transit').read_text()
        entry.write_text(original)
        def build(output, expected):
            result = subprocess.run([str(compiler), 'build', '--target', 'default' if one else 'optional',
                                     '--out', str(root / output), '--format', 'json'], cwd=workspace,
                                    text=True, capture_output=True, timeout=120)
            assert result.returncode == expected and not result.stderr, result
            return json.loads(result.stdout)
        if not one:
            guarded = """        IF found IS NULL THEN
          PRODUCE INTO cardinality_events VALUES (request.id, 'absent', NULL);
        ELSE
          PRODUCE INTO cardinality_events VALUES (request.id, 'present', found.note);
        END IF;"""
            assert guarded in original
            entry.write_text(original.replace(guarded, "PRODUCE INTO cardinality_events VALUES (request.id, 'present', found.note);"))
            refused = build('refused', 1)
            assert 'OptionalRowRequiresPresence' in json.dumps(refused) and not (root / 'refused').exists(), refused
            entry.write_text(original)
        assert build('artifact', 0)['ok']
        sql = (root / 'artifact/application.sql').read_text()
        shutil.rmtree(workspace)
    name = 'one' if one else 'optional'
    (destination / (name + '-generated.sql')).write_text(sql)
    oracle = (SOURCE / (name + '.sql')).read_text()
    (destination / (name + '-oracle.sql')).write_text(oracle)
    from interfaces.installation.server import Fixture
    from interfaces.installation.server_managed_tables import await_head, program_control
    from interfaces.cli.table_console import records
    fixture = Fixture(runtime, parent='/var/tmp')
    fixture.use_private_runtime()
    passed = False
    expected = [{'id': '1', 'presence': 'present', 'note': None}]
    if not one:
        expected.append({'id': '2', 'presence': 'absent', 'note': None})
    try:
        fixture.start()
        fixture.ready()
        def rows(prefix):
            return sorted(records(fixture.console(f'CONSUME * FROM {prefix}cardinality_events;')[-1]), key=lambda row: row['id'])
        for prefix, declaration in (('', sql), ('oracle_', oracle)):
            fixture.console(declaration)
            for index, value in enumerate(("(1, 'single', FALSE)", "(2, 'missing', FALSE)", "(3, 'duplicate', FALSE)", "(4, 'single', TRUE)"), 1):
                fixture.console(f"ENQUEUE INTO {prefix}cardinality_requests VALUES {value};")
                head = await_head(fixture, prefix + 'cardinality_route', lambda h: h['completed'] + h['refused'] >= index)['observation']['head']
                capture.write_json(destination / (name + '-' + ('oracle' if prefix else 'generated') + f'-case-{index}.json'),
                                   {'completed': head['completed'], 'refused': head['refused']})
            assert (head['completed'], head['refused']) == (len(expected), 4 - len(expected)), head
            assert rows(prefix) == expected
            capture.write_json(destination / (name + '-' + ('oracle' if prefix else 'generated') + '-execution.json'),
                               {'rows': expected, 'completed': head['completed'], 'refused': head['refused']})
            if not prefix:
                program_control(fixture, 'SUSPEND DATAFLOW cardinality_route')
        fixture.stop()
        fixture.start()
        fixture.ready()
        assert rows('') == rows('oracle_') == expected
        passed = True
        return {'rows': expected, 'completed': len(expected), 'refused': 4-len(expected),
                'source_removed': True, 'independent_sql': True, 'restart': True,
                'optional_failure_and_correction': not one}
    finally:
        fixture.cleanup()
        if passed:
            shutil.rmtree(fixture.root)
        else:
            print(f'Failed cardinality installation retained at {fixture.root}', file=sys.stderr)


def main():
    compiler = Path(sys.argv[1] if len(sys.argv) > 1 else 'zig-out/bin/transitc').resolve()
    runtime = Path(os.environ['TRANSIT_TEST_RUNTIME']).resolve()
    sys.path.insert(0, str(Path(os.environ['TRANSIT_TEST_SOURCE']) / 'tests'))
    from harness import phases
    recorder = phases.Recorder(ROOT)
    phases.recorder = lambda: recorder
    parent = ROOT / '.cache/checks/cardinality'
    parent.mkdir(parents=True, exist_ok=True)
    destination = Path(tempfile.mkdtemp(prefix='run-', dir=parent))
    summary = {'provenance': capture.provenance(ROOT), 'complete': False}
    capture.write_json(destination / 'evidence.json', summary)
    print(f'Cardinality evidence: {destination}', flush=True)
    for one in (True, False):
        summary['one' if one else 'optional'] = target(compiler, runtime, one, destination)
        capture.write_json(destination / 'evidence.json', summary)
    summary['compiled'] = compiled_cases(compiler, 'application-cardinality', destination)
    capture.write_json(destination / 'evidence.json', summary)
    summary['complete'] = True
    capture.write_json(destination / 'evidence.json', summary)
    print('PASS one/optional rows, absent versus NULL, multiple-row refusal, rollback, source-free SQL and restart')


if __name__ == '__main__':
    main()
