# Use typed values

A source type is available only on the SQL surfaces its runtime supports. For
example, DATE works in module parameters, nominal domains, Tables and queries;
it cannot yet be used by ordered programs or their helper functions.

## Exact calendar dates

```sql
CREATE DOMAIN BusinessDay AS DATE IDENTITY 'example.business-day';
CREATE MODULE Calendar(element TYPE, selected BusinessDay) AS BEGIN
  CREATE PUBLIC TABLE business_days (day $element PRIMARY KEY);
  INSERT INTO business_days VALUES ($selected);
END;
CREATE TARGET default AS BEGIN
  USE Calendar(TYPE BusinessDay, BusinessDay(DATE '2024-02-29'));
END;
```

Save this as `build.transit` in an empty directory, then run `transitc build`.
The generated `application.sql` contains an ordinary DATE column and DATE literal.
It runs without the source tree. The domain identity prevents accidental mixing
with another source domain; ordinary SQL still sees the physical DATE value.

Change the literal to `DATE '2023-02-29'` and build again. The compiler reports an
invalid DATE literal before publishing a new artifact. Restore `2024-02-29` to
correct it. `TIMESTAMP '2024-02-29T00:00:00Z'` is also refused as a BusinessDay
argument: no timezone or timestamp conversion is implicit.

Dates use `YYYY-MM-DD`, years 0001 through 9999. Ordinary DATE values support
comparison by day, while nominal domains allow same-domain equality and
inequality. Date arithmetic is outside this source profile. A nullable DATE column
can contain SQL NULL; NULL is distinct from a date and from an absent query row.

The repository fixture exercises both endpoints, the epoch, a leap day and NULL:

```sh
transitc test -f tests/fixtures/application-date/build.transit
```

## Exact decimal amounts

Declare precision and scale at every NUMERIC source boundary:

```sql
CREATE DOMAIN Amount AS NUMERIC(18,2) IDENTITY 'example.amount';
CREATE MODULE Ledger(element TYPE, amount Amount) AS BEGIN
  CREATE PUBLIC TABLE ledger (id BIGINT PRIMARY KEY, amount $element NOT NULL);
  INSERT INTO ledger VALUES (1, $amount);
END;
CREATE TARGET default AS BEGIN
  USE Ledger(TYPE Amount, Amount(NUMERIC(18,2) '123.45'));
END;
```

Build this in an empty directory. Change `123.45` to `123.451`: the build fails
with `Inexact` before publication. Restore an exactly representable amount to
correct it. Precision ranges from 1 to 38, and scale from 0 to precision.
The compiler never converts decimal values through floating point.

Parameters can use `NUMERIC(18,2)` directly; `TYPE NUMERIC(18,2)` supplies a physical
column type. A domain constructor requires its exact base descriptor. A BIGINT,
a different precision/scale or a foreign domain cannot substitute for it.
Plain NUMERIC values with identical descriptors allow comparisons; nominal amounts
allow same-domain equality and inequality. Source arithmetic and implicit
rescaling are unavailable. SQL functions with explicit rounding policies are a
separate runtime surface, not a source conversion.

## Check the surface before composing

| Value | Source parameters/domains | Ordered programs and helpers |
| --- | --- | --- |
| BIGINT, TEXT, BOOLEAN, UUID, TIMESTAMPTZ, BINARY | Supported | Supported public-data subset |
| DATE | Supported | Not yet supported by Transit |
| NUMERIC(p,s) | Supported with exact descriptors | Not yet supported by Transit |
| JSON, INTERVAL | Not yet admitted as source parameter types | Separate qualification required |
| Runtime variants | Closed record decoding with `MATCH` | See [runtime variants](runtime-variants.md) |

Ordinary SQL supports more descriptors than this source parameter set. Parser
acceptance alone does not establish runtime support. In particular, an SQL
INTERVAL is not the program helper's microsecond duration, JSON does not gain
scalar equality, and native UNION values cannot yet enter ordered programs.

## Ordinary SQL literals

NUMERIC, JSON and INTERVAL can be used directly in Table declarations and
literals. JSON and INTERVAL do not yet have source parameter or domain types.

```sql
CREATE PUBLIC TABLE values_example (id BIGINT PRIMARY KEY, amount NUMERIC(38,9), payload JSON, span INTERVAL);
INSERT INTO values_example VALUES (1, 9007199254740993.123456789, JSON '{"value":null}', INTERVAL(1,-2,3));
```

NUMERIC retains exact decimal coefficients. A literal with extra nonzero scale
digits fails with `Inexact`; supply an exactly representable value. Duplicate
JSON keys fail with `DuplicateField`; remove the duplicate key. JSON null remains
distinct from SQL NULL. INTERVAL keeps months, days and nanoseconds separately.

Run `transitc test -f tests/fixtures/application-sql-scalars/build.transit` for
exact values and boundary cases. The installed checks compare an independent SQL
oracle, including reordered JSON keys, and preserve values after restart. The
qualified query is direct projection: the combined `ORDER BY` query is refused by
Transit's relational profile. This fixture does not qualify JSON extraction,
decimal rounding operations or interval ordering.
