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

The repository example uses imported and nested procedures, two independently
named instances, and a refusal after staging both a Table write and a Stream
append:

```sh
transitc test -f tests/fixtures/application-callables/build.transit
```

Callables are compile-time module arguments. Runtime closures, callable ROW
members, callable helper parameters, arbitrary row/many-result signatures and
implicit signature widening are outside this profile. Scalar queries can use
ONE/OPTIONAL reads inside a checked guard or atomic procedure. Returning from a
procedure preserves the caller's transaction and its rollback behavior.
