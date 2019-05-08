-- ---------------------------------
-- Sierpinski carpet, as GEoJSON
-- Parameter: level
-- ---------------------------------

WITH RECURSIVE centres AS (
  SELECT 0.5 as x, 0.5 as y, 1.0/3.0 AS size, 1 as level
  UNION ALL 
  SELECT x + dx * size, y + dy * size, size/3.0, level
    FROM (
      SELECT x, y, dx, dy, 1.0/(3.0 ^ level) AS size, level+1 as level 
      FROM generate_series(-1, 1) AS xoff(dx)
        CROSS JOIN generate_series(-1, 1) AS yoff(dy)
        CROSS JOIN centres
      WHERE not( dx = 0 AND dy = 0) AND level < 3
    ) dd
),
holes as (
  SELECT ST_MakeEnvelope(x - size/2, y - size/2, x + size/2, y + size/2) AS hole
  FROM centres
),
sierpinski_carpet AS (
  SELECT ST_MakePolygon( ST_ExteriorRing(ST_MakeEnvelope(0,0,1,1)), 
    array_agg( ST_ExteriorRing(hole)) ) AS geom from holes
)
select ST_AsGeoJSON( ST_Translate( ST_Scale(geom, 10, 10 ), 0, 23), 2 ) from sierpinski_carpet;

-- ---------------------------------
-- Hilbert curve, as WKT
-- Parameter: iteration
-- ---------------------------------

WITH RECURSIVE lsystem AS (
  SELECT 'A' AS state, 0 AS iteration
  UNION ALL
  SELECT replace(replace(replace(state, 'A', '-CF+AFA+FC-'), 'B', '+AF-BFB-FA+'), 'C', 'B'), iteration+1 AS iteration
  FROM lsystem WHERE iteration < 6
),
path AS (
  SELECT replace(replace(state, 'A', ''), 'B', '') AS moves 
  FROM (SELECT state FROM lsystem ORDER BY iteration DESC LIMIT 1) st
),
pts AS (
  SELECT moves AS moves, 1 AS index, ' ' AS dir, 0 AS x, 0 AS y, 1 AS dx, 0 AS dy, 0 AS len  from path
  UNION ALL
  SELECT moves, index+1 AS index, substr(moves, index, 1) AS dir,
      x + len*dx AS x, 
      y + len*dy AS y,
      CASE substr(moves, index, 1) WHEN '-' THEN -dy WHEN '+' THEN  dy ELSE dx END AS dx, 
      CASE substr(moves, index, 1) WHEN '-' THEN  dx WHEN '+' THEN -dx ELSE dy END AS dy,
      CASE substr(moves, index, 1) WHEN 'F' THEN 1 ELSE 0 END AS len
    FROM pts WHERE index <= length(moves)
),
hilbert AS ( 
  SELECT ST_RemoveRepeatedPoints( ST_MakeLine( ST_MakePoint( x, y ) ORDER BY index ) ) AS line FROM pts 
)
SELECT ST_AsText(line) from hilbert;
            
                                                         
 -- ---------------------------------
-- Dragon curve, as WKT
-- Parameter: iteration
-- ---------------------------------

WITH RECURSIVE lsystem AS (
  SELECT 'FX' AS state, 0 AS iteration
  UNION ALL
  SELECT replace(replace(replace(state, 'X', 'X+zF+'), 'Y', '-FX-Y'), 'z', 'Y'), iteration+1 AS iteration
  FROM lsystem WHERE iteration < 10
),
path AS (
  SELECT replace(replace(state, 'A', ''), 'B', '') AS moves 
  FROM (SELECT state FROM lsystem ORDER BY iteration DESC LIMIT 1) st
),
pts AS (
  SELECT moves AS moves, 1 AS index, ' ' AS dir, 0 AS x, 0 AS y, 1 AS dx, 0 AS dy, 0 AS len  from path
  UNION ALL
  SELECT moves, index+1 AS index, substr(moves, index, 1) AS dir,
      x + len*dx AS x, 
      y + len*dy AS y,
      CASE substr(moves, index, 1) WHEN '-' THEN -dy WHEN '+' THEN  dy ELSE dx END AS dx, 
      CASE substr(moves, index, 1) WHEN '-' THEN  dx WHEN '+' THEN -dx ELSE dy END AS dy,
      CASE substr(moves, index, 1) WHEN 'F' THEN 1 ELSE 0 END AS len
    FROM pts WHERE index <= length(moves)
),
dragon AS ( 
  SELECT ST_RemoveRepeatedPoints( ST_MakeLine( ST_MakePoint( x, y ) ORDER BY index ) ) AS line FROM pts 
)
SELECT ST_AsText(line) from dragon;
