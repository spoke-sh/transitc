"""Exact SQL/maps/diagnostic parity; executable identity is deliberately separate."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
IDENTITY_FIELDS = {'compiler_revision', 'compiler_digest', 'input_digest'}
# Reviewed upstream definition cutover: Transaction.Origin metadata changed the
# native definition, while these source/SQL fixtures retain their exact meaning.
BASELINE_DEFINITION = 'f311e893f8d2f4c21f426790172fadfebe7eb2364615eb1566c09f11d39bb0bb'
CURRENT_DEFINITION = '7344b5ed271c41ea371aaa6e61867b1a4d1f670e9a9176f96793835d8ead20a5'


def invoke(binary, directory, *args, expected=0, command='build'):
    result = subprocess.run([str(binary), command, '--format', 'json', '--color', 'off', *args],
                            cwd=directory, env={'PATH': os.defpath, 'NO_COLOR': '1'},
                            capture_output=True, text=True, timeout=120)
    assert result.returncode == expected and not result.stderr, (binary, args, result)
    return json.loads(result.stdout)


def artifacts(binary, workspace, destination):
    invoke(binary, workspace, '--out', str(destination))
    sql = (destination / 'application.sql').read_bytes()
    provenance = json.loads((destination / 'provenance.json').read_bytes())
    assert provenance['complete'] is True
    return sql, provenance


def compare(upstream, compiler):
    count = 0
    with tempfile.TemporaryDirectory(prefix='transitc-parity-') as temporary:
        root = Path(temporary).resolve()
        for name in ('application-build', 'application-typed-targets', 'application-queue-programs',
                     'application-typed-queue', 'application-modular-programs'):
            workspace = root / name
            shutil.copytree(ROOT / 'tests/fixtures' / name, workspace)
            for path in workspace.rglob('*'):
                path.chmod(0o700 if path.is_dir() else 0o600)
            old_sql, old = artifacts(upstream, workspace, root / (name + '-upstream'))
            new_sql, new = artifacts(compiler, workspace, root / (name + '-compiler'))
            repeated_sql, repeated = artifacts(compiler, workspace, root / (name + '-repeat'))
            assert old_sql == new_sql == repeated_sql == (workspace / 'expected.sql').read_bytes(), name
            assert new == repeated, (name, 'nondeterministic provenance')
            assert old.keys() == new.keys()
            assert old['definition'] == BASELINE_DEFINITION, (name, 'foreign baseline definition')
            assert new['definition'] == CURRENT_DEFINITION, (name, 'foreign compiler definition')
            expected = dict(old, definition=CURRENT_DEFINITION)
            assert {k: v for k, v in expected.items() if k not in IDENTITY_FIELDS} == {k: v for k, v in new.items() if k not in IDENTITY_FIELDS}, name
            assert old['compiler_digest'] != new['compiler_digest']
            assert old['input_digest'] != new['input_digest']
            count += 1
        # Use one identical path for both invocations, including path-bearing facts.
        workspace = root / 'invalid'
        workspace.mkdir()
        negatives = [
            (None, [], 'application.source.entry', 'build', None),
            ('CREATE TARGET default AS BEGIN SELECT ; END;', [], 'application.source.syntax', 'build', None),
            ('CREATE TARGET default AS BEGIN CREATE PUBLIC TABLE t (id BIGINT); END;', ['--target', 'absent'], 'application.source.target', 'build', None),
            ("IMPORT missing FROM 'missing.transit'; CREATE TARGET default AS BEGIN END;", [], 'application.source.import', 'build', None),
            ('CREATE TEST TARGET default AS BEGIN END;', [], 'application.source.target', 'build', 'transitc test --target default'),
            ('CREATE TARGET tests AS BEGIN END;', ['--target', 'tests'], 'application.source.target', 'test', 'transitc build --target tests'),
            ("DEPENDENCY missing FROM 'https://example.invalid/absent' REVISION '" + '0' * 40 + "'; CREATE TARGET default AS BEGIN END;", [], 'application.source.dependency', 'build', 'transitc build --fetch'),
        ]
        for source, options, code, command, correction in negatives:
            if source is not None:
                (workspace / 'build.transit').write_text(source)
            old = invoke(upstream, workspace, *options, expected=1, command=command)
            new = invoke(compiler, workspace, *options, expected=1, command=command)
            assert old['definition'] == BASELINE_DEFINITION, 'foreign baseline diagnostic definition'
            assert new['definition'] == CURRENT_DEFINITION, 'foreign compiler diagnostic definition'
            expected = dict(old, definition=CURRENT_DEFINITION)
            if code == 'application.source.dependency':
                assert old['message'].count('transit build --fetch') == 1
                expected['message'] = old['message'].replace('transit build --fetch', 'transitc build --fetch')
            assert expected == new, (expected, new)
            assert old['code'] == code, old
            if correction:
                human = subprocess.run([str(compiler), command, '--color', 'off', *options],
                                       cwd=workspace, env={'PATH': os.defpath, 'NO_COLOR': '1'},
                                       capture_output=True, text=True, timeout=120)
                assert human.returncode == 1 and not human.stdout, human
                assert correction in human.stderr, human.stderr
                assert 'transit build' not in human.stderr and 'transit test' not in human.stderr, human.stderr
            assert not (workspace / '.transit/build').exists()
            count += 1
    print(f'PASS {count} upstream/transitc parity cases; exact reviewed native definitions, {sorted(IDENTITY_FIELDS)} and dependency-command correction verified')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--transit', default=os.environ.get('TRANSIT_UPSTREAM_BIN'), required='TRANSIT_UPSTREAM_BIN' not in os.environ)
    parser.add_argument('--transitc', default='zig-out/bin/transitc')
    args = parser.parse_args()
    compare(Path(args.transit).resolve(), Path(args.transitc).resolve())
