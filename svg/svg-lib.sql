CREATE OR REPLACE FUNCTION svgDoc(
  paths text[],
  extent geometry,
  width integer DEFAULT -1,
  height integer DEFAULT -1,
  style text DEFAULT ''
)
RETURNS TEXT AS 
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

  FOR i IN 1..array_length( paths, 1) LOOP
    svg := svg || paths[i] || E'\n';
  END LOOP;

  svg := svg || '</svg>';
  return svg;
END; 
$$ 
LANGUAGE 'plpgsql' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION svgPath(
  geom geometry,
  class TEXT DEFAULT '',
  id TEXT DEFAULT '',
  style TEXT DEFAULT ''
)
RETURNS TEXT AS 
$$
DECLARE 
 svg_geom text;
 fillrule text;
 classAttr TEXT;
 idAttr TEXT;
 styleAttr TEXT;

BEGIN
  -- TODO: wrap multigeoms in g element

 fillrule := ' fill="none" ';
 IF ST_Dimension(geom) = 2 THEN
   fillrule := ' fill-rule="evenodd" ';
 END IF;

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

 svg_geom := ST_AsSVG(geom);
 -- points already have attribute names
 IF ST_Dimension(geom) > 0 THEN
  svg_geom := ' d="' || svg_geom || '" ';
 END IF; 

 return ( '<path' || classAttr || idAttr || styleAttr || fillrule || ' ' || svg_geom || ' />' )::text;
END; 
$$ 
LANGUAGE 'plpgsql' IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION svgStyleProp(
  VARIADIC arr text[]
)
RETURNS TEXT AS 
$$
DECLARE 
 strokeStr text;
 strokeWidthStr text;
 style TEXT;
BEGIN
  style := '';
  FOR i IN 1..array_length( arr, 1)/2 LOOP
    style := style || arr[2*i-1] || ':' || arr[2*i] || '; ';
  END LOOP;
 return style;
END; 
$$ 
LANGUAGE 'plpgsql' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION svgStyle(
  stroke TEXT DEFAULT '',
  stroke_width real DEFAULT -1
)
RETURNS TEXT AS 
$$
DECLARE 
 strokeStr text;
 strokeWidthStr text;
 style TEXT;
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
 return style;
END; 
$$ 
LANGUAGE 'plpgsql' IMMUTABLE STRICT;
