# 3. Compiler and CLI extraction

Status: In Progress

Prerequisites: [dependency boundaries](02-dependency-boundaries.md).

## Preparation already available

The default Nix shell supplies upstream Transit at the frozen source basis.
The [integration suite](../../tests/integration/README.md) checks real compiler
output, provenance, reproducibility, diagnostics, and isolated runtime tests.
This baseline can be extended to compare transitc when extraction lands; no
compiler equivalence is claimed and this milestone remains Planned.

## Move in reviewable slices

1. Freeze the extraction commit and copy the pure compiler with its tests,
   reviewed dependencies, and attribution. Add real Zig manifests and root build
   steps only for code that exists.
2. Move source contracts and independent grammar/corpus. Establish an old/new
   comparison harness before changing package names, formats, or public behavior.
3. Move source capture, dependency resolution, and artifact publication to
   `transitc-workspace`. Wire the CLI's actual build/check/fetch interface from the
   reviewed command contract, and document each supported option.
4. Move migration input/output adapters and test-product compilation. Keep the
   execution runner outside the pure compiler. Explicitly defer runtime-dependent
   commands until their adapter and compatibility checks are available.
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
- Runtime test execution is either separately qualified or explicitly absent
  from CLI help and user documentation.
- Installation, build/check workflows, errors, and artifact references explain
  the implemented commands, including failure behavior.

## Extraction implementation update

The compiler, workspace adapter and independent source checks are implemented.
Shared SQL/value modules remain Transit-owned and exactly pinned; embedded hosts
supply their canonical modules without resolving the standalone pin. See the
[current package map](../../packages/README.md), [attribution](../../NOTICE.md) and
public handbook. Consumer cutover and final clean qualification are still in
progress; this milestone does not inherit prior Transit pass records.
