/************************************************************
Calculate curved monitor measurements
and how many monitors will be required for a 360-degree circle.
************************************************************/


DECLARE @_screen_size_diag_inch FLOAT = 27	-- Screen size (in inches)
,	@_aspect_ratio NVARCHAR(6) = '16:9'		-- Aspect ratio
,	@_radius_mm FLOAT = 1500				-- Vertex of curvature
,	@_mm_per_inch NUMERIC(3, 1) = 25.4		-- Millimeters per inch


DECLARE @_ratio FLOAT
,	@_screen_size_cm FLOAT
,	@_opposite_y FLOAT
,	@_adjacent_x INT
,	@_width_in FLOAT
,	@_height_in FLOAT
,	@_width_mm FLOAT
,	@_height_mm FLOAT
,	@_arc_measure FLOAT
,	@_arc_length_deg FLOAT
,	@_required_units FLOAT

SET @_opposite_y = (SELECT CONVERT(FLOAT, SUBSTRING(@_aspect_ratio, 0, PATINDEX('%[:]%', @_aspect_ratio))))
SET @_adjacent_x = (SELECT CONVERT(INT, SUBSTRING(REVERSE(@_aspect_ratio), 0, PATINDEX('%[:]%', REVERSE(@_aspect_ratio)))))
SET @_ratio = (SELECT @_opposite_y / @_adjacent_x)

SET @_width_in = (SELECT (@_opposite_y * @_screen_size_diag_inch) / SQRT((@_adjacent_x*@_adjacent_x) + (@_opposite_y*@_opposite_y)))
SET @_width_mm = (SELECT @_width_in * @_mm_per_inch)

--SET @_height_in = (SELECT (@_adjacent_x * @_screen_size_diag_inch) / SQRT((@_adjacent_x*@_adjacent_x) + (@_opposite_y*@_opposite_y)))
--SET @_height_mm = (SELECT @_height_in * @_mm_per_inch)


SET @_arc_measure = (SELECT @_width_mm / @_radius_mm)
SET @_arc_length_deg = ((@_arc_measure * 180)/ PI())
SET @_required_units = (360 / @_arc_length_deg)
SELECT @_required_units AS [reqd_displays]
, ROUND(@_required_units + 0.5, 0) AS [reqd_displays_rounded]





/*
DROP TABLE IF EXISTS #_measures
CREATE TABLE #_measures (
	[width_inch] NUMERIC(10, 4)
	,	[width_mm] NUMERIC(10, 4)
	,	[height_inch] NUMERIC(10, 4)
	,	[height_mm] NUMERIC(10, 4)
)


INSERT #_measures
SELECT ROUND(@_width_in, 4) AS [width_inch]
, ROUND(@_width_mm, 4) AS [width_mm]
, ROUND(@_height_in, 4) AS [height_inch]
, ROUND(@_height_mm, 4) AS [height_mm]
*/
--SELECT * FROM #_measures
