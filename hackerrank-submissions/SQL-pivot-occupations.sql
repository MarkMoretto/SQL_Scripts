
--Ref: https://www.hackerrank.com/challenges/occupations/problem

Use MyTestDB
SET QUOTED_IDENTIFIER OFF
DROP TABLE IF EXISTS #_OCCUPATIONS
CREATE TABLE #_OCCUPATIONS (
	[Name] VARCHAR(100)
	,	[Occupation] VARCHAR(100)
)

INSERT INTO #_OCCUPATIONS
VALUES ('Samantha','Doctor'),
('Julia','Actor'),
('Maria','Actor'),
('Meera','Singer'),
('Ashley','Professor'),
('Ketty','Professor'),
('Christeen','Professor'),
('Jane','Actor'),
('Jenny','Doctor'),
('Priya','Singer')


--DROP TABLE IF EXISTS #_tmp_occ
--SELECT ROW_NUMBER() OVER(PARTITION BY X.Occupation ORDER BY X.[Name], X.[occ_rank]) as [person_id]
--,	X.*
--INTO #_tmp_occ
--FROM (
--SELECT O.*
--,	CASE O.Occupation WHEN 'Doctor' THEN 0 WHEN 'Professor' THEN 1 WHEN 'Singer' THEN 2 ELSE 3 END AS [occ_rank]
--FROM #_OCCUPATIONS AS O
--) AS X
--SELECT * FROM #_tmp_occ



;WITH tmp_occ AS (
	SELECT ROW_NUMBER() OVER(PARTITION BY X.Occupation ORDER BY X.[Name], X.[occ_rank]) as [person_id]
	,	X.*
	FROM (
	SELECT O.*
	,	CASE O.Occupation WHEN 'Doctor' THEN 0 WHEN 'Professor' THEN 1 WHEN 'Singer' THEN 2 ELSE 3 END AS [occ_rank]
	FROM #_OCCUPATIONS AS O
	) AS X
)
SELECT pvt.[Doctor], pvt.[Professor], pvt.[Singer], pvt.[Actor]
FROM (
SELECT TOC.Person_id, TOC.[Name], TOC.Occupation
FROM tmp_occ AS TOC
) AS p
PIVOT (
	MAX([Name]) FOR [Occupation] IN ([Doctor], [Professor], [Singer], [Actor])
) as pvt
GROUP BY pvt.person_id, [Doctor], [Professor], [Singer], [Actor]




