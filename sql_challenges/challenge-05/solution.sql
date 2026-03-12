-- Union, Minus, and Intersect: Databases for Developers
-- 5.1
select colour from my_brick_collection
UNION
select colour from your_brick_collection
order by colour;
-- 5.2
select shape from my_brick_collection
UNION ALL
select shape from your_brick_collection
order  by shape;

-- 10.1
select shape from my_brick_collection
MINUS
select shape from your_brick_collection;
-- 10.2
select colour from my_brick_collection
INTERSECT 
select colour from your_brick_collection
order  by colour;