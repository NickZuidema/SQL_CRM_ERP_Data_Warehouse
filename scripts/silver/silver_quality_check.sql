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