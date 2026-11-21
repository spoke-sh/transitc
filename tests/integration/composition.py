"""Complete composition schedule; failures cannot hide independent phases."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time

from runner import capture
from runner.paths import ROOT

INSTALLED = (
    ('typed_composition', 'native'), ('typed_composition', 'dynamic'),
    ('cardinality', 'one'), ('cardinality', 'optional'),
    ('refinements',), ('callables',), ('scalar_surfaces',),
    ('sql_scalars',), ('json_helpers',),
)


def validate(report, expected):
    assert report['complete'] and report['ok'], 'incomplete or failed suite'
    assert [case['name'] for case in report['cases']] == expected, 'case inventory mismatch'
    assert all(case['status'] == 'passed' and case['error_code'] is None
               for case in report['cases']), 'failed or unexecuted case'
    assert report['limits']['case_ms'] == 30000
    assert report['limits']['suite_ms'] == 300000
    assert report['limits']['cleanup_ms'] == 5000


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def schedule(runs, installed, fixtures):
    phases = []
    if installed:
        phases += [('installed-' + '-'.join(args), args) for args in INSTALLED]
    for run in range(1, runs + 1):
        phases += [(f'isolated-{run}-{name}', name) for name in fixtures]
    return phases


def execute(compiler, destination, phases, fixtures):
    runtime = Path(os.environ['TRANSIT_TEST_RUNTIME']).resolve()
    report = {'provenance': capture.provenance(ROOT), 'complete': False, 'ok': False,
              'compiler_sha256': digest(compiler), 'runtime_sha256': digest(runtime),
              'expected_phases': [name for name, _ in phases], 'phases': []}
    output = destination / 'evidence.json'
    capture.write_json(output, report)
    for name, selected in phases:
        result = {'name': name, 'complete': False, 'ok': False}
        report['phases'].append(result)
        capture.write_json(output, report)
        start = time.monotonic()
        try:
            if isinstance(selected, tuple):
                module, *args = selected
                command = [sys.executable, '-B', str(ROOT / 'tests/runner/launch.py'),
                           str(ROOT / f'tests/integration/{module}.py'), str(compiler), *args]
                outcome = capture.run(command, cwd=ROOT, log=destination / (name + '.log'), result=result)
                assert outcome.returncode == 0, f'installed phase exited {outcome.returncode}'
            else:
                with (destination / (name + '.json')).open('w') as stdout, (destination / (name + '.stderr')).open('w') as stderr:
                    with subprocess.Popen([str(compiler), 'test', '-f',
                                           str(ROOT / 'tests/fixtures' / selected / 'build.transit'),
                                           '--format', 'json'], cwd=ROOT, stdout=stdout, stderr=stderr,
                                          start_new_session=True) as process:
                        try:
                            result['exit_code'] = process.wait(timeout=330)
                        except BaseException:
                            # Own the compiler and its host descendants together.
                            # The outer guard cannot leave a native case running.
                            try:
                                os.killpg(process.pid, signal.SIGKILL)
                            except ProcessLookupError:
                                pass
                            process.wait()
                            raise
                result['report'] = capture.identity(destination / (name + '.json'))
                result['stderr'] = capture.identity(destination / (name + '.stderr'))
                suite = json.loads((destination / (name + '.json')).read_text())
                result['cases'] = [{key: case[key] for key in ('name', 'status', 'error_code')} for case in suite['cases']]
                assert result['exit_code'] == 0 and result['stderr']['bytes'] == 0, 'isolated suite failed'
                validate(suite, fixtures[selected])
                assert suite['compiler_digest'] == report['compiler_sha256'], 'compiler changed during schedule'
                assert bytes(suite['runtime']['executable_digest']).hex() == report['runtime_sha256'], 'runtime changed during schedule'
            result['ok'] = True
        except Exception as error:
            result['error'] = f'{type(error).__name__}: {error}'
        finally:
            result['complete'] = True
            result['elapsed_seconds'] = round(time.monotonic() - start, 3)
            capture.write_json(output, report)
        print(f"{'PASS' if result['ok'] else 'FAIL'} {name}", flush=True)
    report['complete'] = True
    report['ok'] = all(result['ok'] for result in report['phases']) and bool(phases)
    capture.write_json(output, report)
    return report['ok']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('compiler', type=Path)
    parser.add_argument('--runs', type=int, default=1, choices=range(1, 4))
    parser.add_argument('--isolated-only', action='store_true')
    args = parser.parse_args()
    fixtures = json.loads((ROOT / 'tests/integration/composition.json').read_text())
    parent = ROOT / '.cache/checks/composition'
    parent.mkdir(parents=True, exist_ok=True)
    destination = Path(tempfile.mkdtemp(prefix='run-', dir=parent))
    print(f'Composition evidence: {destination}', flush=True)
    if not execute(args.compiler.resolve(), destination,
                   schedule(args.runs, not args.isolated_only, fixtures), fixtures):
        raise SystemExit(1)


if __name__ == '__main__':
    main()
