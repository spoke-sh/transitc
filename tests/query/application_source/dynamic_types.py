"""Independent finite expectations for runtime MATCH's ordered nominal footprint."""
import copy

from query.application_source.verify import execute, same


def source(reverse):
    arms = [
        'WHEN Target.Machine(value) THEN INSERT INTO machines VALUES (value) ON CONFLICT (id) DO ASSERT SAME ROW;',
        'WHEN Target.Site(value) THEN INSERT INTO sites VALUES (value) ON CONFLICT (id) DO ASSERT SAME ROW;',
    ]
    if reverse:
        arms.reverse()
    return ("CREATE DOMAIN MachineId AS BIGINT IDENTITY 'example.machine'; "
            "CREATE DOMAIN SiteId AS BIGINT IDENTITY 'example.site'; "
            'CREATE VARIANT Target AS (Machine(id MachineId), Site(id SiteId)); '
            'CREATE MODULE Run(machine TYPE, site TYPE) AS BEGIN '
            'CREATE PUBLIC QUEUE requests (target STRUCT(tag TEXT NOT NULL, machine STRUCT(id BIGINT NOT NULL), site STRUCT(id BIGINT NOT NULL)) NOT NULL); '
            'CREATE PUBLIC TABLE machines (id $machine PRIMARY KEY); '
            'CREATE PUBLIC TABLE sites (id $site PRIMARY KEY); '
            'CREATE PUBLIC DATAFLOW route FROM QUEUE requests AS request AS BEGIN BEGIN ATOMIC '
            'MATCH request.target AS Target ' + ' '.join(arms) + ' END MATCH; END; END; END; '
            'CREATE TARGET default AS BEGIN USE Run(TYPE MachineId, TYPE SiteId); END;')


def compare(reverse, product):
    step = product['steps'][3]
    evidence = step['checked']['program']
    same(['acquire', 'atomic_begin', 'let', 'require'] +
         ['branch_begin', 'let', 'insert', 'branch_else', 'branch_end'] * 2 + ['atomic_end'],
         [event['kind'] for event in evidence['events']], 'runtime MATCH event order')
    wants = [('machines', 'example.machine'), ('sites', 'example.site')]
    if reverse:
        wants.reverse()
    writes = [event for event in evidence['events'] if event['kind'] == 'insert']
    nodes = {node['id']: node for node in evidence['nodes']}
    for (resource, domain), event in zip(wants, writes):
        same(resource, event['resource'], 'runtime MATCH resource')
        same(domain, event['columns'][0]['domain'], 'runtime MATCH column domain')
        same(domain, nodes[event['columns'][0]['value']]['type']['domain'], 'runtime MATCH payload domain')
    # Shape and order checks above are independent of generated local names.
    # Full runtime behavior is compared with hand-authored SQL by integration.
    assert step['sql'].count("'InvalidVariant'") == 1
    assert step['sql'].count("'machine'") == step['sql'].count("'site'") == 2
    assert 'MATCH' not in step['sql']


def run(driver, destination, must_fail):
    outputs = execute(driver, [dict(name=f'dynamic-{reverse}', source=source(reverse), compile='build')
                               for reverse in (False, True)], destination, 'dynamic-products')
    for reverse, output in zip((False, True), outputs):
        assert 'product' in output, output
        compare(reverse, output['product'])
    controls = []
    for label in ('dropped validation', 'foreign payload', 'wrong resource', 'changed runtime tag'):
        product = copy.deepcopy(outputs[0]['product'])
        step = product['steps'][3]
        events = step['checked']['program']['events']
        if label == 'dropped validation':
            events.pop(3)
        elif label == 'foreign payload':
            node_id = next(event for event in events if event['kind'] == 'insert')['columns'][0]['value']
            next(node for node in step['checked']['program']['nodes'] if node['id'] == node_id)['type']['domain'] = 'example.site'
        elif label == 'wrong resource':
            next(event for event in events if event['kind'] == 'insert')['resource'] = 'sites'
        else:
            step['sql'] = step['sql'].replace("'machine'", "'site'")
        controls.append(must_fail('runtime MATCH ' + label, lambda: compare(False, product)))
    return len(outputs), controls
