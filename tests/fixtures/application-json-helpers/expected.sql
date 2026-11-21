CREATE STREAM oracle_events(id BIGINT NOT NULL, number BIGINT, text TEXT, payload JSON);
CREATE QUEUE oracle_requests(id BIGINT NOT NULL, payload JSON) WITH(lease_duration='120s',max_lease_duration='120s');
CREATE DATAFLOW oracle_route FROM QUEUE oracle_requests AS request AS BEGIN
  BEGIN ATOMIC
    LET argument_id = request.id;
    LET unused = 1;
    LET argument_payload = request.payload;
    REQUIRE argument_payload IS NOT NULL ELSE 'SqlNull';
    LET number = JSON_INTEGER(argument_payload, '$.number');
    LET text = JSON_VALUE(argument_payload, '$.value');
    PRODUCE INTO oracle_events VALUES(argument_id, number, text, argument_payload);
  END;
END;
AUTHORIZE DATAFLOW oracle_route AS ROLE CURRENT_ROLE;
ACTIVATE DATAFLOW oracle_route;
