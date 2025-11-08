/*
SCRIPT PURPOSE:
	Creation of the Tables for the Silver Schema.
*/

USE CRM_ERP_DataWarehouse

CREATE TABLE silver.crm_cust_info(
	cst_id INT,
	cst_key NVARCHAR(11) NOT NULL,
	cst_firstname NVARCHAR(25),
	cst_lastname NVARCHAR(25),
	cst_marital_status NVARCHAR(7),
	cst_gender NVARCHAR(6),
	cst_create_date DATE,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE silver.crm_prd_info(
	prd_id INT,
	cat_id CHAR(5),
	prd_key NVARCHAR(16),
	prd_nm NVARCHAR(40),
	prd_cost INT,
	prd_line NVARCHAR(11),
	prd_start_date DATE,
	prd_end_date DATE,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE silver.crm_sales_details(
	sls_ord_num CHAR(7),
	sls_prd_key CHAR(11),
	sls_cust_id INT,
	sls_order_dt INT,
	sls_ship_dt INT,
	sls_due_dt INT,
	sls_sales INT,
	sls_quantity INT,
	sls_price INT,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE silver.erp_cust_az12(
	CID CHAR(13),
	BDATE DATE,
	GEN NVARCHAR(6),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE silver.erp_loc_a101(
	CID CHAR(11),
	CNTRY VARCHAR(20),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE silver.erp_px_cat_g1v2(
	CID CHAR(5),
	CAT VARCHAR(11),
	SUBCAT VARCHAR(20),
	MAINTENANCE VARCHAR(3),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);
