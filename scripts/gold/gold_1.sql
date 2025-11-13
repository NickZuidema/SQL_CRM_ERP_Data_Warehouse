CREATE VIEW gold.dim_customers AS(
	SELECT
		ROW_NUMBER() OVER(ORDER BY cst_id) [customer_key],
		ci.cst_id [customer_id],
		ci.cst_key [customer_number],
		ci.cst_firstname [first_name],
		ci.cst_lastname [last_name],
		la.cntry [country],
		ci.cst_marital_status [marital_status],
		CASE 
			WHEN ci.cst_gender != 'N/A' THEN ci.cst_gender
			ELSE ISNULL(ca.gen, 'N/A')
		END [gender],
		ca.bdate [birthdate],
		ci.cst_create_date [create_date]
	FROM silver.crm_cust_info ci
	LEFT JOIN silver.erp_cust_az12 ca
		ON ci.cst_key=ca.cid
	LEFT JOIN silver.erp_loc_a101 la
		on ci.cst_key=la.CID
)

SELECT 
	cst_id, 
	COUNT(1) --Checking cst_id duplIcates; none found
FROM(
	SELECT 
		ci.cst_id,
		ci.cst_key,
		ci.cst_firstname,
		ci.cst_lastname,
		ci.cst_marital_status,
		ci.cst_gender,
		ci.cst_create_date,
		ca.bdate,
		ca.gen,
		la.cntry
	FROM silver.crm_cust_info ci
	LEFT JOIN silver.erp_cust_az12 ca
		ON ci.cst_key=ca.cid
	LEFT JOIN silver.erp_loc_a101 la
		on ci.cst_key=la.CID
)t
GROUP BY cst_id HAVING COUNT(1) != 1

--DATA INTEGRATION
--For mismatching ci.cst_gender and ca.gen; assumes ci is the Master table
SELECT DISTINCT
	ci.cst_gender,
	ca.gen,
	CASE 
		WHEN ci.cst_gender != 'N/A' THEN ci.cst_gender
		ELSE ISNULL(ca.gen, 'N/A')
	END [gender2]
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
	ON ci.cst_key=ca.cid
ORDER BY 1, 2

SELECT *
FROM silver.erp_cust_az12