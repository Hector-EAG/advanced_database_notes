-- File 6. 
-- EXERCISE 1: Define "Team Velocity"
-- A)
-- 1. What is the business question?
-- How fast can a team complete a task
-- 2. What is the exact definition? (Include every filter, every join)
-- (CAST(completed_at AS DATE) - created_at) * 24
-- 3. What are the edge cases? (NULLs, cancelled tasks, unassigned tasks, etc.)
-- The tasks that have not yet been completed 
-- 4. What is the unit? (Count, percentage, hours, dollars?)
-- hours
-- 5. What would make this metric misleading?
-- It could make seem a team who complets a lot of small tasks, a more hard-working team than a team who complets big tasks
SELECT assigned_to, AVG((CAST(completed_at AS DATE) - created_at) * 24) AS avg_hours
FROM tasks
WHERE completed_at IS NOT NULL
GROUP BY assigned_to
ORDER BY avg_hours;

-- EXERCISE 2: Define "On-Time Delivery Rate"
-- A)
-- 1. What is the business question?
-- How often is a person on time with his/her delivery
-- 2. What is the exact definition? (Include every filter, every join)
-- (SUM(CASE WHEN CAST(completed_at AS DATE) <= due_date THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2)
-- 3. What are the edge cases? (NULLs, cancelled tasks, unassigned tasks, etc.)
-- The tasks that have been canceled and blocked 
-- 4. What is the unit? (Count, percentage, hours, dollars?)
-- percentage
-- 5. What would make this metric misleading?
-- It could make seem a person that has a lot of "unimportant" tasks be very irresponsible, and someone that misses important
-- updates but does everything else on time very responsible 
SELECT 
    assigned_to, ROUND((SUM(
                CASE 
                    WHEN CAST(completed_at AS DATE) <= due_date THEN 1
                    ELSE 0
                END
            ) * 100.0) / COUNT(*), 2) AS compliance_percentage
FROM tasks
WHERE completed_at IS NOT NULL AND due_date IS NOT NULL
GROUP BY assigned_to
ORDER BY compliance_percentage DESC;

-- EXERCISE 3: Improve "Tasks per Team" (KPI 2 from class)
conn = engine.connect()
conn.rollback()
conn.close()
query = """
SELECT 
    t.name AS team_name,

    COUNT(ts.id) AS total_tasks,

    SUM(
        CASE
            WHEN ts.status IN ('open', 'in_progress', 'blocked')
            THEN 1
            ELSE 0
        END
    ) AS active_tasks,

    ROUND(
        (
            SUM(
                CASE
                    WHEN ts.status = 'completed'
                    THEN 1
                    ELSE 0
                END
            ) * 100.0
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN ts.status != 'cancelled'
                    THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS completion_rate,

    CASE
        WHEN SUM(
            CASE
                WHEN ts.status IN ('open', 'in_progress', 'blocked')
                THEN 1
                ELSE 0
            END
        ) > 10
        THEN 'Overloaded'

        WHEN SUM(
            CASE
                WHEN ts.status IN ('open', 'in_progress', 'blocked')
                THEN 1
                ELSE 0
            END
        ) BETWEEN 5 AND 10
        THEN 'Healthy'

        ELSE 'Underutilized'
    END AS health_score

FROM teams t

LEFT JOIN users u
       ON u.team_id = t.id

LEFT JOIN tasks ts
       ON ts.assigned_to = u.id

GROUP BY t.id, t.name

ORDER BY active_tasks DESC
"""

with engine.connect() as conn:
    df_team = pd.read_sql(query, conn)

fig = px.bar(
    df_team,
    x='team_name',
    y=['total_tasks', 'active_tasks', 'completion_rate'],
    barmode='group',
    text_auto=True,
    title='Team KPI Overview',
    labels={
        'value': 'Metric Value',
        'variable': 'KPI',
        'team_name': 'Team'
    },
    hover_data=['health_score']
)

fig.for_each_trace(
    lambda t: t.update(
        name={
            'total_tasks': 'Total Tasks',
            'active_tasks': 'Active Tasks',
            'completion_rate': 'Completion Rate (%)'
        }[t.name]
    )
)

fig.update_layout(
    xaxis_title='Team',
    yaxis_title='Value',
    legend_title='Metrics'
)

fig.show()

--EXERCISE 4: Improve "Average Resolution Time" (KPI 5 from class)
conn = engine.connect()
conn.rollback()
conn.close()
query = """
WITH task_times AS (
    SELECT
        priority,

        (
            EXTRACT(DAY FROM (completed_at - CAST(created_at AS TIMESTAMP))) * 24 +
            EXTRACT(HOUR FROM (completed_at - CAST(created_at AS TIMESTAMP))) +
            EXTRACT(MINUTE FROM (completed_at - CAST(created_at AS TIMESTAMP))) / 60
        ) AS resolution_hours

    FROM tasks

    WHERE status = 'completed'
      AND completed_at IS NOT NULL
)

SELECT
    priority,

    COUNT(*) AS completed_task_count,

    ROUND(AVG(resolution_hours), 1) AS avg_resolution_hours,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY resolution_hours),
        1
    ) AS median_resolution_hours,

    ROUND(MIN(resolution_hours), 1) AS fastest_resolution_hours,

    ROUND(MAX(resolution_hours), 1) AS slowest_resolution_hours,

    CASE
        WHEN priority = 'critical'
             AND AVG(resolution_hours) <= 24 THEN 'Target Met'

        WHEN priority = 'high'
             AND AVG(resolution_hours) <= 72 THEN 'Target Met'

        WHEN priority = 'medium'
             AND AVG(resolution_hours) <= 168 THEN 'Target Met'

        WHEN priority = 'low'
             AND AVG(resolution_hours) <= 336 THEN 'Target Met'

        ELSE 'Target Missed'
    END AS target_met,

    CASE
        WHEN COUNT(*) = 1 THEN 'Low Sample Size'
        ELSE 'Reliable Sample'
    END AS sample_quality

FROM task_times

GROUP BY priority

ORDER BY
    CASE priority
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
        ELSE 5
    END
"""

df_kpi = pd.read_sql(query, engine)

display(df_kpi)

--EXERCISE 5: Improve "Overdue Tasks" (KPI 7 from class)
conn = engine.connect()
conn.rollback()
conn.close()
query = """
WITH overdue_tasks AS (
    SELECT
        ts.title,
        u.full_name AS assignee,
        t.name AS team,
        ts.priority,
        ts.due_date,

        TRUNC(SYSDATE) - TRUNC(ts.due_date) AS days_overdue,

        CASE
            WHEN ts.priority = 'critical'
                 AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 0
            THEN 'CRITICAL'

            WHEN ts.priority = 'high'
                 AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 2
            THEN 'HIGH'

            WHEN ts.priority = 'medium'
                 AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 5
            THEN 'MEDIUM'

            ELSE 'LOW'
        END AS severity

    FROM tasks ts

    LEFT JOIN users u
           ON u.id = ts.assigned_to

    LEFT JOIN teams t
           ON t.id = u.team_id

    WHERE ts.due_date < TRUNC(SYSDATE)
      AND ts.status NOT IN ('completed', 'cancelled')
      AND ts.due_date IS NOT NULL
),

final_report AS (

    SELECT
        title,
        assignee,
        team,
        priority,
        due_date,
        days_overdue,
        severity
    FROM overdue_tasks

    UNION ALL

    SELECT
        'TOTAL (' || severity || ')' AS title,
        NULL AS assignee,
        NULL AS team,
        NULL AS priority,
        NULL AS due_date,
        ROUND(AVG(days_overdue), 1) AS days_overdue,
        severity
    FROM overdue_tasks
    GROUP BY severity
)

SELECT *
FROM final_report

ORDER BY
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        ELSE 4
    END,
    days_overdue DESC
"""

df_overdue = pd.read_sql(query, engine)

df_overdue = pd.read_sql(query, engine)

priority_colors = {
    'CRITICAL': '#d32f2f',
    'HIGH': '#f57c00',
    'MEDIUM': '#fbc02d',
    'LOW': '#388e3c'
}

fig = px.bar(
    df_overdue[df_overdue['assignee'].notna()],
    x='title',
    y='days_overdue',
    color='severity',
    color_discrete_map=priority_colors,
    title='Overdue Tasks Severity Report',
    hover_data=['assignee', 'team', 'priority']
)

fig.update_xaxes(title_text='Task')
fig.update_yaxes(title_text='Days Overdue')

fig.show()

-- EXERCISE 6: Fix the "Productivity Score"
--PROBLEM:
--It does not distinguih between completed and unfinished tasks,
--A person with many tasks may appear more productive than someone who has finish all his/her work,
--It measures how much work somebody has, not productivity
--Query:
WITH completed_tasks AS (
    SELECT
        u.full_name,
        TRUNC(ts.completed_at) AS completed_day,
        CASE ts.priority
            WHEN 'critical' THEN 4
            WHEN 'high' THEN 3
            WHEN 'medium' THEN 2
            ELSE 1
        END AS priority_weight
    FROM users u
    LEFT JOIN tasks ts
           ON ts.assigned_to = u.id
    WHERE ts.status = 'completed'
      AND ts.completed_at IS NOT NULL
)

SELECT
    full_name,
    completed_day,
    COUNT(*) AS completed_tasks,
    SUM(priority_weight) AS weighted_productivity_score
FROM completed_tasks
GROUP BY full_name, completed_day
ORDER BY weighted_productivity_score DESC;

-- EXERCISE 7: Fix the "Team Efficiency"
--PROBLEM:
-- Task id means nothing, it only tells who has the newest/oldest task
--Query:
SELECT
    t.name AS team_name,
    COUNT(ts.id) AS total_tasks,
    SUM(
        CASE
            WHEN ts.status = 'completed'
            THEN 1
            ELSE 0
        END
    ) AS completed_tasks,
    ROUND(
        (
            SUM(
                CASE
                    WHEN ts.status = 'completed'
                    THEN 1
                    ELSE 0
                END
            ) * 100.0
        ) / NULLIF(COUNT(ts.id), 0),
        2
    ) AS completion_ratio
FROM teams t
LEFT JOIN users u
       ON u.team_id = t.id
LEFT JOIN tasks ts
       ON ts.assigned_to = u.id
GROUP BY t.id, t.name
ORDER BY completion_ratio DESC;

-- EXERCISE 8: Fix the "Urgency Index"
--PROBLEM:
-- You can not multiply strings, and adding a date to strings is useless
--Query:
SELECT
    title,
    priority,
    due_date,
    TRUNC(due_date) - TRUNC(SYSDATE) AS days_until_due,
    CASE priority
        WHEN 'critical' THEN 4
        WHEN 'high' THEN 3
        WHEN 'medium' THEN 2
        ELSE 1
    END AS priority_weight,
    (
        CASE priority
            WHEN 'critical' THEN 4
            WHEN 'high' THEN 3
            WHEN 'medium' THEN 2
            ELSE 1
        END * 10
    )
    (TRUNC(due_date) - TRUNC(SYSDATE)) AS urgency_score
FROM tasks
WHERE due_date IS NOT NULL
  AND status NOT IN ('completed', 'cancelled')
ORDER BY urgency_score DESC;