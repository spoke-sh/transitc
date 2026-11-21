# Dispatch runtime variants

Use a runtime variant when a Queue request selects between resource kinds that
have different nominal IDs. The compiler checks every arm and preserves its
payload type. The generated SQL validates the incoming tag and payload before
running that arm.

The [complete example](https://github.com/spoke-sh/transitc/tree/main/tests/fixtures/application-dynamic-dispatch)
defines MachineId and SiteId as distinct BIGINT domains. Both resources contain
ID `7`. Its Target variant has `Machine(id MachineId)` and `Site(id SiteId)` arms.
The request carries this ordinary SQL record:

```sql
STRUCT(tag TEXT NOT NULL,
       machine STRUCT(id BIGINT NOT NULL),
       site STRUCT(id BIGINT NOT NULL))
```

Use the lowercase constructor name as the tag and NULL for inactive payloads:
`STRUCT('machine', STRUCT(7), NULL)` selects Machine. The routing module is:

```sql
IMPORT ids FROM 'types.transit';
CREATE PUBLIC MODULE Routing() AS BEGIN
  CREATE PUBLIC DATAFLOW dynamic_route FROM QUEUE dynamic_requests AS request AS BEGIN
    BEGIN ATOMIC
      MATCH request.target AS ids.Target
        WHEN ids.Target.Machine(machine_id) THEN
          LET found = SELECT id FROM dynamic_machines WHERE id = machine_id;
          REQUIRE found IS NOT NULL ELSE 'MissingMachine';
          INSERT INTO dynamic_accepted_machines VALUES (request.id, machine_id) ON CONFLICT (id) DO ASSERT SAME ROW;
          REQUIRE NOT request.reject ELSE 'RejectedAfterWrite';
          PRODUCE INTO dynamic_events VALUES (request.id, 'machine');
        WHEN ids.Target.Site(site_id) THEN
          LET found = SELECT id FROM dynamic_sites WHERE id = site_id;
          REQUIRE found IS NOT NULL ELSE 'MissingSite';
          INSERT INTO dynamic_accepted_sites VALUES (request.id, site_id) ON CONFLICT (id) DO ASSERT SAME ROW;
          REQUIRE NOT request.reject ELSE 'RejectedAfterWrite';
          PRODUCE INTO dynamic_events VALUES (request.id, 'site');
      END MATCH;
    END;
  END;
  AUTHORIZE DATAFLOW dynamic_route AS ROLE CURRENT_ROLE;
  ACTIVATE DATAFLOW dynamic_route;
END;
```

From a transitc checkout, run the complete example:

```sh
nix develop --command just build
nix develop --command ./zig-out/bin/transitc test -f tests/fixtures/application-dynamic-dispatch/build.transit
```

All seven cases pass: two successes and five expected processing refusals. Each
case starts in an isolated database. Both result Tables and the output Stream
must remain empty after a refusal, including the case that rejects after INSERT.

To exercise a compiler error, change the Machine arm's INSERT target from
`dynamic_accepted_machines` to `dynamic_accepted_sites`, then run:

```sh
./zig-out/bin/transitc build -f tests/fixtures/application-dynamic-dispatch/build.transit --check
```

Compilation fails because MachineId cannot be written into a SiteId column.
Restore `dynamic_accepted_machines` and the check succeeds. Removing either arm
also fails compilation; every constructor must be handled exactly once.

A raw request with `STRUCT('machine', STRUCT(7), STRUCT(7))` has a populated
inactive payload. Queue admission may accept it, but the consumer refuses with
`InvalidVariant` before application effects. Correct it to
`STRUCT('machine', STRUCT(7), NULL)`. An unknown tag or absent active payload also
refuses. Field types are checked by the ordinary runtime input operation.

Nominal source types do not authenticate raw integers. Matching checks the
selected shape; the explicit lookup checks resource existence. Runtime operations
still require current authorization. Tags follow constructor names, so renaming
a constructor or changing its payload needs a schema/definition compatibility
review. Runtime MATCH currently accepts scalar payload fields, not nested variants.

The fixture declares the request Queue with
`WITH (lease_duration = '120s', max_lease_duration = '120s')`. Durable processing
needs enough time to finish before its lease expires. These two optional source
settings use Transit's duration units and validation; omitting them keeps its
30-second defaults. A lease change affects the compiled resource and dependent
program identities. It does not change test timeouts.
