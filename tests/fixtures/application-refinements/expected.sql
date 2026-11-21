CREATE STREAM oracle_refined_events (id BIGINT NOT NULL, amount BIGINT NOT NULL);
CREATE STREAM oracle_refined_after (id BIGINT NOT NULL, amount BIGINT NOT NULL);
CREATE QUEUE oracle_refined_requests (id BIGINT NOT NULL, amount BIGINT, returned BIGINT) WITH (lease_duration='120s', max_lease_duration='120s');
CREATE DATAFLOW oracle_refined_route FROM QUEUE oracle_refined_requests AS request AS BEGIN
  BEGIN ATOMIC
    LET call_id = request.id;
    LET call_amount = request.amount;
    LET call_returned = request.returned;
    REQUIRE call_amount IS NOT NULL ELSE 'MissingAmount';
    REQUIRE call_amount >= 1 AND call_amount <= 10 ELSE 'AmountBounds';
    PRODUCE INTO oracle_refined_events VALUES (call_id, call_amount);
    LET call_result = call_returned;
    REQUIRE call_result = call_amount ELSE 'ChangedAmount';
    LET answer = call_result;
    PRODUCE INTO oracle_refined_after VALUES (request.id, answer);
  END;
END;
AUTHORIZE DATAFLOW oracle_refined_route AS ROLE CURRENT_ROLE;
ACTIVATE DATAFLOW oracle_refined_route;
