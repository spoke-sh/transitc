"""Promote verified CI archives to a draft release without rebuilding them."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import tempfile
from urllib.parse import quote

TARGETS = ('x86_64-linux-musl', 'aarch64-linux-musl', 'x86_64-macos', 'aarch64-macos')


def require(condition, message):
    if not condition:
        raise ValueError(message)


def eligible_run(run, repository):
    require(run['repository']['full_name'] == repository, 'foreign repository')
    require(run['path'] == '.github/workflows/ci.yml', 'wrong workflow')
    require(run['event'] == 'push' and run['head_branch'] == 'main', 'require main push CI')
    require(run['status'] == 'completed' and run['conclusion'] == 'success', 'CI must pass completely')
    require(re.fullmatch(r'[0-9a-f]{40}', run['head_sha']), 'invalid source revision')
    return run['head_sha']


def verify_archive(archive, target, revision, version):
    name = f'transitc-{version}-{revision[:12]}-{target}'
    require(archive.name == name + '.tar.gz', 'unexpected archive identity')
    expected = hashlib.sha256(archive.read_bytes()).hexdigest() + '  ' + archive.name + '\n'
    require(archive.with_name(name + '.sha256').read_text() == expected, 'checksum mismatch')
    with tarfile.open(archive) as tar:
        members = tar.getmembers()
        require({item.name for item in members} == {f'{name}/{p}' for p in ('bin/transitc', 'manifest.json', 'LICENSE', 'NOTICE.md')}
                and len(members) == 4 and all(item.isfile() for item in members), 'unexpected archive members')
        manifest = json.load(tar.extractfile(f'{name}/manifest.json'))
        binary_digest = hashlib.sha256(tar.extractfile(f'{name}/bin/transitc').read()).hexdigest()
    require(manifest['revision'] == revision and manifest['version'] == version and manifest['target'] == target, 'manifest identity mismatch')
    require(manifest['binary_sha256'] == binary_digest, 'binary digest mismatch')
    require(manifest['test_host_bundled'] is False, 'unexpected runtime payload')
    require(json.loads(archive.with_name(name + '.json').read_text()) == manifest, 'sidecar manifest mismatch')
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run-id', type=int, required=True)
    parser.add_argument('--tag', required=True)
    args = parser.parse_args()
    require(re.fullmatch(r'v\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?', args.tag), 'tag must match the packaged version')
    repository = os.environ['GITHUB_REPOSITORY']
    def gh(*arguments):
        return subprocess.check_output(['gh', *arguments], text=True)
    def api(path):
        return json.loads(gh('api', f'repos/{repository}/{path}'))
    run = api(f'actions/runs/{args.run_id}')
    revision = eligible_run(run, repository)
    tag = api('git/ref/tags/' + quote(args.tag, safe=''))['object']
    for _ in range(8):
        if tag['type'] == 'commit':
            break
        require(tag['type'] == 'tag', 'tag does not identify a commit')
        tag = api('git/tags/' + tag['sha'])['object']
    require(tag['type'] == 'commit' and tag['sha'] == revision, 'tag does not match the qualified source')
    with tempfile.TemporaryDirectory(prefix='transitc-release-') as directory:
        root = Path(directory)
        download = root / 'download'
        gh('run', 'download', str(args.run_id), '--repo', repository, '--pattern', 'transitc-*', '--dir', str(download))
        publish = root / 'publish'
        publish.mkdir()
        for target in TARGETS:
            candidate = download / f'transitc-{target}'
            archives = list(candidate.glob('*.tar.gz'))
            require(len(archives) == 1, f'require one {target} archive')
            archive = archives[0]
            # Authenticate bytes before parsing tar or JSON contents.
            gh('attestation', 'verify', str(archive), '--repo', repository,
               '--signer-workflow', repository + '/.github/workflows/ci.yml',
               '--source-digest', revision, '--source-ref', 'refs/heads/main', '--deny-self-hosted-runners',
               '--bundle', str(candidate / 'provenance.jsonl'))
            verify_archive(archive, target, revision, args.tag[1:])
            for path in candidate.iterdir():
                if path.name == 'provenance.jsonl':
                    shutil.copyfile(path, publish / (archive.name + '.sigstore.jsonl'))
                elif path.suffix in ('.gz', '.json', '.sha256'):
                    shutil.copyfile(path, publish / path.name)
        notes = root / 'notes.md'
        notes.write_text(f'Compiler source: `{revision}`.\n\nQualified CI: {run["html_url"]}\n\n'
                         f'Handbook source: https://github.com/{repository}/tree/{revision}/docs/handbook\n\n'
                         'Four native archives, verified against CI provenance before promotion. '
                         'Transit test hosts are separate; consult the installation guide for compatibility.\n')
        gh('release', 'create', args.tag, '--repo', repository, '--verify-tag', '--draft',
           '--title', f'transitc {args.tag}', '--notes-file', str(notes),
           *[str(path) for path in sorted(publish.iterdir())])
    print(f'Created draft {args.tag} from qualified source {revision}')


if __name__ == '__main__':
    main()
