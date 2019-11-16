-- SQL Draw The Triangle 2
-- Ref: https://www.hackerrank.com/challenges/draw-the-triangle-2/problem
-- Difficulty: Easy (?)



DECLARE @_i INT = 20
DECLARE @_output NVARCHAR(MAX) = ''
WHILE (@_i > 0)
	BEGIN
		SET @_output += REPLICATE(N'* ', @_i) + CHAR(13) + CHAR(10)
		SET @_i -= 1
	END
PRINT @_output

