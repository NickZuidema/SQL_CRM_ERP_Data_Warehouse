/*
SCRIPT PURPOSE:
	Bulk inserting the cleaned data from the Bronze tables into the Silver tables.
	This script makes use of a Procedure.
*/

EXEC silver.load_silver

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @total_start_time DATETIME, @total_end_time DATETIME, @start_time DATETIME, @end_time DATETIME;
	SET @total_start_time = GETDATE();
	BEGIN TRY
		PRINT '===================='
		PRINT 'Loading Silver Layer'
		PRINT '===================='

		PRINT '--------------------'
		PRINT 'Loading CRM Tables'
		PRINT '--------------------'
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_cust_info'
		TRUNCATE TABLE [silver].[crm_cust_info];

		PRINT '>> Inserting Data Into: silver.crm_cust_info'
			INSERT INTO [silver].[crm_cust_info](
				cst_id,
				cst_key,
				cst_firstname,
				cst_lastname,
				cst_marital_status,
				cst_gender,
				cst_create_date
			)
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
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_prd_info'
		TRUNCATE TABLE [silver].[crm_prd_info];

		PRINT '>> Inserting Data Into: silver.crm_prd_info'
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
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'


		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_sales_details'
		TRUNCATE TABLE [silver].[crm_sales_details];

		PRINT '>> Inserting Data Into: silver.crm_sales_details'
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
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'


		PRINT '--------------------'
		PRINT 'Loading ERP Tables'
		PRINT '--------------------'

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_px_cat_g1v2'
		TRUNCATE TABLE [silver].[erp_px_cat_g1v2];

		PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2'
			INSERT INTO [silver].[erp_px_cat_g1v2](
				cid,
				cat,
				subcat,
				maintenance
			)
			SELECT
				cid,
				cat,
				subcat,
				maintenance
			FROM [bronze].[erp_px_cat_g1v2]
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'


		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_cust_az12'
		TRUNCATE TABLE [silver].[erp_cust_az12];

		PRINT '>> Inserting Data Into: silver.erp_cust_az12'
			INSERT INTO [silver].[erp_cust_az12](
				cid,
				bdate,
				gen
			)
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
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'


		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_loc_a101'
		TRUNCATE TABLE [silver].[erp_loc_a101];

		PRINT '>> Inserting Data Into: silver.erp_loc_a101'
			INSERT INTO [silver].[erp_loc_a101](
				cid,
				cntry
			)
			SELECT 
				REPLACE(cid, '-', '') [cid],
				CASE 
					WHEN TRIM(cntry) = 'DE' THEN 'Germany'
					WHEN TRIM(cntry) in ('US','USA') THEN 'United States'
					WHEN TRIM(cntry) = '' OR TRIM(cntry) IS NULL THEN 'N/A'
					ELSE TRIM(cntry)
				END [cntry]
			FROM [bronze].[erp_loc_a101] 
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		
		SET @total_end_time = GETDATE();
		PRINT '========================================='
		PRINT 'Loading Silver Layer Complete'
		PRINT '>> Total Load Duration: ' + CAST(DATEDIFF(SECOND, @total_start_time, @total_end_time) AS NVARCHAR) + ' seconds'
		PRINT '========================================='

	END TRY
	BEGIN CATCH
		PRINT '=============================================================='
		PRINT 'ERROR OCCURED DURING LOADING OF SILVER LAYER'
		PRINT 'Error Mesage: ' + ERROR_MESSAGE();
		PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT '=============================================================='
	END CATCH
END

