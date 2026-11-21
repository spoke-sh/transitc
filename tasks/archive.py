"""Build a portable native candidate, verify it after extraction, and archive it."""
import argparse
import gzip
import hashlib
import io
import json
import os
from pathlib import Path
import platform
import re
import struct
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[1]
TARGETS = {('Linux', 'x86_64'): 'x86_64-linux-musl', ('Linux', 'aarch64'): 'aarch64-linux-musl',
           ('Darwin', 'x86_64'): 'x86_64-macos', ('Darwin', 'arm64'): 'aarch64-macos'}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def smoke(binary, version, revision):
    with tempfile.TemporaryDirectory(prefix='transitc-installed-') as directory:
        root = Path(directory)
        env = dict(os.environ, PATH='/unavailable', TRANSIT_TEST_RUNTIME='/unavailable')
        def run(*args, status=0):
            result = subprocess.run([str(binary), *args], cwd=root, env=env, capture_output=True,
                                    text=True, timeout=60)
            assert result.returncode == status, result
            return result
        assert run('--version').stdout == f'transitc {version} ({revision})\n'
        for command in ('build', 'fmt', 'test'):
            assert f'Usage: transitc {command}' in run(command, '--help').stdout
        source = root / 'build.transit'
        source.write_text('create target default as begin create public table items(id bigint);end;')
        run('fmt')
        run('fmt', '--check')
        report = json.loads(run('build', '--check', '--format', 'json').stdout)
        assert report['ok'] and report['statements'] == 1
        run('build', '--out', 'reviewed')
        assert 'CREATE TABLE' in (root / 'reviewed/application.sql').read_text()
        source.write_text('invalid source;')
        assert json.loads(run('build', '--format', 'json', status=1).stdout)['outcome'] == 'not_submitted'
        run('unknown', status=2)
        source.write_text((ROOT / "examples/tests/build.transit").read_text())
        missing = json.loads(run("test", "--runtime", "/unavailable", "--format", "json", status=1).stdout)
        assert missing["cases"][0]["error_code"] == "TestRuntimeUnavailable", missing


def portable(data):
    if data[:4] == b'\x7fELF':
        assert data[4:6] == b'\x02\x01', 'expected 64-bit little-endian ELF'
        offset = struct.unpack_from('<Q', data, 32)[0]
        size, count = struct.unpack_from('<HH', data, 54)
        assert all(struct.unpack_from('<I', data, offset + i * size)[0] != 3 for i in range(count)), 'ELF interpreter makes archive non-portable'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / '.cache/release')
    args = parser.parse_args()
    target = TARGETS[(platform.system(), platform.machine())]
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    assert not subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no'], cwd=ROOT), 'commit source before packaging'
    version = re.search(r'\.version = "([^"]+)"', (ROOT / 'build.zig.zon').read_text())[1]
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='transitc-archive-') as directory:
        prefix = Path(directory) / 'installed'
        subprocess.run(['zig', 'build', '-Doptimize=ReleaseSafe', '-Dcpu=baseline', f'-Dtarget={target}',
                        f'-Drevision={revision}', '-Dtest-runtime=transit', '--prefix', str(prefix)], cwd=ROOT, check=True)
        binary = prefix / 'bin/transitc'
        portable(binary.read_bytes())
        smoke(binary, version, revision)
        lock = json.loads((ROOT / 'flake.lock').read_text())
        manifest = {'version': version, 'revision': revision, 'target': target,
                    'binary_sha256': digest(binary.read_bytes()),
                    'test_runtime_revision': lock['nodes']['transit']['locked']['rev'],
                    'test_host_bundled': False}
        members = {'bin/transitc': binary.read_bytes(),
                   'manifest.json': (json.dumps(manifest, indent=2, sort_keys=True) + '\n').encode(),
                   **{name: (ROOT / name).read_bytes() for name in ('LICENSE', 'NOTICE.md')}}
        name = f'transitc-{version}-{revision[:12]}-{target}'
        archive = output / f'{name}.tar.gz'
        with archive.open('wb') as raw, gzip.GzipFile(filename='', mode='wb', fileobj=raw, mtime=0) as compressed, tarfile.open(fileobj=compressed, mode='w') as tar:
            for relative, data in sorted(members.items()):
                entry = tarfile.TarInfo(f'{name}/{relative}')
                entry.size, entry.mode, entry.mtime = len(data), (0o755 if relative == 'bin/transitc' else 0o644), 0
                tar.addfile(entry, io.BytesIO(data))
        restored = Path(directory) / 'restored'
        with tarfile.open(archive) as tar:
            tar.extractall(restored, filter='data')
        installed = restored / name / 'bin/transitc'
        assert digest(installed.read_bytes()) == manifest['binary_sha256']
        smoke(installed, version, revision)
        (output / f'{name}.sha256').write_text(f'{digest(archive.read_bytes())}  {archive.name}\n')
        (output / f'{name}.json').write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
        print(f'PASS native installed archive: {archive}')


if __name__ == '__main__':
    main()
