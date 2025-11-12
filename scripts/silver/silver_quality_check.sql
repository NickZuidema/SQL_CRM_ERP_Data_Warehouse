/*
SCRIPT PURPOSE:
	Checking the quality of the inserted data within the Silver tables.
*/

--Checking [silver].[crm_cust_info]
--Checking Primary key
SELECT 
	cst_id,
	COUNT(1)
FROM [silver].[crm_cust_info]
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

--Checking Gender
SELECT DISTINCT 
	cst_gender
FROM [silver].[crm_cust_info]

--Checking Marital Status
SELECT DISTINCT 
	cst_marital_status
FROM [silver].[crm_cust_info]

SELECT * FROM [silver].[crm_cust_info]


--Checking [silver].[crm_cust_info]
--Checking Primary key
SELECT 
	prd_id,
	COUNT(1)
FROM [silver].[crm_prd_info]
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

--Checking prd_cost
SELECT 
	prd_cost
FROM [silver].[crm_prd_info]
WHERE prd_cost IS NULL

--Checking prd_line
SELECT DISTINCT prd_line
FROM [silver].[crm_prd_info]

--Checking Dates
SELECT 
	prd_start_date,
	prd_end_date
FROM [silver].[crm_prd_info]
WHERE prd_end_date < prd_start_date

SELECT * FROM [silver].[crm_prd_info]


--Checking [silver].[crm_sales_details]
--Checking Dates
SELECT 
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt
FROM [silver].[crm_sales_details]
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

--Checking Calculations
SELECT DISTINCT
	sls_sales,
	sls_quantity,
	sls_price 
FROM [silver].[crm_sales_details]
WHERE sls_sales != sls_quantity * sls_price
	OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
	OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

SELECT * FROM [silver].[crm_sales_details]


--Checking [silver].[erp_cust_az12]
--Checking for invalid bdates
SELECT DISTINCT
	bdate
FROM [silver].[erp_cust_az12]
WHERE BDATE < '1924-01-01' OR BDATE > GETDATE()

--Checking for different types of gen
SELECT DISTINCT
	gen,
	CASE 
		WHEN UPPER(TRIM(gen)) IN('F', 'FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(gen)) IN('M', 'MALE') THEN 'Male'
		ELSE 'N/A'
	END
FROM [silver].[erp_cust_az12]

SELECT * FROM [silver].[erp_cust_az12]


--Checking [silver].[erp_loc_a101]
--Checking distinct countries
SELECT DISTINCT
	cntry 
FROM [silver].[erp_loc_a101]

SELECT * FROM [silver].[erp_loc_a101]


--Checking [silver].[erp_px_cat_g1v2]
SELECT * FROM [silver].[erp_px_cat_g1v2]