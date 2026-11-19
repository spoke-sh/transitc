"""Run the compiler-owned application suite against the pinned Transit host."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def main():
    compiler = Path(sys.argv[1] if len(sys.argv) > 1 else 'zig-out/bin/transitc').resolve()
    runtime = Path(os.environ['TRANSIT_TEST_RUNTIME']).resolve()
    source = Path(os.environ['TRANSIT_TEST_SOURCE']).resolve()
    # Runtime process helpers stay upstream; source scenarios and fixtures live
    # here. Keep the existing network, PATH and configuration denial controls.
    sys.path.insert(0, str(source / 'tests'))
    from harness import phases
    recorder = phases.Recorder(ROOT)
    phases.recorder = lambda: recorder
    from integration import application_test as suite
    original_oracle = suite.installed_oracle
    suite.installed_oracle = lambda _compiler, sql: original_oracle(runtime, sql)
    original_invoke = suite.invoke
    digest = list(hashlib.sha256(runtime.read_bytes()).digest())
    version = subprocess.run([str(runtime), '--version'], capture_output=True, text=True, check=True).stdout
    revision = version.split('(git ', 1)[1].split(';', 1)[0]

    def invoke(*args, **kwargs):
        report = original_invoke(*args, **kwargs)
        if report.get('runtime') is not None:
            assert report['runtime'] == {'revision': revision, 'executable_digest': digest}, report['runtime']
        return report

    suite.invoke = invoke
    sys.argv = [str(ROOT / 'tests/integration/application_test.py'), str(compiler)]
    # copytree preserves the Nix store's read-only directory modes. Materialize
    # only the pinned fixtures as writable inputs before the original schedule
    # makes its own isolated copies and deliberate permission-denial controls.
    with tempfile.TemporaryDirectory(prefix='transitc-runtime-fixtures-') as temporary:
        suite.ROOT = Path(temporary)
        relative = Path('tests/fixtures')
        fixtures = suite.ROOT / relative
        shutil.copytree(ROOT / relative, fixtures)
        for path in [fixtures, *fixtures.rglob('*')]:
            path.chmod(0o700 if path.is_dir() else 0o600)
        suite.main()
    print('PASS transitc test: complete native application schedule, offline cases, failures, limits, cleanup and runtime identity')


if __name__ == '__main__':
    main()
