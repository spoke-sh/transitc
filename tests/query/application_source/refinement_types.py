"""Independent local/imported obligation order and negative controls."""
import copy
from pathlib import Path
from query.application_source.verify import execute, same

ROOT = Path(__file__).resolve().parents[3]


def compare(product):
    program = product['steps'][3]
    events = program['checked']['program']['events']
    same(['acquire', 'atomic_begin', 'let', 'let', 'let', 'require', 'require',
          'append', 'let', 'require', 'let', 'append', 'atomic_end'],
         [event['kind'] for event in events], 'ordered callable obligations')
    same(['refined_events', 'refined_after'], [event['resource'] for event in events if event['kind'] == 'append'], 'effect resources')
    sql = program['sql']
    same(1, sql.count("'MissingAmount'"), 'non-null check')
    same(1, sql.count("'AmountBounds'"), 'bounds check')
    same(1, sql.count("'ChangedAmount'"), 'postcondition')
    assert sql.index("'MissingAmount'") < sql.index("'AmountBounds'") < sql.index('PRODUCE') < sql.index("'ChangedAmount'") < sql.rindex('PRODUCE')
    assert ' >= 1 ' in sql and ' <= 10 ' in sql
    assert 'REQUIRES' not in sql and 'ENSURES' not in sql and 'CALL' not in sql


def run(driver, destination, must_fail):
    source = (ROOT / 'tests/fixtures/application-refinements/build.transit').read_text()
    helper, rest = source.split('CREATE MODULE', 1)
    requests = [dict(name='local-refinements', source=source, compile='build'),
                dict(name='imported-refinements', source="IMPORT h FROM 'helper.transit'; CREATE MODULE" + rest.replace('CALL Bounded(', 'CALL h.Bounded('),
                     files=[dict(path='helper.transit', text=helper.replace('CREATE PROCEDURE', 'CREATE PUBLIC PROCEDURE'))], compile='build')]
    products = execute(driver, requests, destination, 'refinement-products')
    for output in products:
        assert 'product' in output, output
        compare(output['product'])
    controls = []
    for label in ('lost postcondition', 'early effect', 'widened bound'):
        product = copy.deepcopy(products[0]['product'])
        step = product['steps'][3]
        if label == 'lost postcondition':
            step['checked']['program']['events'].pop(9)
        elif label == 'early effect':
            events = step['checked']['program']['events']
            events[5], events[7] = events[7], events[5]
        else:
            step['sql'] = step['sql'].replace(' <= 10 ', ' <= 11 ')
        controls.append(must_fail(label, lambda: compare(product)))
    return len(products), controls
