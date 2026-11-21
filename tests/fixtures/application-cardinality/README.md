# Explicit query cardinality

ONE and OPTIONAL read the same Table through the same native SELECT owner. Eight
isolated cases distinguish absent rows from present rows containing NULL, refuse
multiple rows in both profiles, and roll back a staged Stream append after a late
refusal. Runtime comparisons use separately authored `one.sql` and `optional.sql`.

The default and optional build targets declare 120-second leases for installed
execution; isolated tests explicitly choose 30-second leases. No runner deadlines
or runtime claims of authority change. Missing/type-error/conflict cells are not
converted into optional rows; bounded many-row values remain an upstream gate.
