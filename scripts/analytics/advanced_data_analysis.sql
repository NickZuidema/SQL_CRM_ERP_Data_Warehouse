--===================================
--Change-Over-Time
--===================================
SELECT 
	--DATETRUNC(MONTH, order_date),
	--FORMAT(order_date, 'yyyy-MMM') [order_date],
	YEAR(order_date) [year],
	MONTH(order_date) [month],
	SUM(sales_amount) [total_sales],
	COUNT(DISTINCT customer_key) [total_customers],
	SUM(quantity) [total_quantity]
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY 
	YEAR(order_date),
	MONTH(order_date)
ORDER BY 1, 2 


--===================================
--Cumulative Analysis
--===================================
--Calculate the total sales per month an the running total of sales over time
SELECT
	[month],
	total_sales,
	SUM(total_sales) OVER(
		PARTITION BY YEAR([month]) 
		ORDER BY [month] ASC) [running_total_sales],
	AVG(total_sales) OVER(
		PARTITION BY YEAR([month])
		ORDER BY [month] ASC) [running_avg_sales]
FROM(
	SELECT
		DATETRUNC(month, order_date) [month],
		SUM(sales_amount) AS [total_sales]
	FROM gold.fact_sales
	WHERE DATETRUNC(month, order_date) IS NOT NULL
	GROUP BY DATETRUNC(month, order_date)
)t

--===================================
--Performance Analysis
--===================================
--Analyze the yearly performance of products by comparing each product's sales to both its average performance and the previous year's sales
WITH yearly_product_sales AS(
	SELECT
		YEAR(s.order_date) [year],
		p.product_name,
		SUM(s.sales_amount) [current_sales]
	FROM gold.fact_sales s
	INNER JOIN gold.dim_products p
		ON s.product_key=p.product_key
	WHERE order_date IS NOT NULL
	GROUP BY 
		YEAR(order_date), 
		p.product_name
)

SELECT
	year,
	product_name,
	current_sales,
	current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY year) [diff_prev_sales],
	CASE 
		WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY year) > 0 THEN 'Increase'
		WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY year) < 0 THEN 'Decrease'
		ELSE 'No Change'
	END [prev_change],
	AVG(current_sales) OVER(PARTITION BY product_name) [avg_sales],
	current_sales - AVG(current_sales) OVER(PARTITION BY product_name) [diff_avg],
	CASE 
		WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Avg'
		WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below Avg'
		ELSE 'Avg'
	END [avg_change]
FROM yearly_product_sales
ORDER BY product_name, year

--===================================
--Part-to-Whole Analysis
--===================================
SELECT 
	*
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='gold'

--Which categories contribute the most to overall sales?
WITH category_sales AS(
	SELECT
		p.category [category],
		SUM(s.sales_amount) [sales]
	FROM gold.fact_sales s
	INNER JOIN gold.dim_products p
	ON s.product_key=p.product_key
	GROUP BY p.category
)

SELECT
	category,
	sales,
	SUM(sales) OVER() [total_sales],
	CONCAT(ROUND((CAST(sales AS float)/SUM(sales) OVER()) * 100, 2), '%')[percentage]
FROM category_sales
ORDER BY sales DESC


--===================================
--Data Segmentation
--===================================
--Segment products into cost ranges and count how many products fall into each segment.
WITH cost_segmentation AS (
	SELECT
		product_name,
		cost,
		CASE 
			WHEN COST < 100 THEN 'Below 100'
			WHEN COST BETWEEN 100 AND 500 THEN '100 - 500'
			WHEN COST BETWEEN 500 AND 1000 THEN '500 - 1000'
			ELSE 'Above 1000'
		END [cost_range]
	FROM gold.dim_products
	--ORDER BY cost ASC
)

SELECT
	cost_range,
	COUNT(1) [products]
FROM cost_segmentation
GROUP BY cost_range
ORDER BY 2 DESC

/*Group customers into three segments based on their spending behavior:
	-VIP: Customers with at least 12 months of history and spending more than $5,000.
	-Regular: Customers with at least 12 months of history but spending $5,000 or less.
	-New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group.*/
WITH customer_segmentation AS(
	SELECT 
		s.customer_key,
		MIN(s.order_date) [earliest_order],
		MAX(s.order_date) [latest_order],
		DATEDIFF(MONTH, MIN(s.order_date), MAX(s.order_date)) [months_of_history],
		SUM(sales_amount) [total_sales],
		CASE
			WHEN 
				DATEDIFF(MONTH, MIN(s.order_date), MAX(s.order_date)) >= 12 
				AND SUM(sales_amount) > 5000
					THEN 'VIP'
			WHEN
				DATEDIFF(MONTH, MIN(s.order_date), MAX(s.order_date)) >= 12 
				AND SUM(sales_amount) <= 5000
					THEN 'Regular'
			ELSE
					'New'
		END [customer_class]
	FROM gold.fact_sales s
	INNER JOIN gold.dim_customers c
		ON s.customer_key=c.customer_key
	GROUP BY s.customer_key
	--ORDER BY 6 DESC
)

SELECT
	customer_class,
	COUNT(1) [class_count]
FROM customer_segmentation
GROUP BY customer_class



