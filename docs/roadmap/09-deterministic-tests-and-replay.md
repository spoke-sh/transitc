# 9. Deterministic tests and replay

Status: In Progress

Prerequisites: [test command extraction](03-compiler-and-cli.md), a compatible
Transit compiled-case host, and each operation exercised by a new control.
Protected cases need [milestone 8](08-protected-workflows.md); replacement
schedules need [milestone 7](07-migrations-and-definition-evolution.md).

Let authors test the same modules they build, control time and external outcomes,
and inspect bounded failure/recovery schedules without containers or listeners.
This expands former M12 D6/P5 and completion-plan G.

## Delivered foundation

`transitc test` compiles the complete selected suite through the production
emitter, then sends bounded cases to a compatible Transit host. The
[test-host contract](../../contracts/TEST_HOST_V1.md) and
[testing guide](../handbook/guides/testing.md) describe isolated Table and Queue
program assertions, typed rows/counts/refusals, limits and cleanup. Compiler-side
validation is distinct from database execution.

Subject controls, virtual clocks, mocks, property generators and automated replay
sweeps are proposals. In particular, `--verify-replay` is not an available option.

## Delivery units

| Unit | Source/tooling contract | Native evidence required |
| --- | --- | --- |
| 9.1 — Subjects and grants | Compile explicit test identities and grants into typed test controls; describe authority changes independently from SQL data. | Denied operations and mid-schedule revocation use real permission checks. Cases cannot leak credentials or grants into one another. |
| 9.2 — Virtual time | Define clock ownership, scheduling order, deterministic seeds and explicit advancement, with bounded pending work. | Exercise expiry, leases and deadlines through the real scheduling owner without wall-clock sleeps or bypassing fencing. |
| 9.3 — Effects and observations | Add bounded scripted/matched sink and observation responses, typed assertions and dispatch counts, including timeout/unknown outcomes. | The actual effect/continuation path consumes controls; unmatched scripts fail, unknown outcomes preserve reservations and replay does not redispatch. |
| 9.4 — Fault and replay sweeps | Specify interruption points, retained snapshot identity, trace format, replay selection and reporting before adding an option. | Sweep admitted atomic, dispatch and observation boundaries; compare independent state/effect projections before/after interruption and replacement. Preserve original known outcomes and unresolved uncertainty. |
| 9.5 — Property schedules | Define bounded generators, deterministic seed replay, shrinking and coverage accounting for admitted operations. | A minimized failure replays against the same native owner and identities; shrinking never changes authorization, accepted tokens or the meaning of unknown outcomes. |

Begin 9.1 when the authority contract is available. Add 9.2/9.3 per native owner,
then build 9.4 on those controls. Unit 9.5 must preserve reproducible failures;
random successes cannot substitute for explicit required schedules.

## Host and process boundary

The compiler owns test syntax, products and source attribution; the workspace
owns orchestration, compatibility, timeouts and reports. Transit owns isolated
databases, native clocks/effects and execution. Controls never enter deployable
SQL or create a second database interpreter in transitc.

Evolve the shared current-v1 host definition deliberately with exact pins and
both consumers' fixtures. Reject mismatched definitions, malformed/oversized or
truncated requests/responses, missing cases, duplicate results and unexpected
process exits. Preserve separate input, per-case action/time, allocation and
temporary-storage bounds. Cancellation and timeouts must join work and clean up
owned state; a partial response cannot become a passing suite.

## Evidence and documentation

Extend existing test-command/host-boundary suites with each control and failure
case. Execute generated SQL through ordinary owners, independently check rows,
counts, dispatches and retained receipts, and record source/compiler/runtime/host
definition/seed identities with results. Temporal-model counterexamples must
replay at stated finite bounds; Lean obligations retain explicit premises.

Publish complete tests for refusals, timeouts, grant changes and uncertain effects,
then a failing replay case with its inspected trace and correction. Explain that
simulation covers declared schedules; physical durability, real providers and
external idempotency require their own integration evidence.

## Completion

All controls have contracts, real-owner execution, bounded work, deterministic
replay and failure/cleanup coverage. The protected admission/capacity cases and
replacement policies run through the production emitter. Reports distinguish
passed, failed, unsupported and incomplete work; missing schedules or unresolved
faults do not count as passing qualification.
