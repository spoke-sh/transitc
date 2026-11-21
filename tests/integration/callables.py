"""Imported higher-order helpers, exact resources and ordinary SQL execution."""
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
SOURCE = ROOT / 'tests/fixtures/application-callables'


def main():
    compiler = Path(sys.argv[1] if len(sys.argv) > 1 else 'zig-out/bin/transitc').resolve()
    runtime = Path(os.environ['TRANSIT_TEST_RUNTIME']).resolve()
    parent = ROOT / '.cache/checks/callables'
    parent.mkdir(parents=True, exist_ok=True)
    destination = Path(tempfile.mkdtemp(prefix='run-', dir=parent))
    summary = {'provenance': capture.provenance(ROOT), 'complete': False}
    capture.write_json(destination / 'evidence.json', summary)
    print(f'Callable evidence: {destination}', flush=True)
    with tempfile.TemporaryDirectory(prefix='transitc-callables-') as temporary:
        root = Path(temporary)
        workspace = root / 'source'
        shutil.copytree(SOURCE, workspace)
        entry = workspace / 'build.transit'
        original = entry.read_text()
        guide = (ROOT / 'docs/handbook/guides/reusable-behavior.md').read_text()
        example = re.findall(r'^```sql\n(.*?)^```', guide, re.M | re.S)[0]
        entry.write_text(example)
        assert build(compiler, workspace, root / 'guide')['ok']
        entry.write_text(example.replace('EFFECTS (PRODUCE events)', 'EFFECTS ()'))
        refused = build(compiler, workspace, root / 'refused', expected=1)
        assert 'EffectContractMismatch' in json.dumps(refused) and not (root / 'refused').exists(), refused
        entry.write_text(original)
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
    from interfaces.cli.migrate_lifecycle import disable_sql_credential
    fixture = Fixture(runtime, parent='/var/tmp')
    fixture.use_private_runtime()
    passed = False
    expected = [{'id': '7'}]
    try:
        fixture.start()
        fixture.ready()
        fixture.console(sql)
        fixture.console(oracle)
        def rows(prefix):
            return [records(fixture.console(query)[-1]) for query in
                    (f'SELECT * FROM {prefix}_rows;', f'CONSUME * FROM {prefix}_events;')]
        for prefix in ('first', 'second', 'oracle'):
            for index, values in enumerate(('(7,TRUE)', '(0,TRUE)', '(9,FALSE)'), 1):
                fixture.console(f'ENQUEUE INTO {prefix}_requests VALUES {values};')
                head = await_head(fixture, prefix + '_route', lambda h: h['completed'] + h['refused'] >= index)['observation']['head']
                assert (head['completed'], head['refused']) == (1, index - 1), head
                assert rows(prefix) == [expected, expected]
                capture.write_json(destination / f'{prefix}-case-{index}.json',
                                   {'completed': head['completed'], 'refused': head['refused'], 'rows': expected})
            program_control(fixture, f'SUSPEND DATAFLOW {prefix}_route')
        fixture.stop()
        fixture.start()
        fixture.ready()
        assert all(rows(prefix) == [expected, expected] for prefix in ('first', 'second', 'oracle'))
        disable_sql_credential(fixture.root, fixture.config['ports'], installation=fixture.installation)
        fixture.console('SELECT * FROM first_rows;', expected=1)
        fixture.console('ENQUEUE INTO second_requests VALUES (8, TRUE);', expected=1)
        summary['installed'] = {'source_removed': True, 'independent_sql': True, 'restart': True,
                                'instances': 2, 'completed_per_instance': 1, 'refused_per_instance': 2,
                                'current_rights_denial': True, 'guide_failure_and_correction': True}
        capture.write_json(destination / 'evidence.json', summary)
        passed = True
    finally:
        fixture.cleanup()
        if passed:
            shutil.rmtree(fixture.root)
        else:
            print(f'Failed callable installation retained at {fixture.root}', file=sys.stderr)
    summary['complete'] = True
    capture.write_json(destination / 'evidence.json', summary)
    print('PASS exact callable signatures, nested atomic effects, explicit instances, independent SQL, restart and denial')


if __name__ == '__main__':
    main()
