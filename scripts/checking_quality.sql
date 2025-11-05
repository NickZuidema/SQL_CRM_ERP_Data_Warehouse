SELECT * FROM [bronze].[crm_cust_info]
SELECT * FROM [bronze].[crm_prd_info]
SELECT * FROM [bronze].[crm_sales_details]
SELECT * FROM [bronze].[erp_cust_az12]
SELECT * FROM [bronze].[erp_loc_a101]
SELECT * FROM [bronze].[erp_px_cat_g1v2]


SELECT 
	cst_id,
	COUNT(1)
FROM [bronze].[crm_cust_info]
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) [date_ranking]
FROM [bronze].[crm_cust_info]
WHERE flag_last = 1
