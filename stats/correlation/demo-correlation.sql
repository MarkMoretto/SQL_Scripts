/***
Topic: Correlations Stored Procedure Demo
Date created: 2019-03-11
Contributor(s): Mark Moretto (MMorett1@hfhs.org)

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
******    Notes on Usage     ******
********				   ********
************           ************
****************   ****************

* Variables and column values should be FLOAT types.  This procedure doesnt convert values.
* Schema name is optional if a temporary table is used. Use '' in place of schema name as placeholder.


****************   ****************
************           ************
********				   ********
******     Example Usage     ******
********				   ********
************           ************
****************   ****************
*** Declare variable to capture output. *
DECLARE @_correlation FLOAT

*** Execute procedure.
	EDWUsersDB.MMorett1.Correlation ( schema_name ), ( table_or_view ), ( column_1 ), ( column_2 ), @_result = (  ) OUTPUT

EXEC EDWUsersDB.MMorett1.Correlation '', '#_demo_1', 'X_vals', 'Y_vals', @_result = _correlation OUTPUT

*** Select result into another table, variable, etc.
SELECT @_correlation

*/


USE CLARITY;
GO

IF OBJECT_ID('tempdb.dbo.#_output') IS NOT NULL DROP TABLE #_output
CREATE TABLE #_output (
	[Demo] SMALLINT NOT NULL PRIMARY KEY,
	[Name] NVARCHAR(25),
	[Expected] FLOAT,
	[Actual] FLOAT,
);
GO


---------------------------------------------------------------------------------------------------------
/***
Demo 1
Expected result: -1

Values:
X	Y
1	10
2	9
3	8
4	7
5	6
6	5
7	4
8	3
9	2
10	1

*/

IF OBJECT_ID('tempdb.dbo.#_demo_1') IS NOT NULL DROP TABLE #_demo_1
CREATE TABLE #_demo_1 (
	[X_vals] FLOAT,
	[Y_vals] FLOAT
);
GO

INSERT INTO #_demo_1 ([X_vals], [Y_vals])
VALUES (1,10),(2,9),(3,8),(4,7),(5,6),(6,5),(7,4),(8,3),(9,2),(10,1)

/***
	Declare a variable to retrieve procedure output.
*/
DECLARE @_corr_1 FLOAT

/***
	Execute procedure.
	NOTE: For temp tables, we don't need to 
*/
EXEC EDWUsersDB.MMorett1.Correlation '', '#_demo_1', 'X_vals', 'Y_vals', @_result = @_corr_1 OUTPUT
INSERT INTO #_output ([Demo], [Name], [Expected], [Actual])
SELECT 1, 'Demo 1', -1, @_corr_1



---------------------------------------------------------------------------------------------------------
/***
Demo 2
Expected result: 1

Values:

X	Y
1	1
2	2
3	3
4	4
5	5
6	6
7	7
8	8
9	9
10	10

*/

IF OBJECT_ID('tempdb.dbo.#_demo_2') IS NOT NULL DROP TABLE #_demo_2
CREATE TABLE #_demo_2 (
	[X_vals] FLOAT,
	[Y_vals] FLOAT
);
GO

INSERT INTO #_demo_2 ([X_vals], [Y_vals])
VALUES (1,1),(2,2),(3,3),(4,4),(5,5),(6,6),(7,7),(8,8),(9,9),(10,10)

/***
	Declare a variable to retrieve procedure output.
*/
DECLARE @_corr_2 FLOAT

/***
	Execute procedure.
	NOTE: For temp tables, we don't need to have a schema.
*/
EXEC EDWUsersDB.MMorett1.Correlation '', '#_demo_2', 'X_vals', 'Y_vals', @_result = @_corr_2 OUTPUT
INSERT INTO #_output ([Demo], [Name], [Expected], [Actual])
SELECT 2, 'Demo 2', 1, @_corr_2



---------------------------------------------------------------------------------------------------------
/***
Demo 3
Expected result: 0.0935

Values:

X		Y
10		12.5
8.5		11.1
16.8	22.3
11.2	15.4
17.8	25.3
5.4		8.4
21.6	32.6
9.6		18.5
14		15.3
13.5	16.8
*/

IF OBJECT_ID('tempdb.dbo.#_demo_3') IS NOT NULL DROP TABLE #_demo_3
CREATE TABLE #_demo_3 (
	[X_vals] FLOAT,
	[Y_vals] FLOAT
);
GO

INSERT INTO #_demo_3 ([X_vals], [Y_vals])
VALUES (10,12.5),(8.5,11.1),(16.8,22.3),(11.2,15.4),(17.8,25.3),(5.4,8.4),(21.6,32.6),(9.6,18.5),(14,15.3),(13.5,16.8)

/***
	Declare a variable to retrieve procedure output.
*/
DECLARE @_corr_3 FLOAT

/***
	Execute procedure.
	NOTE: For temp tables, we don't need to have a schema.
*/
EXEC EDWUsersDB.MMorett1.Correlation '', '#_demo_3', 'X_vals', 'Y_vals', @_result = @_corr_3 OUTPUT
INSERT INTO #_output ([Demo], [Name], [Expected], [Actual])
SELECT 3, 'Demo 3', 0.935, ROUND(@_corr_3, 4)





---------------------------------------------------------------------------------------------------------
/***
Demo 4
Expected result: -0.02111

Values:
	Risk score vs. zip code
*/

IF OBJECT_ID('tempdb.dbo.#_demo_4') IS NOT NULL DROP TABLE #_demo_4

SELECT TOP 1000 TRY_CONVERT(FLOAT,(LEFT(P.ZIP, 5))) AS [ZIP_CODE]
, TRY_CONVERT(FLOAT, RS.[HCC Risk Score]) AS [RISK_SCR]
INTO #_demo_4
FROM [ValidatedUserDB].[dbo].[OptumHCCRiskScore] AS RS
LEFT JOIN vw_patient_x AS P ON P.PAT_MRN_ID = RS.[PrimaryMRN]
WHERE P.COUNTRY_C = '1'

/*** Declare a variable to retrieve procedure output. */
DECLARE @_corr_4 FLOAT

/*** Execute procedure. */
EXEC EDWUsersDB.MMorett1.Correlation '', '#_demo_4', 'ZIP_CODE', 'RISK_SCR', @_result = @_corr_4 OUTPUT
INSERT INTO #_output ([Demo], [Name], [Expected], [Actual])
SELECT 4, 'Demo 4', -0.02111, ROUND(@_corr_4, 4)



/***
	Select results from comparison table.
*/
SELECT O.Name, O.Expected, O.Actual
FROM #_output AS O



IF OBJECT_ID('tempdb.dbo.#_demo_1') IS NOT NULL DROP TABLE #_demo_1
IF OBJECT_ID('tempdb.dbo.#_demo_2') IS NOT NULL DROP TABLE #_demo_2
IF OBJECT_ID('tempdb.dbo.#_demo_3') IS NOT NULL DROP TABLE #_demo_3
IF OBJECT_ID('tempdb.dbo.#_demo_4') IS NOT NULL DROP TABLE #_demo_4
