"""Independent source scalar lexemes, component bounds, and SQL identities."""
import copy
import json
from decimal import Decimal
from query.application_source.verify import execute, same


def source(payload, interval):
    months, days, nanos = interval
    quoted = payload.replace("'", "''")
    return ("CREATE DOMAIN Document AS JSON IDENTITY 'example.document'; "
            "CREATE DOMAIN Elapsed AS INTERVAL IDENTITY 'example.elapsed'; "
            'CREATE MODULE Put(jt TYPE,it TYPE,document Document,elapsed Elapsed) AS BEGIN '
            'CREATE PUBLIC TABLE samples(id BIGINT PRIMARY KEY,payload $jt NOT NULL,span $it NOT NULL); '
            'INSERT INTO samples VALUES(1,$document,$elapsed); END; '
            'CREATE TARGET default AS BEGIN USE Put(TYPE Document,TYPE Elapsed,'
            f"Document(JSON '{quoted}'),Elapsed(INTERVAL({months},{days},{nanos}))); END;")


def compare(case, product):
    payload, interval = case
    decoded = json.loads(payload, parse_float=Decimal)
    for component, bits in zip(interval, (32, 32, 64)):
        assert -(2 ** (bits - 1)) <= component < 2 ** (bits - 1)
    quoted = payload.replace("'", "''")
    m, d, n = interval
    same(['CREATE TABLE SAMPLES ( ID BIGINT PRIMARY KEY , PAYLOAD JSON NOT NULL , SPAN INTERVAL NOT NULL )',
          f"INSERT INTO SAMPLES VALUES ( 1 , JSON '{quoted}' , INTERVAL({m}, {d}, {n}) )"],
         [s['sql'] for s in product['steps']], 'lossless SQL')
    operands = product['steps'][1]['checked']['operands']
    same('example.document', operands[0]['domain'], 'JSON nominal identity')
    same('example.elapsed', operands[1]['domain'], 'interval nominal identity')
    same({'json': payload}, operands[0]['value'], 'exact JSON source bytes')
    assert decoded == json.loads(operands[0]['value']['json'], parse_float=Decimal)
    same({'interval': dict(zip(('months', 'days', 'nanos'), interval))}, operands[1]['value'], 'signed interval components')


def run(driver, destination, must_fail):
    cases = [('{"wide":9007199254740993,"fraction":0.12345678901234567890123456789,"value":null}', (1, -2, 3)),
             ('null', (-2147483648, 2147483647, -9223372036854775808)),
             ('{"text":"it\'s exact","array":[true,false]}', (2147483647, -2147483648, 9223372036854775807))]
    products = execute(driver, [dict(name=f'lossless-{i}', source=source(*case), compile='build') for i, case in enumerate(cases)], destination, 'lossless-products')
    for case, output in zip(cases, products):
        assert 'product' in output, output
        compare(case, output['product'])
    controls = []
    for label in ('rounded JSON number', 'interval collapsed to duration', 'foreign JSON domain'):
        changed = copy.deepcopy(products[0]['product'])
        operands = changed['steps'][1]['checked']['operands']
        if label == 'rounded JSON number':
            operands[0]['value']['json'] = operands[0]['value']['json'].replace('9007199254740993', '9007199254740992')
        elif label == 'interval collapsed to duration':
            operands[1]['value']['interval']['months'] = 0
        else:
            operands[0]['domain'] = 'example.other-document'
        controls.append(must_fail(label, lambda: compare(cases[0], changed)))
    return len(products), controls
