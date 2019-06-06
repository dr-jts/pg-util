--=====================================
-- Linear Referencincg Utilities
--=====================================

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

CREATE OR REPLACE FUNCTION LineMatch(
    line1 geometry,
    line2 geometry,
    matchTol float8
)
RETURNS boolean AS
$$
BEGIN
  RETURN matchTol >= ST_HausdorffDistance(
    LineSubstringLine( line1, line2 ), line2);
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;
