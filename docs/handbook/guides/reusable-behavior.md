# Pass reusable behavior to modules

Declare a helper's resource operations, then use that checked helper as a
signature prototype for a module parameter:

```sql
CREATE PROCEDURE Store(events STREAM(id BIGINT NOT NULL), id BIGINT)
EFFECTS (PRODUCE events)
AS BEGIN ATOMIC
  PRODUCE INTO events VALUES (id);
END;
CREATE MODULE Workflow(save PROCEDURE OF Store) AS BEGIN
  CREATE PUBLIC QUEUE requests (id BIGINT NOT NULL);
  CREATE PUBLIC STREAM accepted (id BIGINT NOT NULL);
  CREATE PUBLIC DATAFLOW save_request FROM QUEUE requests AS request AS BEGIN
    BEGIN ATOMIC
      CALL save(accepted, request.id);
    END;
  END;
  AUTHORIZE DATAFLOW save_request AS ROLE CURRENT_ROLE;
  ACTIVATE DATAFLOW save_request;
END;
CREATE TARGET default AS BEGIN USE Workflow(Store); END;
```

Save this as `build.transit` and run `transitc build`. The output contains an
ordinary Queue program with an inline PRODUCE operation. It executes without the
source helper or a runtime callback.

Change `EFFECTS (PRODUCE events)` to `EFFECTS ()`: compilation fails with
`EffectContractMismatch` before publication because the body writes to the Stream.
Restore the declared operation to correct it. Nested helpers are checked too;
putting the PRODUCE operation behind another call cannot hide it.

Another implementation can replace `Store` only when its parameter names/types,
return type, resource operations and validation clauses match exactly. Use
`FUNCTION OF` for pure functions or `GUARD OF` for ordered guards. A guard or
procedure used this way requires an explicit effect list; functions are pure.
Effect lists describe the exact operation set, so unused declared permissions
also fail. Clause order and refusal codes are part of the contract.

`READ` and `INSERT` refer to Table parameters, `PRODUCE` to Stream parameters, and
`ENQUEUE` to Queue parameters. Resource arguments remain explicit at each call.
A signature does not grant current runtime rights. Follow [input and result
validation](refinements.md) to add bounded pre/postconditions.

ROW arguments can carry the complete Queue input through imported or nested
helpers. Declared named fields are checked without discarding extra input fields
or adding specialization constants to the row. See the
[whole-row specialization example](specialization.md) for a helper receiving both
`request` and a compile-time scalar. Keep resource effects explicit when moving
that helper behind a callable parameter.

The repository example uses imported and nested procedures, two independently
named instances, and a refusal after staging both a Table write and a Stream
append:

```sh
transitc test -f tests/fixtures/application-callables/build.transit
```

A read-only procedure can return a typed query result. The caller retains the
row names, domains and nullability and can iterate a bounded result directly.

```sql
CREATE PROCEDURE SelectBatch(t TABLE(id BIGINT PRIMARY KEY, note TEXT))
RETURNS MANY(2) ROW(id BIGINT NOT NULL, note TEXT) ORDER BY id
EFFECTS (READ t)
AS BEGIN ATOMIC
  LET batch MANY(2) = SELECT id, note FROM t ORDER BY id;
  RETURN batch;
END;
```

Declaring `note TEXT NOT NULL` here fails because the Table permits NULL. Use
`note TEXT` to describe the rows the query actually returns. The same signature
can serve as a `PROCEDURE OF SelectBatch` module parameter. A caller receives
the bound result in its own atomic transaction, so a later refusal rolls back
any appends made while iterating it.

```sh
transitc test -f tests/fixtures/application-query-returns/build.transit
```
