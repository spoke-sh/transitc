"""Source-free callable validation, hand SQL, rollback and restart."""
import json
import os
from pathlib import Path
import re
import shutil
import sys
import tempfile

from runner import capture
from integration.scalar_surfaces import build

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'tests/fixtures/application-refinements'


def main():
    compiler = Path(sys.argv[1] if len(sys.argv) > 1 else 'zig-out/bin/transitc').resolve()
    runtime = Path(os.environ['TRANSIT_TEST_RUNTIME']).resolve()
    parent = ROOT / '.cache/checks/refinements'
    parent.mkdir(parents=True, exist_ok=True)
    destination = Path(tempfile.mkdtemp(prefix='run-', dir=parent))
    summary = {'provenance': capture.provenance(ROOT), 'complete': False}
    capture.write_json(destination / 'evidence.json', summary)
    print(f'Refinement evidence: {destination}', flush=True)
    with tempfile.TemporaryDirectory(prefix='transitc-refinements-') as temporary:
        root = Path(temporary)
        workspace = root / 'source'
        workspace.mkdir()
        entry = workspace / 'build.transit'
        guide = (ROOT / 'docs/handbook/guides/refinements.md').read_text()
        example = re.findall(r'^```sql\n(.*?)^```', guide, re.M | re.S)[0]
        entry.write_text(example)
        assert build(compiler, workspace, root / 'guide')['ok']
        entry.write_text(example.replace('result = amount', 'result = unknown'))
        result = build(compiler, workspace, root / 'refused', expected=1)
        assert 'InvalidRefinementBinding' in json.dumps(result) and not (root / 'refused').exists(), result
        entry.write_text((SOURCE / 'build.transit').read_text())
        assert build(compiler, workspace, root / 'artifact')['ok']
        sql = (root / 'artifact/application.sql').read_text()
        shutil.rmtree(workspace)
    oracle = (SOURCE / 'expected.sql').read_text()
    (destination / 'generated.sql').write_text(sql)
    (destination / 'oracle.sql').write_text(oracle)
    sys.path.insert(0, str(Path(os.environ['TRANSIT_TEST_SOURCE']) / 'tests'))
    from harness import phases
    recorder = phases.Recorder(ROOT)
    phases.recorder = lambda: recorder
    from interfaces.installation.server import Fixture
    from interfaces.installation.server_managed_tables import await_head, program_control
    from interfaces.cli.table_console import records
    fixture = Fixture(runtime, parent='/var/tmp')
    fixture.use_private_runtime()
    passed = False
    expected = [{'id': '1', 'amount': '5'}]
    try:
        fixture.start()
        fixture.ready()
        def rows(prefix):
            return [records(fixture.console(f'CONSUME * FROM {prefix}{stream};')[-1])
                    for stream in ('refined_events', 'refined_after')]
        for prefix, declaration in (('', sql), ('oracle_', oracle)):
            fixture.console(declaration)
            for index, values in enumerate(('(1,5,5)', '(2,NULL,5)', '(3,0,0)', '(4,11,11)', '(5,5,6)'), 1):
                fixture.console(f'ENQUEUE INTO {prefix}refined_requests VALUES {values};')
                head = await_head(fixture, prefix + 'refined_route', lambda h: h['completed'] + h['refused'] >= index)['observation']['head']
                assert (head['completed'], head['refused']) == (1, index - 1), head
                assert rows(prefix) == [expected, expected]
                capture.write_json(destination / f'{prefix}case-{index}.json',
                                   {'completed': head['completed'], 'refused': head['refused'], 'rows': expected})
            if not prefix:
                program_control(fixture, 'SUSPEND DATAFLOW refined_route')
        fixture.stop()
        fixture.start()
        fixture.ready()
        assert rows('') == rows('oracle_') == [expected, expected]
        summary['installed'] = {'source_removed': True, 'independent_sql': True, 'restart': True,
                                'completed': 1, 'refused': 4, 'guide_failure_and_correction': True}
        capture.write_json(destination / 'evidence.json', summary)
        passed = True
    finally:
        fixture.cleanup()
        if passed:
            shutil.rmtree(fixture.root)
        else:
            print(f'Failed refinement installation retained at {fixture.root}', file=sys.stderr)
    summary['complete'] = True
    capture.write_json(destination / 'evidence.json', summary)
    print('PASS bounded callable obligations, ordered refusals, postcondition rollback, hand SQL and restart')


if __name__ == '__main__':
    main()
