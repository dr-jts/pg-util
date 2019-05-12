----------------------------------------
-- Function: svgDoc
----------------------------------------
CREATE OR REPLACE FUNCTION svgDoc(
  content text[],
  extent geometry,
  width integer DEFAULT -1,
  height integer DEFAULT -1,
  style text DEFAULT ''
)
RETURNS text AS
$$
DECLARE
  vbData text;
  viewBox text;
  styleAttr text;
  widthAttr text;
  heightAttr text;
  svg text;
  xSize real;
  ySize real;
BEGIN
  xSize = ST_XMax(extent) - ST_XMin(extent);
  ySize = ST_YMax(extent) - ST_YMin(extent);
  vbData := ST_XMin(extent) || ' ' || -ST_YMax(extent) || ' ' || xSize || ' ' || ySize;
  viewBox := 'viewBox="' || vbData || '" ';

  styleAttr := '';
  IF style <> '' THEN
    styleAttr := ' style="' || style || '" ';
  END IF;

  widthAttr := '';
  IF width >= 0 THEN
    widthAttr := ' width="' || width || '" ';
  END IF;

  heightAttr := '';
  IF height >= 0 THEN
    heightAttr := ' height="' || height || '" ';
  END IF;

  svg := '<svg ' || widthAttr || heightAttr
    || viewBox || styleAttr || 'xmlns="http://www.w3.org/2000/svg">' || E'\n';

  FOR i IN 1..array_length( content, 1) LOOP
    svg := svg || contents[i] || E'\n';
  END LOOP;

  svg := svg || '</svg>';
  return svg;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;


----------------------------------------
-- Function: svgShape
----------------------------------------
CREATE OR REPLACE FUNCTION svgShape(
  geom geometry,
  class text DEFAULT '',
  id text DEFAULT '',
  style text DEFAULT '',
  attr text DEFAULT '',
  radius float DEFAULT 1
)
RETURNS text AS
$$
DECLARE
  svg_geom text;
  svg_pts text;
  fillrule text;
  classAttr text;
  idAttr text;
  styleAttr text;
  attrs text;
  pathAttrs text;
  radiusAttr text;
  tag text;
  geom_dump geometry[];
  gcomp geometry;
  outstr text;
BEGIN
 classAttr := '';
 IF class <> '' THEN
  classAttr :=  (' class="' || class || '"');
 END IF;

 idAttr := '';
 IF id <> '' THEN
  idAttr := ' id="' || id || '"';
 END IF;

 styleAttr := '';
 IF style <> '' THEN
  styleAttr := ' style="' || style || '"';
 END IF;

 attrs := classAttr || idAttr || styleAttr || attr;
 geom_dump := ARRAY( SELECT (ST_Dump( geom )).geom );

 IF array_length( geom_dump,1 ) > 1 THEN
   outstr := '<g ' || attrs || '>' || E'\n';
   pathAttrs := '';
 ELSE
   outstr := '';
   pathAttrs := attrs;
 END IF;

 FOR i IN 1..array_length( geom_dump,1 ) LOOP
   gcomp := geom_dump[i];
   svg_pts := ST_AsSVG( gcomp );
   tag := 'path';
   radiusAttr := '';
   -- points already have attribute names
   IF ST_Dimension(geom) > 0 THEN
     svg_pts := ' d="' || svg_pts || '" ';
   ELSE
     tag := 'circle';
     radiusAttr := ' r="' || radius || '" ';
   END IF;

   CASE ST_Dimension(geom)
   WHEN 1 THEN fillrule := ' fill="none" ';
   WHEN 2 THEN fillrule := ' fill-rule="evenodd" ';
   ELSE fillrule := '';
   END CASE;

   IF i > 1 THEN
     outstr := outstr || E'\n';
   END IF;

   svg_geom := '<' || tag || ' ' || pathAttrs || fillrule
     || radiusAttr
     || ' ' || svg_pts || ' />';
   outstr := outstr || svg_geom;
 END LOOP;

  IF array_length( geom_dump,1 ) > 1 THEN
   outstr := outstr || E'\n' || '</g>';
 END IF;

 RETURN outstr;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;

----------------------------------------
-- Function: svgStyle
-- Encodes CSS name:values from list of parameters
----------------------------------------
CREATE OR REPLACE FUNCTION svgStyle(
  VARIADIC arr text[]
)
RETURNS TEXT AS
$$
DECLARE
  strokeStr text;
  strokeWidthStr text;
  style text;
BEGIN
  style := '';
  FOR i IN 1..array_length( arr, 1)/2 LOOP
    style := style || arr[2*i-1] || ':' || arr[2*i] || '; ';
  END LOOP;
 return style;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;

----------------------------------------
-- Function: svgStyleProp
-- Encodes named parameters as CSS name-values
----------------------------------------
CREATE OR REPLACE FUNCTION svgStyleProp(
  stroke text DEFAULT '',
  stroke_width real DEFAULT -1
)
RETURNS text AS
$$
DECLARE
  strokeStr text;
  strokeWidthStr text;
  style text;
BEGIN

  strokeStr := '';
  IF stroke <> '' THEN
    strokeStr :=  (' stroke:' || stroke || ';');
  END IF;

  strokeWidthStr := '';
  IF stroke_width >= 0 THEN
    strokeWidthStr :=  (' stroke-width:' || stroke_width || ';');
  END IF;

  style := strokeStr || strokeWidthStr;
  RETURN style;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;

----------------------------------------
-- Function: svgHSL
-- Encodes HSL function call
----------------------------------------
CREATE OR REPLACE FUNCTION svgHSL(
  h real,
  s real DEFAULT 100,
  l real DEFAULT 50
)
RETURNS text AS
$$
BEGIN
  RETURN 'hsl(' || h || ',' || s || '%,' || l || '%)';
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;
