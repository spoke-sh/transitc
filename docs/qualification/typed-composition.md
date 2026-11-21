# Typed composition qualification

This record covers the bounded milestone 5 compiler increments. Milestone 5
remains **In Progress**: isolated runtime failures and the explicit native gates
below still prevent closeout. No dependency/runtime pin or standard test deadline
was changed to admit an unsupported operation or obtain a passing report.

## Implemented profile

- Closed-record runtime MATCH with exhaustive arms, tag/payload validation,
  nominal annotations and hygienic ordinary-SQL dispatch. Symbolic program/control
  checking covers every reached compile-time match arm without emitting synthetic
  values or changing durable catalog shape.
- ONE/OPTIONAL query results with distinct row presence and nullable fields.
  Direct REQUIRE/IF facts permit guarded projection; ONE emits ordered validation.
- Bounded scalar REQUIRES/ENSURES contracts: non-nullness, same-type equality and
  constant BIGINT bounds. Every admitted clause remains an ordered runtime
  obligation; no authority or mutable-resource fact is inferred.
- Exact callable module arguments and effect signatures for functions, guards and
  procedures. Nested calls retain single evaluation, explicit resources and the
  caller's atomic transaction. Effects do not grant current runtime rights.
- Exact DATE/NUMERIC/JSON/INTERVAL source values and domains, plus per-surface SQL
  and migration checks. JSON runtime helpers retain native extraction semantics;
  native decimal expressions retain explicit precision, scale and rounding.

The [source contract](../../contracts/APPLICATION_SOURCE_V1.md) and
[SQL support matrix](../../contracts/application-source/SQL_SURFACES_V1.md) define
admission. Parser acceptance, compiler checks, runtime execution and selected
finite/Lean comparisons remain separate evidence.

## Identities

The runtime-qualified implementation through `c0e2c8413fd0d4b47aff371a376ce90687642cc2` uses Zig
`0.17.0-dev.2267+48abf1a34`. Shared packages and the compiled-case host remain at
Transit `f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6`; the old compiler comparison
remains frozen at `e7434306334e3692c6f3e123cba0d278fa412196`.
The compiled-case definition is
`f311e893f8d2f4c21f426790172fadfebe7eb2364615eb1566c09f11d39bb0bb`.

Local runtime checks execute on x86_64 Linux. Runtime qualification used a development compiler
with SHA-256 `ee0714ce7e91073def9b8330acc0a9e0dfb9f0ef61709a416931a59259b46aa6`;
the final Nix package built at `7e57ba1-dirty` has SHA-256
`4006708eaad8cf7f8acfd5f6160ebca5773f2a29fffdd9706d1a5d1982a2cf3d`.
The host executable has SHA-256
`dca1534f2415beff2f6ecb6cb6eec77c3561433e818553a78c2b065ca9a39b79`.
Earlier increments have distinct compiler digests in their retained reports.
The report's actual revision/digest is never relabeled as a later documentation
commit. Working-tree dirtiness during qualification includes pending roadmap and
evidence changes; the shared executable was not replaced during runtime suites.

Commit `1093181` splits the callable isolation case and completes guide coverage.
The final compiler correction in `7e57ba1` rejects unsupported JSON source program
literals in unselected specialization arms too. Its regression and the complete
unit suite pass; it does not change emitted SQL for the positive runtime cases
above. Final compiler/source checks below include that correction. The older
runtime reports retain the executable identities they actually tested.

## Executed evidence

The [report manifest](results/typed-composition/manifest.json) retains exact
compiled-case reports, hashes, identities and outcomes, plus final local check
logs at `7e57ba1`. It includes failures and not-run cases. Installed summaries
retain only reviewed outcomes and example
rows; raw installation accounts/tokens/configuration stay outside the repository.

| Gate | Local result |
| --- | --- |
| Formatting, dependency/diagnostic ownership and mapping checks | Passed; 33 production owners, 440 owner/error pairs and 234 public diagnostic mappings |
| Compiler/workspace unit and allocation-failure tests | Passed |
| Empty-cache source build and public embedding consumer | Passed |
| Frozen compiler comparison | 12 cases passed with the existing identity/dependency-command exceptions |
| Nix compiler/install and ordinary compiled-case smoke checks | Passed on x86_64 Linux; other native systems were not executed locally |
| Release identity/promotion tests | 2 passed |
| Formatter process/filesystem checks | 42 source fixtures passed |
| Workspace journeys | Offline/fetch/lock/override, diagnostics, publication, migrations, typed resources and modular programs passed |
| Documentation coverage | 13 task mappings and runnable success/failure/correction paths passed |
| Test-host protocol boundary | 11 request refusals and 16 response/process refusals passed, including late completion, changed/missing host, timeout and joined cleanup |
| Handbook | Strict build/type checks and 84 browser checks passed at each of `/transitc/` and `/` |

The independent source grammar passed 251 cases, 177 formatter roundtrips and
10 negative controls. Typed checks retain 14 named Lean laws and 136 finite equalities,
16 typed/SQL comparisons, 21 program comparisons, two runtime-MATCH, four DATE,
five NUMERIC, three lossless-value, two cardinality, two symbolic-program, two
refinement and three callable comparisons, four refusals and 47 negative controls.
These are bounded checks under stated premises, not a proof of the entire compiler.
The explicit Nix source check retains the full input/output evidence at the store
path recorded in the manifest; CI uploads the equivalent evidence for its own
tested revision.

### Installed and isolated runtime results

The final dynamic journey passed generated closed-record MATCH and independently
authored SQL: both resource kinds (raw ID 7 in each), five malformed/absent/late
refusals, exact rows, source removal, restart and credential revocation. Native
UNION program consumption and CREATE VIEW refused with ProgramTypeMismatch and
UnsupportedStatement as expected. The isolated flat-encoding suite passed its
first three cases, then hit TestDeadline on the missing-active-payload case; its
remaining cases and the subsequent dynamic suite were not run by that invocation.
Earlier isolated dynamic failures remain local evidence, not a passing gate.

DATE Table values, boundaries and SQL NULL passed the independent SQL/restart
journey and one isolated case. The final scalar journey passed exact wide decimal,
JSON and signed interval cells, independent SQL, source removal and restart.
Its scalar case and decimal-operator case passed in isolation. DECIMAL_ADD with
REJECT and DECIMAL_RESCALE with HALF_EVEN preserved exact results and SQL NULL;
Inexact and Overflow remained explicit failures. Guide mistakes refused before
artifact publication.

JSON helper transport/extraction passed generated and independent SQL: three
accepted requests and three refusals per implementation, unchanged effects on
refusal, source removal and restart. Both isolated cases passed. JSON_INTEGER
preserved the wide integer; JSON_VALUE preserved boolean text. Missing members
and JSON null deliberately project to SQL NULL, while the original payload
retains the distinction. SQL NULL input, fractional integer conversion and i64
overflow refused.

ONE and OPTIONAL both passed the installed generated/independent SQL journeys,
source removal and restart. ONE accepted the present row with a NULL field and
refused absent/multiple rows and late failure. OPTIONAL distinguished the absent
row from the present NULL field, accepted both, and refused multiple rows/late
failure. Unguarded optional projection refused before publication. The isolated
cardinality suite passed all four ONE cases and OPTIONAL's present-NULL case,
then hit TestDeadline on the absent optional row. The two later cases were not run.

The installed refinement journey passed one accepted request and four refusals
for each of generated and independent SQL, including lower/upper bounds, SQL NULL
and a failed postcondition after a staged append. Both Streams retained exact
contents after refusal and restart. Its combined isolated case hit TestDeadline;
a focused Queue/Stream version also hit that limit in a separate retained run.

The installed callable journey passed two explicit generated instances and the
independent SQL oracle. Each accepted one request and refused two, with exact
Table/Stream rollback, restart and current-rights denial after credential
revocation. Its original combined isolated case hit TestDeadline; the later case
split keeps the complete installed journey and focuses isolation on the imported
returning callable and its Stream rollback. Both the final callable probe and the
final refinement probe still hit TestDeadline. These failures are not passes.

## Remaining gates

The [runtime handoff](../roadmap/05-runtime-handoff.md) specifies operations,
representations, bounds and acceptance tests for bounded many, state-carrying
program values, DATE/NUMERIC/INTERVAL program values, symbolic JSON/INTERVAL Table
parameters, broader relational operators and views. Native union consumption
still refuses; the compiler's closed STRUCT representation is a separate profile.
Views remain required for full M5 closeout unless the milestone scope is explicitly
revised. No runtime implementation or pin update is hidden in this compiler PR.

Whole-input ROW helpers combined with symbolic scalar holes still need compiler
work. General refinement implication, callable row/many returns and implicit
signature subtyping are outside the delivered bounded profile. Runtime tests that
miss their 30-second case or five-minute suite deadlines stay failures. Installed
success does not discharge the isolated completion gate.

Four native compiler/archive jobs require GitHub Actions on this PR; their
results must be recorded before claiming native-host closeout. The earlier
[extraction record](extraction.md) is baseline evidence, not a substitute for
executing the changed compiler on those hosts.

## Reproduce

```sh
nix develop --command just check test::unit test::grammar test::types
nix develop --command just test::clean-build test::release test::fmt test::documentation test::workspace test::examples
nix flake check --print-build-logs
nix build .#checks.x86_64-linux.source --no-link --print-build-logs
nix develop --command just test::integration test::build-command test::command
nix develop .#docs-browser --command just docs::install docs::check docs::browser
nix develop .#docs-browser --command env TRANSITC_DOCS_BASE_URL=/ just docs::browser
```

The integration task stops on its first failure. Individual drivers under
`tests/integration` retain their evidence beneath `.cache/checks`; run them
through `tests/runner/launch.py` with a fixed compiler executable when investigating
a later case. Keep deadlines, assertions, isolation and current-rights checks.
