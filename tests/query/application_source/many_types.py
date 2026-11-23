"""Finite independent collection descriptors, event order and ordinary SQL."""
import copy

from query.application_source.verify import execute, same


def source(bound, domain):
    return (f"CREATE DOMAIN Id AS BIGINT IDENTITY '{domain}'; "
            'CREATE MODULE Setup(element TYPE) AS BEGIN '
            'CREATE PUBLIC TABLE items (id $element PRIMARY KEY, note TEXT); '
            'CREATE PUBLIC STREAM output (id $element NOT NULL, note TEXT); '
            'CREATE PUBLIC QUEUE jobs (id BIGINT NOT NULL); '
            'CREATE PUBLIC DATAFLOW route FROM QUEUE jobs AS request AS BEGIN BEGIN ATOMIC '
            f'LET selected MANY({bound}) = SELECT id, note FROM items ORDER BY id; '
            'LET alias = selected; FOR item IN alias DO '
            'PRODUCE INTO output VALUES (item.id, item.note); END FOR; END; END; END; '
            'CREATE TARGET default AS BEGIN USE Setup(TYPE Id); END;')


def expected_sql(bound):
    return [
        'CREATE TABLE ITEMS ( ID BIGINT PRIMARY KEY , NOTE TEXT )',
        'CREATE STREAM OUTPUT ( ID BIGINT NOT NULL , NOTE TEXT )',
        'CREATE QUEUE JOBS ( ID BIGINT NOT NULL )',
        'CREATE DATAFLOW ROUTE FROM QUEUE JOBS AS "__t$1_request" AS BEGIN BEGIN ATOMIC '
        f'LET "__t$2_selected" MANY ( {bound} ) = SELECT ID , NOTE FROM ITEMS ORDER BY ID ; '
        'LET "__t$3_alias" = "__t$2_selected" ; FOR "__t$4_item" IN "__t$3_alias" DO '
        'PRODUCE INTO OUTPUT VALUES ( "__t$4_item" . ID , "__t$4_item" . NOTE ) ; END FOR ; END ; END',
    ]


def compare(bound, domain, product):
    same(expected_sql(bound), [step['sql'] for step in product['steps']], 'bounded ordinary SQL')
    evidence = product['steps'][3]['checked']['program']
    same(['acquire', 'atomic_begin', 'read', 'let', 'iteration_begin', 'append',
          'iteration_end', 'atomic_end'], [e['kind'] for e in evidence['events']], 'bounded event order')
    fields = [dict(name='id', value=dict(kind='integer', nullable=False, domain=domain, fields=[])),
              dict(name='note', value=dict(kind='text', nullable=True, domain=None, fields=[]))]
    bindings = [node for node in evidence['nodes'] if node['kind'] == 'binding']
    same(2, len(bindings), 'read and immutable alias')
    for node in bindings:
        same('many', node['cardinality'], 'collection cardinality')
        same(dict(kind='rows', nullable=False, domain=None, fields=fields, bound=bound, order='id'),
             node['type'], 'complete collection descriptor')
    iterator, = [node for node in evidence['nodes'] if node['kind'] == 'iterator']
    same('one', iterator['cardinality'], 'present iterator')
    same(dict(kind='record', nullable=False, domain=None, fields=fields), iterator['type'], 'iterator descriptor')
    append = next(e for e in evidence['events'] if e['kind'] == 'append')
    same([domain, None], [col['domain'] for col in append['columns']], 'output domains')
    by_id = {node['id']: node for node in evidence['nodes']}
    for col, offset in zip(append['columns'], ('item.id', 'item.note')):
        same(source(bound, domain).index(offset), by_id[col['value']]['source_offset'], 'write origin')


def run(driver, destination, must_fail):
    cases = [(bound, domain) for bound in (1, 3, 64) for domain in ('example.item', 'example.other')]
    results = execute(driver, [dict(name=f'many-{bound}-{domain}', source=source(bound, domain), compile='build')
                               for bound, domain in cases], destination, 'many-products')
    for (bound, domain), result in zip(cases, results):
        assert 'product' in result, result
        compare(bound, domain, result['product'])
    controls = []
    for label in ('bound erased', 'order erased', 'foreign iterator', 'nullable field erased', 'loop event omitted', 'SQL bound changed'):
        product = copy.deepcopy(results[0]['product'])
        program = product['steps'][3]['checked']['program']
        binding = next(n for n in program['nodes'] if n['kind'] == 'binding')
        iterator = next(n for n in program['nodes'] if n['kind'] == 'iterator')
        if label == 'bound erased':
            binding['type']['bound'] = 0
        elif label == 'order erased':
            binding['type']['order'] = None
        elif label == 'foreign iterator':
            iterator['type']['fields'][0]['value']['domain'] = 'example.other'
        elif label == 'nullable field erased':
            iterator['type']['fields'][1]['value']['nullable'] = False
        elif label == 'loop event omitted':
            program['events'].pop(4)
        else:
            product['steps'][3]['sql'] = product['steps'][3]['sql'].replace('MANY ( 1 )', 'MANY ( 2 )')
        controls.append(must_fail(label, lambda: compare(1, 'example.item', product)))
    return len(results), controls
