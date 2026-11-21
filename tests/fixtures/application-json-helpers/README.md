# JSON helpers

Pass an ordinary runtime JSON value through a pure helper and an effect-checked
procedure. The installed comparison checks exact JSON_INTEGER and JSON_VALUE
projection, missing members, JSON null versus SQL NULL, fractional/overflow
refusals, unchanged Stream output, independent SQL and restart.

JSON_INTEGER accepts exact signed i64 decimal-integer tokens; decimal-point,
exponent, string and container inputs refuse. JSON_VALUE returns scalar text.
Both return SQL NULL for a missing member or JSON null, so these projections
intentionally lose that distinction. The original payload remains intact.
No source equality, ordering, source extraction or program JSON literal is added.

The compiled cases retain the standard 30-second/five-minute deadlines.
