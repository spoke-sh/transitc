# Composition completion qualification

This record follows the [typed composition qualification](typed-composition.md)
and the [milestone 5 implementation plan](../roadmap/05-typed-composition-and-sql.md#next-slice-complete-the-existing-composition-profile).
The slice is in progress. The original deadline failures remain failures;
diagnostic executions below do not qualify a replacement compiler or host.

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
