# Validate helper inputs and results

Use `REQUIRES` and `ENSURES` to put explicit checks around an atomic procedure.
The caller supplies scalar arguments once; the checks run in declaration order.

```sql
CREATE PROCEDURE Identity(amount BIGINT) RETURNS BIGINT
REQUIRES amount IS NOT NULL ELSE 'MissingAmount'
REQUIRES amount >= 1 AND amount <= 10 ELSE 'AmountBounds'
ENSURES result = amount ELSE 'ChangedAmount'
AS BEGIN ATOMIC
  RETURN amount;
END;
CREATE TARGET default AS BEGIN
  CREATE PUBLIC QUEUE requests (amount BIGINT);
  CREATE PUBLIC STREAM accepted (amount BIGINT NOT NULL);
  CREATE PUBLIC DATAFLOW validate_amount FROM QUEUE requests AS request AS BEGIN
    BEGIN ATOMIC
      LET amount = CALL Identity(request.amount);
      PRODUCE INTO accepted VALUES (amount);
    END;
  END;
  AUTHORIZE DATAFLOW validate_amount AS ROLE CURRENT_ROLE;
  ACTIVATE DATAFLOW validate_amount;
END;
```

Save this as `build.transit` and run `transitc build`. A NULL input refuses with
`MissingAmount`; 0 and 11 refuse with `AmountBounds`. Values from 1 through 10
reach the Stream. To see a compile-time error, change `result = amount` to
`result = unknown`: the compiler refuses the unknown binding before publishing.
Restore the parameter name to correct it.

The following fixture also stages an append before a deliberately incorrect
return. Its failed postcondition must leave both output Streams empty:

```sh
transitc test -f tests/fixtures/application-refinements/build.transit
```

Clauses accept scalar non-nullness, constant BIGINT comparisons and equality or
inequality between matching scalar types/domains. Use `AND` to join terms, or
write several clauses for distinct refusal codes. A nominal ID cannot be compared
with a raw integer bound or a foreign domain. Guards can also declare clauses;
pure expression functions cannot add ordered refusal effects.

Every clause emits an ordinary runtime check. It does not certify that a row still
exists after another operation or establish current access rights. Query mutable
state again when a later operation needs a fresh observation. A procedure and its
checks run in the caller's atomic transaction; postcondition failure rolls back
all staged effects before the caller can use the returned value.
