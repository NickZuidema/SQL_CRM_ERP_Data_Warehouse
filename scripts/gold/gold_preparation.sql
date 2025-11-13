--===================================================
--For Customer view
--===================================================
--Checking for cst_id duplicates; none found
SELECT 
	cst_id, 
	COUNT(1) [id_count] --Checking cst_id duplicates; none found
FROM(
	SELECT 
		ci.cst_id,
		ci.cst_key,
		ci.cst_firstname,
		ci.cst_lastname,
		ci.cst_marital_status,
		ci.cst_gender,
		ci.cst_create_date,
		ca.bdate,
		ca.gen,
		la.cntry
	FROM silver.crm_cust_info ci
	LEFT JOIN silver.erp_cust_az12 ca
		ON ci.cst_key=ca.cid
	LEFT JOIN silver.erp_loc_a101 la
		on ci.cst_key=la.CID
)t
GROUP BY cst_id HAVING COUNT(1) != 1

--DATA INTEGRATION
--For mismatching ci.cst_gender and ca.gen; assumes ci is the Master table
SELECT DISTINCT
	ci.cst_gender,
	ca.gen,
	CASE 
		WHEN ci.cst_gender != 'N/A' THEN ci.cst_gender
		ELSE ISNULL(ca.gen, 'N/A')
	END [gender2]
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
	ON ci.cst_key=ca.cid
ORDER BY 1, 2

SELECT * FROM silver.erp_cust_az12

--Query for View
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

--===================================================
--For Product view
--===================================================
SELECT 
	pi.prd_id,
	pi.cat_id,
	pi.prd_key,
	pi.prd_nm,
	pi.prd_cost,
	pi.prd_line,
	pi.prd_start_date,
	pi.prd_end_date,
	pc.cat,
	pc.subcat,
	pc.maintenance
FROM silver.crm_prd_info pi
LEFT JOIN silver.erp_px_cat_g1v2 pc
	ON pi.cat_id=pc.cid
WHERE pi.prd_end_date IS NULL --Only included NULL end dates, which means we're only including the latest data; no historical data

--Checking for prd_key duplicates; none found
SELECT 
	prd_key, 
	COUNT(1) [key_count]
FROM(
	SELECT 
		pi.prd_id,
		pi.cat_id,
		pi.prd_key,
		pi.prd_nm,
		pi.prd_cost,
		pi.prd_line,
		pi.prd_start_date,
		pi.prd_end_date,
		pc.cat,
		pc.subcat,
		pc.maintenance
	FROM silver.crm_prd_info pi
	LEFT JOIN silver.erp_px_cat_g1v2 pc
		ON pi.cat_id=pc.cid
	WHERE pi.prd_end_date IS NULL
)t
GROUP BY prd_key
HAVING COUNT(1) != 1

SELECT * FROM silver.crm_prd_info
SELECT * FROM silver.erp_px_cat_g1v2

--Query for View
SELECT 
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
WHERE pi.prd_end_date IS NULL --Only included NULL end dates, which means we're only including the latest data; no historical data
