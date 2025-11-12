/*
SCRIPT PURPOSE:
	Bulk inserting the data from the csv files found in the source_crm and source_erp folders of \datasets.
	This script makes use of a Procedure.
*/

EXEC bronze.load_bronze

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @total_start_time DATETIME, @total_end_time DATETIME, @start_time DATETIME, @end_time DATETIME;
	SET @total_start_time = GETDATE();
	BEGIN TRY
		PRINT '===================='
		PRINT 'Loading Bronze Layer'
		PRINT '===================='

		PRINT '--------------------'
		PRINT 'Loading CRM Tables'
		PRINT '--------------------'
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_cust_info'
		TRUNCATE TABLE [bronze].[crm_cust_info];

		PRINT '>> Inserting Data Into: bronze.crm_cust_info'
		BULK INSERT [bronze].[crm_cust_info]
		FROM 'C:\Users\delat\Documents\PROJECTS\SQL_CRM_ERP_Data_Warehouse\datasets\source_crm\cust_info.csv'
		WITH(
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_prd_info'
		TRUNCATE TABLE [bronze].[crm_prd_info];

		PRINT '>> Inserting Data Into: bronze.crm_prd_info'
		BULK INSERT [bronze].[crm_prd_info]
		FROM 'C:\Users\delat\Documents\PROJECTS\SQL_CRM_ERP_Data_Warehouse\datasets\source_crm\prd_info.csv'
		WITH(
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'


		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_sales_details'
		TRUNCATE TABLE [bronze].[crm_sales_details];

		PRINT '>> Inserting Data Into: bronze.crm_sales_details'
		BULK INSERT [bronze].[crm_sales_details]
		FROM 'C:\Users\delat\Documents\PROJECTS\SQL_CRM_ERP_Data_Warehouse\datasets\source_crm\sales_details.csv'
		WITH(
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'


		PRINT '--------------------'
		PRINT 'Loading ERP Tables'
		PRINT '--------------------'

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2'
		TRUNCATE TABLE [bronze].[erp_px_cat_g1v2];

		BULK INSERT [bronze].[erp_px_cat_g1v2]
		FROM 'C:\Users\delat\Documents\PROJECTS\SQL_CRM_ERP_Data_Warehouse\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH(
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'


		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_cust_az12'
		TRUNCATE TABLE [bronze].[erp_cust_az12];

		BULK INSERT [bronze].[erp_cust_az12]
		FROM 'C:\Users\delat\Documents\PROJECTS\SQL_CRM_ERP_Data_Warehouse\datasets\source_erp\CUST_AZ12.csv'
		WITH(
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'


		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_loc_a101'
		TRUNCATE TABLE [bronze].[erp_loc_a101];

		BULK INSERT [bronze].[erp_loc_a101]
		FROM 'C:\Users\delat\Documents\PROJECTS\SQL_CRM_ERP_Data_Warehouse\datasets\source_erp\LOC_A101.csv'
		WITH(
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		
		SET @total_end_time = GETDATE();
		PRINT '========================================='
		PRINT 'Loading Bronze Layer Complete'
		PRINT '>> Total Load Duration: ' + CAST(DATEDIFF(SECOND, @total_start_time, @total_end_time) AS NVARCHAR) + ' seconds'
		PRINT '========================================='

	END TRY
	BEGIN CATCH
		PRINT '=============================================================='
		PRINT 'ERROR OCCURED DURING LOADING OF BRONZE LAYER'
		PRINT 'Error Mesage: ' + ERROR_MESSAGE();
		PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT '=============================================================='
	END CATCH
END

