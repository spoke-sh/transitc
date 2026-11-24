# Bounded many-row results qualification

Implementation and hosted qualification are complete. The paired changes are
[Transit #480](https://github.com/spoke-sh/transit/pull/480) and
[transitc #7](https://github.com/spoke-sh/transitc/pull/7); the native owner merges
first. This record keeps the merged
composition baseline separate from the bounded-result candidate. The
[implementation plan](../roadmap/05-bounded-many-results.md) remains the acceptance
inventory. Local deadline failures remain failed below; milestone 5 remains open.

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
The [native merge CI](https://github.com/spoke-sh/transit/actions/runs/45232786514)
also completed every selected runtime, interface, SDK and core job successfully;
its documentation-site job was skipped.

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
neither the native runtime nor any time budget. The standalone dynamic phase
passes against the frozen `b914de4` compiler / `b58715b` host using the corrected
driver from `69dc1f1`. Complete build-command and test-command checks also pass
against the frozen pair, closing the CLI checks that the earlier CI aggregate
never reached. Their outcomes are retained in the separate runtime-gate record;
they do not relabel the original failed local composition schedules below.

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
`d65f7c656c8e311806132ca894059b43b52051ee`. Review of persisted records found that
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
cleanup schedule. That pass precedes the mandatory-field corrections. The final
corrected clean results below qualify the later source; interrupted exploratory
clean runs are not passes.

All 28 clean core tasks pass at `ff7386ac665fb23891d36b096ff25dc10bdaac9f`,
including the complete native package check, 49 standalone package builds,
packaged runtime boundaries, SQL wire contracts, Station recovery, storage,
authorization and callers. The first clean installation lane passes Board and
strict handbook checks, then fails on stale generated Node validator digests.
`d65f7c656` regenerates both SDK digests; the owning Node checks pass. That commit
changes only those two digest files, so the native runtime/frontend code and the
completed core result are unchanged. At `d65f7c656`, all 24 installation/UI,
32 storage/query and 16 SDK tasks pass. The final managed proof includes bounded
iteration, selective/cumulative budgets, changed-basis refusal and the existing
lost-reply, restart, cancellation and cleanup schedule. The original failed
installation attempt remains retained.

The complete console gate also passes every startup, latency and memory budget
at clean `d65f7c656`: Document/KV/Stream write metrics are 88/93/90 ms, peak PSS is
1,243,001,856 bytes and memory growth is 1.0955. This uses the unchanged budget
file and shared local host, without overlapping local qualification campaigns.
It does not establish a matched performance improvement. The native
[qualification history](https://github.com/spoke-sh/transit/blob/ec5bb00a9ad4a5a2bd1a4807ae98003c7ed3ed21/docs/history/qualification/runtime.md)
retains exact source identities, report locations, hashes and limits.
[Transit #480](https://github.com/spoke-sh/transit/pull/480) contains the native
implementation and documentation. Its final documentation commit also passes
all 71 fast checks, locked handbook installation and strict handbook checks.

Native [PR CI](https://github.com/spoke-sh/transit/actions/runs/45327605081),
[release-distribution checks](https://github.com/spoke-sh/transit/actions/runs/45327605165)
and the [handbook workflow](https://github.com/spoke-sh/transit/actions/runs/45327605079)
also complete successfully at review head `ec5bb00a9`. Every selected CI job passes;
publication and release qualification remain skipped where the workflows require
a release or main-branch event.

Native frontend, Fuze iteration/environment and query-direct application unit
tests pass, including partial-allocation failures, stale completions, forged
iterator lengths, empty loops, first ordered refusal and cumulative read-budget
controls. The handwritten installed SQL journey passes empty/one/several/exact/
excess bounds, nullable fields, duplicate payloads in exact key order, late
rollback, process restart and retirement. The 71 fast checks, 20 contract checks
and strict handbook build pass. The selected clean runtime lanes are recorded
above; they are not a complete native release campaign.

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
`827dcab443d80d932d4458ae13d94b08ec819fbf` and the final predicate correction at
`c8d680799889767d916ac1ea38987b1acb0bc8d9`. The latter retained output is
`/nix/store/04a2ankbhqz66yzc6f3b3khd2cakfhsz-transitc-source-verification`.

The earlier immutable Transit package at
`73ae483f9073c30b89b3ec90dc67595467a60f44` builds successfully. Both its standalone
Nix build and the compiler dev shell resolve to
`/nix/store/cprylhnlim5zg9cvvk43mjxcbjzbv4fq-transit-0.0.1/bin/transit`, SHA-256
`9095fbc7755c8746675acc2045f66ff06438869249f09ad6d5e0d4d78fe26824`.
That host predates the mandatory-field corrections and is superseded for final
runtime qualification. That earlier shared archive has SHA-256 SRI
`sha256-bahP6fqkRg6/yFhJ5MpfsfDQgUlY1gkze6r6MdOaSnE=` and Zig package hash
`transit_sql_distribution-0.0.1-t9CQA2cRIwBqqqpd72UY1jZ01USaeMUq_7pGHYqeGlJi`.
The final pin's remote retrieval is verified separately below.

Fresh HTTP downloads verify the published `d65f7c656` frontend archive and source
independently of cached Nix retrieval. The archive has SHA-256 SRI
`sha256-HWbBkOjoR+xeIF7XolIajdTJ3jkqsXmWH1pzUAM6NBY=`; fetching it into an empty
Zig cache yields
`transit_sql_distribution-0.0.1-t9CQA2UWIwBbAG3g4rw2HdU9FM1kSbCoZCm1W2_LqLTz`.
The independently unpacked GitHub source has NAR hash
`sha256-1TWjNvpyhEWqAXafkgcY6e5/GZuoQsbszeAY6CnHTIk=`, exactly matching the lock.
The local retrieval report is `.cache/bounded-many/published-inputs/report.json`.

An exploratory installed comparison passed all 21 original cases (seven on each
of two generated instances and one independent SQL instance), including exact
order, nullable fields, overflow, rollback, restart and retirement. That run
predates the added explicit `MANY(4)` correction and used the exploratory native
binary; it does not qualify the final immutable pair or the extended 22-case
journey.

The final immutable compiler package builds and passes its unit and installed
CLI checks at `69dc1f173bf5bb2d0ecc6685b0fb246bd744be96`. Its executable is
`/nix/store/hx0bpmdl0ydcg549advcjp4c6blzy7xl-transitc-0.0.0-dev/bin/transitc`,
SHA-256 `2803e7aecb7b81028a2d054b574e47b232cbbc1c8db2bcb24a4ea7529d5be132`.
The final `d65f7c656` host is
`/nix/store/ab8y3wlv50aw1b9qr1pc0f1zhb0rjvp4-transit-0.0.1/bin/transit`,
SHA-256 `7b7a2adbf1e3e0b6b8fe34f31285ad83ff79c9b5cbed71797ad71e6d7d04f397`.
Upstream smoke, emitted SQL and composition controls pass against this pair.

The first candidate parity check fails because `ApplicationProgram.Select.many`
adds a nullable field to canonical instruction bytes even for existing singleton
reads. `ProgramCheck` hashes those bytes, and AUTHORIZE/ACTIVATE plans include the
program identity. All emitted SQL and source maps remain byte-for-byte equal.
Commit `c659d2d` records the twelve exact old/new plan hashes for the two typed
and two modular Queue instances. The corrected check passes all twelve fixture
and diagnostic comparisons and 24 artifact mutation controls against the same
immutable compiler. Foreign definitions, changed maps, unrelated plan hashes
and unexpected changes to reviewed hashes still fail. The original failed
phase and this supplemental result remain separate. No production code or
runtime budget changed to make this check pass.

All ten installed composition phases pass against the final immutable pair.
The [bounded-result journey](results/bounded-many/candidate/installed-many/evidence.json)
passes all 22 cases: seven on each of two generated instances and an independent
SQL instance, plus the explicit `MANY(4)` correction. It verifies exact order,
nullable rows, overflow, rollback, source removal, restart and retirement. The
sibling case records, generated/oracle/corrected SQL and hash manifest retain
the actual artifacts; this supersedes the exploratory 21-case run above.

The complete [three-pass local schedule](results/bounded-many/candidate/composition/evidence.json)
retains all 49 expected cases per pass:

| Pass | Passed | Failed | Not run | Expected |
| --- | --- | --- | --- | --- |
| 1 | 32 | 4 | 13 | 49 |
| 2 | 10 | 7 | 32 | 49 |
| 3 | 31 | 4 | 14 | 49 |

All 15 failures are `TestDeadline`; the 59 unrun cases remain unrun. Failures
occur in existing fixtures and in different bounded-row cases across the passes.
The [case summary](results/bounded-many/candidate/composition/summary.json),
unaltered reports and manifest retain the exact outcomes. Host-pressure samples
cover part of the isolated schedule and show I/O pressure, but no new matched
experiment assigns these failures to contention. Successful installed or hosted
checks do not relabel this failed local schedule.

The complete [local gate record](results/bounded-many/candidate/runtime-gates/summary.json)
contains all fifteen phases: thirteen pass, the original parity check fails, and
the composition aggregate fails on the isolated deadlines above. The separate
[corrected parity result](results/bounded-many/candidate/parity-supplemental.json)
does not rewrite that original record. Runnable examples, complete build-command
and test-command schedules, eleven request refusals and sixteen response/process
refusals all pass. These include source-free SQL, restart, revoked rights, late
completion, runtime identity and joined cleanup. Empty-cache compilation, unit
tests and the public embedding consumer also pass.

The installed portable `x86_64-linux-musl` archive passes its checks at `69dc1f1`.
Its [metadata](results/bounded-many/candidate/native-archive/transitc-0.0.0-dev-69dc1f173bf5-x86_64-linux-musl.json)
and [checksum](results/bounded-many/candidate/native-archive/transitc-0.0.0-dev-69dc1f173bf5-x86_64-linux-musl.sha256)
identify binary SHA-256
`dcfb70a69e57cdcb494a90cfeb884be9f16e0590b7c2bb0c9096a7a6f3e7916f`
and archive SHA-256
`7bb6d5467af30b11bc33c492d607a6770e784bcc83e98f367cfa9a0d14ad8b89`.
This portable executable is distinct from the Nix package identified above.

All four [platform archive CI jobs](https://github.com/spoke-sh/transitc/actions/runs/45333715699)
and its strict handbook/browser job pass at review head `dd38b8a`; the main
compiler job passes Nix flake checks, source correspondence, release controls
and clean-cache embedding, then is cancelled during the final integration/CLI
aggregate when the review branch advances. Commit `b5807de` adds three complete
isolated passes to hosted CI, using the same case inventory and unchanged limits.
Its [new CI run](https://github.com/spoke-sh/transitc/actions/runs/45338627390)
passes the complete compiler job: Nix checks, source correspondence, clean-cache
embedding, the full integration/CLI aggregate and three isolated passes. The
earlier cancelled aggregate is not recorded as a pass. In the new run,
the x86 macOS build, unit/embedding, installed archive and formatter checks pass,
but signing fails when GitHub's identity-token endpoint times out. The
[failure record](results/bounded-many/candidate/macos-attestation-failure.json)
retains that distinction. Signing remains required; GitHub permits a job retry
only after the containing workflow finishes. The retry of that macOS job passes
every step, including signing, signature/source verification, tamper refusal and
artifact upload. The [final workflow status](results/bounded-many/candidate/hosted/workflow-status.json)
retains the successful jobs alongside the original failure record. CI and the
handbook workflow both complete successfully.

The verified hosted artifact `14898414817` has ZIP SHA-256
`d72fe41606336a9db80bcf0f524e698ece60ad12fbe86a57f87cdcb7bc19435f`.
Its [summary](results/bounded-many/candidate/hosted/summary.json) and sibling raw
reports retain a separate 49/49 integration pass, all ten installed phases and
three further passes of 49/49 cases: **147/147** in the repeated schedule, with
zero failures or unrun cases. All case, suite and cleanup limits remain unchanged.
The hosted 22-case bounded-result journey also completes successfully.

The tested merge is `0cd8ca7473a26d78605d86a83721242ccf940ad1`; its Git tree
`e805adb181188a5e17fa15285df5722286b7e180` exactly equals review head `b5807de`.
The recorded production paths and composition fixtures/drivers are unchanged
from local compiler source `69dc1f1`. Every hosted case name and SQL digest equals
its local counterpart, and the generated/oracle/corrected SQL bytes also match.
CI uses compiler executable SHA-256
`3b01e8dbac89bd95f8f22316b427565a551d3b1da007e0f375be5c20b84ceb3d`
and host SHA-256
`298fa95ae2b563280cdd1ec55537d69a5ceddc9bd2d8ee0ddd4256bce6728349`,
with host revision `d65f7c656`. These executable hashes differ from the local Nix
pair. The source/SQL comparisons establish their stated correspondence; they do
not establish byte-identical binaries or a matched performance result.

All local runtime/package phases completed at the clean `69dc1f1` checkout.
Later review commits change parity expectations, the CI schedule and documentation;
they do not change compiler/runtime production code. Final local formatting,
dependency/diagnostic, compilation and strict handbook checks pass; relative
documentation links and retained evidence hashes are also verified. Milestone 5 remains in
progress, with state-carrying values, query-result callable contracts, remaining
scalar surfaces, views and final integrated qualification still required.
