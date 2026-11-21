CREATE QUEUE oracle_cardinality_requests (id BIGINT NOT NULL, lookup TEXT NOT NULL, reject BOOLEAN NOT NULL) WITH (lease_duration = '120s', max_lease_duration = '120s');
CREATE TABLE oracle_cardinality_rows (id BIGINT PRIMARY KEY, lookup TEXT NOT NULL, note TEXT);
CREATE STREAM oracle_cardinality_events (id BIGINT NOT NULL, presence TEXT NOT NULL, note TEXT);
INSERT INTO oracle_cardinality_rows VALUES (1, 'single', NULL), (2, 'duplicate', 'a'), (3, 'duplicate', 'b');
CREATE DATAFLOW oracle_cardinality_route FROM QUEUE oracle_cardinality_requests AS request AS BEGIN
  BEGIN ATOMIC
    LET found = SELECT note FROM oracle_cardinality_rows WHERE lookup = request.lookup;
    REQUIRE found IS NOT NULL ELSE 'ExpectedOneRow';
    PRODUCE INTO oracle_cardinality_events VALUES (request.id, 'present', found.note);
    REQUIRE NOT request.reject ELSE 'LateRefusal';
  END;
END;
AUTHORIZE DATAFLOW oracle_cardinality_route AS ROLE CURRENT_ROLE;
ACTIVATE DATAFLOW oracle_cardinality_route;
