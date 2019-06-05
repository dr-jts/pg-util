--=====================================
-- Linear Referencincg Utilities
--=====================================

CREATE OR REPLACE FUNCTION LineSubstringLine(
    line geometry,
    clipLine geometry
)
RETURNS geometry AS
$$
BEGIN
  RETURN ST_LineSubstring( line,
    ST_LineLocatePoint(line, ST_StartPoint( clipLine )),
    ST_LineLocatePoint(line, ST_EndPoint( clipLine ))
  );
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
