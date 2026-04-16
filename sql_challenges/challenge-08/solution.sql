-- Questions:
-- a) What scan type do you see? Why?
-- Full table scann, given that it checked the whole table without an index 

-- b) site_id has values 1–5. Is this high or low cardinality?
-- high

-- c) Would adding an index on site_id help? Why or why not?
-- It would be helpfull, but if we want to search for an especific record we would have to support it with another conditional

-- ============================================================
-- Exercise 2 — Create an index and see if it helps
--
-- Create an index on visit_date.
-- Then run the range query below and check the plan.
-- ============================================================

-- Step 1: Create it
CREATE INDEX excer2
ON patient_visits (visit_date);


-- Step 2: Gather stats
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

-- Step 3: Run the range query and check the plan
EXPLAIN PLAN FOR
SELECT * FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 30 AND SYSDATE;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) Does Oracle use the index for this range?
-- No it is not using its index

-- b) Change the range to the last 7 days. Does the plan change?
--  No it did not change

-- c) Change to the last 700 days. What happens?
-- No it did not change

-- d) Why does the range size affect whether Oracle uses the index?
-- Because the range of the table is so large, it does not make sense for the logic

-- ============================================================
-- Exercise 3 — Composite index
--
-- You often query by both patient_id AND visit_date together:
--   WHERE patient_id = 1234 AND visit_date > SYSDATE - 90
--
-- Two options:
--   Option A: Two separate indexes (one per column)
--   Option B: One composite index (patient_id, visit_date)
--
-- Create the composite index and test the query.
-- ============================================================

CREATE INDEX idx_pv_patient_date ON patient_visits(patient_id, visit_date);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

EXPLAIN PLAN FOR
SELECT * FROM patient_visits
WHERE patient_id = 1234
  AND visit_date > SYSDATE - 90;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) Does the plan use the composite index?
-- Yes it did 

-- b) Now try querying ONLY on visit_date (no patient_id).
-- It stopped using composite index and came back to using the full table scann

-- c) Does the composite index get used? Why not?
-- Given that the key of the index is compoosed of 2 values, when we ut only one the index is not called

-- d) What's the rule about column order in composite indexes?
-- That in whatever order you put values in the definition of the index, you must put in that order when searching with WHERE

-- ============================================================
-- Exercise 4 — Function that breaks an index
--
-- There IS an index on patient_id (from lesson 03).
-- Predict what happens when you wrap the column in a function.
-- ============================================================

-- This query CAN use the index:
EXPLAIN PLAN FOR
SELECT * FROM patient_visits WHERE patient_id = 5432;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- This one cannot — why?
EXPLAIN PLAN FOR
SELECT * FROM patient_visits WHERE TO_CHAR(patient_id) = '5432';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) What scan type did the second query use?
-- full table scann

-- b) Why does wrapping a column in a function break index use?
-- given that it changes the type of data, and the index was defined with other data

-- c) How would you rewrite the second query to allow index use?
-- SELECT * FROM patient_visits WHERE patient_id = TO_INT('5432')

-- ============================================================
-- Exercise 5 — Discussion: real-world scenarios
--
-- For each scenario below, decide:
--   a) Would you add an index?
--   b) On which column(s)?
--   c) Any concerns?
-- ============================================================

-- Scenario A:
-- A reporting table gets loaded once per night (batch ETL).
-- During the day, analysts run SELECT queries by date range.
-- The table has 50 million rows.
-- → Index on date? Yes/No, why?
-- Yes, given that the table has 50 million rows, and the the queries are made in between two dates 
-- on the clomun of date
-- Given the size of the table, the indx would be very big, a B-tree would be the best option

-- Scenario B:
-- An OLTP orders table gets 10,000 inserts per minute.
-- Support staff look up orders by customer_id or order_status.
-- order_status has 4 values: pending, processing, shipped, cancelled.
-- → What indexes would you add?
-- Yes, a composite index
-- on customer_id and order_status
-- Given that there are 10,000 insertions per minute, can slow the queries relatively fast over the day

-- Scenario C:
-- A patient table has an email column (unique per patient).
-- There are 5 million patients.
-- The app frequently does: WHERE email = 'user@example.com'
-- → What kind of index would be best here?
-- Yes, a B-tree index, given that it would fastly search for the range in which the email is, even if its 5 million long
-- on email 
-- It would take space and it could make a bot slower the inserts, but this does not represent a problem in this case