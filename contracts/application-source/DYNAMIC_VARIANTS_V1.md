# Runtime variant representation v1

This is the bounded runtime MATCH profile of
[Application source v1](../APPLICATION_SOURCE_V1.md). Compile-time constructors
and matches retain their existing semantics. Runtime MATCH belongs inside public
ordered programs and inline guards/procedures; it cannot select schemas, catalog
objects, exports or module definitions dynamically.

```sql
MATCH request.target AS ids.Target
  WHEN ids.Target.Machine(machine_id) THEN
    -- machine_id has the declared MachineId domain here.
  WHEN ids.Target.Site(site_id) THEN
    -- site_id has the declared SiteId domain here.
END MATCH;
```

The operand is an ordinary record expression. Evaluate it exactly once into an
inaccessible hygienic binding. Check its complete bound descriptor, validate the
runtime tag/presence combination, then expose lexical payload bindings only in
the selected arm. Every constructor occurs exactly once, with exact arity and the
same variant declaration. All arms are checked, including arms not exercised by
an input. Pattern binders cannot capture existing locals or module arguments.
All bodies are parsed even when their enclosing module is unused.

## Physical encoding and input validation

For `Target AS (Machine(id MachineId), Site(id SiteId))`, the record is:

```sql
STRUCT(
  tag TEXT NOT NULL,
  machine STRUCT(id BIGINT NOT NULL),
  site STRUCT(id BIGINT NOT NULL)
)
```

- `tag` is a required ordinary TEXT field. Its value is the normalized lowercase
  source constructor name, compared exactly by the ordinary program evaluator.
  Source name case changes are immaterial; constructor renames change tags.
- Every constructor has a nullable record field of the same normalized name.
  Exactly the selected record must be present; every inactive record must be NULL.
- Each arm record has exactly its declared scalar/domain fields, with non-null
  physical scalar types. Field names determine correspondence; declaration order
  never determines a tag. The whole input record may be nullable, but a NULL
  input fails validation.
- Extra/missing fields, incompatible physical types, nullable scalar payloads or
  conflicting existing domain annotations fail compilation. A constructor named
  `tag` cannot use this profile. Nested/recursive variants remain unsupported.
- Shared descriptor, program depth/node/argument and compiler work/output bounds
  apply. An otherwise valid source variant may exceed a runtime representation
  bound; compilation fails before publication. No limit is implicitly enlarged.

An ordinary SQL caller submits `STRUCT('machine', STRUCT(7), NULL)` or
`STRUCT('site', NULL, STRUCT(7))`. The runtime's Queue/Table operation checks the
physical descriptor. The generated ordered REQUIRE checks tag and active/inactive
presence and refuses with `InvalidVariant` before arm effects. Queue admission
can succeed before consumer processing refuses. This profile admits ordinary
scalar values and NULL arm records; it does not encode missing, type-error or
conflict cells as NULL or as a source variant constructor.

Domain annotations are source evidence. After descriptor and tag/presence checks,
payload bindings receive the domain declared by that variant arm. An existing
foreign domain cannot be rebranded. Raw SQL scalar inputs have no authenticated
domain of origin: if Machine and Site both contain ID `7`, an integer alone cannot
prove which the sender intended. Applications still perform selected-resource
lookups/guards when existence is required. Every runtime operation checks current
authority; matching grants no rights.

## Lowering, compatibility and limits

Lower MATCH to one LET, one ordered validation REQUIRE, and an IF for each arm.
The immutable tag and exhaustive unique arm table ensure one arm runs. Preserve
source arm order, argument evaluation count, source locations, guard order and
the caller's atomic boundary. Failure after a staged write rolls back the caller's
transaction. Runtime-private objects and external effects are outside this profile.

Nominal annotations stay in the checked compiler projection. The published SQL
contains the physical record, validation and branches and runs without source or
an executable sidecar. Shared SQL parsing, binding and definition fingerprints
remain authoritative. Tags are independent of import paths and aliases. Changing
a domain, tag, payload or record layout requires explicit definition/migration
review; this feature does not make log or program replacement automatically safe.

The native logical UNION was considered first. At Transit
`f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6`, Queue DDL accepts it, but an ordered
program consuming that Queue refuses with `ProgramTypeMismatch`. The explicit
record encoding uses existing executable operations. A future native UNION
encoding needs separate compatibility and runtime qualification.

## Queue lease configuration

`CREATE PUBLIC QUEUE` accepts `WITH (lease_duration = '120s',
max_lease_duration = '120s')`. Only these two string options are admitted in this
source profile. Ordinary Transit LogDdl binds duration units, rejects duplicate
options and validates the relationship between initial and maximum lease. The
compiler does not change runtime defaults. The bound millisecond values enter
resource, module-binding and program-dependency identities; equivalent units and
option order retain the same policy identity. Explicit defaults retain the frozen
default-policy identity. Log evolution remains outside the migration profile.

The installed dispatch journey declares a 120-second lease because durable
execution exceeded the default 30-second lease in qualification. This changes the
application declaration, not the compiled-case or suite timeout. Applications
must choose leases appropriate to their workload and retry behavior.

## Evidence owners

- `dynamic_test.zig`: nominal annotations, malformed shapes, exhaustive arms,
  hygiene, allocation failures and bounded compiler behavior.
- Independent ANTLR corpus and source formatter: syntax, locations, comments and
  semantic round trips.
- `application-variant-encoding`: ordinary SQL feasibility and execution refusals.
- `application-dynamic-dispatch`: imported runtime variants, both kinds with raw
  ID `7`, malformed external inputs, lookups, exact rows and atomic rollback.
- `tests/integration/typed_composition.py`: real compiled-case host, independent
  installed SQL, source-free execution, restart and current-rights refusal.

Finite checks do not prove the full compiler or runtime. The existing Lean laws
retain their original premises; compile-time selection laws are not a proof of
this runtime decoder.
