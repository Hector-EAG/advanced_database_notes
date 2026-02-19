-- lesson 6
-- 6.1
SELECT title, domestic_sales, international_sales 
FROM movies
JOIN boxoffice
ON movies.id = boxoffice.movie_id;
-- 6.2
SELECT title, domestic_sales, international_sales 
FROM movies
JOIN boxoffice
ON movies.id = boxoffice.movie_id
Where boxoffice.international_sales > boxoffice.domestic_sales;
-- 6.3
SELECT title, rating 
FROM movies
JOIN boxoffice
ON movies.id = boxoffice.movie_id
ORDER BY boxoffice.rating DESC;

-- lesson 7
-- 7.1
SELECT DISTINCT building_name FROM buildings
JOIN employees
ON buildings.building_name = employees.building;
-- 7.2
SELECT * FROM buildings;
-- 7.3
SELECT DISTINCT building_name, role FROM buildings
LEFT JOIN employees
ON building_name = employees.building;

-- Lemur
SELECT pages.page_id FROM pages
LEFT JOIN page_likes
ON pages.page_id = page_likes.page_id
WHERE page_likes.user_id IS NULL
ORDER BY pages.page_id;