-- lesson 1
-- 1.1
SELECT Title FROM movies;
-- 1.2
SELECT Director FROM movies;
-- 1.3
SELECT Director, Title FROM movies;
-- 1.4
SELECT year, Title FROM movies;
-- 1.5
SELECT * FROM movies;

-- lesson 2
-- 2.1
SELECT * FROM movies Where id = 6;
-- 2.2
SELECT * FROM movies Where year BETWEEN 2000 AND 2010;
-- 2.3
SELECT * FROM movies Where year NOT BETWEEN 2000 AND 2010;
-- 2.4
SELECT title, year FROM movies WHERE year <= 2003;

-- lesson 3
-- 3.1
SELECT * FROM movies Where title Like "Toy Story%";
-- 3.2
SELECT * FROM movies Where director Like "John Lasseter";
-- 3.3
SELECT * FROM movies Where director NOT Like "John Lasseter";
-- 3.4
SELECT * FROM movies Where title Like "WALL-%";

-- lesson 4
-- 4.1
SELECT Distinct Director FROM movies Order By director ASC;
-- 4.2
SELECT * FROM movies Order By year DESC Limit 4;
-- 4.3
SELECT * FROM movies Order By Title ASC Limit 5;
-- 4.4
SELECT * FROM movies Order By Title ASC Limit 5 Offset 5;

-- lesson 5
-- 5.1
SELECT * FROM north_american_cities Where country like "Canada";
-- 5.2
SELECT * FROM north_american_cities Where country like "United States" Order BY latitude DESC;
-- 5.3
SELECT * FROM north_american_cities Where longitude < -87.629798 Order BY longitude ASC;
-- 5.4
SELECT * FROM north_american_cities Where Country like "Mexico" Order BY population DESC Limit 2;
-- 5.5
SELECT * FROM north_american_cities Where Country like "United States" Order BY population DESC Limit 2 OFFSET 2;
