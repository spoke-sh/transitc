"""Exact scalar cells including NUMERIC source parameters and independent SQL."""
from decimal import Decimal
import json
import os
import re
from pathlib import Path
import shutil
import sys
import tempfile

from runner import capture
from integration.scalar_surfaces import build

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'tests/fixtures/application-sql-scalars'
OPERATORS = ROOT / 'tests/fixtures/application-numeric-operators'


def normalized(result):
    fields = result['schema']['type']['structure']
    assert fields[1]['type'] == {'decimal': {'precision': 38, 'scale': 9}}, fields[1]
    rows = []
    for row in result['rows']:
        converted = []
        for cell in row:
            if 'null' in cell:
                converted.append({'sql_null': True})
            elif 'json' in cell['value']:
                converted.append({'json': json.loads(cell['value']['json'], parse_float=Decimal)})
            else:
                converted.append(cell['value']['atom'])
        rows.append(converted)
    return sorted(rows, key=lambda row: int(row[0]['signed']))


EXPECTED = [
    [{'signed': '1'}, {'decimal': '9007199254740993123456789'},
     {'json': {'large': 9007199254740993, 'fraction': Decimal('1.25'), 'value': None}},
     {'interval': {'months': '1', 'days': '-2', 'nanos': '3'}}],
    [{'signed': '2'}, {'decimal': '-99999999999999999999999999999999999999'}, {'json': None},
     {'interval': {'months': '-2147483648', 'days': '2147483647', 'nanos': '-9223372036854775808'}}],
    [{'signed': '3'}, {'sql_null': True}, {'sql_null': True}, {'sql_null': True}],
]


def main():
    compiler = Path(sys.argv[1] if len(sys.argv) > 1 else 'zig-out/bin/transitc').resolve()
    runtime = Path(os.environ['TRANSIT_TEST_RUNTIME']).resolve()
    parent = ROOT / '.cache/checks/sql-scalars'
    parent.mkdir(parents=True, exist_ok=True)
    destination = Path(tempfile.mkdtemp(prefix='run-', dir=parent))
    summary = {'provenance': capture.provenance(ROOT), 'complete': False}
    capture.write_json(destination / 'evidence.json', summary)
    print(f'SQL scalar evidence: {destination}', flush=True)
    capture.write_json(destination / 'evidence.json', summary)
    with tempfile.TemporaryDirectory(prefix='transitc-sql-scalars-') as temporary:
        root = Path(temporary)
        workspace = root / 'source'
        workspace.mkdir()
        entry = workspace / 'build.transit'
        guide = (ROOT / 'docs/handbook/guides/typed-values.md').read_text()
        example = re.findall(r'^```sql\n(.*?)^```', guide, re.M | re.S)[1]
        entry.write_text(example)
        assert build(compiler, workspace, root / 'guide')['ok']
        entry.write_text(example.replace('123.45', '123.451'))
        refused = build(compiler, workspace, root / 'guide-refused', expected=1)
        assert 'Inexact' in json.dumps(refused) and not (root / 'guide-refused').exists(), refused
        lossless = re.findall(r'^```sql\n(.*?)^```', guide, re.M | re.S)[2]
        entry.write_text(lossless)
        assert build(compiler, workspace, root / 'lossless-guide')['ok']
        for name, replacement, cause in [('duplicate', lossless.replace('{"wide":9007199254740993,"value":null}', '{"value":1,"value":2}'), 'DuplicateField'),
                                          ('interval', lossless.replace('INTERVAL(1, -2, 3)', 'INTERVAL(2147483648, -2, 3)'), 'Overflow')]:
            entry.write_text(replacement)
            out = root / name
            refused = build(compiler, workspace, out, expected=1)
            assert cause in json.dumps(refused) and not out.exists(), refused
        for index, (column, value, cause) in enumerate([
            ('amount NUMERIC(5,2)', '1000.00', 'Overflow'),
            ('amount NUMERIC(5,2)', '1.001', 'Inexact'),
            ('payload JSON', '''JSON '{"a":1,"a":2}' ''', 'DuplicateField'),
            ('span INTERVAL', 'INTERVAL(2147483648,0,0)', 'Overflow'),
        ]):
            entry.write_text(f'CREATE TARGET default AS BEGIN CREATE PUBLIC TABLE t (id BIGINT PRIMARY KEY, {column}); INSERT INTO t VALUES (1, {value}); END;')
            out = root / f'refused-{index}'
            result = build(compiler, workspace, out, expected=1)
            assert cause in json.dumps(result) and not out.exists(), result
        entry.write_text((SOURCE / 'build.transit').read_text())
        assert build(compiler, workspace, root / 'artifact')['ok']
        sql = (root / 'artifact/application.sql').read_text()
        entry.write_text((OPERATORS / 'build.transit').read_text())
        assert build(compiler, workspace, root / 'operators')['ok']
        operator_sql = (root / 'operators/application.sql').read_text()
        shutil.rmtree(workspace)
    oracle = (SOURCE / 'expected.sql').read_text()
    (destination / 'generated.sql').write_text(sql)
    (destination / 'oracle.sql').write_text(oracle)
    (destination / 'numeric-generated.sql').write_text(operator_sql)
    sys.path.insert(0, str(Path(os.environ['TRANSIT_TEST_SOURCE']) / 'tests'))
    from harness import phases
    recorder = phases.Recorder(ROOT)
    phases.recorder = lambda: recorder
    from interfaces.installation.server import Fixture
    fixture = Fixture(runtime, parent='/var/tmp')
    fixture.use_private_runtime()
    passed = False
    try:
        fixture.start()
        fixture.ready()
        def result():
            return fixture.console('SELECT id, amount, payload, span FROM exact_values;')[-1]
        fixture.console(sql)
        unsupported = fixture.console('SELECT id, amount, payload, span FROM exact_values ORDER BY id;', expected=1)
        assert 'UnsupportedRelationalType' in unsupported.stderr, unsupported
        (destination / 'relational-profile.stderr').write_text(unsupported.stderr)
        actual = result()
        assert normalized(actual) == EXPECTED, actual
        capture.write_json(destination / 'cells.json', actual)
        fixture.stop()
        fixture.start()
        fixture.ready()
        assert normalized(result()) == EXPECTED
        fixture.console('DROP TABLE exact_values;')
        fixture.console(oracle)
        assert normalized(result()) == EXPECTED
        for declaration in (operator_sql, (OPERATORS / 'expected.sql').read_text()):
            results = fixture.console(declaration)
            for result, scale, coefficient in zip(results[-2:], (3, 2), ('18014398509480250', '900719925474012')):
                assert result['schema']['type']['structure'][0]['type'] == {'decimal': {'precision': 20, 'scale': scale}}, result
                cells = [row[0] for row in result['rows']]
                assert len(cells) == 2 and sum('null' in cell for cell in cells) == 1, cells
                assert next(cell['value']['atom']['decimal'] for cell in cells if 'value' in cell) == coefficient, cells
            for query, cause in [('SELECT DECIMAL_RESCALE(amount,20,2,REJECT) FROM numbers;', 'Inexact'),
                                 ('SELECT DECIMAL_ADD(amount,amount,3,2,REJECT) FROM numbers;', 'Overflow')]:
                refused = fixture.console(query, expected=1)
                assert cause in refused.stderr, refused
            fixture.console('DROP TABLE numbers;')
        summary['numeric_expressions'] = {'independent_sql': True, 'explicit_rounding': True, 'null': True, 'inexact': True, 'overflow': True}
        summary['values'] = {'source_removed': True, 'independent_sql': True, 'restart': True,
                             'rows': 3, 'refused_before_publication': 7, 'numeric_guide_failure_and_correction': True, 'lossless_guide_failure_and_correction': True}
        passed = True
    finally:
        fixture.cleanup()
        if passed:
            shutil.rmtree(fixture.root)
        else:
            print(f'Failed SQL scalar installation retained at {fixture.root}', file=sys.stderr)
    summary['complete'] = True
    capture.write_json(destination / 'evidence.json', summary)
    print('PASS exact NUMERIC/JSON/INTERVAL cells, NULL distinction, bounds, source-free SQL and restart')


if __name__ == '__main__':
    main()
