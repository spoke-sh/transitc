# 8. Protected workflows and runtime integration

Status: Planned

Prerequisites: [typed composition](05-typed-composition-and-sql.md) and reviewed
Transit catalog, serving and managed-execution contracts for each admitted
operation. Tests join [milestone 9](09-deterministic-tests-and-replay.md).

Let applications expose typed operations over private state, settle capabilities
on every path and handle protected values and uncertain effects explicitly.
This extracts former M12 P1–P3 and completion-plan D/E. Existing source visibility,
reference-only Table exports and public Queue programs are the starting point;
they do not establish the protected runtime profile planned here.

## Contract-first sequence

1. **Runtime module boundaries.** Agree how an ordinary public operation reaches
   private storage under current caller rights, how module ownership is recorded
   and validated, and how direct SQL is denied equivalent unauthorized access.
   Compile interfaces and explicit stable bindings to that contract. Imports,
   `PUBLIC` source exports and inline helpers cannot manufacture grants or bypass
   native checks. Preserve foreign-key-only references without row disclosure.
2. **Typed declaration profiles.** Specify reusable SOURCE/SINK/PUBLICATION option
   profiles, explicit overrides and conflict/unknown-key errors. Emit concrete
   ordinary declarations and retain profile provenance. Runtime settings and
   secret references remain references; build evaluation never reads deployment
   credentials or freezes their private values into SQL. Enable each declaration
   only after its Transit owner provides executable syntax and lifecycle checks.
3. **Effects and capability settlement.** Carry reads, writes, enqueue/produce,
   dispatch, time/random inputs, protected disclosure and transfers through
   signatures and control flow. Check every branch, refusal and failure handler
   for missing or duplicate settlement of capability/operation handles. Pure
   helpers cannot hide effects and atomic procedures cannot dispatch externally.
4. **Protected information flow.** Track secrets and protected derivatives through
   explicit and control-dependent flows in the admitted profile. Only approved
   commitment/challenge operations yield public values; bearer/cookie encodings
   retain their sink restrictions. Reject raw secret persistence, queue/stream
   payloads and unprotected responses. Define diagnostic redaction too. Do not
   claim general timing/side-channel noninterference from these checks.
5. **Transitions and lifecycle ordering.** Check admitted pre/postconditions and
   named invariants over authoritative state. Preserve exact object, definition,
   generation and operation bindings on evidence, including dynamic validation
   of external inputs. Model success, refusal and unknown branches explicitly.
   Lower transitions into native transactions and verify authorization/activation
   dependencies before an inbound source can admit work.

This is a compiler delivery sequence. Runtime ownership/privacy must be agreed
before source promises protection; current authorization must be rechecked at
execution, effect, suspension and commit boundaries. Static settlement alone
does not establish durable exactly-once processing or provider idempotency.

## Upstream handoffs

Transit [M12](https://github.com/spoke-sh/transit/blob/main/docs/roadmap/12-application-modules-compilation-and-testing.md)
tracks the integration boundary. Its M5/M6 owners supply atomic state/output and
Queue settlement; M13 supplies Station-independent serving and publication;
M14 supplies managed execution, effects and continuation recovery. Broader
identity/secret/disclosure capabilities join from M29/M30 only where required.
Do not gate basic publication on completion of those entire milestones.

A handoff names exact contract/definition IDs, ordinary SQL operations, supported
types, current-rights enforcement, resource limits and executed failure/recovery
evidence. Update the pure dependency pin and compatible host together where
required; Transit must not acquire a reverse dependency on this compiler.

## Synthetic cases and acceptance

| Case | Required observations and negative controls |
| --- | --- |
| One-use request admission and continuation | Two competing callers cannot both consume the request; claim, enqueue and handoff preserve one atomic decision. Exercise revocation, interruption, duplicate settlement and unknown effects without redispatch on replay. |
| Bounded-capacity admission | Ordered guards and exact revision/operation bindings prevent oversubscription under concurrent admission. Removing a guard must fail the intended invariant; stale evidence and interrupted reservations remain visible. |
| Private module operations | Exported procedures can perform only admitted operations under current rights. Direct SQL, forged ownership and reference-only reads/mutations reject without leaking private rows. |

Use small independent temporal models for races and recovery, selected Lean laws
for ordered lowering/transitions, and native trace replay with explicit projections.
State finite domains, fairness premises and incomplete exploration. Parser errors
are not successful negative controls. Model evidence does not replace native
authorization, transaction or provider qualification.

## Documentation and completion

Publish source guides for module interfaces, protected inputs, failure branches
and observing uncertain operations only as the corresponding runtime profile
lands. Include denied direct SQL and stale-authority examples. Runtime security,
activation and recovery usage stay linked to Transit's owning reference.

Complete when all five units and three cases have static, negative, native and
appropriately scoped formal evidence. Unsupported effects, proof obligations or
runtime capabilities must reject before producing deployable artifacts.
