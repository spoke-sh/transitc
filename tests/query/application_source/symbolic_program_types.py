"""Independent selected-program and all-arm refusal expectations."""
import copy
from pathlib import Path
from query.application_source.verify import execute, same

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / 'tests/fixtures/application-symbolic-program/build.transit'


def whole_shape(product, domain=None):
    records = [node['type'] for node in product['steps'][3]['checked']['program']['nodes']
               if node['type']['kind'] == 'record' and len(node['type']['fields']) == 64]
    same(True, bool(records), 'whole input shape')
    expected = [dict(name='id' if i == 0 else f'c{i}', value=dict(
        kind='integer', nullable=i != 0, domain=domain if i == 0 else None, fields=[]))
        for i in range(64)]
    for record in records:
        same(expected, record['fields'], 'authored field names, nullability and nominal domains')


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


def row_matrix(driver, destination, must_fail):
    source = SOURCE.read_text()
    columns = 'id BIGINT NOT NULL' + ''.join(f', c{i} BIGINT' for i in range(1, 64))
    forms = [
        ('function', "CREATE FUNCTION Accept(entry ROW(id BIGINT), expected SiteId) RETURNS BOOLEAN AS BEGIN RETURN entry.id > 0 AND expected = expected; END;", "REQUIRE Accept(request, $value) ELSE 'BadInput';"),
        ('guard', "CREATE GUARD Accept(entry ROW(id BIGINT), expected SiteId) AS BEGIN REQUIRE entry.id > 0 ELSE 'BadInput'; REQUIRE expected = expected ELSE 'BadId'; END;", "CHECK GUARD Accept(request, $value);"),
        ('procedure', "CREATE PROCEDURE Accept(entry ROW(id BIGINT), expected SiteId) AS BEGIN ATOMIC REQUIRE entry.id > 0 ELSE 'BadInput'; REQUIRE expected = expected ELSE 'BadId'; END;", "CALL Accept(request, $value);"),
        ('alias', "CREATE FUNCTION Accept(entry ROW(id BIGINT), expected SiteId) RETURNS BOOLEAN AS BEGIN RETURN entry.id > 0 AND expected = expected; END;", "LET input_copy = request; REQUIRE Accept(input_copy, $value) ELSE 'BadInput';"),
        ('positional', "CREATE FUNCTION Accept(entry ROW(id BIGINT), expected SiteId) RETURNS BOOLEAN AS BEGIN RETURN entry.id > 0 AND expected = expected; END;", "REQUIRE Accept(ROW(request.id), $value) ELSE 'BadInput';"),
        ('unused', "CREATE FUNCTION Accept(entry ROW(id BIGINT), expected SiteId) RETURNS BOOLEAN AS BEGIN RETURN entry.id > 0; END;", "REQUIRE Accept(request, $value) ELSE 'BadInput';"),
    ]
    cases = []
    for label, helper, invocation in forms:
        body = source.replace('id BIGINT NOT NULL', columns).replace('CREATE MODULE EmitSite', helper + '\nCREATE MODULE EmitSite')
        body = body.replace('INSERT INTO sites VALUES ($value)', invocation + ' INSERT INTO sites VALUES ($value)')
        # Select each arm. The Site helper must also check when unselected.
        for selected in ('Machine', 'Site'):
            entry = body.replace('Target.Machine(MachineId(7))', f'Target.{selected}({selected}Id(7))')
            cases.append(dict(name=f'whole-row-{label}-{selected}', source=entry, compile='build'))
    outputs = execute(driver, cases, destination, 'whole-row-products')
    for case, output in zip(cases, outputs):
        assert 'product' in output, output
        product = output['product']
        same(6, len(product['steps']), 'one selected program')
        same(False, any('__transit$symbolic' in step['sql'] for step in product['steps']), 'no checker constants emitted')
        same(63, product['steps'][2]['sql'].count(' BIGINT ,') + product['steps'][2]['sql'].count(' BIGINT )'), 'authored nullable columns')
        if case['name'].endswith('Site') and 'positional' not in case['name']:
            whole_shape(product)
    # All-arm checking must leave already-concrete SQL and definition identity unchanged.
    concrete = []
    for case in cases:
        if not case['name'].endswith('Site'):
            continue
        entry = case['source']
        begin = entry.index('  MATCH selected')
        end = entry.index('  END MATCH;', begin) + len('  END MATCH;')
        concrete.append(dict(name=case['name'] + '-concrete', source=entry[:begin] + '  USE EmitSite(SiteId(7));' + entry[end:], compile='build'))
    fixed = execute(driver, concrete, destination, 'whole-row-concrete')
    for symbolic, ordinary in zip(outputs[1::2], fixed):
        assert 'product' in ordinary, ordinary
        for left, right in zip(symbolic['product']['steps'], ordinary['product']['steps']):
            same(left['sql'], right['sql'], 'concrete SQL preserved')
            same(left['fingerprint'], right['fingerprint'], 'concrete definition preserved')
    callable_source = cases[1]['source'].replace('CREATE MODULE EmitSite(value SiteId)', 'CREATE MODULE EmitSite(value SiteId, pred FUNCTION OF Accept)').replace('REQUIRE Accept(request, $value)', 'REQUIRE pred(request, $value)').replace('USE EmitSite(value)', 'USE EmitSite(value, Accept)')
    imported_source = "IMPORT helpers FROM 'helpers.transit';\n" + cases[1]['source'].replace('entry.id > 0 AND expected = expected', 'helpers.positive(entry) AND expected = expected')
    extra = execute(driver, [
        dict(name='whole-row-callable', source=callable_source, compile='build'),
        dict(name='whole-row-imported-nested', source=imported_source, files=[dict(path='helpers.transit', text="CREATE FUNCTION inner(entry ROW(id BIGINT)) RETURNS BOOLEAN AS BEGIN RETURN entry.id > 0; END; CREATE PUBLIC FUNCTION positive(entry ROW(id BIGINT)) RETURNS BOOLEAN AS BEGIN RETURN inner(entry); END;")], compile='build')], destination, 'whole-row-composed')
    for result in extra:
        assert 'product' in result, result
        same(False, any('__transit$symbolic' in step['sql'] for step in result['product']['steps']), 'no composed checker constants emitted')
    nominal = cases[1]['source'].replace('id BIGINT NOT NULL', 'id $site NOT NULL').replace(
        'ROW(id BIGINT)', 'ROW(id SiteId)').replace('entry.id > 0', 'entry.id = expected')
    nullable = cases[1]['source'].replace('ROW(id BIGINT)', 'ROW(c1 BIGINT)').replace(
        'entry.id > 0', 'entry.c1 IS NOT NULL')
    descriptors = execute(driver, [dict(name=f'{label}-{arm}', source=entry.replace(
        'Target.Site(SiteId(7))', f'Target.{arm}({arm}Id(7))'), compile='build')
        for label, entry in (('nominal-row', nominal), ('nullable-row', nullable))
        for arm in ('Machine', 'Site')], destination, 'whole-row-descriptors')
    for result in descriptors:
        assert 'product' in result, result
    whole_shape(descriptors[1]['product'], 'example.site')
    whole_shape(descriptors[3]['product'])
    bad = []
    for label, before, after, code in [
            ('missing-field', 'ROW(id BIGINT)', 'ROW(absent BIGINT)', 'UnknownProgramField'),
            ('foreign-domain', 'expected SiteId', 'expected MachineId', 'SourceDomainMismatch'),
            ('forged-name', 'Accept(request, $value)', 'Accept(request, "__transit$symbolic_0")', 'UnsupportedSymbolicProgram')]:
        entry = cases[0]['source'].replace(before, after)
        if label == 'missing-field':
            entry = entry.replace('entry.id', 'entry.absent')
        bad.append((dict(name=label, source=entry, compile='build'), code))
    bad.append((dict(name='foreign-row-field', source=nominal.replace(
        'ROW(id SiteId)', 'ROW(id MachineId)').replace('entry.id = expected', 'entry.id = entry.id'),
        compile='build'), 'SourceDomainMismatch'))
    refused = execute(driver, [case for case, _ in bad], destination, 'whole-row-refusals')
    for (_, expected), result in zip(bad, refused):
        same(expected, result.get('compile_error'), 'invalid unselected whole-row call')
    controls = []
    damaged = copy.deepcopy(outputs[1]['product'])
    for node in damaged['steps'][3]['checked']['program']['nodes']:
        if node['type']['kind'] == 'record':
            node['type']['fields'] = []
    controls.append(must_fail('lost whole input fields', lambda: whole_shape(damaged)))
    damaged = copy.deepcopy(descriptors[1]['product'])
    for node in damaged['steps'][3]['checked']['program']['nodes']:
        if node['type']['kind'] == 'record' and len(node['type']['fields']) == 64:
            node['type']['fields'][1]['value']['nullable'] = False
    controls.append(must_fail('lost whole input nullability', lambda: whole_shape(damaged, 'example.site')))
    return len(outputs) + len(fixed) + len(extra) + len(descriptors), controls


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
    rows, row_controls = row_matrix(driver, destination, must_fail)
    return len(products) + rows, controls + row_controls
