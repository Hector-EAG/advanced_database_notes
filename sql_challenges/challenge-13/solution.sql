-- Step 1
CREATE TABLE tickets (
    ticket_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title         VARCHAR2(200) NOT NULL,
    status        VARCHAR2(20) NOT NULL,
    priority      VARCHAR2(10) NOT NULL,
    created_at    DATE NOT NULL,
    resolved_at   DATE,
    assigned_to   NUMBER NOT NULL,
    CONSTRAINT fk_assigned
        FOREIGN KEY (assigned_to)
        REFERENCES users(id)
);

CREATE TABLE ticket_assignments (
    assignment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id     NUMBER NOT NULL,
    assigned_to   NUMBER NOT NULL,
    assigned_by   NUMBER NOT NULL,
    valid_from    DATE NOT NULL,
    valid_to      DATE,
    CONSTRAINT fk_ticket
        FOREIGN KEY (ticket_id)
        REFERENCES tickets(ticket_id),
    CONSTRAINT fk_ta_assigned_to
        FOREIGN KEY (assigned_to)
        REFERENCES users(id),
    CONSTRAINT fk_ta_assigned_by
        FOREIGN KEY (assigned_by)
        REFERENCES users(id)
);

-- Step 2
-- TICKETS
INSERT INTO tickets
(title, status, priority, created_at, resolved_at, assigned_to)
VALUES
(
    'Email server outage',
    'completed',
    'high',
    TO_DATE('2026-05-01 08:30', 'YYYY-MM-DD HH24:MI'),
    TO_DATE('2026-05-02 14:00', 'YYYY-MM-DD HH24:MI'),
    3
);

INSERT INTO tickets
(title, status, priority, created_at, resolved_at, assigned_to)
VALUES
(
    'Login authentication bug',
    'in_progress',
    'medium',
    TO_DATE('2026-05-03 10:15', 'YYYY-MM-DD HH24:MI'),
    NULL,
    2
);

INSERT INTO tickets
(title, status, priority, created_at, resolved_at, assigned_to)
VALUES
(
    'Database backup failure',
    'blocked',
    'high',
    TO_DATE('2026-05-04 09:45', 'YYYY-MM-DD HH24:MI'),
    NULL,
    4
);

INSERT INTO tickets
(title, status, priority, created_at, resolved_at, assigned_to)
VALUES
(
    'UI alignment issue',
    'completed',
    'low',
    TO_DATE('2026-05-05 11:20', 'YYYY-MM-DD HH24:MI'),
    TO_DATE('2026-05-05 16:30', 'YYYY-MM-DD HH24:MI'),
    1
);

INSERT INTO tickets
(title, status, priority, created_at, resolved_at, assigned_to)
VALUES
(
    'API timeout problem',
    'open',
    'critical',
    TO_DATE('2026-05-06 13:10', 'YYYY-MM-DD HH24:MI'),
    NULL,
    1
);

-- TICKETS
-- Ticket 1 was reassigned to user 1 to from user 3
INSERT INTO ticket_assignments
(ticket_id, assigned_to, assigned_by, valid_from, valid_to)
VALUES
(
    1,
    1,
    4,
    TO_DATE('2026-05-01 08:30', 'YYYY-MM-DD HH24:MI'),
    TO_DATE('2026-05-01 18:00', 'YYYY-MM-DD HH24:MI')
);

INSERT INTO ticket_assignments
(ticket_id, assigned_to, assigned_by, valid_from, valid_to)
VALUES
(
    2,
    2,
    4,
    TO_DATE('2026-05-01 18:00', 'YYYY-MM-DD HH24:MI'),
    NULL
);

INSERT INTO ticket_assignments
(ticket_id, assigned_to, assigned_by, valid_from, valid_to)
VALUES
(
    3,
    4,
    4,
    TO_DATE('2026-05-03 10:15', 'YYYY-MM-DD HH24:MI'),
    NULL
);

INSERT INTO ticket_assignments
(ticket_id, assigned_to, assigned_by, valid_from, valid_to)
VALUES
(
    4,
    1,
    4,
    TO_DATE('2026-05-04 09:45', 'YYYY-MM-DD HH24:MI'),
    NULL
);

INSERT INTO ticket_assignments
(ticket_id, assigned_to, assigned_by, valid_from, valid_to)
VALUES
(
    5,
    1,
    4,
    TO_DATE('2026-05-05 11:20', 'YYYY-MM-DD HH24:MI'),
    NULL
);

--Step 3
CREATE OR REPLACE TRIGGER trg_ticket_assignment_history
AFTER INSERT OR UPDATE OF assigned_to
ON tickets
FOR EACH ROW
BEGIN

    IF UPDATING THEN
        UPDATE ticket_assignments
        SET valid_to = SYSDATE
        WHERE ticket_id = :NEW.ticket_id
          AND valid_to IS NULL;
    END IF;

    INSERT INTO ticket_assignments (
        ticket_id,
        assigned_to,
        assigned_by,
        valid_from,
        valid_to
    )
    VALUES (
        :NEW.ticket_id,
        :NEW.assigned_to,
        1,              
        SYSDATE,
        NULL
    );

END;

--Step 4
CREATE TABLE dim_agent (
    agent_key   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_id    NUMBER NOT NULL,
    agent_name  VARCHAR2(100) NOT NULL,
    team        VARCHAR2(50) NOT NULL,

    CONSTRAINT uq_dim_agent UNIQUE (agent_id)
);

CREATE TABLE fact_ticket_daily (
    fact_key          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key          NUMBER NOT NULL,
    agent_key         NUMBER NOT NULL,
    status            VARCHAR2(20) NOT NULL,
    priority          VARCHAR2(10) NOT NULL,
    tickets_created   NUMBER DEFAULT 0,
    tickets_resolved  NUMBER DEFAULT 0,

    CONSTRAINT fk_fact_date
        FOREIGN KEY (date_key)
        REFERENCES dim_date(date_key),

    CONSTRAINT fk_fact_agent
        FOREIGN KEY (agent_key)
        REFERENCES dim_agent(agent_key),

    CONSTRAINT uq_fact_ticket_daily
        UNIQUE (date_key, agent_key, status, priority)
);

--Step 5
INSERT INTO dim_agent (agent_id, agent_name, team)
VALUES (1, 'Alice Johnson', 'Support');

INSERT INTO dim_agent (agent_id, agent_name, team)
VALUES (2, 'Bob Smith', 'Support');

INSERT INTO dim_agent (agent_id, agent_name, team)
VALUES (3, 'Carol Davis', 'Infrastructure');

INSERT INTO dim_agent (agent_id, agent_name, team)
VALUES (4, 'David Wilson', 'Infrastructure');

--Step 7
SELECT f.date_key, a.agent_name, a.team, f.status, f.priority, f.tickets_created, f.tickets_resolved
FROM fact_ticket_daily f
JOIN dim_agent a ON f.agent_key = a.agent_key
ORDER BY f.date_key, a.agent_name;