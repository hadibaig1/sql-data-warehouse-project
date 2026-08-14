/*
===================================
DDL Script: Create Bronze Tables and filling the the data
------------------------------------
Script Purpose:
  This stored procedure loads data into the procedure from external CSVs
 ----------------------------------
Usage Examples:
  EXEC bronze.load_bronze */


CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
DECLARE @start_time DATETIME, @end_time DATETIME, @full_start_time DATETIME, @full_end_time DATETIME
	BEGIN TRY
		PRINT '================================================';
		PRINT 'Loading Bronze Layer'
		PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables'
		PRINT '------------------------------------------------';


		-- Setting the full time for the whole query --
		SET @full_start_time = GETDATE()

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.crm_cust_info'
		TRUNCATE TABLE bronze.crm_cust_info;

		PRINT '>> Inserting Data Into: bronze.crm_cust_info'
		BULK INSERT bronze.crm_cust_info
		FROM "C:\Users\loung\Downloads\cust_info.csv"
		WITH (
			-- TELLING SQL TO SKIP THE FIRST ROW, SINCE THERE ARE ONLY HEADERS THERE
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE()
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'



		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.crm_sales_detailes'
		TRUNCATE TABLE bronze.crm_sales_detailes;

		PRINT '>> Inserting Data Into: bronze.crm_sales_detailes'
		BULK INSERT bronze.crm_sales_detailes
		FROM "C:\Users\loung\Downloads\sales_details.csv"
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);



		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.crm_prd_info'
		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT '>> Inserting Data Into: bronze.crm_prd_info'
		BULK INSERT bronze.crm_prd_info
		FROM "C:\Users\loung\Downloads\prd_info.csv"
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE()
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'


		PRINT '------------------------------------------------';
		PRINT 'Loading ERP Tables'
		PRINT '------------------------------------------------';



		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.erp_cust_az12'
		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT '>> Inserting Data Into: bronze.erp_cust_az12'
		BULK INSERT bronze.erp_cust_az12
		FROM "C:\Users\loung\Downloads\CUST_AZ12.csv"
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE()
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'



		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.erp_loc_a101'
		TRUNCATE TABLE bronze.erp_loc_a101;

		PRINT '>> Inserting Data Into: bronze.erp_loc_a101'
		BULK INSERT bronze.erp_loc_a101
		FROM "C:\Users\loung\Downloads\LOC_A101.csv"
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE()
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'


		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2'
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2'
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM "C:\Users\loung\Downloads\PX_CAT_G1V2.csv"
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		SET @end_time = GETDATE()
		SET @full_end_time = GETDATE()
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
	

		-- Printing out the whole time it took to execute the query --
		PRINT '>>Full Load duration: ' + CAST(DATEDIFF(second, @full_start_time, @full_end_time) AS NVARCHAR) + ' seconds'
	END TRY
	BEGIN CATCH
		PRINT '==================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT '==================================='
	END CATCH
END
