/*
============================================
Customer Report
============================================
Purpose:
	-Consolidates key consumer metrics and behaviors
		1. Segmentaion of customers based on customer category and age group
		2. Customer-level metrics:
			- total orders
			- total sales
			- total quantity purchased
			- total products
			- lifespan (in months)
		3. KPIs:
			- recency (months since last order)
			- average order value
			- average monthly spend
*/

CREATE VIEW gold.report_customers AS
WITH base_query AS(
	--Joins important columns from gold.fact_sales and gold.dim_customers,
	--as well as simple transformations/calculations
	SELECT
		s.order_number,
		s.product_key,
		s.order_date,
		s.sales_amount,
		s.quantity,
		c.customer_key,
		c.customer_number,
		c.first_name,
		c.last_name,
		CONCAT(c.first_name, ' ', c.last_name) [customer_name],
		c.birthdate,
		DATEDIFF(YEAR, c.birthdate, GETDATE()) [age]
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_customers c
		ON s.customer_key=c.customer_key
	WHERE s.order_date IS NOT NULL
)

, customer_aggregation AS(
--Aggregates important values, such as the sum of sales per customer
SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) [total_orders],
	SUM(sales_amount) [total_sales],
	SUM(quantity) [total_quantity],
	COUNT(DISTINCT product_key) [total_products],
	MAX(order_date) [last_order_date],
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) [lifespan]
FROM base_query
GROUP BY
	customer_key,
	customer_number,
	customer_name,
	age
)

--Final query which compiles all data that is important for business decision-making
SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	CASE	
		WHEN age < 20 THEN 'Under 20' 
		WHEN age BETWEEN 20 AND 29 THEN '20-29'
		WHEN age BETWEEN 30 AND 39 THEN '30-39'
		WHEN age BETWEEN 40 AND 49 THEN '40-49'
		ELSE '50 and Above'
	END [age_group],
	CASE	
		WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
		WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
		ELSE 'New'
	END [customer_segment],
	last_order_date,
	DATEDIFF(MONTH, last_order_date, GETDATE()) [recency],
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	lifespan,
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	END [avg_order_value],
	CASE 
		WHEN lifespan = 0 THEN 0
		ELSE total_sales / lifespan
	END [avg_monthly_spend]
FROM customer_aggregation