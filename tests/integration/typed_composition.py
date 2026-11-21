"""Independent SQL representation probes and compiled typed-composition journeys."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

from runner import capture

ROOT = Path(__file__).resolve().parents[2]
FIXTURES = ROOT / 'tests/fixtures'


def compiled_cases(compiler, name, destination):
    with tempfile.TemporaryDirectory(prefix='transitc-composition-') as temporary:
        workspace = Path(temporary) / 'source'
        shutil.copytree(FIXTURES / name, workspace)
        for path in [workspace, *workspace.rglob('*')]:
            path.chmod(0o700 if path.is_dir() else 0o600)
        result = subprocess.run([str(compiler), 'test', '--format', 'json'], cwd=workspace,
                                text=True, capture_output=True, timeout=330)
        (destination / (name + '.stdout')).write_text(result.stdout)
        (destination / (name + '.stderr')).write_text(result.stderr)
        assert result.returncode == 0 and not result.stderr, (result.returncode, result.stdout, result.stderr)
        report = json.loads(result.stdout)
        assert report['ok'] and report['complete'] and report['cases'], report
        assert all(case['status'] == 'passed' for case in report['cases']), report
        return {'fixture': name, 'cases': len(report['cases']), 'runtime': report['runtime'],
                'compiler_digest': report['compiler_digest'], 'input_digest': report['input_digest']}


def native_probes(runtime, destination):
    sys.path.insert(0, str(Path(os.environ['TRANSIT_TEST_SOURCE']) / 'tests'))
    from harness import phases
    recorder = phases.Recorder(ROOT)
    phases.recorder = lambda: recorder
    from interfaces.installation.server import Fixture
    from interfaces.installation.server_managed_tables import await_head
    from interfaces.cli.table_console import records
    from interfaces.cli.migrate_lifecycle import disable_sql_credential

    fixture = Fixture(runtime, parent='/var/tmp')
    fixture.use_private_runtime()
    passed = False
    results = []
    try:
        fixture.start()
        fixture.ready()
        fixture.console('CREATE QUEUE variant_probe (id BIGINT NOT NULL, target UNION(machine BIGINT NOT NULL, site BIGINT NOT NULL) NOT NULL);')
        for name, sql, code in [
            ('union-program', "CREATE DATAFLOW variant_probe_route FROM QUEUE variant_probe AS request AS BEGIN REQUIRE TRUE ELSE 'No'; END;", 'ProgramTypeMismatch'),
            ('view-ddl', 'CREATE VIEW view_probe AS SELECT * FROM items;', 'UnsupportedStatement'),
        ]:
            result = fixture.console(sql, expected=1)
            assert f'Cause: {code}.' in result.stderr, result
            (destination / (name + '.stderr')).write_text(result.stderr)
            results.append({'operation': name, 'cause': code})
        # This SQL oracle is authored independently, with no source compilation.
        fixture.console((FIXTURES / 'application-variant-encoding/expected.sql').read_text())
        fixture.console("ENQUEUE INTO dynamic_requests VALUES (1, 'Machine', 7, NULL, FALSE), (2, 'Site', NULL, 7, FALSE);")
        head = await_head(fixture, 'dynamic_route', lambda h: h['completed'] + h['refused'] >= 2)['observation']['head']
        assert (head['completed'], head['refused']) == (2, 0), head
        fixture.console("ENQUEUE INTO dynamic_requests VALUES (3, 'Other', 7, NULL, FALSE);")
        head = await_head(fixture, 'dynamic_route', lambda h: h['completed'] + h['refused'] >= 3)['observation']['head']
        assert (head['completed'], head['refused']) == (2, 1), head
        expected = [{'id': '1', 'tag': 'Machine', 'resource_id': '7'}, {'id': '2', 'tag': 'Site', 'resource_id': '7'}]
        rows = fixture.console('SELECT * FROM dynamic_accepted ORDER BY id; CONSUME * FROM dynamic_events;')
        assert [sorted(records(row), key=lambda item: item['id']) for row in rows if 'schema' in row] == [expected, expected], rows
        fixture.stop()
        fixture.start()
        fixture.ready()
        assert records(fixture.console('SELECT * FROM dynamic_accepted ORDER BY id;')[-1]) == expected
        disable_sql_credential(fixture.root, fixture.config['ports'], installation=fixture.installation)
        fixture.console('SELECT * FROM dynamic_accepted;', expected=1)
        fixture.console("ENQUEUE INTO dynamic_requests VALUES (4, 'Machine', 7, NULL, FALSE);", expected=1)
        results.append({'operation': 'tag-payload-dispatch', 'completed': 2, 'refused': 1,
                        'rows': expected, 'restart': True, 'revocation': True})
        passed = True
        return results
    finally:
        fixture.cleanup()
        if passed:
            shutil.rmtree(fixture.root)
        else:
            print(f'Failed typed-composition runtime retained at {fixture.root}', file=sys.stderr)


def main():
    compiler = Path(sys.argv[1] if len(sys.argv) > 1 else 'zig-out/bin/transitc').resolve()
    runtime = Path(os.environ['TRANSIT_TEST_RUNTIME']).resolve()
    parent = ROOT / '.cache/checks/typed-composition'
    parent.mkdir(parents=True, exist_ok=True)
    destination = Path(tempfile.mkdtemp(prefix='run-', dir=parent))
    summary = {'provenance': capture.provenance(ROOT), 'complete': False}
    capture.write_json(destination / 'evidence.json', summary)
    print(f'Typed composition evidence: {destination}', flush=True)
    summary['native'] = native_probes(runtime, destination)
    summary['compiled'] = [compiled_cases(compiler, 'application-variant-encoding', destination)]
    summary['complete'] = True
    capture.write_json(destination / 'evidence.json', summary)
    print('PASS ordinary SQL representation probes, source-free dispatch, restart, current rights and seven isolated cases')


if __name__ == '__main__':
    main()
