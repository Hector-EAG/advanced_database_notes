-- Analytic Functions: Databases for Developers
-- 3
select b.*,
       count(*) over (
         partition BY shape
       ) bricks_per_shape,
       median ( weight ) over (
         partition BY shape
       ) median_weight_per_shape
from   bricks b
order  by shape, weight, brick_id;

-- 5
select b.brick_id, b.weight,
       round ( avg ( weight ) over (
         order BY brick_id
       ), 2 ) running_average_weight
from   bricks b
order  by brick_id;

-- 9
select b.*,
       min ( colour ) over (
         order by brick_id
         rows between 2 preceding and 1 preceding
       ) first_colour_two_prev,
       count (*) over (
         order by weight
         range between current row and 1 following
       ) count_values_this_and_next
from   bricks b
order  by weight;

-- 11
with totals as (
  select b.*,
         sum ( weight ) over (
           PARTITION BY b.SHAPE
         ) weight_per_shape,
         sum ( weight ) over (
           ORDER BY b.BRICK_ID
         ) running_weight_by_id
  from   bricks b
)
select * from totals
where  weight_per_shape > 4 AND running_weight_by_id > 4
order  by brick_id

-- Data Lemur
SELECT 
    d.department_name,
    e.name,
    e.salary
FROM (
    SELECT 
        employee_id,
        name,
        salary,
        department_id,
        DENSE_RANK() OVER (
            PARTITION BY department_id
            ORDER BY salary DESC
        ) AS salary_rank
    FROM employee
) e
JOIN department d 
    ON e.department_id = d.department_id
WHERE e.salary_rank <= 3
ORDER BY 
    d.department_name ASC,
    e.salary DESC,
    e.name ASC;