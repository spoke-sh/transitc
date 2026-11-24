# Composition completion qualification

This record follows the [typed composition qualification](typed-composition.md)
and the [milestone 5 implementation plan](../roadmap/05-typed-composition-and-sql.md#previous-slice-complete-the-existing-composition-profile).
The implementation is merged. Subsequent qualification is recorded in the
[bounded-result candidate](bounded-many.md): the missing baseline CLI gates
pass, and the current profile passes complete hosted integration and three
49-case schedules. The dated results below retain their original identities.
The original
deadline failures remain failures; diagnostic executions below do not qualify a
replacement compiler or host.

## Baseline investigation, 2026-11-21

[PR #5's run](https://github.com/spoke-sh/transitc/actions/runs/44948950220)
finished successfully: the compiler, four native archive jobs and handbook job
all passed. Its success does not erase the retained local failures.

The [baseline manifest](results/composition-completion/baseline-manifest.json)
fixes the original Nix compiler and Transit host identities. A sequential local
schedule passed both callable cases and four typed-Queue cases. The fifth
typed-Queue case and the first encoding, dynamic-dispatch, cardinality and
refinement cases exhausted the unchanged 30-second case budget. Later cases
remain explicitly `not_run` in the original reports.

The [single-case request](results/composition-completion/reproducer/case.json)
reduces the cardinality failure to ordinary SQL and typed expectations, without
the compiler or suite driver: three resources, one input, a nullable selected
field, an atomic Stream append, exact workflow counts and the exact result row.
It preserves the original authorization, activation, Queue lease and assertion
order. A fresh private directory containing this request can be passed to the
pinned host's private `__transit_test_case_v1` harness. This is a diagnostic seam,
not a public CLI command. Remove the owned directory after the process joins;
never publish its generated credentials or storage.

Direct executions of the unchanged saved request have both passed and exhausted
the case deadline. The latter rules out compiler scheduling as the owner of that
reproduction. An instrumented build of the exact pinned source also reproduced
the cardinality and refinement deadlines. The retained traces show successful
claiming, input loading, evaluation, atomic staging, acknowledgement, checkpoint
and settlement progress. They show no worker error before deadline cancellation.
Instrumentation was captured through a private wrapper; it is not a production
wire change and is excluded from qualification. Pending operation identities
were removed from published traces.

The failed wall-time syscall sample coincided with concurrent storage proof
work: 4,886 `fsync` calls accumulated 42.69 seconds across threads (8.74 ms mean),
and the host exhausted its 30-second budget. Linux I/O pressure samples and the
strict host response are retained under `results/composition-completion/contention/`.
The identical request and binary, under the identical wall-time tracing command,
passed in 17.83 seconds after the storage proof finished its active phase. The
completed case performed 7,996 `fsync` calls, accumulating 11.01 seconds across
threads (1.38 ms mean); I/O pressure at entry fell from 4.89% to 0.10%.
The unchanged exact row and workflow assertions passed. These paired results
are retained under `results/composition-completion/low-io/`.

This reproduction assigns deadline exhaustion to storage latency under competing
durable workloads, not a stalled Queue claim or compiler scheduling. It does not
establish that every older failure had that cause. Final qualification must run
without overlapping storage-heavy proofs; the aggregate composition runner itself
executes each independent phase sequentially. No timeout, authority check, lease
or durability setting has been relaxed, and no speculative runtime fix is claimed.

The five original failed case requests were then replayed once each, sequentially,
against the unchanged uninstrumented Nix host. Typed-Queue, flat encoding,
generated dynamic dispatch, cardinality and refinement assertions all passed in
13.58, 14.96, 18.54, 14.21 and 22.53 seconds respectively. The
[direct-control schedule](results/composition-completion/direct-controls/summary.json)
retains every result and I/O pressure samples; no case was retried inside that
schedule. These controls support the storage-latency diagnosis and preserve the
original SQL, but do not replace the required complete candidate schedules.


## Candidate checking changes

Transit candidate `8fcf3ca0ca4aeb2d39af6601f7462712a3b208fe` adds separate,
bounded scalar environments for program binding and Queue-predicate analysis.
Neither API adds fields to the authored Queue or invents values for unknown
scalars. Native installation and predicate compilation continue to reject
unresolved names. transitc uses these APIs while checking every specialization
arm and emits only the selected concrete program.

The independent source suite passes 58 symbolic-program comparisons, including
64-column whole-input ROWs, nominal field identities, nullable fields, imported
and nested helpers, callable arguments, and concrete SQL/fingerprint controls.
Boolean filter leaves, helper expansion, `AND`, `OR`, and `NOT` cover both variant
arms and both boolean values. The boolean cases exposed an intermediate
regression when parameter binding was separated before predicate validation;
they fail against that earlier compiler and pass against the corrected one.
Column-to-column and arithmetic acquisition predicates retain their native
refusals. The complete typed suite passes its 49 mutation controls.

Frontend package tests and the upstream 71 fast checks, 20 contract checks, and
locked handbook gate pass at this candidate. The first clean storage/query lane
was stopped after 12 completed tasks because its source revision was superseded
by the predicate fix. Its partial evidence is retained and is not a lane pass.
The replacement clean lane at `8fcf3ca0ca4aeb2d39af6601f7462712a3b208fe`
passed 17 tasks, then failed `test::station-transaction`: its `calls` subprocess
exceeded the existing 180-second limit. The remaining 14 tasks did not execute.
The failed checkout and private fixture are retained locally. Server logs show
successful requests continuing up to the deadline, and a separate SDK storage
campaign overlapped this run. These observations do not by themselves assign the
failure to contention or qualify the lane. The native timeout and assertions are
unchanged; this failure remains open pending its owning investigation.
A fresh-fixture diagnostic selecting only `calls` reproduced the timeout under
`strace -f -c -w`. Its 23,746 `fsync` calls accumulated 215.62 seconds across
threads (9.08 ms mean), with sustained host I/O pressure. The
[Station diagnostic summary](results/composition-completion/station-timeout/summary.json)
retains binary identities, the original clean-lane inventory and syscall/pressure
samples. This selected, traced run is diagnostic evidence, not qualification or
a complete Station schedule. After the competing durable SDK phase ended, one
matched fresh-fixture comparison with the same binaries, tracing, assertions and
deadline passed in 96.97 seconds. It completed 29,019 `fsync` calls at 2.63 ms mean
wall time (76.22 seconds summed across threads). Together these results support
storage contention as the cause of this reproduced timeout. The full clean lane
still requires a passing execution; neither traced diagnostic substitutes for it.

At compiler revision `0fa5e0bde3a9e28bdf54d91245132144af483038`, the exact
candidate Nix package and all four local x86_64-linux flake checks pass. Explicit
source verification passes 253 grammar cases, 179 round trips, 10 grammar
negative controls, the 58 symbolic comparisons and the full type suite. The
portable x86_64-linux-musl archive, formatter/workspace/documentation consumers,
three aggregate-runner controls, strict handbook build and 84 browser checks at
each base path also pass. Compiled-case boundary checks pass 11 request refusals,
16 response/process refusals, late completion and joined cleanup against the
candidate host. Runnable handbook examples pass; the source-free SQL/restart
comparison separately uses the frozen old backend.

The [complete build-command schedule](results/composition-completion/candidate-build-command.log)
also passes with this compiler and candidate host. It executes generated and
independent ordinary, typed Queue and modular Queue SQL, migration recovery,
module-instance/delegated targets, six-schema dataflows, retained restart and
current-rights revocation. This installed schedule does not replace the pending
isolated test-command or composition schedules.

Full candidate qualification is still pending: the clean upstream lane, remote
archive/empty-cache admission, installed composition phases, the three complete
42-case isolated schedules, and the final CI/native-archive matrix. Earlier
whole-row runtime checks against the preceding candidate do not
substitute for these final gates. Milestone 5 remains in progress.

## Publication refresh, 2026-11-23

Transit main advanced to `9e68d9dcfba5a03b368045279b9f706d1b3ba789` before
publication. Candidate `b58715bf4ef4e5236748547ce15e37a602c4b471` merges that main
revision and resolves the generated archive conflict by regenerating all 196
authoritative source files. The scalar-analysis API changes are unchanged.
The archive downloaded from its published immutable URL matches
`sha256-bF7LJoomnA+QCkZDkf76WU35vm7xIWAxVgNRBTx1rQ0=`.

The compiler's shared distribution and test-host pins move together. This also
adopts upstream's committed Queue effect-admission definition
`ad3bc9aef1bc97a05c8a1ce5ea511a1d5185ebbb00f256eeec1ef287517e83ff`.
The frozen old compiler remains unchanged; parity requires its exact old
definition and this exact new definition before comparing the remaining fields.

The passing checks above retain their original compiler/host identities; they
are not passes for the refreshed pair. At publication, new qualification was
pending and the PRs were drafts while the upstream dependency and required gates
were open. Their subsequent merge and qualification status are recorded below.

## Merge and CI review, 2026-11-23

[transitc #6](https://github.com/spoke-sh/transitc/pull/6) merged at
`b914de44bb596e6df4940120e4c583a8bf9ba101` and
[Transit #479](https://github.com/spoke-sh/transit/pull/479) merged at
`6201f4d5ffc5b1849888b396cc75503f10f073f2`. The shared archive and host remain
pinned to their included `b58715bf4ef4e5236748547ce15e37a602c4b471` revision.
The upstream API merge requirement is satisfied.

At the next-slice planning review (18:06 UTC), [transitc PR CI](https://github.com/spoke-sh/transitc/actions/runs/45230348359)
had passed all four native compiler/archive jobs and the handbook job, including
both browser base paths. Its compiler job had passed the initial Nix checks and
explicit source grammar/type verification and was running `check test::release`;
the clean-build and process/integration steps had not yet executed. The
[upstream PR CI](https://github.com/spoke-sh/transit/actions/runs/45229910032)
storage/query job was still running. Both
[transitc merge CI](https://github.com/spoke-sh/transitc/actions/runs/45232864531)
and [Transit merge CI](https://github.com/spoke-sh/transit/actions/runs/45232786514)
were in progress. This is a dated observation, not their eventual conclusion.

The three complete local 42-case isolated schedules are still unrecorded. The
refreshed pair's complete installed composition, build-command and test-command
schedules and upstream clean storage/query lane also need final passing evidence.
The earlier failed lanes and diagnostic controls remain under their original
revisions. The [next slice plan](../roadmap/05-bounded-many-results.md)
starts with these qualification obligations; merging has not turned them into
passes or closed milestone 5.
