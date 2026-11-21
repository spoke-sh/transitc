# 5. Typed composition and executable SQL

Status: In Progress

Prerequisites: [compiler extraction](03-compiler-and-cli.md); each new emitted
operation needs its ordinary Transit SQL contract and executable owner.

Let authors compose a complete application from typed modules and inspect SQL
that runs independently of the source tree. This expands Transit's former M12
P0–P3 and completion-plan B.2b into compiler-owned delivery units. The
[roadmap index](README.md#source-and-ownership) records the extraction basis.

## Delivered foundation

The [source contract](../../contracts/APPLICATION_SOURCE_V1.md) covers recursive
constructors, module interfaces and instances, delegated targets, concrete schema
binding, nominal scalar domains, compile-time variants and exhaustive matching.
Public Table/Stream/Queue handles and restricted reference exports have explicit
types. Pure functions, ordered guards and hygienic atomic procedures, including
value-returning calls, lower through the production SQL frontend.

These are bounded source features. Compile-time matching does not establish
dynamic dispatch, source visibility does not establish runtime-private storage,
and reference-only exports do not grant row access. The independent grammar and
selected Lean/SQL comparisons cover the admitted profile; they do not prove the
whole compiler correct. The remaining units below are proposals.

## Delivery units

| Unit | Contract and implementation | Acceptance |
| --- | --- | --- |
| 5.1 — Dynamic representations | Specify runtime variant tags/payloads, nominal identity, external-input validation and compatible SQL encodings before adding syntax. Extend symbolic program specialization. | A command selecting either of two resource kinds rejects wrong IDs, invalid tags and missing arms; raw SQL inputs receive the same required runtime validation. |
| 5.2 — Cardinality and refinements | Distinguish one/optional/many rows from nullable values and the five cell states. Admit a bounded refinement subset with explicit proof or runtime-validation obligations. | Empty/multiple results, NULL, missing, type errors, conflicts and invalid refinements preserve exact errors and evaluation order through lowering. Unknown obligations reject. |
| 5.3 — Behavioral composition | Extend typed query/predicate/command constructors and callable module interfaces. Track resource bindings, effect signatures and pre/postconditions through higher-order arguments. | Imported and nested helpers cannot widen effects, erase authority requirements, duplicate argument evaluation or capture caller locals; repeated instances preserve explicit identity. |
| 5.4 — SQL and scalar coverage | Add reviewed scalar/composite types such as NUMERIC, JSON, INTERVAL and DATE, then views and additional declarations as their upstream owners permit. | Each type preserves collation, precision, nullability and errors; each declaration reparses/rebinds and executes without source. Unsupported declarations fail before publication. |

Start with 5.1's representation and independent test cases. Develop 5.2 against
that representation; 5.3 composes only admitted types/effects. Unit 5.4 proceeds
per operation, rather than waiting for every Transit milestone. Runtime closures,
unrestricted dependent types, runtime recursion and implicit parallel effect
dispatch remain outside these units; any extension needs a separate contract.

## Implementation boundaries

Keep syntax, source types, typed origins, working catalogs and lowering in
[transitc-compiler](../../packages/transitc-compiler/README.md). Its input is a
resolved graph; filesystem access, Git, time and database execution stay outside.
Reuse the pinned Transit SQL frontend for logical types, scalar semantics and
canonical statements. Do not create a second runtime SQL dialect.

Every language increment updates the source contract, independent ANTLR grammar,
positive/negative corpus, production parser, typed representation, diagnostics,
formatter and lowering together. Fully parse unused bodies and unselected
branches, retaining the contract's distinction between syntax checks and reached
semantic checks. Source/build/test stages remain distinct from runtime SQL.

Preserve function purity, ordered guard refusals and a procedure's single caller
transaction. External dispatch and observation waits remain outside inline atomic
procedures. Imports and inlining confer no privilege. Runtime module protection
belongs to [milestone 8](08-protected-workflows.md).

Use stable explicit object and domain bindings, independent of source paths and
import aliases. Separate logical types, semantic descriptors and physical codecs.
Budget whole-program graphs, recursion, specialization and output independently;
exhaustion must produce attributable failure without complete-looking artifacts.

Preserve compound SQL framing above 50 KiB with nested atomic, failure, IF, CASE
and FOR blocks as each form becomes executable. Internal semicolons must never
become migration-step boundaries. Keep source, statement, migration-file and
editor limits separate; new syntax cannot silently widen an upstream bound.

## Verification and documentation

For every unit, compare independent syntax/locations, normalized typed projections
and generated SQL with hand-expanded equivalents. Include malformed nesting,
precedence, quoted/commented holes, foreign nominal types, hidden effects, ordered
refusals, allocation failures and boundary exhaustion. Formatter idempotence and
comment/literal preservation accompany semantic round trips.

Use pinned ANTLR generation with warnings as errors, full input consumption and
exact ambiguity diagnostics on the corpus. Runtime SQL must reject source-only
forms. A clean corpus establishes neither global grammar unambiguity nor general
semantic correctness.

Extend selected Lean laws with explicit premises and audited axioms. Independent
finite comparisons and real SQL execution remain necessary even when model and
SQL generation share a typed graph. Keep parsed, checked, executed and proved
results distinct; missing evidence cannot pass.

Add guides for domain modeling, optional query results, reusable helpers and
diagnosing failed specialization. Each guide needs a runnable example, a deliberate
failure and its correction. Update the source reference and supported-type table
in the same change; proposed spellings are not tutorials.

## Completion

All four units have contracts and executed positive/negative evidence. The
two-resource command case works from source through ordinary runtime operations;
generated SQL preserves identities, cell states, ordered failures and current
authorization. Qualification names both compiler and runtime revisions and the
remaining unsupported profile. The broader application workload is closed in
[milestone 10](10-application-qualification.md).
