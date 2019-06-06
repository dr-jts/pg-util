--=====================================
-- Tests for Linear Referencincg Utilities
--=====================================

-- base line segment clipped to a shorter segment
SELECT ST_OrderingEquals( LineSubstringLine(
    'LINESTRING(0 0, 9 9)',
    'LINESTRING(1 1, 4 4)'),
    'LINESTRING(1 1, 4 4)')
-- base line with extra vertices
UNION SELECT ST_OrderingEquals( LineSubstringLine(
    'LINESTRING(0 0, 3 3, 9 9)',
    'LINESTRING(1 1, 4 4)'),
    'LINESTRING(1 1, 3 3, 4 4)')
-- clip line extending beyond base line
UNION SELECT ST_OrderingEquals( LineSubstringLine(
    'LINESTRING(1 1, 3 3, 5 5)',
    'LINESTRING(0 0, 9 9)'),
    'LINESTRING(1 1, 3 3, 5 5)')
-- test lines in opposite directions
UNION SELECT ST_OrderingEquals( ST_SnapToGrid( LineSubstringLine(
    'LINESTRING(1 1, 9 9)',
    'LINESTRING(8 8, 2 2)'),
        0.0000001 ),
    'LINESTRING(2 2, 8 8)')
;

SELECT LineMatch(
    'LINESTRING(0 0, 9 0)',
    'LINESTRING(1 0.1, 3 0.1)', 0.2)
UNION SELECT NOT LineMatch(
    'LINESTRING(0 0, 9 0)',
    'LINESTRING(1 0.1, 1 3)', 0.2)
;
