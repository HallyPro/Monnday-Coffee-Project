-- Monday Coffee -- Data Analysis

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;


-- Reports & Data Analysis

-- Q.1 Coffee Consumers Count 
-- How many people in each city are estimated to consume coffee, given that 25% of the population does 

SELECT 
	city_name,
	ROUND((population * 0.25)/1000000, 2) as coffee_counsumers_in_milliions,
	city_rank 
FROM city 
ORDER BY 2 DESC;


-- Q.2 
-- Total revenue from coffee sales 
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT 
	SUM(total) AS total_revenue 
FROM sales
WHERE 
	EXTRACT(YEAR FROM sale_date) = 2023
	AND
	EXTRACT(QUARTER FROM sale_date) = 4 ;

SELECT 
	ci.city_name,
	SUM(total) AS total_revenue 
FROM sales AS s
JOIN customers AS c 
ON s.customer_id = c.customer_id
JOIN city AS ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date) = 2023
	AND
	EXTRACT(QUARTER FROM s.sale_date) = 4
GROUP BY 1 
ORDER BY 2 DESC;


-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM products AS p
LEFT JOIN sales AS s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY COUNT(s.sale_id) DESC


-- Q.4
-- Average Sales Amount per city 
-- What is the average sales amount per customer in each city?

SELECT 
	ci.city_name,
	SUM(total) AS total_revenue, 
	COUNT(DISTINCT s.customer_id) AS total_cx,
	ROUND(SUM(s.total):: numeric /COUNT(DISTINCT s.customer_id) :: numeric, 2) AS avg_sale_pr_cx
FROM sales AS s
JOIN customers AS c 
ON s.customer_id = c.customer_id
JOIN city AS ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC


-- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- Return city_name, total current cx, estimated coffee consumers (25% )

WITH city_table AS (
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) AS coffee_consumers_in_millions
	FROM city
),
customers_table AS 
(
	SELECT
		ci.city_name AS city_name,
		COUNT(DISTINCT c.customer_id) AS unique_cx
	FROM sales AS s
	JOIN customers AS c 
	ON s.customer_id = c.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id	GROUP BY 1
)
SELECT 
	ct.city_name,
	ct.coffee_consumers_in_millions,
	cu.unique_cx
FROM city_table AS ct
JOIN customers_table AS cu
ON ct.city_name = cu.city_name 


-- Q6 
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volumes?
SELECT *
FROM
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) AS total_orders,
		DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS rank
	FROM sales AS s
	JOIN products AS p
	on s.product_id = p.product_id
	JOIN customers AS c
	ON c.customer_id = s.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1,2
	-- ORDER BY 1,3 DESC
) AS t
WHERE rank <= 3


-- Q.7
-- Customer Segmentation by City 
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) AS unique_cx
FROM city AS ci
LEFT JOIN customers AS c
ON c.city_id = ci.city_id
JOIN sales AS s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id <= 14
GROUP BY 1

-- Q.8 
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

WITH city_table AS (
	SELECT 
		ci.city_name,
		SUM(total) AS total_revenue, 
		COUNT(DISTINCT s.customer_id) AS total_cx,
		ROUND(SUM(s.total):: numeric /COUNT(DISTINCT s.customer_id) :: numeric, 2) AS avg_sale_pr_cx
	FROM sales AS s
	JOIN customers AS c 
	ON s.customer_id = c.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC 
),
city_rent AS (
	SELECT 
		 city_name,
		 estimated_rent
	FROM city
)

SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sale_pr_cx,
	ROUND(cr.estimated_rent :: NUMERIC /ct.total_cx :: NUMERIC, 2) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
ON cr.city_name = ct.city_name
ORDER BY 5 DESC

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
WITH monthly_sales
AS (
	SELECT 
		ci.city_name AS city,
		EXTRACT(MONTH FROM sale_date) AS month_,
		EXTRACT(YEAR FROM sale_date) AS year_ ,
		SUM(s.total) AS total_sale
	FROM sales AS s 
	JOIN customers AS c
	ON c.customer_id = s.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1,2,3
	ORDER BY 1,3,2
)
SELECT 
	city, 
	month_,
	year_,
	cr_month_sale,
	COALESCE(ROUND((cr_month_sale - last_month_sale):: NUMERIC / last_month_sale:: NUMERIC * 100 ,2), 0) AS growth_ratio
FROM (
	SELECT
		city,
		month_,
		year_,
		total_sale AS cr_month_sale,
		LAG(total_sale, 1) OVER (PARTITION BY city ORDER BY year_, month_) AS last_month_sale
	FROM monthly_sales
) AS t


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total consumers, estimated coffee consumers
WITH city_table AS (
	SELECT 
		ci.city_name,
		SUM(total) AS total_revenue, 
		COUNT(DISTINCT s.customer_id) AS total_cx,
		ROUND(SUM(s.total):: numeric /COUNT(DISTINCT s.customer_id) :: numeric, 2) AS avg_sale_pr_cx
	FROM sales AS s
	JOIN customers AS c 
	ON s.customer_id = c.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC 
),
city_rent AS (
	SELECT 
		 city_name,
		 estimated_rent, 
		 ROUND((population * 0.25)/1000000, 3) AS estimated_coffee_consumer_in_million
	FROM city
)

SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent AS total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_million,
	ct.avg_sale_pr_cx,
	ROUND(cr.estimated_rent :: NUMERIC /ct.total_cx :: NUMERIC, 2) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC

/* 
-- Recomendation 
City 1: Pune
	1. Avg rent per cx is very less,
	2. Highest total revenue,
	3. Avg_sale per cx is also  high 

City 2: Delhi 
	1. Highest estimated coffee consumer which is 7.7M
	2. Has 2nd highest total cx which is 68 
	3. Avg rent per cx 330 (still under 500)

City 3: Jaipur 
	1. Highest cx no which is 69 
	2. Avg rent per cx is very less 156
	3. Avg sale per cx is better which is at 11.6



