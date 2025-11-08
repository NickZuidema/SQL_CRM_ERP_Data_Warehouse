USE CRM_ERP_DataWarehouse

SELECT * FROM [bronze].[crm_cust_info]
SELECT * FROM [bronze].[crm_prd_info]
SELECT * FROM [bronze].[crm_sales_details]
SELECT * FROM [bronze].[erp_cust_az12]
SELECT * FROM [bronze].[erp_loc_a101]
SELECT * FROM [bronze].[erp_px_cat_g1v2]

--=========================================================================================================
--Checking [bronze].[crm_cust_info]
--Checking Primary key
SELECT 
	cst_id,
	COUNT(1)
FROM [bronze].[crm_cust_info]
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

--Checking Gender
SELECT DISTINCT 
	cst_gender
FROM [bronze].[crm_cust_info]

--Checking Marital Status
SELECT DISTINCT 
	cst_marital_status
FROM [bronze].[crm_cust_info]

------------------------------------------------------------------------------------------------------
--Data Insertion into [silver].[crm_cust_info]
INSERT INTO [silver].[crm_cust_info](
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gender,
	cst_create_date
)
--Cleaned [bronze].[crm_cust_info] Dealt with:
--	Duplicates, leading/trailing Spaces, NULL Primary Keys, Spelled out Gender and Marital Status
SELECT 
	cst_id,
	cst_key,
	TRIM(cst_firstname) [cst_firstname],
	TRIM(cst_lastname) [cst_lastname],
	CASE UPPER(TRIM(cst_marital_status))  
		WHEN 'S' THEN 'Single'
		WHEN 'M' THEN 'Married'
		ELSE 'N/A'
	END [cst_marital_status],
	CASE UPPER(TRIM(cst_gender))  
		WHEN 'F' THEN 'Female'
		WHEN 'M' THEN 'Male'
		ELSE 'N/A'
	END [cst_gender],
	cst_create_date
FROM(
	SELECT 
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gender,
		cst_create_date,
		ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) [date_ranking]
	FROM [bronze].[crm_cust_info]
	WHERE cst_id IS NOT NULL
)t
WHERE date_ranking = 1 
--=========================================================================================================

--=========================================================================================================
--Checking [bronze].[crm_prd_info] for duplicates, none found
SELECT 
	prd_id,
	COUNT(1)
FROM [bronze].[crm_prd_info]
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

--Checking [bronze].[crm_prd_info] prd_cost for NULLs or negative values, two found
SELECT 
	prd_cost
FROM [bronze].[crm_prd_info]
WHERE prd_cost < 0 OR prd_cost IS NULL

--Checking for end dates larger than start dates
SELECT 
	prd_start_date,
	prd_end_date [old_prd_end_date],
	CASE 
		WHEN prd_end_date < prd_start_date
		THEN LEAD(prd_start_date, 1) OVER(PARTITION BY prd_key ORDER BY prd_start_date)
	END [prd_end_date]
FROM [bronze].[crm_prd_info]
WHERE prd_end_date < prd_start_date
ORDER BY prd_start_date

------------------------------------------------------------------------------------------------------
--Data Insertion into [silver].[crm_prd_info]
INSERT INTO [silver].[crm_prd_info](
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_date,
	prd_end_date
)
--Cleaned [bronze].[crm_prd_info] Dealt with:
--	Separated prd_key into cat_id and prd_key, replaced NULL prd_costs with 0, spelled out prd_line, added new prd_end_dates
SELECT
	prd_id,
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') [cat_id],
	SUBSTRING(prd_key, 7, LEN(prd_key)) [prd_key],
	prd_nm,
	ISNULL(prd_cost, 0) [prd_cost],
	CASE UPPER(TRIM(prd_line))
		WHEN 'M' THEN 'Mountain'
		WHEN 'R' THEN 'Roads'
		WHEN 'S' THEN 'Other Sales'
		WHEN 'T' THEN 'Touring'
		ELSE 'N/A'
	END [prd_line],
	prd_start_date,
	LEAD(prd_start_date) OVER(PARTITION BY prd_key ORDER BY prd_start_date) [prd_end_date]
FROM [bronze].[crm_prd_info]
--=========================================================================================================

--=========================================================================================================
--Checking [bronze].[crm_sales_details]
SELECT 
	sls_ord_num,
	COUNT(1)
FROM [bronze].[crm_sales_details]
GROUP BY sls_ord_num
HAVING COUNT(*) > 1 OR sls_ord_num IS NULL

--Cleaned [bronze].[crm_sales_details] Dealt with:
--	Duplicates
SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY sls_ord_num ORDER BY sls_order_dt DESC) [date_ranking]
FROM [bronze].[crm_sales_details]
--=========================================================================================================

--=========================================================================================================
--Checking [bronze].[erp_cust_az12], Seems clean already
SELECT 
	CID,
	COUNT(1)
FROM [bronze].[erp_cust_az12]
GROUP BY CID
HAVING COUNT(*) > 1 OR CID IS NULL

--=========================================================================================================
--Checking [bronze].[erp_loc_a101], Seems clean already
SELECT 
	CID,
	COUNT(1)
FROM [bronze].[erp_loc_a101]
GROUP BY CID
HAVING COUNT(*) > 1 OR CID IS NULL
--=========================================================================================================
--Checking [bronze].[erp_px_cat_g1v2], Seems clean already
SELECT 
	CID,
	COUNT(1)
FROM [bronze].[erp_px_cat_g1v2]
GROUP BY CID
HAVING COUNT(*) > 1 OR CID IS NULL

SELECT * FROM [bronze].[erp_px_cat_g1v2]
--=========================================================================================================

































--Successfully joins the Sales, Product and Customer tables
SELECT 
	S.*,
	P.trimmed_prd_key,
	C.cst_id
FROM [bronze].[crm_sales_details] S
LEFT JOIN( 
	SELECT 
		SUBSTRING(prd_key, 7, LEN(prd_key)) AS trimmed_prd_key
	FROM [bronze].[crm_prd_info]) P
ON S.sls_prd_key=P.trimmed_prd_key
LEFT JOIN bronze.crm_cust_info C
ON S.sls_cust_id=c.cst_id

SELECT 
	*
FROM [bronze].[crm_sales_details] S
SELECT 
	*,
	SUBSTRING(prd_key, 7, LEN(prd_key)) AS trimmed_prd_key
FROM [bronze].[crm_prd_info]