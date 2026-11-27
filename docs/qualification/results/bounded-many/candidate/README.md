# Bounded-result candidate evidence

Local runtime qualification uses compiler `69dc1f173bf5bb2d0ecc6685b0fb246bd744be96`
and Transit `d65f7c656c8e311806132ca894059b43b52051ee`. The compiler checkout stays
clean and unchanged throughout the schedule. The top-level manifest records the
retained file hashes; package records identify the exact executables.

- `runtime-gates/` retains all fifteen phases and their logs. Thirteen pass;
  the original parity phase and the three-pass composition aggregate fail.
  Its first three phases use the separately identified frozen baseline pair.
- `parity-supplemental.json` and its log retain the corrected twelve-case parity
  comparison and 24 artifact mutation controls. Driver commit `c659d2d` runs
  against the same immutable candidate compiler. It does not rewrite the
  original failed phase.
- `composition/` retains the complete three-pass inventory, unaltered case
  reports, empty stderr files, summary and hashes. All 147 expected cases remain
  represented: 73 pass, 15 reach `TestDeadline`, and 59 are not run. Pressure
  samples begin partway through the first isolated pass; they do not establish
  a causal diagnosis. Full installed-phase operational logs remain in the
  original ignored run directory named by the summary.
- `installed-many/` retains all 22 passing case records, generated and
  independently authored SQL, the explicit bound correction, and the completed
  source-removal/restart/retirement result.
- `hosted/` retains the successful CI integration schedule (49 cases and ten
  installed phases), three additional 49-case passes, and the hosted 22-case
  bounded-result journey. Its summary verifies the artifact ZIP digest, tested
  merge/review tree equality, unchanged production scope and exact correspondence
  of local/hosted case SQL. Hosted executable hashes are recorded separately.
- `native-archive/` retains metadata and checksums for the passing local portable
  archive. The archive itself remains under `.cache/bounded-many/native-archive`;
  this local build does not claim a hosted signing attestation.

The published-input record verifies fresh archive/source retrieval. The macOS
failure record describes the later hosted identity-token timeout during signing,
after that job's build and tests passed. `hosted/workflow-status.json` records the
successful retry, including signature verification and artifact upload. See the
[qualification narrative](../../../bounded-many.md) for hosted outcomes and the
distinction between completed checks, corrected checks and outstanding gates.
