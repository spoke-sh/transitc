"""Check handbook coverage, public options and runnable automation/dependency guides."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
HANDBOOK = ROOT / 'docs/handbook'


def main():
    compiler = Path(sys.argv[1]).resolve()
    coverage = json.loads((ROOT / 'tests/documentation.json').read_text())
    milestone = (ROOT / 'docs/roadmap/04-documentation-and-qualification.md').read_text()
    tasks = re.findall(r'^\| ([^|]+?) \|', milestone, re.M)[2:]
    assert {row['task'] for row in coverage} == set(tasks), tasks
    sidebar = (HANDBOOK / 'sidebars.ts').read_text()
    for row in coverage:
        assert (HANDBOOK / row['page']).is_file(), row
        assert f'"{row["page"][:-3]}"' in sidebar, row
        assert row['evidence'] and all((ROOT / path).is_file() for path in row['evidence']), row
    for section in ('guides', 'reference', 'internals'):
        for page in (HANDBOOK / section).glob('*.md'):
            assert f'"{page.relative_to(HANDBOOK).with_suffix("")}"' in sidebar, page

    reference = (HANDBOOK / 'reference/cli.md').read_text()
    for command in ([], ['build'], ['fmt'], ['test']):
        help_text = subprocess.check_output([str(compiler), *command, '--help'], text=True)
        for option in re.findall(r'^  (-[\w-]+)\b', help_text, re.M):
            assert f'`{option}' in reference, (command, option)
    version = re.search(r'\.version = "([^"]+)"', (ROOT / 'build.zig.zon').read_text())[1]
    assert json.loads((HANDBOOK / 'package.json').read_text())['version'] == version
    assert f'`{version}`' in (HANDBOOK / 'guides/installation.md').read_text()
    for page, script in [('guides/automation.md', 'check.sh'), ('guides/source-workflow.md', 'dependencies.sh')]:
        snippets = re.findall(r'^```sh\n(.*?)^```', (HANDBOOK / page).read_text(), re.M | re.S)
        assert (ROOT / 'examples' / script).read_text() in snippets, (page, script)

    env = dict(os.environ, TRANSITC=str(compiler))
    with tempfile.TemporaryDirectory(prefix='transitc-docs-') as directory:
        root = Path(directory).resolve()
        def run(args, cwd, status=0):
            result = subprocess.run(args, cwd=cwd, env=env, text=True, capture_output=True, timeout=120)
            assert result.returncode == status, result
            return result
        project = root / 'project'
        shutil.copytree(ROOT / 'examples/first', project)
        check = ['sh', str(ROOT / 'examples/check.sh')]
        run(check + ['reviewed'], project)
        original = (project / 'reviewed/application.sql').read_bytes()
        run(check + ['reviewed'], project, status=1)
        assert (project / 'reviewed/application.sql').read_bytes() == original
        source = project / 'build.transit'
        valid = source.read_text()
        source.write_text(valid.replace('CREATE TARGET', 'create target'))
        run(check + ['unformatted'], project, status=1)
        assert not (project / 'unformatted').exists()
        run([str(compiler), 'fmt'], project)
        run(check + ['corrected'], project)
        source.write_text('invalid source;')
        run(check + ['invalid'], project, status=1)
        rejected = run([str(compiler), 'build', '--check', '--format', 'json'], project, status=1)
        assert json.loads(rejected.stdout)['outcome'] == 'not_submitted'
        assert not (project / 'invalid').exists()
        source.write_text(valid)
        run(check + ['restored'], project)
        dependency = root / 'dependency'
        dependency.mkdir()
        run(['sh', str(ROOT / 'examples/dependencies.sh')], dependency)
        application = dependency / 'application'
        lock = (application / 'transit.lock').read_bytes()
        assert (application / 'reviewed/application.sql').read_text() == 'CREATE TABLE ITEMS ( ID BIGINT );\n'
        # Check the correction path: a missing cache fails offline; restoring the
        # exact origin and fetching repairs it without editing the locked digest.
        shutil.rmtree(application / '.transit/packages')
        run([str(compiler), 'build', '--check'], application, status=1)
        (dependency / 'library-unavailable').rename(dependency / 'library')
        run([str(compiler), 'build', '--fetch'], application)
        assert (application / 'transit.lock').read_bytes() == lock
        run([str(compiler), 'build', '--check'], application)
    print(f'PASS {len(coverage)} handbook task mappings, CLI options, version and runnable guide success/failure/correction paths')


if __name__ == '__main__':
    main()
