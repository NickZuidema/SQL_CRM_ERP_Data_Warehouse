--Customers (Dimension)
CREATE VIEW gold.dim_customers AS(
	SELECT
		ROW_NUMBER() OVER(ORDER BY cst_id) [customer_key],
		ci.cst_id [customer_id],
		ci.cst_key [customer_number],
		ci.cst_firstname [first_name],
		ci.cst_lastname [last_name],
		la.cntry [country],
		ci.cst_marital_status [marital_status],
		CASE 
			WHEN ci.cst_gender != 'N/A' THEN ci.cst_gender
			ELSE ISNULL(ca.gen, 'N/A')
		END [gender],
		ca.bdate [birthdate],
		ci.cst_create_date [create_date]
	FROM silver.crm_cust_info ci
	LEFT JOIN silver.erp_cust_az12 ca
		ON ci.cst_key=ca.cid
	LEFT JOIN silver.erp_loc_a101 la
		on ci.cst_key=la.CID
)

--Products (Dimension)
CREATE VIEW gold.dim_products AS(
	SELECT 
		ROW_NUMBER() OVER(ORDER BY pi.prd_start_date, pi.prd_key) [product_key],
		pi.prd_id [product_id],
		pi.prd_key [product_number],
		pi.prd_nm [product_name],
		pi.cat_id [category_id],
		pc.cat [category],
		pc.subcat[subcategory],
		pc.maintenance,
		pi.prd_cost [cost],
		pi.prd_line [product_line],
		pi.prd_start_date [start_date]
	FROM silver.crm_prd_info pi
	LEFT JOIN silver.erp_px_cat_g1v2 pc
		ON pi.cat_id=pc.cid
	WHERE pi.prd_end_date IS NULL 
)

--Sales (Fact)
CREATE VIEW gold.fact_sales AS (
	SELECT 
		sd.sls_ord_num [order_number],
		pr.product_key,
		cu.customer_key,
		sls_order_dt [order_date],
		sls_ship_dt [shipping_date],
		sls_due_dt [due_date],
		sls_sales [sales_amount],
		sls_quantity [quantity],
		sls_price [price]
	FROM silver.crm_sales_details sd
	LEFT JOIN gold.dim_products pr
		ON sd.sls_prd_key=pr.product_number
	LEFT JOIN gold.dim_customers cu
		ON sd.sls_cust_id=cu.customer_id
)