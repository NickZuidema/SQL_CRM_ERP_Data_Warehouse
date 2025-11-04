/*
SCRIPT PURPOSE:
	
*/
USE master

--Creating the Database and the bronze, silver, and gold Schemas
CREATE DATABASE CRM_ERP_DataWarehouse

USE CRM_ERP_DataWarehouse

CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO

--Creating tables for the bronze Schema
CREATE TABLE bronze.crm_cust_info(
	cst_id INT,
	cst_key NVARCHAR(11) NOT NULL,
	cst_firstname NVARCHAR(25),
	cst_lastname NVARCHAR(25),
	cst_marital_status CHAR(1),
	cst_gender CHAR(1),
	cst_create_date DATE
);

CREATE TABLE bronze.crm_prd_info(
	prd_id INT,
	prd_key NVARCHAR(16),
	prd_nm NVARCHAR(40),
	prd_cost INT,
	prd_line NVARCHAR(2),
	prd_start_date DATE,
	prd_end_date DATE
);

CREATE TABLE bronze.crm_sales_details(
	sls_ord_num CHAR(7),
	sls_prd_key CHAR(11),
	sls_cust_id INT,
	sls_order_dt INT,
	sls_ship_dt INT,
	sls_due_dt INT,
	sls_sales INT,
	sls_quantity INT,
	sls_price INT
);

CREATE TABLE bronze.erp_cust_az12(
	CID CHAR(13),
	BDATE DATE,
	GEN NVARCHAR(6),
);

CREATE TABLE bronze.erp_loc_a101(
	CID CHAR(11),
	CNTRY VARCHAR(20),
);

CREATE TABLE bronze.erp_px_cat_g1v2(
	CID CHAR(5),
	CAT VARCHAR(11),
	SUBCAT VARCHAR(20),
	MAINTENANCE VARCHAR(3),
);

