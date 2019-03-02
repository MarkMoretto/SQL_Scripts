
/***
	Attempt at Stakoverflow question: 54958713
	URL: https://stackoverflow.com/questions/54958713/i-have-a-table-which-has-the-below-data

Title: I have a table with the below data
Body:

The table is

Id      name      department        salary
1       ABC       sales             20000
2       DEF       market            30000
3       POL       sales             35000      
4       SWE       market            26000
5       DTR       advert            10000
6       AWK       advert            10000

If I add the salary of sales department or market department or advert department
and if that each individual department sum is greater than 50000 then that should be displayed in the output,
like if I add the salary is sales department which is 20000 + 35000 = 55000
which is greater than 50000 that rows should be displayed in the output is that possible.

*/


------------------------------------------------------------------------------------------------
-- Create table and add data.
IF OBJECT_ID('tempdb.dbo.#_data') IS NOT NULL DROP TABLE #_data
CREATE TABLE #_data (
	[ID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[name] NCHAR(5),
	[department] NVARCHAR(25),
	[salary] FLOAT
)
INSERT INTO #_data ([name], [department], [salary])
VALUES ('ABC', 'sales', 20000),
		('DEF', 'market', 30000),
		('POL', 'sales', 35000),
		('SWE', 'market', 26000),
		('DTR', 'advert', 10000),
		('AWK', 'advert', 10000)



/***
	We'll use a subquery to get the total salary from each department then add in a WHERE clause
	to return only those records above our minimum salary threshold.
	If no minimu salary is given, the default is zero.
*/

------------------------------------------------------------------------------------------------
-- Example with minimum salary value
DECLARE @_min_salary NVARCHAR(10) = 50000

/***
	We first check to see if a value is given
*/
IF @_min_salary IS NULL
	/***
		If no value is given, then we set the minimum salary to zero and get results.
		NOTE: You can also abort the query or have it print a message indicating that
		a salary is required beofre running the query.
	*/
	BEGIN
		/***
			Set a new minimum salary value
		*/
		SET @_min_salary = 0
	END

/***
	Use a subquery to get total salaries by department.
	Reformat results for a currency format of your choice.
*/
SELECT X.[DEPARTMENT]
,	'$' + CONVERT(NVARCHAR(25), FORMAT(X.TOT_DEPT_SALARY, '#,#.00')) AS [SALARY]
FROM (
	SELECT department AS [DEPARTMENT]
	, SUM(salary) AS [TOT_DEPT_SALARY]

	FROM #_data
	GROUP BY department
) AS X
WHERE X.[TOT_DEPT_SALARY] > @_min_salary
GROUP BY X.DEPARTMENT, X.TOT_DEPT_SALARY




------------------------------------------------------------------------------------------------
-- Example with NO minimum salary value given
DECLARE @_no_min_salary NVARCHAR(10)
IF @_no_min_salary IS NULL
	BEGIN
		SET @_no_min_salary = 0
		SELECT X.[DEPARTMENT], X.TOT_DEPT_SALARY AS [SALARY]
		FROM (
			SELECT department AS [DEPARTMENT], SUM(salary) AS [TOT_DEPT_SALARY]
			FROM #_data
			GROUP BY department) AS X
		WHERE X.[TOT_DEPT_SALARY] > @_no_min_salary
	END
ELSE
	BEGIN
		SELECT X.[DEPARTMENT], X.TOT_DEPT_SALARY AS [SALARY]
		FROM (
			SELECT department AS [DEPARTMENT], SUM(salary) AS [TOT_DEPT_SALARY]
			FROM #_data
			GROUP BY department) AS X
		WHERE X.[TOT_DEPT_SALARY] > @_no_min_salary
	END