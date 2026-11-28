# Exact callable composition v1

A module parameter may be `FUNCTION OF name`, `GUARD OF name` or
`PROCEDURE OF name`, where `name` resolves to an existing checked helper used as
the signature prototype. Pass a helper reference, including an imported or
explicitly exported helper, as the argument. Helpers remain compile-time values;
no runtime closure, indirect dispatch or authority token is emitted.

The initial match is exact: helper kind, ordered parameter names/types, resource
column descriptors and nominal identities, declared return descriptor, ordered
pre/postconditions and refusal codes must agree. Guard/procedure prototypes and
arguments must declare `EFFECTS (...)`; pure functions have an empty effect set.
Effect order is immaterial. Parameter renaming, predicate implication, result
widening, implicit subtyping and extra permissions are not inferred. Callables
are direct module/interface parameters, not ROW members or helper parameters.

`EFFECTS` names resource parameters and ordinary operations: `READ`/`INSERT` on
Tables, `PRODUCE` on Streams, and `ENQUEUE` on Queues. `EFFECTS ()` is explicit.
Duplicates, unknown bindings and wrong resource kinds reject. The fully inlined
helper body is rebound against distinct synthetic resource parameters; its exact
set of resource operations, including every branch and nested call, must equal
the declaration. Unused permissions and hidden/captured resource operations
reject. Queries can use checked SELECT results in a guard or scalar-returning
atomic procedure. Read-only procedures also support the query results specified below.

Each invocation supplies concrete resource handles. An operation cannot migrate
to another same-shaped resource through aliasing or a nested helper: checking
compares bound resource identity, not just schema. Current runtime rights remain
required for those operations. The caller separately owns input-Queue acquisition
and authorization/activation. A static signature neither grants a right nor
certifies that it will remain available after revocation.

Call arguments use existing single-evaluation, hygienic inlining and scalar/domain
obligations. Nested procedures share the caller's transaction; returning through
a helper cannot escape a later refusal or commit staged effects early. Declared
pre/postconditions retain the [bounded validation contract](REFINEMENTS_V1.md).
Callable specialization retains graph, depth, work, memory and output bounds.
Recursive helper calls remain refused. Explicit resource names distinguish module
instances; source paths/import aliases do not become runtime object names.

The compiler checks every helper body, including unused implementations. Existing
helpers without explicit effects retain their prior direct-call behavior, but
cannot be supplied as guard/procedure callable arguments. Functions retain their
existing purity restrictions. No external dispatch is admitted.

Independent comparisons cover direct/imported/nested/higher-order calls, exact
ordinary SQL, two instances, hidden effect and changed-signature controls. The
installed fixture removes source, compares hand SQL, verifies Table/Stream
rollback through a returning helper, restarts and denies access after credential
revocation. A failed or timed-out isolated report is not a passing qualification.

## Query results

A procedure with explicit READ effects can return an ordinary query binding.
Declare `RETURNS ONE ROW(...)`, `RETURNS OPTIONAL ROW(...)`, or
`RETURNS MANY(n) ROW(...) ORDER BY key`. The result declaration lists the
projected column names in order, with their source types, nullability and
collations. A MANY result also carries its asserted bound and ordering key.
The compiler checks each descriptor against the query in the helper body and
again when matching a callable prototype. Calls inline once in the caller's
atomic block. An OPTIONAL result requires a whole-row presence check before
projection. A MANY result can feed the caller's bounded FOR directly.
