# Install, verify and upgrade

Choose an exact compiler revision and keep it with your application. The current
development version is `0.0.0-dev`; the revision in `transitc --version`
distinguishes builds. There is no automatic updater.

## Install with Nix

Install Nix with flakes enabled and Git on the host, then check out the reviewed
revision of this repository. From that checkout:

```sh
nix build .#transitc
./result/bin/transitc --version
./result/bin/transitc build --help
```

Use the resulting executable directly, or add `result/bin` to PATH. The package
contains a compatible Transit test host in its Nix closure. Build and formatting
commands do not start the host. Zig is a build dependency, not an installation
prerequisite for an already built executable. A checkout can also be built with
`nix develop --command just build`; its executable is `zig-out/bin/transitc`.
The complete Nix package and bundled test host are qualified on x86_64 Linux;
the native compiler matrix below covers the standalone archives.

The source toolchain is pinned to Zig `0.17.0-dev.2267+48abf1a34`. Use the flake's
wrapper, including its Linux loader fixes, rather than substituting another Zig
development release. A missing package download is an installation failure;
retry with connectivity before attempting an offline application build.

## Verify an archive

CI produces native archive candidates for the following compiler hosts. The
qualification record links the executed jobs; a candidate is not a stable release.

| Host | Archive target | Compiler operations |
| --- | --- | --- |
| Linux x86_64 | `x86_64-linux-musl` | Build, check, fetch, format, library tests |
| Linux ARM64 | `aarch64-linux-musl` | Build, check, fetch, format, library tests |
| macOS x86_64 | `x86_64-macos` | Build, check, fetch, format, library tests |
| macOS ARM64 | `aarch64-macos` | Build, check, fetch, format, library tests |

Linux archives are static executables, with no Nix loader dependency. macOS
archives are qualified on the CI macOS 15 hosts. Other operating systems and older
macOS releases are not qualified. Git is required only for explicit dependency
fetches. Archives do not bundle a Transit runtime. Actual isolated database tests
are qualified separately on x86_64 Linux against the pinned host; other runtime
hosts are outside this extraction qualification.

Download the archive, checksum, manifest and provenance bundle from one successful
[CI run](https://github.com/spoke-sh/transitc/actions/workflows/ci.yml). With the
GitHub CLI installed and authenticated, set `archive` to its filename and
`revision` to the full source commit recorded by that run:

```sh
gh attestation verify "$archive" --repo spoke-sh/transitc \
  --signer-workflow spoke-sh/transitc/.github/workflows/ci.yml \
  --source-digest "$revision" --deny-self-hosted-runners
tar -xzf "$archive"
```

Verify before extracting or executing. A changed archive, different source revision
or another signing workflow must fail verification. The adjacent SHA-256 file
helps detect transfer damage; it does not authenticate a download by itself.
The archive's `manifest.json` records version, revision, target, binary digest
and compatible test-host revision. The executable's `--version` must match.
Keep the archive and provenance bundle together for later verification with
`gh attestation verify --bundle provenance.jsonl` and the same identity options.

Release maintainers use the separate release workflow to promote the four verified
archives from a successful `main` CI run into a draft release at an existing
matching tag. It verifies source identity again and never rebuilds the bytes.
There is no stable release claim implied by a development candidate.

## Upgrade and compatibility

Save the previous executable, its version/revision and application lockfile.
Build or verify the new revision in a separate location, then run:

```sh
transitc --version
transitc fmt --check
transitc build --check --format json
transitc test --format json
```

The final command needs the compatible host described in [testing](testing.md).
Review formatter changes before applying them. Retain previous SQL, provenance,
migration basis and immutable history: compiler identity changes can change
artifact paths even when SQL remains equal. Compare the new proposal in a new
explicit output directory; do not overwrite or relabel accepted history.

The selected host revision is
`d65f7c656c8e311806132ca894059b43b52051ee`. The process protocol checks the exact
compiled-case definition, bounded responses and executable identity. A matching
version label alone does not establish compatibility. If host lookup or definition
checking fails, select the pinned host with `--runtime`; do not reinterpret an
incomplete test report as success. To roll back, restore the prior executable and
its matching host. Compiler installation and rollback never apply database SQL.

See [artifacts](../reference/artifacts.md), [diagnostics](../reference/diagnostics.md)
and the [qualification record](https://github.com/spoke-sh/transitc/blob/main/docs/qualification/extraction.md)
for evidence and exact boundaries.
