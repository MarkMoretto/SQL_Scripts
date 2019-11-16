-- SQL Project Planning
-- Ref: https://www.hackerrank.com/challenges/sql-projects/problem
-- Difficulty: Medium


USE MyTestDB


-- Create Projects table
DROP TABLE IF EXISTS #_Projects

CREATE TABLE #_Projects ([task_id] INTEGER IDENTITY(1,1) NOT NULL, [start_date] DATE, [end_date] DATE)
INSERT INTO #_Projects ([start_date], [end_date])
VALUES
('2015-10-01','2015-10-02'),
('2015-10-02','2015-10-03'),
('2015-10-03','2015-10-04'),
('2015-10-13','2015-10-14'),
('2015-10-14','2015-10-15'),
('2015-10-28','2015-10-29'),
('2015-10-30','2015-10-31')


---- Solution

--Declare table variables for submission purposes; Temp tables would work otherwise
DECLARE @_temp TABLE ([start_dt_test] DATE, [end_dt_test] DATE)
DECLARE @_starts TABLE ([idx] INT, [start_dt_test] DATE)
DECLARE @_ends TABLE ([idx] INT, [end_dt_test] DATE)

;WITH dtCTE AS (
	SELECT X.task_id
	,	X.[start_date]
	,	X.end_date
	,	X.[lead_end_date]
	,	X.[lag_end_date]
	,	DATEDIFF(DAY, X.end_date, X.[lead_end_date]) AS [end_to_lead_end_days] -- Check the day difference between an end date and "moved ahead" lead end date

	,	-- Omit start dates that were also end dates.
		CASE
			WHEN X.[start_date] = X.[lag_end_date] THEN NULL
			ELSE X.[start_date]
		END AS [start_dt_test]

	,	-- When [end_to_lead_end_days] is greater than 1 or NULL, then use end_date value
		CASE
			WHEN DATEDIFF(DAY, X.end_date, X.[lead_end_date]) > 1 OR DATEDIFF(DAY, X.end_date, X.[lead_end_date]) IS NULL THEN X.end_date
			ELSE NULL
		END AS [end_dt_test]
	FROM (
		-- Lots of time manipulation
		SELECT P.task_id, P.[start_date], P.[end_date]
		,	LEAD(P.[start_date], 1) OVER(ORDER BY P.[start_date], P.[end_date]) AS [lead_start_date]
		,	LAG(P.[start_date], 1) OVER(ORDER BY P.[start_date], P.[end_date]) AS [lag_start_date]
		,	LEAD(P.[end_date], 1) OVER(ORDER BY P.[start_date], P.[end_date]) AS [lead_end_date]
		,	LAG(P.[end_date], 1) OVER(ORDER BY P.[start_date], P.[end_date]) AS [lag_end_date]
		FROM #_Projects AS P
	) AS X
)
-- Populate our temp table variable
INSERT INTO @_temp ([start_dt_test], [end_dt_test])
SELECT start_dt_test, end_dt_test
FROM dtCTE

-- Select non-null start date values into table variable
-- Order by date value ascending and add a row number
INSERT INTO @_starts ([idx], [start_dt_test])
SELECT [idx] = ROW_NUMBER() OVER(ORDER BY start_dt_test)
,	start_dt_test
FROM @_temp
WHERE start_dt_test IS NOT NULL

-- Select non-null end date values into table variable
-- Order by date value ascending and add a row number
INSERT INTO @_ends ([idx], [end_dt_test])
SELECT [idx] = ROW_NUMBER() OVER(ORDER BY end_dt_test)
,	end_dt_test
FROM @_temp
WHERE end_dt_test IS NOT NULL

-- Join resulting tables on their indices
-- Calculate net date difference in days
-- Select results and order by net days ascending, start_date ascending.
SELECT Q.[start_date], Q.end_date
FROM (
SELECT S.start_dt_test AS [start_date], E.end_dt_test AS [end_date]
,	DATEDIFF(DAY, S.start_dt_test, E.end_dt_test) AS [net_days]
FROM @_starts AS S
INNER JOIN @_ends AS E ON E.idx = S.idx
) AS Q
ORDER BY Q.net_days ASC, Q.[start_date]


