/*
SCRIPT PURPOSE:
	Queries that result in data from the Bronze tables which are cleaned and ready to be inserted to
	the Silver tables.
*/

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
--Checking [bronze].[crm_sales_details] for duplicate or NULL PKs
SELECT 
	sls_ord_num,
	COUNT(1)
FROM [bronze].[crm_sales_details]
GROUP BY sls_ord_num
HAVING COUNT(*) > 1 OR sls_ord_num IS NULL

--Checking [bronze].[crm_sales_details] for whitespaces in PK
SELECT * FROM [bronze].[crm_sales_details]
WHERE sls_ord_num != TRIM(sls_ord_num)

--Checking [bronze].[crm_sales_details] for sls_prd_key not in silver.crm_prd_info, none found
SELECT * FROM [bronze].[crm_sales_details]
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info)

--Checking [bronze].[crm_sales_details] for sls_cust_key not in silver.crm_cust_info, none found
SELECT * FROM [bronze].[crm_sales_details]
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info)

--[INCORRECT]Converting date columns (INTs) to DATEs and checking validity
SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price,
	order_date,
	order_is_date,
	ship_date,
	ship_is_date,
	due_date,
	due_is_date
FROM(
	SELECT
		*,
		CONCAT([order_year], '-', [order_month], '-', [order_day]) [order_date],
		ISDATE(CONCAT([order_year], '-', [order_month], '-', [order_day])) [order_is_date],
		CONCAT([ship_year], '-', [ship_month], '-', [ship_day]) [ship_date],
		ISDATE(CONCAT([ship_year], '-', [ship_month], '-', [ship_day])) [ship_is_date],
		CONCAT([due_year], '-', [due_month], '-', [due_day]) [due_date],
		ISDATE(CONCAT([due_year], '-', [due_month], '-', [due_day])) [due_is_date]
	FROM(
		SELECT
			*,
			SUBSTRING(TRIM(STR(sls_order_dt)), 0, 5) [order_year],
			SUBSTRING(TRIM(STR(sls_order_dt)), 5, 2) [order_month],
			SUBSTRING(TRIM(STR(sls_order_dt)), 7, 2) [order_day],
			SUBSTRING(TRIM(STR(sls_ship_dt)), 0, 5) [ship_year],
			SUBSTRING(TRIM(STR(sls_ship_dt)), 5, 2) [ship_month],
			SUBSTRING(TRIM(STR(sls_ship_dt)), 7, 2) [ship_day],
			SUBSTRING(TRIM(STR(sls_due_dt)), 0, 5) [due_year],
			SUBSTRING(TRIM(STR(sls_due_dt)), 5, 2) [due_month],
			SUBSTRING(TRIM(STR(sls_due_dt)), 7, 2) [due_day]
		FROM(
			SELECT	
				sls_ord_num,
				sls_prd_key,
				sls_cust_id,
				CASE WHEN sls_order_dt <= 0 THEN NULL ELSE sls_order_dt END [sls_order_dt],
				sls_ship_dt,
				sls_due_dt,
				sls_sales,
				sls_quantity,
				sls_price
			FROM [bronze].[crm_sales_details]
		)t 
	)t
)t
WHERE order_is_date = 0 OR ship_is_date = 0 OR due_is_date = 0

--Checking for sls_order_dt > sls_ship_dt or sls_due_dt
SELECT 
	*
FROM [bronze].[crm_sales_details]
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

--Converting [bronze].[crm_sales_details] date columns (INTs) to DATEs and checking validity
SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	CASE 
		WHEN sls_order_dt = 0 OR LEN(sls_order_dt) !=8 THEN NULL
		ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	END [sls_order_dt],
	CASE 
		WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) !=8 THEN NULL
		ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
	END [sls_ship_dt],
	CASE 
		WHEN sls_due_dt = 0 OR LEN(sls_due_dt) !=8 THEN NULL
		ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
	END [sls_due_dt],
	sls_sales,
	sls_quantity,
	sls_price
FROM [bronze].[crm_sales_details]

--Checking for incorrect sls_sales
SELECT DISTINCT
	sls_sales [old_sls_sales],
	sls_quantity,
	sls_price [old_sls_price],
	CASE 
		WHEN sls_sales <= 0 
			OR sls_sales IS NULL 
			OR sls_sales != sls_quantity * ABS(sls_price) 
			THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
	END [sls_sales],
	CASE 
		WHEN sls_price = 0 
			OR sls_price IS NULL 
			THEN sls_sales / NULLIF(sls_quantity, 0)
		ELSE sls_price
	END [sls_price]
FROM [bronze].[crm_sales_details]
WHERE sls_sales != sls_quantity * sls_price
	OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
	OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

------------------------------------------------------------------------------------------------------
--Data Insertion into [silver].[crm_prd_info]
INSERT INTO [silver].[crm_sales_details](
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
)

--Cleaned [bronze].[crm_sales_details] Dealt with:
--	Invalid dates, and invalid sales and prices
SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	CASE 
		WHEN sls_order_dt = 0 OR LEN(sls_order_dt) !=8 THEN NULL
		ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	END [sls_order_dt],
	CASE 
		WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) !=8 THEN NULL
		ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
	END [sls_ship_dt],
	CASE 
		WHEN sls_due_dt = 0 OR LEN(sls_due_dt) !=8 THEN NULL
		ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
	END [sls_due_dt],
	CASE 
		WHEN sls_sales <= 0 
			OR sls_sales IS NULL 
			OR sls_sales != sls_quantity * ABS(sls_price) 
			THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
	END [sls_sales],
	sls_quantity,
	CASE 
		WHEN sls_price <= 0 
			OR sls_price IS NULL 
			THEN sls_sales / NULLIF(sls_quantity, 0)
		ELSE sls_price
	END [sls_price]
FROM [bronze].[crm_sales_details]

--=========================================================================================================

--=========================================================================================================
--Checking [bronze].[erp_cust_az12] PK, Seems clean already
SELECT 
	CID,
	COUNT(1)
FROM [bronze].[erp_cust_az12]
GROUP BY CID
HAVING COUNT(*) > 1 OR CID IS NULL

SELECT * FROM [silver].[crm_cust_info]
SELECT SUBSTRING(CID, 4, LEN(CID)) FROM [bronze].[erp_cust_az12]

--Making if [bronze].[erp_cust_az12] CID and [silver].[crm_cust_info] cst_key
SELECT 
	*,
	CASE WHEN E.CID LIKE 'NAS%' THEN SUBSTRING(E.CID, 4, LEN(E.CID))
		ELSE E.CID
	END
FROM [silver].[crm_cust_info] C
FULL JOIN [bronze].[erp_cust_az12] E
ON C.cst_key=CASE 
		WHEN E.CID LIKE 'NAS%' THEN SUBSTRING(E.CID, 4, LEN(E.CID))
		ELSE E.CID
	END

--Checking for invalid bdates
SELECT DISTINCT
	bdate
FROM [bronze].[erp_cust_az12]
WHERE BDATE < '1924-01-01' OR BDATE > GETDATE()

--Checking for different types of gen
SELECT DISTINCT
	gen,
	CASE 
		WHEN UPPER(TRIM(gen)) IN('F', 'FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(gen)) IN('M', 'MALE') THEN 'Male'
		ELSE 'N/A'
	END
FROM [bronze].[erp_cust_az12]

------------------------------------------------------------------------------------------------------
--Data Insertion into [silver].[erp_cust_az12]
INSERT INTO [silver].[erp_cust_az12](
	cid,
	bdate,
	gen
)

--Cleaned [bronze].[erp_cust_az12] Dealt with:
--	Invalid CIDs, BDATEs, GENs
SELECT 
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
		ELSE CID
	END [cid],
	CASE WHEN bdate > GETDATE() THEN NULL
		ELSE bdate
	END [bdate],
	CASE 
		WHEN UPPER(TRIM(gen)) IN('F', 'FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(gen)) IN('M', 'MALE') THEN 'Male'
		ELSE 'N/A'
	END [GEN]
FROM [bronze].[erp_cust_az12] 
--=========================================================================================================

--=========================================================================================================
--Checking [bronze].[erp_loc_a101], Seems clean already
SELECT 
	CID,
	COUNT(1)
FROM [bronze].[erp_loc_a101]
GROUP BY CID
HAVING COUNT(*) > 1 OR CID IS NULL

--Comparing CID and silver.crm_cust_info cst_id
SELECT 
	*
FROM [bronze].[erp_loc_a101]
SELECT * FROM silver.crm_cust_info

--Comparing cid and cst_key if '-' of cid is removed
SELECT 
	REPLACE(cid, '-', '') [cid],
	cntry
FROM [bronze].[erp_loc_a101] 
WHERE REPLACE(cid, '-', '') NOT IN (SELECT cst_key FROM silver.crm_cust_info)

--Standardizing ctry column
SELECT DISTINCT
	cntry [old_cntry],
	CASE 
		WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		WHEN TRIM(cntry) in ('US','USA') THEN 'United States'
		WHEN TRIM(cntry) = '' OR TRIM(cntry) IS NULL THEN 'N/A'
		ELSE TRIM(cntry)
	END [cntry]
FROM [bronze].[erp_loc_a101]
------------------------------------------------------------------------------------------------------
--Data Insertion into [silver].[erp_loc_a101]
INSERT INTO [silver].[erp_loc_a101](
	cid,
	cntry
)

--Cleaned [bronze].[erp_loc_a101] Dealt with:
--	Invalid CIDs
SELECT 
	REPLACE(cid, '-', '') [cid],
	CASE 
		WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		WHEN TRIM(cntry) in ('US','USA') THEN 'United States'
		WHEN TRIM(cntry) = '' OR TRIM(cntry) IS NULL THEN 'N/A'
		ELSE TRIM(cntry)
	END [cntry]
FROM [bronze].[erp_loc_a101] 
--=========================================================================================================
--Checking [bronze].[erp_px_cat_g1v2], Seems clean already
SELECT 
	CID,
	COUNT(1)
FROM [bronze].[erp_px_cat_g1v2]
GROUP BY CID
HAVING COUNT(*) > 1 OR CID IS NULL

--Checking for white spaces
SELECT 
	* 
FROM [bronze].[erp_px_cat_g1v2]
WHERE cat != TRIM(cat)

--Checking for data quality
SELECT DISTINCT
	MAINTENANCE
FROM [bronze].[erp_px_cat_g1v2]

------------------------------------------------------------------------------------------------------
--Data Insertion into [silver].[erp_px_cat_g1v2]
INSERT INTO [silver].[erp_px_cat_g1v2](
	cid,
	cat,
	subcat,
	maintenance
)

--Cleaned [bronze].[erp_px_cat_g1v2] Dealt with:
--	Nothing; data was clean
SELECT
	cid,
	cat,
	subcat,
	maintenance
FROM [bronze].[erp_px_cat_g1v2]
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