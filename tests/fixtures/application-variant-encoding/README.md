# Dynamic representation probes

This fixture uses only the existing source profile and independently authored
ordinary SQL. A request chooses Machine or Site at runtime; both resources hold
raw ID `7`. Explicit tag/payload validation runs before either branch can write.

The seven isolated cases cover both kinds, unknown tags, an absent active payload,
a populated inactive payload, a missing resource and refusal after a staged
write. They assert exact Table and Stream rows, including no surviving effects
on refusal. Queue admission succeeds before these processing refusals.

`expected.sql` is a hand-authored execution oracle. The installed journey runs
without compiler source, checks both kinds and malformed ordinary SQL inputs,
then checks retained rows after restart and current-rights denial.

The integration runner also records that the pinned host accepts a union-typed
Queue but rejects its ordered program with `ProgramTypeMismatch`, and rejects
`CREATE VIEW` with `UnsupportedStatement`. Logical type availability alone does
not qualify either execution surface. Native union dispatch and view DDL need
upstream work. The scalar tag/payload probe establishes the ordinary runtime
operations used by the nested-record encoding of runtime source MATCH.

Both declarations use an explicit 120-second Queue lease for the installed
durable journey. Test case and suite timeouts retain their existing bounds.
