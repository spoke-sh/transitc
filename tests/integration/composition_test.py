"""Negative controls for complete case inventories and failure aggregation."""
import copy
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from integration import composition


class Composition(unittest.TestCase):
    def test_case_inventory_and_budgets(self):
        report = {'complete': True, 'ok': True, 'cases': [
            {'name': name, 'status': 'passed', 'error_code': None} for name in ('one', 'two')],
            'limits': {'case_ms': 30000, 'suite_ms': 300000, 'cleanup_ms': 5000}}
        composition.validate(report, ['one', 'two'])
        for damage in ('missing', 'duplicate', 'not_run', 'deadline', 'incomplete', 'budget'):
            changed = copy.deepcopy(report)
            if damage == 'missing':
                changed['cases'].pop()
            elif damage == 'duplicate':
                changed['cases'][1] = changed['cases'][0]
            elif damage == 'not_run':
                changed['cases'][1]['status'] = 'not_run'
            elif damage == 'deadline':
                changed['cases'][1]['error_code'] = 'TestDeadline'
            elif damage == 'incomplete':
                changed['complete'] = False
            else:
                changed['limits']['case_ms'] += 1
            with self.subTest(damage=damage), self.assertRaises(AssertionError):
                composition.validate(changed, ['one', 'two'])

    def test_failed_process_does_not_hide_later_independent_suite(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            compiler = directory / 'compiler'
            compiler.write_text('''#!/usr/bin/env python3
import hashlib,json,pathlib,sys
fixture = pathlib.Path(sys.argv[sys.argv.index('-f') + 1]).parent.name
digest = hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest()
print(json.dumps({'ok': fixture == 'last', 'complete': True,
    'compiler_digest': digest, 'runtime': {'executable_digest': list(bytes.fromhex(digest))},
    'cases': [{'name': fixture, 'status': 'passed', 'error_code': None}],
    'limits': {'case_ms': 30000, 'suite_ms': 300000, 'cleanup_ms': 5000}}))
sys.exit(0 if fixture == 'last' else 1)
''')
            compiler.chmod(0o700)
            fixtures = {'first': ['first'], 'last': ['last']}
            phases = composition.schedule(1, False, fixtures)
            with patch.dict(os.environ, TRANSIT_TEST_RUNTIME=str(compiler)):
                self.assertFalse(composition.execute(compiler, directory, phases, fixtures))
            report = json.loads((directory / 'evidence.json').read_text())
            self.assertTrue(report['complete'])
            self.assertEqual(report['expected_phases'], [row['name'] for row in report['phases']])
            self.assertEqual([False, True], [row['ok'] for row in report['phases']])
            self.assertTrue(all(row['complete'] for row in report['phases']))


if __name__ == '__main__':
    unittest.main()
