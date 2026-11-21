"""Independent presence/order expectations; no claim of a complete proof."""
import copy
from query.application_source.verify import execute, same


def source(one):
    read = 'LET found ONE = SELECT id, note FROM items;' if one else 'LET found OPTIONAL = SELECT id, note FROM items;'
    write = 'INSERT INTO accepted VALUES (found.id, found.note) ON CONFLICT (id) DO ASSERT SAME ROW;'
    if not one:
        write = 'IF found IS NOT NULL THEN ' + write + ' END IF;'
    return ("CREATE DOMAIN ItemId AS BIGINT IDENTITY 'example.item'; "
            'CREATE MODULE Setup(element TYPE) AS BEGIN '
            'CREATE PUBLIC TABLE items (id $element PRIMARY KEY, note TEXT); '
            'CREATE PUBLIC TABLE accepted (id $element PRIMARY KEY, note TEXT); '
            'CREATE PUBLIC QUEUE jobs (id BIGINT NOT NULL); '
            'CREATE PUBLIC DATAFLOW route FROM QUEUE jobs AS request AS BEGIN BEGIN ATOMIC '
            + read + write + ' END; END; END; CREATE TARGET default AS BEGIN USE Setup(TYPE ItemId); END;')


def compare(one, product):
    evidence = product['steps'][3]['checked']['program']
    wanted = ['acquire', 'atomic_begin', 'read'] + (['require', 'let', 'insert'] if one else
              ['branch_begin', 'insert', 'branch_else', 'branch_end']) + ['atomic_end']
    same(wanted, [event['kind'] for event in evidence['events']], 'cardinality event order')
    reads = [node for node in evidence['nodes'] if node['kind'] == 'binding']
    same(['optional', 'one'] if one else ['optional'], [node['cardinality'] for node in reads], 'result cardinalities')
    for read in reads:
        same('example.item', read['type']['fields'][0]['value']['domain'], 'nominal result field')
        same(True, read['type']['fields'][1]['value']['nullable'], 'nullable field remains nullable')
    write = next(event for event in evidence['events'] if event['kind'] == 'insert')
    same('example.item', write['columns'][0]['domain'], 'write domain')
    same(one, "'ExpectedOneRow'" in product['steps'][3]['sql'], 'one-row validation')


def run(driver, destination, must_fail):
    products = execute(driver, [dict(name=f'cardinality-{one}', source=source(one), compile='build')
                                for one in (True, False)], destination, 'cardinality-products')
    for one, result in zip((True, False), products):
        assert 'product' in result, result
        compare(one, result['product'])
    controls = []
    for label in ('presence validation removed', 'absence erased', 'NULL field narrowed', 'foreign result domain'):
        product = copy.deepcopy(products[0]['product'])
        evidence = product['steps'][3]['checked']['program']
        bindings = [node for node in evidence['nodes'] if node['kind'] == 'binding']
        if label == 'presence validation removed':
            evidence['events'].pop(3)
        elif label == 'absence erased':
            bindings[0]['cardinality'] = 'one'
        elif label == 'NULL field narrowed':
            bindings[1]['type']['fields'][1]['value']['nullable'] = False
        else:
            bindings[1]['type']['fields'][0]['value']['domain'] = 'example.other'
        controls.append(must_fail(label, lambda: compare(True, product)))
    return len(products), controls
