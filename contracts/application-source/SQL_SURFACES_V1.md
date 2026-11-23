# SQL surface qualification v1

The surface evidence below was established with Transit
`f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6`. The shared frontend and compiled-case
host now pin `73ae483f9073c30b89b3ec90dc67595467a60f44`; the
[bounded-result record](../../docs/qualification/bounded-many.md) tracks
qualification of that refreshed pair separately. A logical type appearing in the
frontend does not admit it everywhere in the source language. The frozen old
compiler comparison remains at `e7434306334e3692c6f3e123cba0d278fa412196`.

| Type | Source values, parameters and domain bases | Ordinary resource DDL/literals and queries | Ordered programs/helpers | Compiled-case expected values | Migration products |
| --- | --- | --- | --- | --- | --- |
| BIGINT, TEXT, BOOLEAN, UUID, TIMESTAMPTZ, BINARY | Admitted | Qualified existing profile | Qualified public-data profile | Shared typed codecs | Existing bounded Table diff rules |
| DATE | Admitted, exact Gregorian day | Qualified DATE fixture | Refused by pinned schema/value owner | Exact DATE and SQL NULL fixture | Existing Table creation/add-column rules; no new conversion policy |
| NUMERIC | Explicit precision/scale literals, parameters and domain bases | Qualified native Table literal/projection fixture | Refused by pinned schema/value owner | Exact scalar and SQL NULL fixture | Creation/add-column descriptor tests; conversion changes refuse |
| JSON | Lossless literals, parameters and domains; no comparison traits | Native Table literal/projection fixture | Typed runtime arguments/results and native extraction; program literals unavailable | Exact scalar and SQL NULL fixture | Creation/add-column descriptor tests; conversion changes refuse |
| INTERVAL | Exact signed month/day/nanosecond components, parameters and domains | Qualified native Table literal/projection fixture | Native SQL interval unavailable; microsecond duration is a different type | Exact scalar and SQL NULL fixture | Creation/add-column descriptor tests; conversion changes refuse |
| Runtime variant record | Explicit `MATCH operand AS Variant`; closed scalar/domain payload profile | Ordinary STRUCT with required tag and nullable arm records | Qualified decoder and ordered IF lowering | Exact effects and refusals in dispatch fixture | No log/program replacement policy |
| Native UNION | Compile-time source variants are separate | Queue DDL probe accepts descriptor | Consuming program refuses `ProgramTypeMismatch` | No native program-value admission | Not qualified |
| Views | Not admitted | `CREATE VIEW` probe refuses `UnsupportedStatement` | Upstream dependency | Not available | Not available |

“Pending” does not change existing parser admission or claim execution support.
Every newly advertised surface needs an independent SQL comparison.

The NUMERIC/JSON/INTERVAL fixture qualifies direct Table projection. Adding
ORDER BY to the combined projection routes it through a native relational
profile that refuses `UnsupportedRelationalType`; this is retained negative
evidence. JSON equality and interval arithmetic/ordering are not qualified by a literal round
trip. The separate numeric-operators fixture qualifies DECIMAL_ADD with REJECT
and DECIMAL_RESCALE with HALF_EVEN, explicit result descriptors, NULL, Inexact and
Overflow. Other decimal operators remain outside that executed evidence.
NUMERIC literals must fit their declared precision and scale exactly; inexact
scale refuses `Inexact` and overflow refuses `Overflow`. Duplicate JSON keys
refuse `DuplicateField`. No intermediate float conversion is introduced. SQL NULL,
missing, type-error and conflict cells retain their individual owners; none is an
implicit optional-row or variant encoding. JSON must not acquire equality/hash/
ordering traits. SQL intervals must preserve months, days and sub-day components.

Queue declarations additionally admit the two explicit lease duration settings
specified by the [runtime variant contract](DYNAMIC_VARIANTS_V1.md#queue-lease-configuration).
Partitioning, destinations and broader policy/evolution remain outside this
increment. Ordinary views require upstream DDL, binding, execution, identity and
authorization before any dependent compiler surface can be admitted.

## NUMERIC source values

`NUMERIC(p,s) 'decimal'`, parameter `NUMERIC(p,s)`, `TYPE NUMERIC(p,s)` and
`CREATE DOMAIN Name AS NUMERIC(p,s) IDENTITY '...'` carry one exact descriptor.
Precision is 1–38 and scale is 0–precision. The shared binder parses a coefficient
without floating point, rejects overflow/inexact scale, and lowering writes the
coefficient at the declared scale. No input string is spliced into emitted SQL.
Zero has a canonical unsigned spelling. Descriptor matching is exact; no integer,
float, implicit rescale or foreign domain conversion is admitted.

Source comparisons use exact coefficients after descriptor equality. Nominal
values allow only same-domain equality/inequality. Arithmetic, explicit rounding
functions and NUMERIC program values remain separate, unsupported source
surfaces. Source identity hashing includes precision, scale and coefficient; it
does not change the hashing of preexisting types. The independent decimal checker
uses Python Decimal, and the installed scalar fixture compares source parameters
with independently authored ordinary SQL and exact wire coefficients.

## JSON and interval boundaries

The [source contract](../APPLICATION_SOURCE_V1.md#lossless-json-and-interval-source-values)
specifies exact bounds, decoded duplicate-key refusal and safe literal emission.
Concrete source parameters are compared with the same independent Table SQL and
wire cells used for literal qualification. Native prepared Table parameter binding
for these two types refuses `UnsupportedComparison`; compile-time MATCH does not
bypass that boundary. INTERVAL ordered-program values remain unavailable.

`application-json-helpers` separately checks JSON argument/result transport and
native JSON_INTEGER/JSON_VALUE extraction, including lossless wide integers,
JSON null versus SQL NULL, missing fields and invalid numeric conversion. Missing
members and JSON null both project to SQL NULL. Original JSON transport retains
the distinction; the projection deliberately does not. Program JSON literal holes
refuse before publication. Runtime qualification results, including any deadlines,
are recorded separately from compiler admission in the milestone qualification.
