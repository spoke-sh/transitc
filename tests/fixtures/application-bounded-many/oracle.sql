CREATE QUEUE oracle_many_requests (id BIGINT NOT NULL, batch BIGINT NOT NULL, reject BIGINT NOT NULL) WITH (lease_duration = '120s', max_lease_duration = '120s');
CREATE TABLE oracle_many_items (id BIGINT PRIMARY KEY, batch BIGINT NOT NULL, note TEXT);
CREATE STREAM oracle_many_events (request BIGINT NOT NULL, id BIGINT NOT NULL, note TEXT);
CREATE STREAM oracle_many_failures (request BIGINT NOT NULL, reason TEXT NOT NULL);
INSERT INTO oracle_many_items VALUES (3, 1, 'same'), (1, 1, 'same'), (2, 2, NULL),
  (6, 3, 'six'), (4, 3, NULL), (5, 3, 'five'),
  (10, 4, 'ten'), (7, 4, 'seven'), (9, 4, 'nine'), (8, 4, 'eight');
CREATE DATAFLOW oracle_many_route FROM QUEUE oracle_many_requests AS request AS BEGIN
  BEGIN ATOMIC
    LET selected MANY(3) = SELECT id, note FROM oracle_many_items WHERE batch = request.batch ORDER BY id ASC;
    FOR item IN selected DO
      REQUIRE item.id = item.id ELSE 'InvalidItem';
      IF request.reject = 1 THEN
        REQUIRE item.id <> 5 ELSE 'LateRefusal';
      END IF;
      IF request.reject = 2 THEN
        REQUIRE item.id <> 4 ELSE 'FirstKey';
        REQUIRE item.id <> 6 ELSE 'LastKey';
      END IF;
      PRODUCE INTO oracle_many_events VALUES (request.id, item.id, item.note);
    END FOR;
  END;
ON FAILURE failure
  BEGIN ATOMIC
    PRODUCE INTO oracle_many_failures VALUES (request.id, 'refused');
  END;
END;
AUTHORIZE DATAFLOW oracle_many_route AS ROLE CURRENT_ROLE;
ACTIVATE DATAFLOW oracle_many_route;
