CREATE QUEUE dynamic_requests (id BIGINT NOT NULL, tag TEXT NOT NULL, machine_id BIGINT, site_id BIGINT, reject BOOLEAN NOT NULL);
CREATE TABLE dynamic_machines (id BIGINT PRIMARY KEY);
CREATE TABLE dynamic_sites (id BIGINT PRIMARY KEY);
CREATE TABLE dynamic_accepted (id BIGINT PRIMARY KEY, tag TEXT NOT NULL, resource_id BIGINT NOT NULL);
CREATE STREAM dynamic_events (id BIGINT NOT NULL, tag TEXT NOT NULL, resource_id BIGINT NOT NULL);
INSERT INTO dynamic_machines VALUES (7);
INSERT INTO dynamic_sites VALUES (7);
CREATE DATAFLOW dynamic_route FROM QUEUE dynamic_requests AS request AS BEGIN
  REQUIRE (request.tag = 'Machine' AND request.machine_id IS NOT NULL AND request.site_id IS NULL) OR (request.tag = 'Site' AND request.site_id IS NOT NULL AND request.machine_id IS NULL) ELSE 'InvalidVariant';
  BEGIN ATOMIC
    IF request.tag = 'Machine' THEN
      LET found = SELECT id FROM dynamic_machines WHERE id = request.machine_id;
      REQUIRE found IS NOT NULL ELSE 'MissingMachine';
      INSERT INTO dynamic_accepted VALUES (request.id, request.tag, found.id) ON CONFLICT (id) DO ASSERT SAME ROW;
      REQUIRE NOT request.reject ELSE 'RejectedAfterWrite';
      PRODUCE INTO dynamic_events VALUES (request.id, request.tag, found.id);
    ELSE
      LET found = SELECT id FROM dynamic_sites WHERE id = request.site_id;
      REQUIRE found IS NOT NULL ELSE 'MissingSite';
      INSERT INTO dynamic_accepted VALUES (request.id, request.tag, found.id) ON CONFLICT (id) DO ASSERT SAME ROW;
      REQUIRE NOT request.reject ELSE 'RejectedAfterWrite';
      PRODUCE INTO dynamic_events VALUES (request.id, request.tag, found.id);
    END IF;
  END;
END;
AUTHORIZE DATAFLOW dynamic_route AS ROLE CURRENT_ROLE;
ACTIVATE DATAFLOW dynamic_route;
