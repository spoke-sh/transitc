"""Native JSON projection through typed helpers, with independent SQL."""
from decimal import Decimal
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile

from runner import capture
from integration.scalar_surfaces import build

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'tests/fixtures/application-json-helpers'


def normalized(result):
    def cell(item):
        if 'null' in item:
            return None
        value = item['value']
        if 'json' in value:
            return {'json': json.loads(value['json'], parse_float=Decimal)}
        atom = value['atom']
        assert len(atom) == 1, atom
        return next(iter(atom.values()))
    return sorted([[cell(item) for item in row] for row in result['rows']], key=lambda row: int(row[0]))


def main():
    compiler = Path(sys.argv[1] if len(sys.argv) > 1 else 'zig-out/bin/transitc').resolve()
    parent = ROOT / '.cache/checks/json-helpers'
    parent.mkdir(parents=True, exist_ok=True)
    destination = Path(tempfile.mkdtemp(prefix='run-', dir=parent))
    summary = {'provenance': capture.provenance(ROOT), 'complete': False}
    capture.write_json(destination / 'evidence.json', summary)
    print(f'JSON helper evidence: {destination}', flush=True)
    with tempfile.TemporaryDirectory(prefix='transitc-json-') as temporary:
        root = Path(temporary)
        workspace = root / 'source'
        shutil.copytree(SOURCE, workspace)
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
    fixture = Fixture(Path(os.environ['TRANSIT_TEST_RUNTIME']), parent='/var/tmp')
    fixture.use_private_runtime()
    passed = False
    expected = []
    requests = [('JSON \'{"number":9007199254740993,"value":false}\'', True, '9007199254740993', 'false', {'number': 9007199254740993, 'value': False}),
                ("JSON 'null'", True, None, None, None),
                ("JSON '{}'", True, None, None, {}),
                ("NULL", False, None, None, None),
                ('JSON \'{"number":1.0}\'', False, None, None, None),
                ('JSON \'{"number":9223372036854775808}\'', False, None, None, None)]
    try:
        fixture.start()
        fixture.ready()
        def rows(prefix):
            return normalized(fixture.console(f'CONSUME id,number,text,payload FROM {prefix}_events;')[-1])
        for prefix, declaration in (('json', sql), ('oracle', oracle)):
            fixture.console(declaration)
            expected = []
            completed = 0
            for index, (literal, accepted, number, text, payload) in enumerate(requests, 1):
                fixture.console(f'ENQUEUE INTO {prefix}_requests VALUES({index},{literal});')
                if accepted:
                    completed += 1
                    expected.append([str(index), number, text, {'json': payload}])
                head = await_head(fixture, prefix + '_route', lambda h: h['completed'] + h['refused'] >= index)['observation']['head']
                assert (head['completed'], head['refused']) == (completed, index - completed), head
                assert rows(prefix) == expected, rows(prefix)
                capture.write_json(destination / f'{prefix}-case-{index}.json', {'completed': completed, 'refused': index - completed, 'rows': expected})
            program_control(fixture, f'SUSPEND DATAFLOW {prefix}_route')
        fixture.stop()
        fixture.start()
        fixture.ready()
        assert rows('json') == rows('oracle') == expected
        summary['installed'] = {'source_removed': True, 'independent_sql': True, 'restart': True, 'completed': 3, 'refused': 3}
        capture.write_json(destination / 'evidence.json', summary)
        passed = True
    finally:
        fixture.cleanup()
        if passed:
            shutil.rmtree(fixture.root)
        else:
            print(f'Failed JSON installation retained at {fixture.root}', file=sys.stderr)
    summary['complete'] = True
    capture.write_json(destination / 'evidence.json', summary)
    print('PASS exact JSON projection, helper arguments, explicit null collapse, refusals and restart')


if __name__ == '__main__':
    main()
