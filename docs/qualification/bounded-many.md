# Bounded many-row results qualification

Implementation and qualification are in progress. This record keeps the merged
composition baseline separate from the bounded-result candidate. The
[implementation plan](../roadmap/05-bounded-many-results.md) remains the acceptance
inventory; a partial schedule does not close it or milestone 5.

## Merged composition baseline

The frozen compiler is `b914de44bb596e6df4940120e4c583a8bf9ba101`, with shared
frontend and host `b58715bf4ef4e5236748547ce15e37a602c4b471`. Its explicit Nix
package build and installed smoke suite passed before the retained schedule.
The older comparison compiler remains `e7434306334e3692c6f3e123cba0d278fa412196`.

The [Transit PR CI](https://github.com/spoke-sh/transit/actions/runs/45229910032)
completed successfully, including storage/query, core, installation, console
latency, interfaces, browser, callers and SDK lanes. Its tested merge revision
was `b67ebfe7c3e98cb893c79c4cd43364c4486942ac`, whose Git tree
`a07b741bcc8a2f86981ceed201ae90b5f986f831` exactly equals the pinned `b58715b`
tree. This is checked tree equivalence, not an assumption about PR head metadata.
The [retained storage/query tasks](results/bounded-many/baseline/baseline-storage-query-storage-query.json)
and [provenance](results/bounded-many/baseline/baseline-storage-query-feedback-storage-query.json)
come from artifact `14851208892`, SHA-256
`6303cbd6a5a7aed6ceefd78855eeae1603590f122e2ed13fa0a0f9e59d23211d`.

The [compiler PR CI](https://github.com/spoke-sh/transitc/actions/runs/45230348359)
passed all four native archive jobs and handbook/browser checks. Its compiler
job passed all 42 isolated cases and eight installed phases, but the standalone
dynamic installed phase failed with `ModuleNotFoundError: interfaces`.
Build-command and test-command later in the same aggregate were not reached.
The tested merge `4ba623a0236a4ab1434e42da8313cb866aeb00c7` and merged compiler
`b914de4` have identical tree `6678a9c38ca8f238f8a8c901b831a06c84ef28c3`.
[Retained composition evidence](results/bounded-many/baseline/baseline-compiler-ci-evidence.json)
comes from artifact `14851355903`, SHA-256
`a7992f411c802dc0e03504c749ed3afe1183200a75db7dd84cf1649b72348ce0`.
The [merge CI](https://github.com/spoke-sh/transitc/actions/runs/45232864531)
also passed all 42 isolated cases and failed that same import boundary.

Commit `c034b99` fixes the owning driver by initializing the pinned upstream
import root and phase recorder independently of the native phase. It changes
neither the native runtime nor any time budget. Its separate execution result
will be recorded with the completed candidate schedule.

The predeclared three local passes completed against the frozen pair, retaining
every failed and unexecuted case:

| Pass | Passed | Failed | Not run | Expected |
| --- | --- | --- | --- | --- |
| 1 | 24 | 4 | 14 | 42 |
| 2 | 23 | 5 | 14 | 42 |
| 3 | 16 | 5 | 21 | 42 |

All 14 executed failures were `TestDeadline`; no timeout was raised or discarded.
The nine installed phases yielded eight passes and the known dynamic import
failure. See the [unaltered schedule](results/bounded-many/baseline/evidence.json),
[case summary](results/bounded-many/baseline/summary.json) and sibling full case
reports. The schedule SHA-256 is
`14bc39fe2bf69e7dc8eb4cd7e008679d65236719e3308f6eec221df327437e46`.
Compiler executable SHA-256:
`3ce8183c0883884ed590937f9961aa957e7e93e0b4ecf4ffa2b29a988c4ee2fd`.
Host executable SHA-256:
`73bf349295b4d87ddfc7720865aa2d2a4881bdf4f6ab9f6e6d1929630c0efaed`.

These local schedules failed; successful CI does not relabel them. The earlier
[matched contention investigation](composition-completion.md) remains evidence
for its measured runs. This run shared the machine with other workloads and
native builds; no new matched contention experiment has been claimed.

## Bounded-result candidate

The current native definition is
`dd6352c075f480dabbc2d1349cc79c9a5c85687ecafd33055d6a2d56f28251d0`.
The compiled-case protocol stays unchanged. Shared frontend and host pins move
together; the old comparison compiler remains frozen. The paired native PR must
land before dependent compiler admission ships.

The final candidate now targets native
`ff7386ac665fb23891d36b096ff25dc10bdaac9f`. Review of persisted records found that
missing accounting and iterator fields could acquire zero defaults inside saved
candidates. Those fields are now mandatory, with positive round trips and explicit
missing-field refusal tests. Native program declarations already require canonical
decoding. A further predicate audit found database-observation calls outside the
MANY request accounting; the bounded profile now refuses these calls, including
unselected branches. The regenerated shared archive and host move together.

The clean core attempt at `735e0f4a1495ac8b44c5d2f2a073da0ae91baf67` failed on
a grammar corpus descriptor containing the previous definition. Commit `7ce191a43`
refreshes those inputs and the handbook fingerprint, and adds an explicit
prior-definition refusal case. All 783 public compiler grammar cases then pass.
The managed-runtime proof at `735e0f4a1` passes the new loop, selective scan,
cumulative budget and changed-basis assertions alongside the existing fault and
cleanup schedule. That pass precedes the mandatory-field corrections; final clean
qualification remains pending. Interrupted exploratory clean runs are not passes.

Native frontend, Fuze iteration/environment and query-direct application unit
tests pass, including partial-allocation failures, stale completions, forged
iterator lengths, empty loops, first ordered refusal and cumulative read-budget
controls. The handwritten installed SQL journey passes empty/one/several/exact/
excess bounds, nullable fields, duplicate payloads in exact key order, late
rollback, process restart and retirement. The 71 fast checks, 20 contract checks
and strict handbook build pass. Clean runtime lanes remain to be recorded.

Compiler/workspace unit tests pass (137 tests). Formatter coverage passes all
46 fixtures; documentation coverage, eight workspace journeys and both release
controls pass. Strict handbook validation and all 84 browser checks pass at each
of the root and `/transitc/` base paths.

Source correspondence passes 262 syntax
cases, 182 formatting round trips and ten negative controls. Typed correspondence
passes 14 existing Lean laws, 136 finite equalities, six new bounded-result
comparisons and 55 comparison controls. No new Lean theorem is claimed for
iteration, storage, authority or replay. Unselected-arm nominal checks and
callable-hidden-read refusals have separate executable unit coverage. The explicit
Nix source check repeats this complete correspondence schedule at compiler
`827dcab443d80d932d4458ae13d94b08ec819fbf`; its retained output is
`/nix/store/n3n1pjpinwhrzgi7dn89mbl6j10gjxmn-transitc-source-verification`.

The earlier immutable Transit package at
`73ae483f9073c30b89b3ec90dc67595467a60f44` builds successfully. Both its standalone
Nix build and the compiler dev shell resolve to
`/nix/store/cprylhnlim5zg9cvvk43mjxcbjzbv4fq-transit-0.0.1/bin/transit`, SHA-256
`9095fbc7755c8746675acc2045f66ff06438869249f09ad6d5e0d4d78fe26824`.
That host predates the mandatory-field corrections and is superseded for final
runtime qualification. The unchanged shared archive has SHA-256 SRI
`sha256-bahP6fqkRg6/yFhJ5MpfsfDQgUlY1gkze6r6MdOaSnE=` and Zig package hash
`transit_sql_distribution-0.0.1-t9CQA2cRIwBqqqpd72UY1jZ01USaeMUq_7pGHYqeGlJi`.
Remote retrieval remains to be verified after the native branch is published.

An exploratory installed comparison passed all 21 original cases (seven on each
of two generated instances and one independent SQL instance), including exact
order, nullable fields, overflow, rollback, restart and retirement. That run
predates the added explicit `MANY(4)` correction and used the exploratory native
binary; it does not qualify the final immutable pair or the extended 22-case
journey.

The final installed generated/oracle comparison, three-pass 49-case composition
schedule, CLI/runtime checks, clean-cache/public embedding, installed Nix package
and four-platform archive CI remain acceptance gates.
This section will be updated with actual completed outcomes and immutable
compiler/shared/host identities before submission.
