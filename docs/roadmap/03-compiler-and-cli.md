# 3. Compiler and CLI extraction

Status: Completed

Prerequisites: [dependency boundaries](02-dependency-boundaries.md).

## Frozen comparison basis

The default Nix shell supplies the frozen upstream comparison binary and the
separately pinned compatible Transit test host.
The [integration suite](../../tests/integration/README.md) checks real compiler
output, provenance, reproducibility, diagnostics, and isolated runtime tests.
The original seven upstream cases remain unchanged. Twelve additional parity
cases compare the extracted compiler with that frozen binary, covering the
expanded source profile and expected tool-identity differences. Runtime
execution of emitted SQL and retained restart are checked separately.

## Move in reviewable slices

1. Freeze the extraction commit and copy the pure compiler with its tests,
   reviewed dependencies, and attribution. Add real Zig manifests and root build
   steps only for code that exists.
2. Move source contracts and independent grammar/corpus. Establish an old/new
   comparison harness before changing package names, formats, or public behavior.
3. Move source capture, dependency resolution, and artifact publication to
   `transitc-workspace`. Wire the CLI's actual build/check/fetch interface from the
   reviewed command contract, and document each supported option.
4. Move migration input/output adapters, test-product compilation and `transitc test`
   orchestration. Keep database execution outside the pure compiler through a
   bounded compiled-case host contract, with compatibility and lifecycle checks.
5. Update Transit consumers through the approved shared-package strategy and
   remove superseded ownership as part of that coordinated extraction.

Source candidates: `packages/zig/transit-compiler/`, CLI `Build*.zig`, relevant
diagnostic rendering, `contracts/APPLICATION_SOURCE_V1.md`,
`contracts/application-source/`, `tests/query/application_source/`, and the
application build/program/typed-target/queue/test fixture families. Inventory
their licenses and all referenced helpers; directory copying alone is insufficient.

## Acceptance

- Compiler products, ordered SQL, diagnostics/spans, and deterministic digests
  match the frozen source basis except for explicitly reviewed identity changes.
- Unit, allocation-failure, input/output-bound, grammar, and independent SQL
  verification checks run from a checkout without the source repository.
- Offline dependency resolution, explicit fetch, lock failures, overrides,
  missing/invalid sources, and incomplete artifact publication have executable
  positive and negative coverage.
- Migration proposals preserve explicit basis/history and do not execute SQL.
- `transitc test` executes the compiler-owned application schedule through the
  pinned host, preserving assertions, isolation, resource limits and cleanup.
  Foreign definitions, malformed or incomplete responses and process failures reject.
- Installation, build/check workflows, errors, and artifact references explain
  the implemented commands, including failure behavior.

## Extraction implementation update

The compiler, workspace adapter and independent source checks are implemented.
Shared SQL/value and compiled-case modules remain Transit-owned and exactly
pinned. Transit no longer embeds compiler or workspace code; native runtime
execution stays upstream behind the bounded process contract.

The coordinated [Transit cutover](https://github.com/spoke-sh/transit/pull/474)
is merged. The [qualification record](../qualification/extraction.md) retains
standalone clean-cache/native builds, source comparisons, runtime journeys,
host-boundary refusals, revisions and corrected failures. New language profiles
and expanded application qualification remain in milestones 5–10.
