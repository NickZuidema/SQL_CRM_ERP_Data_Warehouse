USE CRM_ERP_DataWarehouse

SELECT * FROM [bronze].[crm_cust_info]
SELECT * FROM [bronze].[crm_prd_info]
SELECT * FROM [bronze].[crm_sales_details]
SELECT * FROM [bronze].[erp_cust_az12]
SELECT * FROM [bronze].[erp_loc_a101]
SELECT * FROM [bronze].[erp_px_cat_g1v2]

--Checking [bronze].[crm_cust_info]
SELECT 
	cst_id,
	COUNT(1)
FROM [bronze].[crm_cust_info]
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

--Cleaned [bronze].[crm_cust_info] without Duplicates, leading/trailing Spaces, and NULL Primary Keys
SELECT 
	cst_id,
		cst_key,
		TRIM(cst_firstname),
		TRIM(cst_lastname),
		cst_marital_status,
		cst_gender,
		cst_create_date,
		date_ranking
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


--Checking [bronze].[crm_prd_info], seems Clean already
SELECT 
	prd_id,
	COUNT(1)
FROM [bronze].[crm_prd_info]
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

--Checking [bronze].[crm_sales_details]
SELECT 
	sls_ord_num,
	COUNT(1)
FROM [bronze].[crm_sales_details]
GROUP BY sls_ord_num
HAVING COUNT(*) > 1 OR sls_ord_num IS NULL

--Cleaned [bronze].[crm_sales_details] without Duplicates, leading/trailing Spaces, and NULL Primary Keys
SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY sls_ord_num ORDER BY sls_order_dt DESC) [date_ranking]
FROM [bronze].[crm_sales_details]

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