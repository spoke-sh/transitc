"""Independent effect/order expectations for direct and higher-order calls."""
import copy
from pathlib import Path
from query.application_source.verify import execute, same

ROOT = Path(__file__).resolve().parents[3]
FIXTURE = ROOT / 'tests/fixtures/application-callables'


def compare(product):
    same(12, len(product['steps']), 'two complete callable instances')
    wanted = ['acquire', 'atomic_begin', 'let', 'let', 'require', 'let', 'let', 'require',
              'insert', 'append', 'require', 'let', 'require', 'let', 'let', 'require', 'let', 'require', 'atomic_end']
    for index, prefix in ((3, 'first'), (9, 'second')):
        step = product['steps'][index]
        events = step['checked']['program']['events']
        same(wanted, [event['kind'] for event in events], 'nested callable order')
        same(prefix + '_rows', next(e['resource'] for e in events if e['kind'] == 'insert'), 'bound Table')
        same(prefix + '_events', next(e['resource'] for e in events if e['kind'] == 'append'), 'bound Stream')
        same(2, step['sql'].count("'PositiveId'"), 'both preconditions')
        same(2, step['sql'].count("'SameId'"), 'both postconditions')
        same(1, step['sql'].count("'LateRefusal'"), 'ordered refusal')
        assert 'CALL' not in step['sql'] and 'EFFECTS' not in step['sql']
    assert product['steps'][3]['fingerprint'] != product['steps'][9]['fingerprint']


def run(driver, destination, must_fail):
    source = (FIXTURE / 'build.transit').read_text()
    steps = (FIXTURE / 'steps.transit').read_text()
    pipeline = (FIXTURE / 'pipeline.transit').read_text()
    requests = []
    for label, entry, body in [
            ('higher-order', source, pipeline),
            ('direct', source.replace('steps.Save, ', ''), pipeline.replace('command PROCEDURE OF steps.Store, ', '').replace('CALL command(', 'CALL steps.Save(')),
            ('import-alias', source.replace('IMPORT steps FROM', 'IMPORT ops FROM').replace('steps.Save', 'ops.Save'), pipeline)]:
        requests.append(dict(name=label, source=entry, files=[dict(path='steps.transit', text=steps), dict(path='pipeline.transit', text=body)], compile='build'))
    products = execute(driver, requests, destination, 'callable-products')
    for output in products:
        assert 'product' in output, output
        compare(output['product'])
    for other in products[1:]:
        for index in (3, 9):
            same(products[0]['product']['steps'][index]['sql'], other['product']['steps'][index]['sql'], 'ordinary SQL correspondence')
    controls = []
    for label in ('foreign resource', 'hidden effect', 'lost callable validation'):
        product = copy.deepcopy(products[0]['product'])
        step = product['steps'][3]
        events = step['checked']['program']['events']
        if label == 'foreign resource':
            next(e for e in events if e['kind'] == 'insert')['resource'] = 'second_rows'
        elif label == 'hidden effect':
            events.insert(8, copy.deepcopy(next(e for e in events if e['kind'] == 'append')))
        else:
            step['sql'] = step['sql'].replace("'SameId'", "'LostContract'", 1)
        controls.append(must_fail(label, lambda: compare(product)))
    bad = copy.deepcopy(requests[0])
    bad['name'] = 'widened-callee-precondition'
    prototype, implementation = steps.split('CREATE PUBLIC PROCEDURE Save', 1)
    bad['files'][0]['text'] = prototype + 'CREATE PUBLIC PROCEDURE Save' + implementation.replace('id >= 1', 'id >= 0')
    refused = execute(driver, [bad], destination, 'callable-refusal')[0]
    same('CallableSignatureMismatch', refused.get('compile_error'), 'exact precondition signature refusal')
    assert 'product' not in refused
    return len(products), controls
