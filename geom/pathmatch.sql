--=====================================
-- Path Matching Utilities
--=====================================

-------------------------------------
-- Function: LineSubstringLine
--
-- Extract substring of line determined by
-- closest locations to start and end of clipLine
-------------------------------------
CREATE OR REPLACE FUNCTION LineSubstringLine(
    line geometry,
    clipLine geometry
)
RETURNS geometry AS
$$
DECLARE
  loc1 float8;
  loc2 float8;
  tmp float8;
BEGIN
  loc1 = ST_LineLocatePoint(line, ST_StartPoint( clipLine ));
  loc2 = ST_LineLocatePoint(line, ST_EndPoint( clipLine ));
  -- locations must be in order along target line
  IF loc1 > loc2 THEN
    tmp = loc1;
    loc1 = loc2;
    loc2 = tmp;
  END IF;
  RETURN ST_LineSubstring( line, loc1, loc2 );
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;

-------------------------------------
-- Function: PathMatchesLine
--
-- Test if a path matches a line within a match distance tolerance
-------------------------------------
CREATE OR REPLACE FUNCTION PathMatchesLine(
    pathLine geometry,
    line geometry,
    matchDist float8
)
RETURNS boolean AS
$$
BEGIN
  RETURN matchDist >= ST_HausdorffDistance(
    LineSubstringLine( pathLine, line ), line);
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;
