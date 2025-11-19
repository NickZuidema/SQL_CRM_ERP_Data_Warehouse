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