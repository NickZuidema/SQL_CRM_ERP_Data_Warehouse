USE CRM_ERP_DataWarehouse

--============================================
--Exploratory Data Analysis
--============================================
--Explore all Objects in the Database
SELECT 
	* 
FROM INFORMATION_SCHEMA.TABLES

--Explore all columns in the Database
SELECT 
	*
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers' --All columns for a specific table


--============================================
--Dimensions Exploration
--============================================
--Explore all countries where customers come from
SELECT DISTINCT	
	country
FROM gold.dim_customers

--Explore all product categories "The Major Divisions"
SELECT DISTINCT
	category,
	subcategory,
	product_name
FROM gold.dim_products
ORDER BY 1,2,3

--============================================
--Date Exploration
--============================================
--Find the date of the first and last order
--How many months of sales are available
SELECT
	MIN(order_date) [first_order_date],
	MAX(order_date) [last_order_date],
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) [months_of_sales]
FROM gold.fact_sales

--Find the youngest and oldest customer
SELECT
	*,
	DATEDIFF(YEAR, birthdate, GETDATE()) [age]
FROM gold.dim_customers
WHERE birthdate = (SELECT MIN(birthdate) from gold.dim_customers)
	OR birthdate = (SELECT MAX(birthdate) from gold.dim_customers)


--============================================
--Measures Exploration
--============================================
SELECT 
	*
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold'

SELECT * FROM gold.dim_customers
SELECT * FROM gold.dim_products
SELECT * FROM gold.fact_sales

--Find the total sales
SELECT 
	SUM(sales_amount) [total_sales]
FROM gold.fact_sales

--Find how many items are sold
SELECT
	SUM(quantity) [total_sold_items]
FROM gold.fact_sales

--Find the average selling price
SELECT
	AVG(price) [avg_selling_price]
FROM gold.fact_sales

--Find the total number of orders
SELECT
	COUNT(DISTINCT order_number) [total_no_of_orders]
FROM gold.fact_sales

--Find the total number of products
SELECT 
	COUNT(1) [total no_of_products]
FROM gold.dim_products

--Find the total number of customers
SELECT
	COUNT(1) [total_no_of_customers]
FROM gold.dim_customers

--Find the total number of customers that have placed an order
SELECT 
	COUNT(DISTINCT customer_key) [total_customers_ordered]
FROM gold.fact_sales --Counts distinct customers from sales view directly

SELECT 
	COUNT(DISTINCT s.customer_key) [total_customers_ordered]
FROM gold.fact_sales s
INNER JOIN gold.dim_customers c
	ON s.customer_key=c.customer_key --Checks first for customers that exist in both sales and customers views, then counts the distinct members

--Report that shows all key metrics of the business
--Column-based
SELECT
	SUM(s.sales_amount) [total_sales],
	SUM(s.quantity) [total_sold_items],
	AVG(s.price) [avg_selling_price],
	COUNT(DISTINCT s.order_number) [total_no_of_orders],
	COUNT(DISTINCT p.product_id) [total no_of_products],
	COUNT(DISTINCT c.customer_id) [total_no_of_customers],
	COUNT(DISTINCT s.customer_key) [total_customers_ordered]
FROM gold.fact_sales s
FULL JOIN gold.dim_products p
	ON s.product_key=p.product_key
LEFT JOIN gold.dim_customers c
	ON s.customer_key=c.customer_key

--Row-based (Better)
SELECT 'Total Sales' [measure_name], SUM(sales_amount) [measure_value] FROM gold.fact_sales
UNION ALL
SELECT 'Total Sold Items' [measure_name], SUM(quantity) [measure_value] FROM gold.fact_sales
UNION ALL
SELECT 'Avg Selling Price' [measure_name], AVG(price) [measure_value] FROM gold.fact_sales
UNION ALL
SELECT 'Total No. of Orders' [measure_name], COUNT(DISTINCT order_number) [measure_value] FROM gold.fact_sales
UNION ALL
SELECT 'Total No. of Products' [measure_name], COUNT(1) [measure_value] FROM gold.dim_products
UNION ALL
SELECT 'Total No. of Customers' [measure_name], COUNT(1) [measure_value] FROM gold.dim_customers
UNION ALL
SELECT 'Total Customers Ordered' [measure_name], COUNT(DISTINCT customer_key) [measure_value] FROM gold.fact_sales


--============================================
--Magnitude Analysis
--============================================
--Find total customers by country
SELECT
	country,
	COUNT(1) [no_of_customers]
FROM gold.dim_customers
GROUP BY country
ORDER BY [no_of_customers] DESC

--Find total customers by gender
SELECT
	gender,
	COUNT(1) [no_of_customers]
FROM gold.dim_customers
GROUP BY gender
ORDER BY [no_of_customers] DESC

--Find total products by category
SELECT
	category,
	COUNT(1) [no_of_products]
FROM gold.dim_products
GROUP BY category
ORDER BY [no_of_products] DESC

--What is the average costs in each category?
SELECT
	category,
	AVG(cost) [avg_cost]
FROM gold.dim_products
WHERE cost > 0 --Products that cost 0 are not counted
GROUP BY category
ORDER BY [avg_cost] DESC

--What is the total revenue generated for each category?
SELECT
	p.category,
	SUM(s.sales_amount) [avg_revenue]
FROM gold.fact_sales s
INNER JOIN gold.dim_products p
	ON s.product_key=p.product_key
GROUP BY p.category
ORDER BY [avg_revenue] DESC
	
--Find total revenue that is generated by each customer
SELECT
	s.customer_key,
	c.first_name,
	c.last_name,
	SUM(s.sales_amount) [total_sales]
FROM gold.fact_sales s
INNER JOIN gold.dim_customers c
	ON s.customer_key=c.customer_key
GROUP BY 
	s.customer_key,
	c.first_name,
	c.last_name
ORDER BY [total_sales] DESC

--What is the distribution of sold items accross countries?
--More specific
SELECT
	c.country,
	p.product_name,
	COUNT(1) [sold_items]
FROM gold.fact_sales s
INNER JOIN gold.dim_customers c
	ON c.customer_key=s.customer_key
INNER JOIN gold.dim_products p
	ON p.product_key=s.product_key
GROUP BY c.country, p.product_name
ORDER BY 1,2

--Less Specific
SELECT
	c.country,
	COUNT(1) [sold_items]
FROM gold.fact_sales s
INNER JOIN gold.dim_customers c
	ON c.customer_key=s.customer_key
GROUP BY c.country
ORDER BY 1 DESC


--============================================
--Ranking Analysis
--============================================
SELECT 
	*
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold'

SELECT * FROM gold.dim_customers
SELECT * FROM gold.dim_products
SELECT * FROM gold.fact_sales

--Which 5 products generate the highest revenue?
SELECT TOP 5
	p.product_name,
	SUM(sales_amount) [total_revenue]
FROM gold.fact_sales s
INNER JOIN gold.dim_products p
	ON s.product_key=p.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC

SELECT *
FROM(
	SELECT 
		p.product_name,
		SUM(sales_amount) [total_revenue],
		ROW_NUMBER() OVER(ORDER BY SUM(sales_amount) DESC) [ranking]
	FROM gold.fact_sales s
	INNER JOIN gold.dim_products p
		ON s.product_key=p.product_key
	GROUP BY p.product_name
)t
WHERE ranking <= 5

--What are the 5 worst-performing products in terms of sales?
SELECT TOP 5
	p.product_name,
	SUM(sales_amount) [total_revenue]
FROM gold.fact_sales s
INNER JOIN gold.dim_products p
	ON s.product_key=p.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC

--Find the top 10 customers who ave generated the highest revenue
SELECT 
	t.customer_key,
	c.first_name,
	c.last_name,
	t.total_revenue,
	t.ranking
FROM(
	SELECT
		customer_key,
		SUM(sales_amount) [total_revenue],
		ROW_NUMBER() OVER(ORDER BY SUM(sales_amount) DESC) [ranking]
	FROM gold.fact_sales 
	GROUP BY customer_key
)t
INNER JOIN gold.dim_customers c
	on t.customer_key=c.customer_key
WHERE ranking <= 10
ORDER BY ranking ASC

--Simpler
SELECT TOP 10
	s.customer_key,
	c.first_name,
	c.last_name,
	SUM(sales_amount) [total_revenue]
FROM gold.fact_sales s
INNER JOIN gold.dim_customers c
	ON s.customer_key=c.customer_key
GROUP BY
	s.customer_key,
	c.first_name,
	c.last_name
ORDER BY total_revenue DESC


--The 3 customers with the fewest orders placed
SELECT TOP 3
	s.customer_key,
	c.first_name,
	c.last_name,
	COUNT(1) [total_orders]
FROM gold.fact_sales s
INNER JOIN gold.dim_customers c
	ON s.customer_key=c.customer_key
GROUP BY
	s.customer_key,
	c.first_name,
	c.last_name
ORDER BY total_orders ASC