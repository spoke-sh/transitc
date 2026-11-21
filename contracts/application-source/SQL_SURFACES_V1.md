# SQL surface qualification v1

The shared frontend and compiled-case host are pinned to Transit
`f31673bbd0fa599c9d2bd98c2ceb47d328c19ae6`. A logical type appearing in that
frontend does not admit it everywhere in the source language. The frozen old
compiler comparison remains at `e7434306334e3692c6f3e123cba0d278fa412196`.

| Type | Source values, parameters and domain bases | Ordinary resource DDL/literals and queries | Ordered programs/helpers | Compiled-case expected values | Migration products |
| --- | --- | --- | --- | --- | --- |
| BIGINT, TEXT, BOOLEAN, UUID, TIMESTAMPTZ, BINARY | Admitted | Qualified existing profile | Qualified public-data profile | Shared typed codecs | Existing bounded Table diff rules |
| DATE | Admitted, exact Gregorian day | Qualified DATE fixture | Refused by pinned schema/value owner | Exact DATE and SQL NULL fixture | Existing Table creation/add-column rules; no new conversion policy |
| NUMERIC | Not admitted as a source parameter or domain base | Native descriptors/literals exist; surface qualification pending | Refused by pinned schema/value owner | Qualification pending | Qualification pending |
| JSON | Not admitted as a source parameter or domain base | Native descriptors/literals exist; surface qualification pending | Native kind exists; source helper type not admitted | Qualification pending | Qualification pending |
| INTERVAL | Not admitted as a source parameter or domain base | Native descriptors/literals exist; surface qualification pending | Native SQL interval unavailable; microsecond duration is a different type | Qualification pending | Qualification pending |
| Runtime variant record | Explicit `MATCH operand AS Variant`; closed scalar/domain payload profile | Ordinary STRUCT with required tag and nullable arm records | Qualified decoder and ordered IF lowering | Exact effects and refusals in dispatch fixture | No log/program replacement policy |
| Native UNION | Compile-time source variants are separate | Queue DDL probe accepts descriptor | Consuming program refuses `ProgramTypeMismatch` | No native program-value admission | Not qualified |
| Views | Not admitted | `CREATE VIEW` probe refuses `UnsupportedStatement` | Upstream dependency | Not available | Not available |

“Pending” does not change existing parser admission or claim execution support.
Every newly advertised surface needs an independent SQL comparison. SQL NULL,
missing, type-error and conflict cells retain their individual owners; none is an
implicit optional-row or variant encoding. JSON must not acquire equality/hash/
ordering traits. SQL intervals must preserve months, days and sub-day components.

Queue declarations additionally admit the two explicit lease duration settings
specified by the [runtime variant contract](DYNAMIC_VARIANTS_V1.md#queue-lease-configuration).
Partitioning, destinations and broader policy/evolution remain outside this
increment. Ordinary views require upstream DDL, binding, execution, identity and
authorization before any dependent compiler surface can be admitted.
