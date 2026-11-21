# Compiler extraction qualification

This record closes the extraction foundation in milestones 3 and 4. It does not
extend the source language or complete the feature work in milestones 5–10.
The results collected in [PR #4](https://github.com/spoke-sh/transitc/pull/4)
complete the foundation for the supported profile below.

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

The four native jobs in [run 44859572964](https://github.com/spoke-sh/transitc/actions/runs/44859572964)
passed at branch revision `b650d0f0ad106b1c5b3a9919f2f554fe5ce097f7`, testing merge
commit `02cfc59e446a9e28eb6d22f96ddbb6e66e52b189`. Each job executed clean-cache
builds/unit tests, the embedding consumer, portable archive installation, formatter
checks, runnable automation/dependency guides, signing, verification and tamper
refusal. All four downloaded candidates were independently verified again with
`gh attestation verify`, including the expected signer workflow and source digest.
[Archive manifests](native-archives.json) retain exact binary/archive digests and
job/artifact links.

All four native jobs also passed in
[run 44862769779](https://github.com/spoke-sh/transitc/actions/runs/44862769779)
at branch revision `7aee57f4f988b114994848eadc37de6193b84a55`. The manifest record
above deliberately retains the earlier candidates that were independently
downloaded and verified, rather than assigning their digests to a newer build.

| Native compiler host | Executed result |
| --- | --- |
| Ubuntu 24.04 x86_64, static musl archive | [Passed](https://github.com/spoke-sh/transitc/actions/runs/44859572964/job/136709690400) |
| Ubuntu 24.04 ARM64, static musl archive | [Passed](https://github.com/spoke-sh/transitc/actions/runs/44859572964/job/136709690440) |
| macOS 15 Intel, system-library archive | [Passed](https://github.com/spoke-sh/transitc/actions/runs/44859572964/job/136709690287) |
| macOS 15 ARM64, system-library archive | [Passed](https://github.com/spoke-sh/transitc/actions/runs/44859572964/job/136709690396) |

The local qualification host is x86_64 Linux, kernel `6.17.0-41-generic`.
Sandboxed Nix package/install checks and independent source verification passed
at `b650d0f0ad106b1c5b3a9919f2f554fe5ce097f7`. Source verification executed 192
cases, 134 formatting roundtrips and 10 negative controls; typed correspondence
executed 14 Lean laws, 136 finite equalities, 16 typed/SQL and 21 program
comparisons, four refusals and 21 negative controls. The Nix check now retains raw
comparison inputs, outputs and summaries, with a separate `source-revision` file
because exported Nix sources have no `.git` metadata.

The browser job in that run correctly rejected the new footer's unstyled source
link. Commit `09a2256` added its underline. Strict TypeScript/build checks and all
60 browser cases then passed locally at each hosting path (120 total). This is
recorded as a correction, not a claim that the earlier browser job passed.
Representative desktop/light and mobile/dark code screenshots were also inspected.
The corrected [handbook CI job](https://github.com/spoke-sh/transitc/actions/runs/44862769779/job/136719701236)
then passed both paths at branch revision `7aee57f4f988b114994848eadc37de6193b84a55`,
including all 120 browser cases and uploaded reports.

The local compiler reports `transitc 0.0.0-dev (development)` and executable SHA-256
`2ba2df1a2f45ac85e04c05ee69ec1bcc9b4dd6eab00350f42e639f363306bd4b`.
The runtime suite began at `6200fd0e945f68d28c706b9afbc6b79a9667dfc3`; compiler,
workspace, CLI, root Zig build inputs and dependency/toolchain locks are unchanged
between that revision and `7aee57f`. Later commits add packaging, documentation,
qualification tooling and a test-case correction. This distinction preserves the actual recorded
revisions rather than relabeling older runs as the final documentation commit.

The initial runtime transcript records passing workspace journeys, seven unchanged
upstream cases, twelve compiler parity cases, source-free SQL/restart and the full
application-build schedule, including its independent ordinary-SQL oracles,
migrations, multi-schema execution and credential revocation. Host-boundary checks
passed eleven request refusals and sixteen response/process refusals, including
late completion, unavailable/changed runtime, timeout and joined cleanup.

That invocation then failed at the combined multi-schema application-test case's
30-second deadline. Positive and nested-guard refusal paths passed independently;
`7aee57f` separates them into fresh cases and checks empty published outputs on
refusal. The focused corrected suite passed with the original limits and isolation
controls. The ordinary installed-runtime build journey still checks successive
successful and refused requests in one installation.

The full application-test schedule then passed at `7aee57f`, including offline
isolation, typed rows/counts, refusals, child/remote targets, resource limits,
failure cleanup, both multi-schema cases and the independent installed-SQL oracle.
It ran against a fixed copy of the compiler with the digest above. An intervening
attempt was discarded after a concurrent documentation build replaced the shared
local executable without its pinned host path; that setup failure is retained too.

Local command transcripts and their SHA-256 hashes are retained in
[`results/identities.json`](results/identities.json), including the failed initial
run. Terminal escape sequences and trailing whitespace are removed from these text
transcripts. Native job logs, provenance bundles and browser artifacts remain linked
to their actual CI runs; they are not relabeled as evidence from later commits.

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
Its [publication build](https://github.com/spoke-sh/transitc/actions/runs/44862769700)
passed at `7aee57f`.

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
- A combined multi-schema success/refusal scenario exceeded the fixed case
  deadline. Separate cases preserve both expectations and add explicit empty
  output checks on refusal without increasing runtime limits.
