/*
SCRIPT PURPOSE:
	Quality check on all Gold views.
*/

--Customers
SELECT * FROM gold.dim_customers

SELECT DISTINCT 
	gender 
FROM gold.dim_customers


--Products
SELECT * FROM gold.dim_products


--Sales
SELECT * FROM gold.fact_sales

--Check FK Integrity
SELECT 
	*
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
	ON c.customer_key=f.customer_key
LEFT JOIN gold.dim_products p
	ON p.product_key=f.product_key
WHERE c.customer_key IS NULL


--Everything
SELECT * FROM gold.dim_customers
SELECT * FROM gold.dim_products
SELECT * FROM gold.fact_sales

