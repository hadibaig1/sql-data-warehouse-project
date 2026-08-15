/*
This file creates our Stored Procedure, which takes in the tables from the Bronze layer, and cleans up all of the data
To execute this code, simple run the following code:
  EXEC silver.load_silver
*/
-- Creating our big Stored Procedure for the Silver Layer --
CREATE OR ALTER PROCEDURE silver.load_silver  AS 
BEGIN
BEGIN TRY
 -- Declaring our Variables
 DECLARE @start_time DATETIME, @end_time DATETIME, @full_start_time DATETIME,
 @full_end_time DATETIME

	PRINT '=============================================='
	PRINT 'LOADING THE SILVER LAYER' 
	PRINT '=============================================='

	-- ============================
	-- INSERTING DATA FROM CRM_PRD_INFO
	-- ============================

	-- Start Time for the query, and for the whole Procedure
	SET @full_start_time = GETDATE()
	SET @start_time = GETDATE()

	 PRINT 'Dropping Table silver.crm_prd_info' 
	 IF OBJECT_ID ('silver.crm_prd_info', 'U') IS NOT NULL
		DROP TABLE silver.crm_prd_info;
	 CREATE TABLE silver.crm_prd_info (
	prd_id INT,
	cat_id NVARCHAR(50),
	prd_key NVARCHAR(50),
	prd_nm NVARCHAR(50),
	prd_cost INT,
	prd_line NVARCHAR(50),
	prd_start_dt DATE,
	prd_end_dt DATE,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
 
	 );

	-- INSERT THE RESULT OF THE QUERY INTO THE TABLE
	PRINT 'Inserting Table silver.crm_prd_info'
	INSERT INTO silver.crm_prd_info(
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
	)
	SELECT
	prd_id,
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
	SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
	prd_nm,
	COALESCE(prd_cost, 0) AS prd_cost,
	CASE UPPER(TRIM(prd_line))
		WHEN 'M' THEN 'Mountain'
		WHEN 'R' THEN 'Road'
		WHEN 'S' THEN 'Other Sales'
		WHEN 'T' THEN 'Touring'
		ELSE 'n/a'
	END AS prd_line,
	CAST(prd_start_dt AS DATE) AS prd_start_dt,
	CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt ASC) - 1 AS DATE) AS prd_end_dt
	FROM bronze.crm_prd_info;

	-- End time
	SET @end_time = GETDATE()
	PRINT 'Time: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds'




	-- ============================
	-- INSERTING DATA FROM ERP_LOC_A101
	-- ============================

	SET @start_time = GETDATE()
	TRUNCATE TABLE silver.erp_loc_a101 ;
	INSERT INTO silver.erp_loc_a101
	(cid, cntry)

	SELECT 
	REPLACE(cid, '-', '') AS cid,
	CASE
		WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
		WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
		ELSE TRIM(cntry)

	END AS cntry
	FROM bronze.erp_loc_a101;
	SET @end_time = GETDATE()
	PRINT 'Time: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds'





	-- ============================
	-- INSERTING DATA FROM CRM_SALES_DETAILES
	-- ============================
	SET @start_time = GETDATE()

		-- Truncating Table
	PRINT 'Truncating Table silver.crm_sales_detailes'
	TRUNCATE TABLE silver.crm_sales_detailes;

	WITH cleaned_price AS (
		SELECT
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales, 
			sls_quantity,
			CASE 
				WHEN sls_price < 0 THEN (sls_price * -1)
				WHEN sls_price = 0 OR sls_price IS NULL THEN sls_sales / sls_quantity
				ELSE sls_price
			END AS sls_price
		FROM bronze.crm_sales_detailes
	),
	cleaned_sales AS(
	SELECT
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
	
		-- Cleaning up our dates
		CASE
			WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
		END AS sls_order_dt,
		CASE
			WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
		END AS sls_ship_dt,
		CASE
			WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
		END AS sls_due_dt,

		-- Cleaning up Sales
		CASE 
			WHEN sls_sales != (sls_price * sls_quantity) THEN sls_price * sls_quantity
			WHEN sls_sales <= 0 OR sls_sales IS NULL THEN sls_price * sls_quantity
			ELSE sls_sales
		END AS sls_sales,

		sls_quantity,
		sls_price

	FROM cleaned_price
	)
	-- INSERTING DATA

	INSERT INTO silver.crm_sales_detailes(
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
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales, 
	sls_quantity,
	sls_price 
	FROM cleaned_sales;

	SET @end_time = GETDATE()
	PRINT 'Time: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds'





	-- ============================
	-- INSERTING DATA FROM ERP_PX_CAT_G1V2
	-- ============================
	-- Truncating Table
	SET @start_time = GETDATE()
	PRINT 'Truncating Table silver.erp_px_cat_g1v2'
	TRUNCATE TABLE silver.erp_px_cat_g1v2
	-- Inserting Table
	PRINT 'Inserting Table silver.erp_px_cat_g1v2'
	INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
	SELECT
	id, 
	cat, subcat, maintenance
	FROM bronze.erp_px_cat_g1v2;

	SET @end_time = GETDATE()
	PRINT 'Time: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds'





	-- ============================
	-- INSERTING DATA FROM ERP_CUST_AZ12
	-- ============================
	-- Truncating Table
	SET @start_time = GETDATE()
	PRINT 'Truncating Table silver.erp_cust_az12'
	TRUNCATE TABLE silver.erp_cust_az12

		-- Inserting Table
	PRINT 'Inserting Table silver.erp_cust_az12'
	INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
	SELECT 
	CASE
		WHEN cid LIKE 'NAS%'  THEN SUBSTRING(cid, 4, LEN(cid))
		ELSE cid
	END AS cid,
	CASE
	WHEN bdate > GETDATE() THEN NULL
	ELSE bdate
	END AS bdate,
	CASE
		WHEN TRIM(UPPER(gen)) IN ('F', 'FEMALE') THEN 'Female'
		WHEN TRIM(UPPER(gen)) IN ('M', 'MALE') THEN 'Male'
		ELSE 'n/a'
	END AS gen
	FROM bronze.erp_cust_az12
	
	SET @end_time = GETDATE()
	PRINT 'Time: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds'

	SET @full_end_time = GETDATE()
	PRINT 'Full Time: ' + CAST(DATEDIFF(second, @full_start_time, @full_end_time) AS NVARCHAR) + 'seconds'


END TRY
BEGIN CATCH
	-- Printing out Error Messages
	PRINT 'Error Number: ' + ERROR_NUMBER()
	PRINT 'Error Line: ' + ERROR_LINE()
	PRINT 'Error Msg' + ERROR_MESSAGE()
END CATCH
END



-- RUNNING OUT STORED PROCEDURE
EXEC silver.load_silver
