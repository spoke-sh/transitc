# Source language

The [current source contract](https://github.com/spoke-sh/transitc/blob/main/contracts/APPLICATION_SOURCE_V1.md)
and [independent grammar/corpus](https://github.com/spoke-sh/transitc/tree/main/contracts/application-source)
own the supported `.transit` profile. The compiler was extracted from Transit
`e7434306334e3692c6f3e123cba0d278fa412196` without a language cutover.

The profile includes typed modules and interfaces, constructors, nominal domains
and variants, recursive bounded composition, child build modules, declared targets,
concrete schema binding, restricted reference exports, typed SQL holes, ordered
Queue programs and pure function/guard/atomic procedure lowering. Scalars include
UUID, TIMESTAMPTZ and BINARY, and helpers support ROW parameters. Reference handles
do not escalate privileges. NOT ENFORCED foreign keys retain catalog dependencies.

Generated statements are checked by Transit's shared SQL frontend and reparsed
against an independently built catalog. Parser acceptance does not imply runtime
support outside the exact supported target profile. Compilation grants no rights.
The SQL grammar remains Transit-owned and pinned separately for verification.

Default compiler limits are 256 files, 16 MiB aggregate source, depth 64,
100,000 work units, 64 MiB compiler memory and 8 MiB SQL output. Statement-specific
SQL limits and individual syntax bounds also apply. The CLI workspace has a
256 MiB tooling budget and a 64 MiB provenance ceiling. Reducing a source graph or
splitting targets can address a limit; changing a constant does not establish
qualification of a larger workload.

Test targets compile through the same emitter into bounded typed cases/actions.
Runtime assertions, isolation and completion are provided by Transit's test host,
not by the standalone CLI. Finite grammar/type comparisons and Lean laws retain
explicit premises; they are not an unbounded compiler correctness proof.
