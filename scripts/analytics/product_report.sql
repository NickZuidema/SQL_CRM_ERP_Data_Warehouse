/*
============================================
Product Report
============================================
Purpose:
	-Consolidates key product metrics and behaviors
		1. Segmentaion of products by revenue to identify tiers of performances
		2. Product-level metrics:
			- total orders
			- total sales
			- total quantity sold
			- total unique customers
			- lifespan (in months)
		3. KPIs:
			- recency (months since last sale)
			- average order revenue
			- average monthly revenue
*/
CREATE VIEW gold.report_products AS
WITH base_table AS(
	--Joins important columns from gold.fact_sales and gold.dim_products
	SELECT 
		s.order_number,
		s.customer_key,
		s.order_date,
		s.sales_amount,
		s.quantity,
		p.product_key,
		p.product_number,
		p.product_name,
		p.category,
		p.subcategory,
		p.cost
	FROM gold.fact_sales s
	INNER JOIN gold.dim_products p
		ON s.product_key=p.product_key
)

, product_aggregation AS(
	--Aggregates important values, such as the sum of sales per product
	SELECT 
		product_key,
		product_number,
		product_name,
		category,
		subcategory,
		cost,
		COUNT(DISTINCT order_number) [total_orders],
		SUM(sales_amount) [total_sales],
		SUM(quantity) [total_quantity],
		COUNT(DISTINCT customer_key) [total_customers],
		MAX(order_date) [last_order_date],
		DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) [lifespan]
	FROM base_table
	GROUP BY 
		product_key,
		product_number,
		product_name,
		category,
		subcategory,
		cost
)

SELECT 
	product_key,
	product_number,
	product_name,
	category,
	subcategory,
	cost,
	total_sales,
	CASE
		WHEN total_sales > 800000 THEN 'High-Performer'
		WHEN total_sales BETWEEN 400000 AND 800000 THEN 'Mid-Range'
		WHEN total_sales < 400000 THEN 'Low-Performer'
		ELSE 'N/A'
	END
	last_order_date,
	DATEDIFF(MONTH, last_order_date, GETDATE()) [recency],
	total_orders,
	total_quantity,
	total_customers,
	lifespan,
	CASE
		WHEN total_sales = 0 THEN 0
		ELSE total_sales / total_orders
	END [avg_order_revenue],
	CASE
		WHEN total_sales = 0 THEN 0
		ELSE total_sales / lifespan
	END [avg_monthly_revenue]
FROM product_aggregation


