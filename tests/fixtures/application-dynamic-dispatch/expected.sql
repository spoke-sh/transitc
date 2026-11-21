CREATE QUEUE dynamic_requests (id BIGINT NOT NULL, target STRUCT(tag TEXT NOT NULL, machine STRUCT(id BIGINT NOT NULL), site STRUCT(id BIGINT NOT NULL)) NOT NULL, reject BOOLEAN NOT NULL) WITH (lease_duration = '120s', max_lease_duration = '120s');
CREATE TABLE dynamic_machines (id BIGINT PRIMARY KEY);
CREATE TABLE dynamic_sites (id BIGINT PRIMARY KEY);
CREATE TABLE dynamic_accepted_machines (id BIGINT PRIMARY KEY, machine_id BIGINT NOT NULL);
CREATE TABLE dynamic_accepted_sites (id BIGINT PRIMARY KEY, site_id BIGINT NOT NULL);
CREATE STREAM dynamic_events (id BIGINT NOT NULL, tag TEXT NOT NULL);
INSERT INTO dynamic_machines VALUES (7);
INSERT INTO dynamic_sites VALUES (7);
CREATE DATAFLOW dynamic_route FROM QUEUE dynamic_requests AS request AS BEGIN
  BEGIN ATOMIC
    LET target = request.target;
    REQUIRE target IS NOT NULL AND ((target.tag = 'machine' AND target.machine IS NOT NULL AND target.site IS NULL) OR (target.tag = 'site' AND target.machine IS NULL AND target.site IS NOT NULL)) ELSE 'InvalidVariant';
    IF target.tag = 'machine' THEN
      LET machine_id = target.machine.id;
      LET found = SELECT id FROM dynamic_machines WHERE id = machine_id;
      REQUIRE found IS NOT NULL ELSE 'MissingMachine';
      INSERT INTO dynamic_accepted_machines VALUES (request.id, machine_id) ON CONFLICT (id) DO ASSERT SAME ROW;
      REQUIRE NOT request.reject ELSE 'RejectedAfterWrite';
      PRODUCE INTO dynamic_events VALUES (request.id, 'machine');
    END IF;
    IF target.tag = 'site' THEN
      LET site_id = target.site.id;
      LET found = SELECT id FROM dynamic_sites WHERE id = site_id;
      REQUIRE found IS NOT NULL ELSE 'MissingSite';
      INSERT INTO dynamic_accepted_sites VALUES (request.id, site_id) ON CONFLICT (id) DO ASSERT SAME ROW;
      REQUIRE NOT request.reject ELSE 'RejectedAfterWrite';
      PRODUCE INTO dynamic_events VALUES (request.id, 'site');
    END IF;
  END;
END;
AUTHORIZE DATAFLOW dynamic_route AS ROLE CURRENT_ROLE;
ACTIVATE DATAFLOW dynamic_route;
