"""Independent DATE values, nominal evidence and ordinary SQL comparisons."""
import copy
from datetime import date
from query.application_source.verify import execute, same


def source(day):
    return ("CREATE DOMAIN BusinessDay AS DATE IDENTITY 'example.business-day'; "
            'CREATE MODULE Calendar(element TYPE, selected BusinessDay) AS BEGIN '
            'CREATE PUBLIC TABLE business_days (day $element PRIMARY KEY); '
            'INSERT INTO business_days VALUES ($selected); END; '
            'CREATE TARGET default AS BEGIN '
            f"USE Calendar(TYPE BusinessDay, BusinessDay(DATE '{day}')); END;")


def compare(day, product):
    same(day, date.fromisoformat(day).isoformat(), 'independent calendar value')
    same(['CREATE TABLE BUSINESS_DAYS ( DAY DATE PRIMARY KEY )',
          f"INSERT INTO BUSINESS_DAYS VALUES ( DATE '{day}' )"],
         [step['sql'] for step in product['steps']], 'DATE SQL')
    checked = product['steps'][1]['checked']
    same('example.business-day', checked['columns'][0]['domain'], 'DATE column domain')
    same('example.business-day', checked['operands'][0]['domain'], 'DATE operand domain')
    same({'date': day}, checked['operands'][0]['value'], 'DATE exact value')


def run(driver, destination, must_fail):
    days = ['0001-01-01', '1970-01-01', '2024-02-29', '9999-12-31']
    products = execute(driver, [dict(name='date-' + day, source=source(day), compile='build')
                                for day in days], destination, 'date-products')
    for day, output in zip(days, products):
        assert 'product' in output, output
        compare(day, output['product'])
    controls = []
    for label in ('changed calendar day', 'timestamp conversion', 'foreign date domain'):
        product = copy.deepcopy(products[2]['product'])
        step = product['steps'][1]
        if label == 'changed calendar day':
            step['sql'] = step['sql'].replace('2024-02-29', '2024-03-01')
        elif label == 'timestamp conversion':
            step['sql'] = step['sql'].replace("DATE '", "TIMESTAMP '")
        else:
            step['checked']['operands'][0]['domain'] = 'example.other-day'
        controls.append(must_fail(label, lambda: compare(days[2], product)))
    return len(products), controls
