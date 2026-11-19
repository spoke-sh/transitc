# Upstream Transit integration

Run `nix develop --command just test-integration` from the repository root.
The shell provides the upstream `transit` package and Python; no pip dependencies,
sibling checkout, downloads during tests, or running server are needed.

The same suite is `checks.<system>.integration` in the flake. `nix flake check`
runs it in the sandbox, including in CI. To run only this check on x86_64 Linux:

```sh
nix build .#checks.x86_64-linux.integration --no-link --print-build-logs
```

## What is checked

Seven integration tests invoke the actual upstream executable:

- `build --check` verifies a two-file module graph and publishes no artifact.
- Two independent builds produce the hand-written `expected.sql`, identical
  provenance, correct source/output hashes, the pinned compiler revision, and
  four statement mappings.
- Default builds reuse intact artifacts and reject corrupted SQL without
  overwriting it.
- Missing entries and unknown targets fail with bounded structured diagnostics
  and no build artifact.
- Invalid SQL produces the expected syntax diagnostic and exact byte coordinates.
- `transit test` executes Table writes, duplicate-key rejection, and row checks
  in two isolated cases; both pass and their temporary runtime state is removed.
- A deliberately incorrect row expectation returns failure while producing a
  complete report, proving that the runtime assertions actually execute.

The fixture is adapted from Transit's `tests/fixtures/application-tests/` at
[`c1f2680d9353175e58ad503e750e7b4da76a84c5`](https://github.com/spoke-sh/transit/tree/c1f2680d9353175e58ad503e750e7b4da76a84c5/tests/fixtures/application-tests).
The build target adds an update and select; expected SQL is maintained explicitly,
not regenerated from the compiler being tested. Fixture `.transit` files and SQL
expectations live separately so expected output cannot be captured as source.

Each test copies source into a fresh temporary workspace and supplies isolated
home/config/cache/data/temp paths to its child process. It does not inherit
Transit credentials or settings. Subprocesses have deadlines; unexpected exits,
missing/malformed JSON, incomplete reports, or a wrong revision fail the suite.
No test is silently skipped when Transit is missing.

This is an upstream behavior baseline. transitc currently implements only
help/version, so these are not compiler parity tests. When extraction lands,
compile the same source with transitc, compare SQL/diagnostics and the reviewed
provenance fields, then execute the resulting SQL with the pinned Transit runtime.
Do not replace upstream execution with a mock or a successful help command.

## Upstream identity and updates

`flake.nix` names the exact GitHub revision and `flake.lock` records its content
hash. `TRANSIT_UPSTREAM_BIN` and `TRANSIT_UPSTREAM_REVISION` are exported by the
default shell; the runner verifies the executable's reported revision before
running any tests. Nix checks pass these inputs explicitly.

To upgrade the baseline, review the new upstream source/CLI contracts, change
the revision in `flake.nix`, run `nix flake lock`, and re-enter the shell. Run
`just test-integration` and `nix flake check`, and review changed expectations
against the source contract rather than accepting new output automatically.
Update this guide and the extraction source inventory when adopting a new basis.

For an explicitly selected local build, the runner also accepts
`--transit /absolute/path/to/transit --expected-revision FULL_GIT_COMMIT`.
Such a run does not replace the pinned Nix check and still validates the revision.

## Validation

On 2026-11-18, all seven tests passed on x86_64 Linux both through
`nix develop --command just test-integration` and the sandboxed integration
derivation. `just check`, the handbook check, and workflow lint also passed.
Flake evaluation passed for all four declared systems; ARM and Darwin test
execution was not performed.
