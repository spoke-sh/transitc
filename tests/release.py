"""Refuse unqualified source identities and damaged release payloads."""
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('release', ROOT / 'tasks/release.py')
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class ReleaseQualification(unittest.TestCase):
    def test_requires_complete_main_ci(self):
        valid = {'repository': {'full_name': 'spoke-sh/transitc'}, 'path': '.github/workflows/ci.yml',
                 'event': 'push', 'head_branch': 'main', 'status': 'completed', 'conclusion': 'success',
                 'head_sha': 'a' * 40}
        self.assertEqual(release.eligible_run(valid, 'spoke-sh/transitc'), 'a' * 40)
        for key, value in [('repository', {'full_name': 'other/repo'}), ('path', '.github/workflows/other.yml'),
                           ('event', 'pull_request'), ('head_branch', 'feature'), ('status', 'in_progress'),
                           ('conclusion', 'failure'), ('head_sha', 'development')]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                release.eligible_run(dict(valid, **{key: value}), 'spoke-sh/transitc')

    def test_archive_identity_and_corruption(self):
        with tempfile.TemporaryDirectory() as directory:
            revision, version, target = 'a' * 40, '0.0.0-dev', 'x86_64-linux-musl'
            name = f'transitc-{version}-{revision[:12]}-{target}'
            archive = Path(directory) / (name + '.tar.gz')
            manifest = {'revision': revision, 'version': version, 'target': target,
                        'binary_sha256': hashlib.sha256(b'binary').hexdigest(), 'test_host_bundled': False}
            def write(value, extra=None):
                members = {'bin/transitc': b'binary', 'manifest.json': json.dumps(value).encode(), 'LICENSE': b'license', 'NOTICE.md': b'notice'}
                if extra:
                    members.update(extra)
                with tarfile.open(archive, 'w:gz') as tar:
                    for path, data in members.items():
                        entry = tarfile.TarInfo(name + '/' + path)
                        entry.size = len(data)
                        tar.addfile(entry, io.BytesIO(data))
                archive.with_name(name + '.sha256').write_text(hashlib.sha256(archive.read_bytes()).hexdigest() + '  ' + archive.name + '\n')
                archive.with_name(name + '.json').write_text(json.dumps(value))
            write(manifest)
            self.assertEqual(release.verify_archive(archive, target, revision, version), manifest)
            with archive.open('ab') as stream:
                stream.write(b'corruption')
            with self.assertRaisesRegex(ValueError, 'checksum'):
                release.verify_archive(archive, target, revision, version)
            for field, value in [('revision', 'b' * 40), ('version', '9.0.0'), ('target', 'aarch64-macos'),
                                 ('binary_sha256', 'b' * 64), ('test_host_bundled', True)]:
                write(dict(manifest, **{field: value}))
                with self.subTest(field=field), self.assertRaises(ValueError):
                    release.verify_archive(archive, target, revision, version)
            write(manifest, {'../../escape': b'bad'})
            with self.assertRaisesRegex(ValueError, 'members'):
                release.verify_archive(archive, target, revision, version)


if __name__ == '__main__':
    unittest.main()
