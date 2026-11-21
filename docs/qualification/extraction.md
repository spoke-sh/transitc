# Compiler extraction qualification

This record closes the extraction foundation in milestones 3 and 4. It does not
extend the source language or complete the feature work in milestones 5–10.
Qualification is being collected on [PR #4](https://github.com/spoke-sh/transitc/pull/4);
the roadmap remains In Progress until the required results below are recorded.

## Reproduce the checks

Use the committed `flake.lock`, host Git, and a checkout without a sibling Transit
repository. The default shell contains the pinned host; `toolchain` excludes it.

```sh
nix develop --command just check test::unit test::clean-build
nix develop --command just test::fmt test::documentation test::release test::workspace test::examples test::integration test::build-command test::command
nix flake check --print-build-logs
nix build .#checks.x86_64-linux.source --no-link --print-build-logs
nix develop .#docs --command just docs::install docs::check
nix develop .#docs-browser --command just docs::browser
nix develop .#docs-browser --command env TRANSITC_DOCS_BASE_URL=/ just docs::browser
```

The compiler/runtime process suites run on x86_64 Linux. Source comparisons use
the independent grammar, typed/program models and Lean laws under their stated
finite bounds. Clean-cache/native tests execute the pure compiler, workspace unit
tests and an embedding consumer. They do not imply native Transit runtime testing
on every compiler host.

## Identities and support boundary

- Compiler version: `0.0.0-dev`; each native archive and `--version` carries its
  full source revision. PR artifacts identify GitHub's tested merge commit.
- Toolchain: Zig `0.17.0-dev.2267+48abf1a34`, with the committed Nix loader patch.
- Frozen pre-extraction comparison: Transit
  `e7434306334e3692c6f3e123cba0d278fa412196`.
- Test host: Transit `f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6`.
- Compiled-case definition:
  `f311e893f8d2f4c21f426790172fadfebe7eb2364615eb1566c09f11d39bb0bb`.
- Shared frontend/package pins remain in the Zig manifests and attribution
  inventory; this qualification does not repin them.

Portable archives support native Linux x86_64/ARM64 and macOS x86_64/ARM64 for
compiler operations. Linux archives have no ELF interpreter; macOS linkage is
restricted to system libraries. macOS execution is qualified on macOS 15. Windows,
older macOS and native database-host execution outside x86_64 Linux are outside
this foundation's support claim. The test command reports unavailable or
incompatible hosts explicitly. Git is required for explicit fetches and source
development, and is not supplied by the development shell.

## Evidence

Final CI/source identities and result links will be recorded here after the
complete pipeline passes. Local checks so far include clean builds, compiler and
workspace unit tests, all four handbook projects, formatter checks, workspace
journeys, twelve old/new parity cases, seven unchanged upstream cases and emitted
SQL execution with retained restart. These are distinct suites; upstream results
are not labeled as transitc executions.

The handbook's thirteen reader tasks map to pages and executable owners in
[`tests/documentation.json`](../../tests/documentation.json). Its validator checks
the roadmap table, navigation entries, every advertised help option, version, and
automation/dependency success, failure and correction paths. Exact source snippets
and emitted SQL are checked by `tests/examples.py`, including migration history
preservation and isolated application tests.

Browser qualification visits every published page in Chromium at `/transitc/` and
`/`, with 1440×1000 and 390×844 viewports in light/dark themes. It checks page
errors, horizontal overflow, WCAG A/AA rules, skip links, responsive navigation and
theme controls. Reports, failure traces and representative code/CLI screenshots
are retained by CI. This is Chromium coverage, not a claim about every browser or
assistive technology.

The existing main-site deployment passed in
[run 44857232879](https://github.com/spoke-sh/transitc/actions/runs/44857232879)
at `67aed9cfebb3bdcb9a6d0eee10ba850ef3ff138a`, including checks of public routes at
<https://spoke-sh.github.io/transitc/>. PRs build publication artifacts; only current
`main` can deploy. This PR's new pages will become live after merge and publication.

## Signed candidates and releases

Native CI installs and executes each archive in a fresh directory with no runtime
or development tools on PATH. It checks help/version, formatting, positive and
negative source builds, publication and explicit missing-host failure. The archive
contains its manifest, license and attribution; checksums cover the exact bytes.
CI creates GitHub/Sigstore build provenance, verifies signer and source identity,
and confirms that tampered bytes fail verification. The archive and verification
bundle are retained together for 30 days; copy qualified candidates before expiry.

`Prepare release` accepts a successful main-push CI run and an existing `vVERSION`
tag at the exact same commit. It requires all four archives, verifies signatures
and manifests again, and creates a draft release without rebuilding. Refusal tests
cover foreign/failed/unfinished runs, wrong source/version/target, corruption and
unexpected archive members. Publishing the draft remains a release decision;
qualification of development candidates does not claim a stable release exists.

## Fixes discovered by qualification

- Mandatory Zig dependencies were incorrectly lazy. An empty cache could return
  before exporting `transitc_compiler`; they now resolve before module setup.
- The migration guide's header had drifted from its checked fixture; source
  snippets and the expanded evolution example now agree exactly.
- Inline links needed a non-color cue, mobile tables needed keyboard focus, and
  syntax highlighting needed readable contrast in both themes. Browser checks
  now protect these behaviors.
