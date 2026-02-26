-- lesson 10
-- 10.1
SELECT Name, max(Years_employed) FROM employees;
-- 10.2
SELECT Role, avg(Years_employed) FROM employees Group By Role;
-- 10.3
SELECT Building, sum(Years_employed) FROM employees Group By Building;

-- lesson 11
-- 11.1
SELECT role, count(*) as Num_Employees FROM employees WHERE Role = "Artist";
-- 11.2
SELECT role, count(*) as Num_Employees FROM employees GROUP BY Role;
-- 11.3
SELECT role, sum(Years_Employed) as Total_Number_Years_Employed 
FROM employees WHERE Role = "Engineer" GROUP BY Role;

-- Aggregating Rows: Databases for Developers
-- 4
Select count( DISTINCT SHAPE) as NUMBER_OF_SHAPES, stddev( DISTINCT WEIGHT) as DISTINCT_WEIGHT_STDDEV FROM BRICKS;
-- 6
Select Shape, sum(WEIGHT) as SHAPE_WEIGHT FROM BRICKS GROUP BY Shape ORDER BY Shape;
-- 8
select shape, sum ( weight ) from   bricks
having sum(weight) < 4 group by shape;