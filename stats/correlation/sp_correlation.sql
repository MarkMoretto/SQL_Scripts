  
/***
Topic: Correlation function
Date: 2019-03-11
Contributor(s): Mark Moretto (MMorett1@hfhs.org)
Status: TESTING / PRODUCTION
****************   ****************
************           ************
********				   ********
****** Correlation formula 1 ******
********				   ********
************           ************
****************   ****************
	r(xy) = 
					SUM((Xi - X_mean) * (Yi - Y_mean))
			-------------------------------------------------
			SQRT(SUM((Xi - X_mean)^2) * SUM((Yi - Y_mean)^2))
	for all i = 1 to n
	where
		n = number of rows in sample
		Xi = Field 1
		Yi = Field 2
		X_mean, Y_mean = The average (arithmetic mean) of the two datasets.
****************   ****************
************           ************
********				   ********
****** Correlation formula 2 ******
********				   ********
************           ************
****************   ****************
	r(xy) = 
						n * SUM(Xi * Yi) - (SUM(Xi) * SUM(Yi))
			-----------------------------------------------------------------
			[SQRT(n * SUM(Xi^2) - SUM(Xi)^2)] * [SQRT(n * SUM(Yi^2) - SUM(Yi)^2)]
	
	for all i = 1 to n
	where
		n = number of rows in sample
		Xi = Field 1
		Yi = Field 2
		X_mean, Y_mean = The average (arithmetic mean) of the two datasets.
****************   ****************
************           ************
********				   ********
******         NOTES         ******
********				   ********
************           ************
****************   ****************
* Bivariate input only!
	--- This procedure will evaluate "X" and "Y" values only.
* Input data should be numeric (float, int, etc.).
* Requires declaration of OUTPUT variable (FLOAT type) to capture result once procedure is run.
Example usage:
	Demonstration query located at: C:\Users\MMorett1\Desktop\Programming\Teams\SQL\Stats\Correlation_Demo.sql
*/

USE EDWUsersDB;
GO


/*** Remove any current procedures with the same name */
IF (SELECT COUNT(*) FROM sys.all_objects WHERE type IN ('P') AND name LIKE N'Correlation') > '0' DROP PROCEDURE MMorett1.Correlation;
GO


CREATE PROC MMorett1.Correlation
	@_schema NVARCHAR(256) = NULL,
	@_table_name NVARCHAR(255),
	@_column_1 NVARCHAR(255),
	@_column_2 NVARCHAR(255),
	@_result FLOAT = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON
	
	/***
		Table variable to store imported dataset.
	*/
	DECLARE @_data TABLE (
		[X] NVARCHAR(255),
		[Y] NVARCHAR(255)
	);

	/*** 
		If @_schema argument empty, set to default database schema.
	*/
	IF @_schema IS NULL OR LEN(@_schema) = '0'
		BEGIN
			SET @_schema = 'dbo'
		END;


	/*** Create and execute sql string to populate table variable. */
	/*** NOTE: Must also declare table variable in the string to be executed
		   and select all values at the end. */
		
	DECLARE @_sql NVARCHAR(MAX);
	SET @_sql = 'DECLARE @_data TABLE (
					[X] NVARCHAR(255),
					[Y] NVARCHAR(255)
				);
				INSERT INTO @_data ([X], [Y])'
	SET @_sql += ' ' + 'SELECT ' + QUOTENAME(@_column_1) + ', ' + QUOTENAME(@_column_2) + ''
	IF LEFT(@_table_name, '1') LIKE '#' OR LEFT(@_table_name, '2') LIKE '##'
	BEGIN
		SET @_sql += ' ' + 'FROM tempdb.' + @_schema + '.'  + @_table_name + ''
	END;
	ELSE
	BEGIN
		SET @_sql += ' ' + 'FROM ' + QUOTENAME(@_schema) + '.'  + QUOTENAME(@_table_name) + ''
	END;
	SET @_sql += ' ' + 'SELECT * FROM @_data'

	INSERT INTO @_data
	EXEC(@_sql);


	/***
		Declare and set minor calculated variables.
	*/
	DECLARE @_N FLOAT = (SELECT COUNT(*) FROM @_data)
	DECLARE @_x_mean FLOAT = (SELECT SUM(CONVERT(FLOAT, Dx.[X])) / @_N FROM @_data AS Dx)
	DECLARE @_y_mean FLOAT = (SELECT SUM(CONVERT(FLOAT, Dy.[Y])) / @_N FROM @_data AS Dy)
	PRINT N'Row count: ' + CONVERT(NVARCHAR(10), @_N) + NCHAR(10) + 'X Mnea: ' + CONVERT(NVARCHAR(20), @_x_mean) + NCHAR(10) + 'Y Mean: ' + CONVERT(NVARCHAR(20), @_y_mean)

	/***
		Declare table variable.
	*/
	DECLARE @_out_tbl TABLE (
		[CORRELATION] FLOAT
	)

	/***
		Calculate additional values and insert result into table variable.
	*/
	;WITH initial_calcs AS (
		/***
			Squared differences.
		*/
		SELECT ((ABC.[X] - @_x_mean) * (ABC.[Y] - @_y_mean)) AS [XY]
		,	((ABC.[X] - @_x_mean) * (ABC.[X] - @_x_mean)) AS [XX]
		,	((ABC.[Y] - @_y_mean) * (ABC.[Y] - @_y_mean)) AS [YY]
		FROM @_data AS ABC
	)
	, fin AS (
		/***
			Sum of squared differences.
		*/
		SELECT CONVERT(FLOAT, SUM(DEF.XY)) AS [XY_sum]
		,	CONVERT(FLOAT, SUM(DEF.XX)) AS [XX_sum]
		,	CONVERT(FLOAT, SUM(DEF.YY)) AS [YY_sum]
		FROM initial_calcs AS DEF
	)
	INSERT INTO @_out_tbl ([CORRELATION])
	SELECT (GHI.XY_sum / SQRT(GHI.XX_sum * GHI.YY_sum)) AS [CORRELATION]
	FROM fin AS GHI


	/***
		Convert result data to match output type; Return result
	*/
	SET @_result = (SELECT [CORRELATION] FROM @_out_tbl);
	RETURN @_result;
END;
GO
