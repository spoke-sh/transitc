# Runtime nominal variant dispatch

Imported `Target` has Machine and Site constructors with distinct nominal IDs,
both physically BIGINT. The Queue carries a closed STRUCT with a canonical
lowercase tag, one nullable record per constructor, and non-null scalar payload
fields. Runtime MATCH validates exactly one active payload before exposing its
nominal field bindings. It does not authenticate the origin of a raw integer.

Both resources contain ID `7`. Seven isolated cases check both dispatch paths,
unknown tags, missing active payloads, populated inactive payloads, lookup refusal
and rollback after a write. Every refusal asserts both empty result Tables and an
empty output Stream. The Queue may accept a malformed tag/presence combination;
its consumer refuses before application effects. Physical type errors are owned
by ordinary Queue admission.

`expected.sql` is independently authored ordinary SQL. The integration runner
executes it and source-free compiler output against separate real installations,
checking complete rows, restart and current-rights denial. Type/grammar checks
also reject swapped source domains, missing/duplicate arms and malformed unused
bodies. The checked projection and finite independent comparisons retain domains
and ordered validation; artifacts contain no executable type sidecar.

Each isolated case seeds only the rows its premise needs. Both successful cases
retain raw ID `7` in both resources. The populated-inactive-payload case retains
the selected resource, so removing input validation would incorrectly complete.
The installed default target always seeds both resources. This avoids unrelated
setup work within the unchanged compiled-case deadline.
