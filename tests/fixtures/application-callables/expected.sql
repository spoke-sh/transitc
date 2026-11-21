CREATE TABLE oracle_rows (id BIGINT PRIMARY KEY);
CREATE STREAM oracle_events (id BIGINT NOT NULL);
CREATE QUEUE oracle_requests (id BIGINT NOT NULL, allowed BOOLEAN NOT NULL) WITH (lease_duration='120s', max_lease_duration='120s');
CREATE DATAFLOW oracle_route FROM QUEUE oracle_requests AS request AS BEGIN
  BEGIN ATOMIC
    LET outer_id = request.id;
    LET outer_allowed = request.allowed;
    REQUIRE outer_id >= 1 ELSE 'PositiveId';
    LET inner_id = outer_id;
    LET inner_allowed = outer_allowed;
    REQUIRE inner_id >= 1 ELSE 'PositiveId';
    INSERT INTO oracle_rows VALUES (inner_id) ON CONFLICT (id) DO ASSERT SAME ROW;
    PRODUCE INTO oracle_events VALUES (inner_id);
    REQUIRE inner_allowed ELSE 'LateRefusal';
    LET inner_result = inner_id;
    REQUIRE inner_result = inner_id ELSE 'SameId';
    LET saved_in_helper = inner_result;
    LET outer_result = saved_in_helper;
    REQUIRE outer_result = outer_id ELSE 'SameId';
    LET saved = outer_result;
    REQUIRE saved = request.id ELSE 'WrongReturn';
  END;
END;
AUTHORIZE DATAFLOW oracle_route AS ROLE CURRENT_ROLE;
ACTIVATE DATAFLOW oracle_route;
