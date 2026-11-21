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

## Check the surface before composing

| Value | Source parameters/domains | Ordered programs and helpers |
| --- | --- | --- |
| BIGINT, TEXT, BOOLEAN, UUID, TIMESTAMPTZ, BINARY | Supported | Supported public-data subset |
| DATE | Supported | Not yet supported by Transit |
| NUMERIC, JSON, INTERVAL | Not yet admitted as source parameter types | Separate qualification required |
| Runtime variants | Closed record decoding with `MATCH` | See [runtime variants](runtime-variants.md) |

Ordinary SQL supports more descriptors than this source parameter set. Parser
acceptance alone does not establish runtime support. In particular, an SQL
INTERVAL is not the program helper's microsecond duration, JSON does not gain
scalar equality, and native UNION values cannot yet enter ordered programs.
