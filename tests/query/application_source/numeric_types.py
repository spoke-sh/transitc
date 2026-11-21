"""Exact decimal expectations calculated without production scalar helpers."""
import copy
from decimal import Decimal, localcontext
from query.application_source.verify import execute, same


def source(precision, scale, text):
    return (f"CREATE DOMAIN Amount AS NUMERIC({precision},{scale}) IDENTITY 'example.amount'; "
            'CREATE MODULE Put(element TYPE, selected Amount) AS BEGIN '
            'CREATE PUBLIC TABLE amounts (id BIGINT PRIMARY KEY, amount $element NOT NULL); '
            'INSERT INTO amounts VALUES (1,$selected); END; '
            'CREATE TARGET default AS BEGIN '
            f"USE Put(TYPE Amount, Amount(NUMERIC({precision},{scale}) '{text}')); END;")


def compare(case, product):
    precision, scale, text = case
    with localcontext() as context:
        context.prec = 80
        number = Decimal(text)
        coefficient = int(number.scaleb(scale))
        assert abs(coefficient) < 10 ** precision and Decimal(coefficient).scaleb(-scale) == number
        canonical = format(number, f'.{scale}f')
        if coefficient == 0:
            canonical = canonical.lstrip('-')
    same([f'CREATE TABLE AMOUNTS ( ID BIGINT PRIMARY KEY , AMOUNT NUMERIC({precision}, {scale}) NOT NULL )',
          f'INSERT INTO AMOUNTS VALUES ( 1 , {canonical} )'],
         [step['sql'] for step in product['steps']], 'numeric SQL')
    checked = product['steps'][1]['checked']
    same('example.amount', checked['columns'][1]['domain'], 'numeric column domain')
    same('example.amount', checked['operands'][0]['domain'], 'numeric operand domain')
    same({'numeric': {'coefficient': coefficient, 'type': {'precision': precision, 'scale': scale}}},
         checked['operands'][0]['value'], 'numeric coefficient and descriptor')


def run(driver, destination, must_fail):
    cases = [(38, 9, '9007199254740993.123456789'), (38, 9, '-99999999999999999999999999999.999999999'),
             (38, 38, '0.00000000000000000000000000000000000001'), (5, 2, '-0'), (5, 2, '12.3')]
    products = execute(driver, [dict(name=f'numeric-{index}', source=source(*case), compile='build')
                                for index, case in enumerate(cases)], destination, 'numeric-products')
    for case, output in zip(cases, products):
        assert 'product' in output, output
        compare(case, output['product'])
    controls = []
    for label in ('rounded coefficient', 'changed scale', 'foreign numeric domain'):
        product = copy.deepcopy(products[0]['product'])
        operand = product['steps'][1]['checked']['operands'][0]
        if label == 'rounded coefficient':
            operand['value']['numeric']['coefficient'] += 1
        elif label == 'changed scale':
            operand['value']['numeric']['type']['scale'] -= 1
        else:
            operand['domain'] = 'example.foreign-amount'
        controls.append(must_fail(label, lambda: compare(cases[0], product)))
    return len(products), controls
