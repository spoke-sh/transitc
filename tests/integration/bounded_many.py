"""Installed bounded batches against independent SQL, after source removal."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

from runner import capture

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'tests/fixtures/application-bounded-many'
CASES = ((0, 0, ()), (2, 0, ((2, None),)),
         (1, 0, ((1, 'same'), (3, 'same'))),
         (3, 0, ((4, None), (5, 'five'), (6, 'six'))),
         (4, 0, None), (3, 1, None), (3, 2, None))


def journey(compiler, runtime, destination):
    with tempfile.TemporaryDirectory(prefix='transitc-many-source-') as temporary:
        root = Path(temporary)
        workspace = root / 'source'
        shutil.copytree(SOURCE, workspace)
        result = subprocess.run([str(compiler), 'build', '--target', 'two', '--out',
                                 str(root / 'artifact'), '--format', 'json'], cwd=workspace,
                                text=True, capture_output=True, timeout=120)
        assert result.returncode == 0 and not result.stderr and json.loads(result.stdout)['ok'], result
        generated = (root / 'artifact/application.sql').read_text()
        shutil.rmtree(workspace)
    oracle = (SOURCE / 'oracle.sql').read_text()
    (destination / 'generated.sql').write_text(generated)
    (destination / 'oracle.sql').write_text(oracle)
    from interfaces.installation.server import Fixture
    from interfaces.installation.server_managed_tables import await_head, program_control
    from interfaces.cli.table_console import records
    fixture = Fixture(runtime, parent='/var/tmp')
    fixture.use_private_runtime()
    passed = False
    expected = []
    failures = []
    try:
        fixture.start()
        fixture.ready()
        fixture.console(generated)
        fixture.console(oracle)
        for prefix in ('many', 'other', 'oracle_many'):
            expected = []
            failures = []
            completed = refused = 0
            for request, (batch, reject, rows) in enumerate(CASES, 1):
                fixture.console(f'ENQUEUE INTO {prefix}_requests VALUES ({request}, {batch}, {reject});')
                completed += rows is not None
                refused += rows is None
                head = await_head(fixture, prefix + '_route',
                                  lambda h: h['completed'] + h['refused'] >= request)['observation']['head']
                assert (head['completed'], head['refused']) == (completed, refused), head
                expected.extend(dict(request=str(request), id=str(identity), note=note)
                                for identity, note in rows or ())
                if rows is None:
                    failures.append(dict(request=str(request), reason='refused'))
                actual = records(fixture.console(f'CONSUME * FROM {prefix}_events;')[-1])
                rejected = records(fixture.console(f'CONSUME * FROM {prefix}_failures;')[-1])
                assert actual == expected and rejected == failures, (actual, expected, rejected, failures)
                capture.write_json(destination / f'{prefix}-case-{request}.json',
                                   dict(completed=completed, refused=refused, rows=actual, failures=rejected))
            program_control(fixture, f'SUSPEND DATAFLOW {prefix}_route')
            await_head(fixture, prefix + '_route', lambda h: h['pending'] is None)
        fixture.stop(kill=True)
        fixture.start()
        fixture.ready()
        for prefix in ('many', 'other', 'oracle_many'):
            assert records(fixture.console(f'CONSUME * FROM {prefix}_events;')[-1]) == expected
            assert records(fixture.console(f'CONSUME * FROM {prefix}_failures;')[-1]) == failures
            program_control(fixture, f'RETIRE DATAFLOW {prefix}_route')
            await_head(fixture, prefix + '_route', lambda h: h['retirement_complete'])
        passed = True
        return dict(rows=expected, failures=failures, cases_per_instance=len(CASES),
                    completed=completed, refused=refused, generated_instances=2,
                    source_removed=True, independent_sql=True, exact_order=True, restart=True,
                    first_refusal_code='private native cursor test; not exposed by the failure record')
    finally:
        fixture.cleanup()
        if passed:
            shutil.rmtree(fixture.root)
        else:
            print(f'Failed bounded MANY installation retained at {fixture.root}', file=sys.stderr)


def main():
    compiler = Path(sys.argv[1] if len(sys.argv) > 1 else 'zig-out/bin/transitc').resolve()
    runtime = Path(os.environ['TRANSIT_TEST_RUNTIME']).resolve()
    sys.path.insert(0, str(Path(os.environ['TRANSIT_TEST_SOURCE']) / 'tests'))
    from harness import phases
    recorder = phases.Recorder(ROOT)
    phases.recorder = lambda: recorder
    parent = ROOT / '.cache/checks/bounded-many'
    parent.mkdir(parents=True, exist_ok=True)
    destination = Path(tempfile.mkdtemp(prefix='run-', dir=parent))
    summary = dict(provenance=capture.provenance(ROOT), compiler=capture.identity(compiler),
                   runtime=capture.identity(runtime), complete=False)
    capture.write_json(destination / 'evidence.json', summary)
    print(f'Bounded MANY evidence: {destination}', flush=True)
    summary['execution'] = journey(compiler, runtime, destination)
    summary['complete'] = True
    capture.write_json(destination / 'evidence.json', summary)
    print('PASS bounded rows, exact order, NULL, overflow, rollback, independent instances, source-free SQL and restart')


if __name__ == '__main__':
    main()
