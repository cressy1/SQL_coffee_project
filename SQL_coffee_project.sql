-- monday_coffee_data analysis
SELECT *
FROM city;
SELECT *
FROM products;
SELECT *
FROM customers;
SELECT *
FROM sales;

-- Reports and Data Analysis
-- Q1. Count of coffee consumers:
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT 
	city_name,
	ROUND((population * 0.25)/1000000, 2) AS coffee_consumers_in_millions,
	city_rank
FROM
	city
ORDER BY 2 DESC;

-- Q2. Total revenue from coffee sales: What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT *,
	EXTRACT(YEAR FROM sale_date) AS Year,
	EXTRACT(QUARTER FROM sale_date) AS QTR
FROM 
	sales
WHERE
	EXTRACT(YEAR FROM sale_date) = 2023 
AND
	EXTRACT(QUARTER FROM sale_date) = 4;

SELECT
	SUM(total) AS total_revenue
FROM
	sales
WHERE
	EXTRACT(YEAR FROM sale_date) = 2023 
AND
	EXTRACT(QUARTER FROM sale_date) = 4;

-- If we want to find out each city revenue
SELECT
	ci.city_name,
	SUM(s.total) AS total_revenue
FROM
	sales AS s
JOIN customers AS c
ON 
	s.customer_id = c.customer_id
JOIN city AS ci
ON 
	ci.city_id = c.city_id
WHERE
EXTRACT
	(YEAR FROM s.sale_date) = 2023 
AND
EXTRACT
	(QUARTER FROM s.sale_date) = 4
GROUP BY 
	1
ORDER BY 
	2 DESC;

-- Q3. Sales count for each product: How many units of each coffee product have been sold?
SELECT 
	p.product_name,
	COUNT(s.sale_id) AS total_orders
FROM products AS p
	LEFT JOIN sales AS s  -- we do a left join here because we want to see all the products even if they have not made any sales
	ON s.product_id = p.product_id
	GROUP BY 1
	ORDER BY 2 DESC;

-- Q4. Average sales amount per city: What is the average sales amount per customer in each city?
-- STEP 1. Find each city and their total sales
-- STEP 2. Find number of customers in each city.

SELECT
	ci.city_name,
	SUM(s.total) AS total_revenue,
	COUNT(DISTINCT s.customer_id) AS total_customers,
	ROUND(
		SUM(s.total):: NUMERIC/
		COUNT(DISTINCT s.customer_id):: NUMERIC, 2) AS average_sales_per_customer -- I used DISTINCT because i want a count of each unique customer not repeated customers
FROM sales AS s
JOIN customers AS c
	ON s.customer_id = c.customer_id
JOIN city AS ci
	ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;

-- Q5. City population and coffee consumers (25%): Provide a list of cities with their population and estimated coffee consumers.
--  STEP1. City population and coffee consumers (25%)
-- STEP2. provide the list of cities along with their populations and estimated coffee consumers
-- STEP3. return city name, total customers, estimated coffee consumers (25%)
WITH city_table AS
	(
	SELECT 
	city_name,
	ROUND((population * 0.25)/1000000, 2) AS coffee_consumers_in_millions
	FROM city
	),
customer_table AS
	(
	SELECT
	ci.city_name,
	COUNT(DISTINCT c.customer_id) AS unique_customers
	FROM sales AS s
	JOIN customers AS c
	ON s.customer_id = c.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	ct.city_name,
	ct.coffee_consumers_in_millions,
	cu.unique_customers
FROM city_table AS ct
JOIN customer_table AS cu
ON ct.city_name = cu.city_name;

-- Q6. Top selling products by city: what are the top 3 selling products in each city based on sales volume?
SELECT 
	c.city_name,
	p.product_name,
	COUNT(s.sale_id) AS total_orders,
	DENSE_RANK() OVER(PARTITION BY c.city_name ORDER BY COUNT(s.sale_id) DESC) AS rank -- we are using dense rank because it's possible two or three products may have the same sale amount or order amount 
FROM sales AS s
JOIN products AS p
ON s.product_id = p.product_id
JOIN customers AS cu
ON cu.customer_id = s.customer_id
JOIN city AS c
ON c.city_id = cu.city_id
GROUP BY 1, 2;
	-- ORDER BY 1, 3 DESC;
-- to get the top 3  selling products, we will need to filter using the WHERE statement. Note that the WHERE statement will not work on the DENSE RANK column cos it's not an actual column, it's a window function. So we are going to save the entire query in a subquerry
SELECT *
FROM 	
	(SELECT 
	c.city_name,
	p.product_name,
	COUNT(s.sale_id) AS total_orders,
	DENSE_RANK() OVER(PARTITION BY c.city_name ORDER BY COUNT(s.sale_id) DESC) AS rank -- we are using dense rank because it's possible two or three products may have the same sale amount or order amount 
	FROM sales AS s
	JOIN products AS p
	ON s.product_id = p.product_id
	JOIN customers AS cu
	ON cu.customer_id = s.customer_id
	JOIN city AS c
	ON c.city_id = cu.city_id
	GROUP BY 1, 2)
	 AS t1
WHERE rank <=3;

-- Q. Customer segmentation by city: How many unique customers are there in each city who have purchased coffee products?
SELECT * 
FROM products;

SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) AS uniqu_customers
FROM city AS ci
LEFT JOIN customers AS c
ON c.city_id = ci.city_id
JOIN sales AS s
ON s.customer_id = c.customer_id
WHERE s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY 1;
-- JOIN  products AS p
-- ON p.product_id = s.product_id

-- Q8. Average sales VS rent: Find each city and their average sale per customer and average rent per customer

SELECT
	ci.city_name,
	COUNT(DISTINCT s.customer_id) AS total_customers,
	ROUND(
		SUM(s.total):: NUMERIC/
		COUNT(DISTINCT s.customer_id):: NUMERIC, 2) AS average_sales_per_customer -- I used DISTINCT because i want a count of each unique customer not repeated customers
FROM sales AS s
JOIN customers AS c
ON s.customer_id = c.customer_id
JOIN city AS ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;

-- tO GET THE AVG RENT: city and total rent/total customers. we need to put the above querry in a CTE
WITH city_table
	AS
		(SELECT
			ci.city_name,
			COUNT(DISTINCT s.customer_id) AS total_customers,
			ROUND(
				SUM(s.total):: NUMERIC/
				COUNT(DISTINCT s.customer_id):: NUMERIC, 2) AS average_sales_per_customer -- I used DISTINCT because i want a count of each unique customer not repeated customers
		FROM sales AS s
		JOIN customers AS c
		ON s.customer_id = c.customer_id
		JOIN city AS ci
		ON ci.city_id = c.city_id
		GROUP BY 1
		ORDER BY 2 DESC),
city_rent 
	AS
(	
	SELECT
		city_name,
		estimated_rent
	FROM city
)

SELECT
	cr.city_name,
	cr.estimated_rent,
	ct.total_customers,
	ct.average_sales_per_customer,
	ROUND
	(cr.estimated_rent::NUMERIC/
	ct.total_customers::NUMERIC, 2) AS average_rent
FROM city_rent as cr
JOIN city_table AS ct
ON ct.city_name = cr.city_name
ORDER BY 4 DESC;

-- Q9. Monthly sales growth: Sales growth rate, Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city.
WITH 
 monthly_sales
AS	
	(SELECT
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) AS month,
		EXTRACT(YEAR FROM sale_date) AS year,
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
	city_name,
	month,
	year,
	total_sale AS current_month_sale,
	LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) AS last_month_sale --we use a LAG window function to get the sale of the previous monthly total sale 
-- to find the growth ratio, current_month_sale - last_month_sale/last_month_sale
FROM monthly_sales;

WITH 
 monthly_sales
AS	
	(SELECT
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) AS month,
		EXTRACT(YEAR FROM sale_date) AS year,
		SUM(s.total) AS total_sale
	FROM sales AS s
	JOIN customers AS c
	ON c.customer_id = s.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1,2,3
	ORDER BY 1,3,2
),
growth_ratio
AS	
(
	SELECT
		city_name,
		month,
		year,
		total_sale AS current_month_sale,
		LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) AS last_month_sale
	FROM monthly_sales
)
SELECT
	city_name,
	month,
	year,
	current_month_sale,
	last_month_sale,
	ROUND((current_month_sale-last_month_sale)::NUMERIC/last_month_sale::NUMERIC * 100, 2) AS growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL;

-- Q10. Market potential analysis: Identify top 3 cities based on highest sales, return city name, total sale, total rent, total customers, total rent, estimated rent
	
WITH city_table
	AS
		(SELECT
			ci.city_name,
			SUM(s.total) AS total_revenue,
			COUNT(DISTINCT s.customer_id) AS total_customers,
			ROUND(
				SUM(s.total):: NUMERIC/
				COUNT(DISTINCT s.customer_id):: NUMERIC, 2) AS average_sales_per_customer -- I used DISTINCT because i want a count of each unique customer not repeated customers
		FROM sales AS s
		JOIN customers AS c
		ON s.customer_id = c.customer_id
		JOIN city AS ci
		ON ci.city_id = c.city_id
		GROUP BY 1
		ORDER BY 2 DESC),
city_rent 
	AS
(	
	SELECT
		city_name,
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) AS estimated_coffee_consumers_in_millions
	FROM city
)

SELECT
	cr.city_name,
	total_revenue,
	cr.estimated_rent AS total_rent,
	ct.total_customers,
	estimated_coffee_consumers_in_millions,
	ct.average_sales_per_customer,
	ROUND
	(cr.estimated_rent::NUMERIC/
	ct.total_customers::NUMERIC, 2) AS average_rent
FROM city_rent as cr
JOIN city_table AS ct
ON ct.city_name = cr.city_name
ORDER BY 2 DESC;

-- RECOMMENDATION
-- City 1: pune - 
-- 		1. Avg rent per customer is less
--		2. highest total revenue 
--		3. avg sale per customer is also high

-- City 2: Delhi-
--		1. Highest estimated coffee consumers - 7.7million
--		2. Highest total customers - 68
--		3. Avg rent per customer 330.88

-- City 3: jaipur -
--		1. Highest customer number which is 69
-- 		2. Avg rent per customer is very less - 156.52
--		3. Avg sale per customer is better - 11.6k