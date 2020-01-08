/*
Stackoverflow question to https://stackoverflow.com/questions/59638257/sql-query-that-counts-the-number-of-characters-match-in-two-text-columns#59638257

Basice premise: Finding matching characters in two strings.  No stipulation was made about position of the characters.

The poster wanted MySQL, but I only have MS SQL.
*/



DROP TABLE IF EXISTS #_tmp
CREATE TABLE #_tmp (
	[RowNum] INT IDENTITY(1,1) PRIMARY KEY,
	[Template] NVARCHAR(20),
	[Answer] NVARCHAR(20),
	[Result] INT
)

INSERT INTO #_tmp
VALUES ('ABCDEABCDEABCDE','ABCDAABCDBABCDC', NULL),
('EDAEDAEDAEDAEDA','EDBEDBEDBEDBEDB', NULL)


DECLARE @_current_template NVARCHAR(50) -- Variable to hold the current template
,	@_current_answer NVARCHAR(50) -- Variable to hold the current answer
,	@_template_char CHAR(1) -- Char for template letter
,	@_answer_char CHAR(1) -- Char for answer letter
,	@_word_index INT -- Index (position) within each word
,	@_match_counter INT -- Match counter for each word
,	@_max_iter INT = (SELECT TOP 1 RowNum FROM #_tmp ORDER BY RowNum DESC) -- Max iterations
,	@_row_idx INT = (SELECT TOP 1 RowNum FROM #_tmp) -- Minimum RowNum as initial row index value.

WHILE (@_row_idx <= @_max_iter)
	BEGIN
		SET @_match_counter = 0 -- Reset match counter for each row
		SET @_word_index = 1 -- Reset word index for each row
		SET @_current_template = (SELECT [Template] FROM #_tmp WHERE RowNum = @_row_idx)
		SET @_current_answer = (SELECT [Answer] FROM #_tmp WHERE RowNum = @_row_idx)
		WHILE (@_word_index <= LEN(@_current_template))
			BEGIN
				SET @_template_char = SUBSTRING(@_current_template, @_word_index, 1)
				SET @_answer_char = SUBSTRING(@_current_answer, @_word_index, 1)
				IF (@_answer_char = @_template_char)
					BEGIN
						SET @_match_counter += 1
					END
				SET @_word_index += 1
			END

	UPDATE #_tmp
	SET Result = @_match_counter
	WHERE RowNum = @_row_idx

	SET @_row_idx += 1
	END

SELECT * FROM #_tmp
