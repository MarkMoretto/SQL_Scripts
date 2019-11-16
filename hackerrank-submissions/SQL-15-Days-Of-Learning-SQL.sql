-- 15 Days of Learning SQL
-- URI: https://www.hackerrank.com/challenges/15-days-of-learning-sql/problem
-- Difficulty: Hard


USE MyTestDB


DROP TABLE IF EXISTS #_Hackers
DROP TABLE IF EXISTS #_Submissions

CREATE TABLE #_Hackers ([hacker_id] INTEGER NOT NULL, [name] VARCHAR(50))
INSERT INTO #_Hackers
VALUES (15758, 'Rose'),
(20703, 'Angela'),
(36396, 'Frank'),
(38289, 'Patrick'),
(44065, 'Lisa'),
(53473, 'Kimberly'),
(62529, 'Bonnie'),
(79722, 'Michael')



CREATE TABLE #_Submissions ([submission_date] DATE, [submission_id] INTEGER, [hacker_id] INTEGER, [score] INTEGER)
INSERT INTO #_Submissions
VALUES ('2016-03-01',8494, 20703, 0),
	('2016-03-01',22403, 53473, 15),
	('2016-03-01',23965, 79722, 60),
	('2016-03-01',30173, 36396, 70),
	('2016-03-02',34928, 20703, 0),
	('2016-03-02',38740, 15758, 60),
	('2016-03-02',42769, 79722, 25),
	('2016-03-02',44364, 79722, 60),
	('2016-03-03',45440, 20703, 0),
	('2016-03-03',49050, 36396, 70),
	('2016-03-03',50273, 79722, 5),
	('2016-03-04',50344, 20703, 0),
	('2016-03-04',51360, 44065, 90),
	('2016-03-04',54404, 53473, 65),
	('2016-03-04',61533, 79722, 45),
	('2016-03-05',72852, 20703, 0),
	('2016-03-05',74546, 38289, 0),
	('2016-03-05',76487, 62529, 0),
	('2016-03-05',82439, 36396, 10),
	('2016-03-05',90006, 36396, 40),
	('2016-03-06',90404, 20703, 0)


;WITH dtCTE AS (
	-- Retrieve minimum date in data set
	SELECT MIN(submission_date) AS [min_dt]
	FROM #_Submissions
)
, byday AS (
	-- Count of hacker_id by date
	SELECT S.submission_date
	,	S.hacker_id
	,	COUNT(1) OVER(PARTITION BY S.submission_date, S.hacker_id ORDER BY S.submission_date, S.hacker_id) AS [id_count_by_dt]
	FROM #_Submissions AS S
)
, baseCTE1 AS (
	-- Join Hackers table to get hacker name
	SELECT Q.submission_date
	,	Q.max_hacker_id
	,	H.[name] AS [hacker_name]
	FROM (
		-- Rejoin byday onto results from max id count query; Return minimum hacker_id
		-- with the maximum count for each date
		SELECT Z.submission_date
		,	MIN(Z.hacker_id) AS [max_hacker_id]
		FROM (
			-- Get max id_count for each date
			SELECT submission_date
			,	MAX(id_count_by_dt) AS [max_count_by_dt]
			FROM byday --> Prior CTE
			GROUP BY submission_date
		) AS Q
		INNER JOIN byday AS Z --> Prior CTE
			ON Z.submission_date = Q.submission_date AND Z.id_count_by_dt = Q.max_count_by_dt
		GROUP BY Z.submission_date
	) AS Q
	INNER JOIN #_Hackers AS H ON H.hacker_id = Q.max_hacker_id
)
, initCTE AS (
	-- Set static date variable to check perpetuity of hacker_id value
	SELECT submission_date
	,	hacker_id
	,	DATEADD(DAY, -ROW_NUMBER() OVER(PARTITION BY hacker_id ORDER BY submission_date) + 1, submission_date) AS [start_dt] --> [Clause]
	FROM #_Submissions
	GROUP BY submission_date, hacker_id
	-- [Clause]: Inverse additive to DATEADD() to revert the current date back to the start date.
	-- This is padded with 1 to offset ROW_NUMBER() starting at 1 and not zero
)
, baseCTE2 AS (
	-- Sum unique_date values by date to find unique hacker_ids that have 
	SELECT X.submission_date
	,	SUM(X.unique_dt) AS [unique_id_count]
	FROM (
		SELECT IC.submission_date
		, IC.hacker_id
		, CASE WHEN IC.start_dt = D.min_dt THEN 1 ELSE 0 END AS [unique_dt] --> [Case Statement]
		FROM initCTE AS IC, dtCTE AS D
		-- [Case Statement]: Looks for start date to equal minimum date, indicating that
		-- the record has continued since the beginning of the data set
	) AS X
	GROUP BY X.submission_date
)
-- Select results for output
-- BaseCTE1 and baseCTE2 should have unique rows by now, so joining on submission_date is appropriate
SELECT B1.submission_date, B2.unique_id_count, B1.max_hacker_id, B1.hacker_name
FROM baseCTE1 AS B1
INNER JOIN baseCTE2 AS B2 ON B2.submission_date = B1.submission_date
ORDER BY B1.submission_date

