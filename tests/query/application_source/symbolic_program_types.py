"""Independent selected-program and all-arm refusal expectations."""
import copy
from pathlib import Path
from query.application_source.verify import execute, same

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / 'tests/fixtures/application-symbolic-program/build.transit'


def compare(kind, product):
    steps = product['steps']
    same(6, len(steps), 'only selected program/control statements emitted')
    same('CREATE QUEUE REQUESTS ( ID BIGINT NOT NULL )', steps[2]['sql'], 'no checking fields in input schema')
    same(False, any('__transit$symbolic' in step['sql'] for step in steps), 'no type-only values published')
    program = steps[3]['checked']['program']
    events = program['events']
    same(['acquire', 'atomic_begin', 'insert', 'atomic_end'],
         [event['kind'] for event in events], 'single helper argument evaluation')
    write = next(event for event in events if event['kind'] == 'insert')
    same(kind + 's', write['resource'], 'selected resource')
    same('example.' + kind, write['columns'][0]['domain'], 'selected nominal identity')
    same(True, kind.upper() + '_ROUTE' in steps[4]['sql'], 'selected control target')
    same(True, '7' in steps[3]['sql'], 'concrete payload emitted')


def run(driver, destination, must_fail):
    source = SOURCE.read_text()
    cases = [dict(name='symbolic-program-' + kind, source=source.replace('Target.Machine(MachineId(7))',
             'Target.' + kind.title() + '(' + kind.title() + 'Id(7))'), compile='build') for kind in ('machine', 'site')]
    products = execute(driver, cases, destination, 'symbolic-program-products')
    for kind, result in zip(('machine', 'site'), products):
        assert 'product' in result, result
        compare(kind, result['product'])
    refused = execute(driver, [dict(name='symbolic-program-unselected-refusal', source=source.replace(
        'INSERT INTO sites VALUES ($value)', 'INSERT INTO machines VALUES ($value)'), compile='build')],
        destination, 'symbolic-program-refusal')
    same('SourceDomainMismatch', refused[0].get('compile_error'), 'unselected arm refuses a foreign domain')
    controls = []
    for label in ('symbolic field published', 'unselected program emitted', 'specialization foreign domain'):
        damaged = copy.deepcopy(products[0]['product'])
        if label == 'symbolic field published':
            damaged['steps'][2]['sql'] += ' __transit$symbolic_0'
        elif label == 'unselected program emitted':
            damaged['steps'].append(products[1]['product']['steps'][3])
        else:
            next(event for event in damaged['steps'][3]['checked']['program']['events'] if event['kind'] == 'insert')['columns'][0]['domain'] = 'example.site'
        controls.append(must_fail(label, lambda: compare('machine', damaged)))
    return len(products), controls
