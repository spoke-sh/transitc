# Bounded atomic batches

`transitc test -f tests/fixtures/application-bounded-many/build.transit` runs seven
isolated cases at the existing 30-second case and 300-second suite budgets.
They distinguish empty collections from present NULL fields, preserve duplicate
non-key payloads in key order, check exact and excess cardinality, and verify
rollback after an earlier staged append. Imported and nested ROW helpers retain
the nominal ItemId domain. The `two` build target binds independent resources.

`oracle.sql` is separately authored native SQL. The installed
[`bounded_many.py`](../../integration/bounded_many.py) journey removes source
before executing generated SQL, compares both instances and this oracle in exact
Stream order, verifies the explicit MANY(4) correction for an overflowing
four-row batch, then checks restart and retirement. Its failure record deliberately
uses a public constant: the native internal refusal code is not a public field.
The first ordered refusal is checked directly at the native ApplicationStep
boundary; this fixture's corresponding case proves rollback only.

The native contract owns row/work/byte/scan/request bounds, read-basis validation,
current rights and replay. These tests do not establish missing/type-error/conflict
values, collection returns, nested iteration or reads inside loop bodies.
